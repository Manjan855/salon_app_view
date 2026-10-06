-- =============================================================================
-- Salon App — Triggers, Helper Functions & Availability RPC
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Generic updated_at maintenance
-- -----------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

do $$
declare t text;
begin
  foreach t in array array['profiles','salons','services','staff','bookings','payments','reviews']
  loop
    execute format(
      'create trigger set_updated_at before update on public.%I
         for each row execute function public.set_updated_at()', t);
  end loop;
end;
$$;

-- -----------------------------------------------------------------------------
-- 2. Auto-create a profile row when a user signs up
-- Reads auth.users.raw_user_meta_data so AuthProvider.signUp({data:{name:...}})
-- immediately produces a profiles row (fixes the login "profile incomplete" path).
-- -----------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.profiles (id, name, email, persona)
  values (
    new.id,
    coalesce(
      nullif(trim(new.raw_user_meta_data ->> 'name'), ''),
      nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''),
      split_part(coalesce(new.email, 'user'), '@', 1)
    ),
    new.email,
    'customer'
  )
  on conflict (id) do update
    set email = excluded.email,
        updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- -----------------------------------------------------------------------------
-- 3. profiles: never let a client write somebody else's row, and never let it
--    forge the email address. Service role (auth.uid() is null) is unrestricted,
--    so seeding/admin tooling still works.
-- -----------------------------------------------------------------------------
-- SECURITY DEFINER: the trigger fires as the calling role (e.g. `authenticated`),
-- which has no SELECT privilege on auth.users.
create or replace function public.protect_profile()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then
    return new;                       -- service role / admin / signup trigger
  end if;

  if new.id is distinct from v_uid then
    raise exception 'You may only write your own profile';
  end if;

  -- email always mirrors auth.users so it cannot be tampered with
  select u.email into new.email from auth.users u where u.id = v_uid;
  return new;
end;
$$;

drop trigger if exists protect_profile on public.profiles;
create trigger protect_profile
  before insert or update on public.profiles
  for each row execute function public.protect_profile();

-- -----------------------------------------------------------------------------
-- 4. bookings: derive booking_date_time, generate pickup OTP, block past slots
--    Uses Asia/Kathmandu (UTC+05:45, no DST) so date+time round-trips exactly.
-- -----------------------------------------------------------------------------
create or replace function public.set_booking_times()
returns trigger
language plpgsql
as $$
begin
  new.booking_date_time := (new.booking_date + new.start_time) at time zone 'Asia/Kathmandu';

  -- Only enforce the "no past slots" rule when the slot itself changes.
  -- Otherwise confirming/completing an already-past appointment would fail.
  -- (OLD is unassigned on INSERT, so it must not be touched on that path.)
  if TG_OP = 'INSERT' then
    if (new.booking_date + new.start_time) <= (now() at time zone 'Asia/Kathmandu') then
      raise exception 'Cannot book a slot in the past';
    end if;
  elsif new.booking_date is distinct from old.booking_date
     or new.start_time   is distinct from old.start_time then
    if (new.booking_date + new.start_time) <= (now() at time zone 'Asia/Kathmandu') then
      raise exception 'Cannot book a slot in the past';
    end if;
  end if;

  -- 6-digit code the salon asks for (shown on the appointment card)
  if new.otp_code is null and new.status in ('pending','confirmed') then
    new.otp_code := lpad((floor(random() * 1000000))::int::text, 6, '0');
  end if;

  if new.end_time <= new.start_time then
    raise exception 'end_time must be after start_time';
  end if;

  return new;
end;
$$;

drop trigger if exists set_booking_times on public.bookings;
create trigger set_booking_times
  before insert or update on public.bookings
  for each row execute function public.set_booking_times();

-- -----------------------------------------------------------------------------
-- 5. bookings: prevent double-booking of the same staff member.
--    An advisory transaction lock serialises concurrent requests for the same
--    staff member so two customers cannot grab the same slot.
-- -----------------------------------------------------------------------------
-- SECURITY DEFINER: the overlap check must see OTHER customers' bookings, and
-- under RLS a customer can only see their own — without this the check would
-- silently pass and two people could take the same slot.
create or replace function public.prevent_double_booking()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare v_overlap int;
begin
  if new.staff_id is null then
    return new;
  end if;

  perform pg_advisory_xact_lock(hashtextextended(new.staff_id::text, 42));

  if new.status in ('cancelled', 'no_show') then
    return new;
  end if;

  select count(*) into v_overlap
  from public.bookings b
  where b.staff_id = new.staff_id
    and b.booking_date = new.booking_date
    and b.status in ('pending','confirmed')
    and (b.id is distinct from new.id)
    and b.start_time < new.end_time
    and b.end_time   > new.start_time;

  if v_overlap > 0 then
    raise exception 'That stylist already has a booking overlapping % %',
      new.booking_date, new.start_time;
  end if;

  return new;
end;
$$;

drop trigger if exists prevent_double_booking on public.bookings;
create trigger prevent_double_booking
  before insert or update on public.bookings
  for each row execute function public.prevent_double_booking();

-- -----------------------------------------------------------------------------
-- 6. reviews: keep salons.rating_avg / rating_count in sync
-- -----------------------------------------------------------------------------
create or replace function public.update_salon_rating()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare v_salon uuid := coalesce(new.salon_id, old.salon_id);
begin
  update public.salons s
  set rating_avg   = coalesce((select round(avg(r.rating)::numeric, 2)
                               from public.reviews r
                               where r.salon_id = v_salon and r.is_visible), 0),
      rating_count = (select count(*) from public.reviews r
                      where r.salon_id = v_salon and r.is_visible),
      updated_at   = now()
  where s.id = v_salon;
  return coalesce(new, old);
end;
$$;

drop trigger if exists reviews_rating_sync on public.reviews;
create trigger reviews_rating_sync
  after insert or update or delete on public.reviews
  for each row execute function public.update_salon_rating();

-- =============================================================================
-- 7. Availability RPC
--    Backs lib/features/salon_detail/slots_screen.dart and
--    lib/features/booking/booking_slot_screen.dart with real data.
--
--    Returns every candidate slot for a given salon/staff/day and flags which
--    ones are already taken. Slots in the past, outside the salon's opening
--    hours, outside the stylist's working window, or overlapping an existing
--    booking come back with is_available = false.
-- =============================================================================
create or replace function public.get_available_slots(
  p_salon_id uuid,
  p_date date,
  p_staff_id uuid default null,
  p_duration_minutes int default null,
  p_include_unavailable boolean default false
)
returns table (
  slot_start     timestamptz,
  slot_end       timestamptz,
  is_available   boolean,
  unavailable_reason text
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_open       time;
  v_close      time;
  v_step       int;
  v_dur        int;
  v_weekday    int;
  v_has_window boolean;
  v_now_local  timestamp := (now() at time zone 'Asia/Kathmandu');
begin
  if p_duration_minutes is not null and p_duration_minutes > 0 then
    v_dur := p_duration_minutes;
  else
    v_dur := 30;
  end if;

  select s.opening_time, s.closing_time, s.slot_minutes
    into v_open, v_close, v_step
  from public.salons s
  where s.id = p_salon_id and s.is_active;

  if not found then
    return;
  end if;

  -- step must fit at least one slot
  if v_step > v_dur then
    v_step := v_dur;
  end if;

  v_weekday := extract(dow from p_date)::int;

  -- Staff window: intersect with salon hours when the stylist has a schedule.
  -- A stylist with no rows for this weekday is treated as off duty.
  if p_staff_id is not null then
    select exists (
      select 1 from public.staff_availability a
      where a.staff_id = p_staff_id and a.weekday = v_weekday
    ) into v_has_window;

    -- No rows for this weekday == the stylist is off duty. No slots at all.
    if not v_has_window then
      return;
    end if;

    select greatest(v_open, min(a.start_time)), least(v_close, max(a.end_time))
      into v_open, v_close
    from public.staff_availability a
    where a.staff_id = p_staff_id and a.weekday = v_weekday;

    if v_close <= v_open then
      return;   -- stylist is effectively off today
    end if;
  end if;

  return query
  with slots as (
    select s::timestamp as ts
    from generate_series(
      (p_date + v_open)::timestamp,
      (p_date + v_close)::timestamp - make_interval(mins => v_dur),
      make_interval(mins => v_step)
    ) s
  ),
  busy as (
    select b.start_time as bs, b.end_time as be
    from public.bookings b
    where b.salon_id = p_salon_id
      and b.booking_date = p_date
      and b.status in ('pending','confirmed')
      and (p_staff_id is null or b.staff_id = p_staff_id)
  )
  select
    (sl.ts at time zone 'Asia/Kathmandu')::timestamptz,
    (sl.ts + make_interval(mins => v_dur)) at time zone 'Asia/Kathmandu',
    case
      when sl.ts < v_now_local then false
      when exists (select 1 from busy b where b.bs < sl.ts + make_interval(mins => v_dur)
                                            and b.be > sl.ts) then false
      else true
    end,
    case
      when sl.ts < v_now_local then 'past'
      when exists (select 1 from busy b where b.bs < sl.ts + make_interval(mins => v_dur)
                                            and b.be > sl.ts) then 'booked'
      else null
    end
  from slots sl
  where p_include_unavailable
     or (sl.ts >= v_now_local
         and not exists (select 1 from busy b
                         where b.bs < sl.ts + make_interval(mins => v_dur)
                           and b.be > sl.ts))
  order by 1;
end;
$$;

comment on function public.get_available_slots(uuid, date, uuid, int, boolean) is
  'Real slot availability for a salon/stylist/day. Set p_include_unavailable=true to get the full grid with reasons.';

-- =============================================================================
-- 8. Salon search RPC — powers home/explore search with fuzzy + city matching
-- =============================================================================
create or replace function public.search_salons(
  p_query text default null,
  p_city text default null,
  p_limit int default 50,
  p_offset int default 0
)
returns setof public.salons
language sql
stable
security invoker
set search_path = public, pg_temp
as $$
  select *
  from public.salons s
  where s.is_active
    and (p_city is null or lower(s.city) = lower(p_city))
    and (p_query is null
         or s.name % p_query
         or s.name ilike '%' || p_query || '%'
         or s.city  ilike '%' || p_query || '%'
         or coalesce(s.description,'') ilike '%' || p_query || '%')
  order by s.rating_avg desc, s.rating_count desc, s.name
  limit p_limit offset p_offset;
$$;
