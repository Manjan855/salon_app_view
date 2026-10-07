-- ==========================================================================
-- Salon App - CORE BUILD SCRIPT (paste #1 of 2)
-- ==========================================================================
-- Paste this ENTIRE file into the Supabase SQL Editor and click RUN.
-- Runs as ONE transaction: it either fully succeeds or fully rolls back.
-- 
-- Files, in dependency order:
--   supabase/migrations/20261005235959_archive_legacy_schema.sql
--   supabase/migrations/20261006000001_schema.sql
--   supabase/migrations/20261006000002_functions.sql
--   supabase/migrations/20261006000003_rls.sql
--   supabase/migrations/20261006000005_backfill_profiles.sql
--   supabase/seed.sql


-- ==========================================================================
-- FILE: supabase/migrations/20261005235959_archive_legacy_schema.sql
-- ==========================================================================

-- =============================================================================
-- Salon App — Archive legacy hand-made schema
-- Run this FIRST, before 20261006000001_schema.sql
--
-- Why this and not DROP:
--   The live project already contains 8 hand-made tables. They return 0 rows to
--   the anon key, but that could be row-level security hiding rows rather than
--   the tables genuinely being empty — so we cannot prove from outside that
--   there is no data worth keeping.
--
--   Moving them to the `archive` schema takes them out of the API entirely
--   (PostgREST only exposes `public`) while keeping them recoverable.
--
--   Once you have confirmed nothing is needed:
--       drop schema archive cascade;
--
-- Idempotent: skips any table that no longer exists.
-- =============================================================================
create schema if not exists archive;

do $$
declare t text;
begin
  foreach t in array array[
    'staff_services', 'staff_profiles', 'appointments', 'payments',
    'bookings', 'services', 'salons', 'profiles'
  ] loop
    if to_regclass('public.' || t) is not null then
      execute format('alter table public.%I set schema archive', t);
      raise notice 'archived public.%', t;
    else
      raise notice 'skipped public.% (does not exist)', t;
    end if;
  end loop;
end;
$$;

comment on schema archive is
  'Pre-existing hand-made salon schema, archived 2026-10-06. Drop once the rebuilt schema is confirmed.';

-- ==========================================================================
-- FILE: supabase/migrations/20261006000001_schema.sql
-- ==========================================================================

-- =============================================================================
-- Salon App — Core Schema
-- Nepal-first production schema for the customer-facing Flutter app.
--
-- Conventions
--   * All money is NPR (Nepalese Rupee), stored as numeric(10,2).
--   * All timestamps are timestamptz; the app timezone is Asia/Kathmandu (UTC+05:45,
--     no DST). Booking date/time are stored as local date + time and combined
--     into `bookings.booking_date_time` by trigger.
--   * All tables carry RLS. See 20261006000003_rls.sql.
-- =============================================================================

create extension if not exists pg_trgm;

-- -----------------------------------------------------------------------------
-- Enums
-- Idempotent: the legacy hand-made schema already owns some of these names
-- (payment_status is confirmed to exist live, and enum types are invisible to
-- PostgREST so a plain "create type" fails on the first run). Create when
-- missing; when the existing definition differs, RENAME it aside (never drop)
-- so legacy columns keep working, then create ours.
-- -----------------------------------------------------------------------------
do $$
declare
  v_name   text;
  v_labels text;
  v_kind   text;   -- pg_type.typtype: e=enum, d=domain, c=composite, ...
  v_have   text;   -- enum labels, marker for a non-enum type, or null (absent)
  v_list   text;
  v_alt    text;
  v_n      int;
begin
  for v_name, v_labels in
    select * from (values
      ('persona_type',     'customer,salon_owner,stylist,admin'),
      ('booking_status',   'pending,confirmed,completed,cancelled,no_show'),
      ('payment_status',   'pending,paid,failed,refunded,expired'),
      ('payment_provider', 'cash,esewa,khalti,connect_ips,ime_pay,fonepay'),
      ('service_category', 'hair,beard,skin,spa,nails,makeup,massage,other')
    ) as v(name, labels)
  loop
    -- what (if anything) already occupies public.<name>
    select k.typtype,
           (select string_agg(e.enumlabel, ',' order by e.enumsortorder)
              from pg_enum e where e.enumtypid = k.oid)
      into v_kind, v_have
      from pg_type k
      join pg_namespace n on n.oid = k.typnamespace
     where n.nspname = 'public' and k.typname = v_name;

    if v_kind is not null and v_kind <> 'e' then
      v_have := '<non-enum type>';   -- occupies the name: move it aside too
    end if;

    if v_have is distinct from v_labels then
      if v_have is not null then
        v_alt := v_name || '_legacy';
        v_n   := 0;
        while exists (select 1 from pg_type t
                        join pg_namespace n on n.oid = t.typnamespace
                       where n.nspname = 'public' and t.typname = v_alt)
        loop
          v_n   := v_n + 1;
          v_alt := v_name || '_legacy' || v_n;
        end loop;

        if v_kind = 'd' then
          execute format('alter domain public.%I rename to %I', v_name, v_alt);
        else
          execute format('alter type   public.%I rename to %I', v_name, v_alt);
        end if;
        raise notice 'renamed pre-existing public.% to public.%', v_name, v_alt;
      end if;

      select string_agg(quote_literal(x), ', ' order by u.ord)
        into v_list
        from unnest(string_to_array(v_labels, ',')) with ordinality as u(x, ord);

      execute format('create type public.%I as enum (%s)', v_name, v_list);
    end if;
  end loop;
end;
$$;

-- -----------------------------------------------------------------------------
-- profiles
-- Written by: AuthProvider.updateProfile (insert/update), login (select),
--             and the auth.users trigger on signup.
-- NOTE: the column is `name` (not `full_name`) to match auth_provider.dart:53.
-- -----------------------------------------------------------------------------
create table public.profiles (
  id               uuid primary key references auth.users (id) on delete cascade,
  name             text not null check (char_length(trim(name)) between 1 and 120),
  email            text unique,
  phone            text,
  persona          public.persona_type not null default 'customer',
  profile_image_url text,
  city             text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

comment on column public.profiles.name is 'Mirrors auth.users.raw_user_meta_data.name. Do NOT rename to full_name: lib/shared/providers/auth_provider.dart writes `name`.';

-- -----------------------------------------------------------------------------
-- salons
-- Matches lib/shared/models/salon_model.dart exactly (owner_id, name,
-- description, address, city, latitude, longitude, phone, image_url,
-- opening_time, closing_time) plus production extras.
-- -----------------------------------------------------------------------------
create table public.salons (
  id            uuid primary key default gen_random_uuid(),
  owner_id      uuid references public.profiles (id) on delete set null,
  name          text not null check (char_length(name) between 2 and 160),
  description   text,
  address       text not null,
  city          text not null,
  province      text,
  country       text not null default 'Nepal',
  latitude      double precision,
  longitude     double precision,
  phone         text,
  email         text,
  image_url     text,
  gallery_urls  text[] not null default '{}',
  opening_time  time not null default '09:00',
  closing_time  time not null default '20:00',
  slot_minutes  int  not null default 30 check (slot_minutes between 5 and 240),
  tags          text[] not null default '{}',
  rating_avg    numeric(3,2) not null default 0 check (rating_avg between 0 and 5),
  rating_count  int not null default 0,
  is_active     boolean not null default true,
  is_verified   boolean not null default false,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  constraint salons_hours_check check (closing_time > opening_time)
);

create index salons_city_idx        on public.salons (lower(city));
create index salons_active_idx      on public.salons (is_active) where is_active;
create index salons_name_trgm_idx   on public.salons using gin (name gin_trgm_ops);
create index salons_city_trgm_idx   on public.salons using gin (city gin_trgm_ops);

-- -----------------------------------------------------------------------------
-- services
-- Matches lib/shared/models/service_model.dart
-- -----------------------------------------------------------------------------
create table public.services (
  id               uuid primary key default gen_random_uuid(),
  salon_id         uuid not null references public.salons (id) on delete cascade,
  name             text not null check (char_length(name) between 2 and 160),
  description      text,
  price            numeric(10,2) not null check (price >= 0),
  duration_minutes int not null default 30 check (duration_minutes between 5 and 600),
  category         public.service_category not null default 'other',
  image_url        text,
  is_active        boolean not null default true,
  sort_order       int not null default 0,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

create index services_salon_idx    on public.services (salon_id) where is_active;
create index services_category_idx on public.services (category);

-- -----------------------------------------------------------------------------
-- staff — barbers / stylists. Serves the barber picker in
-- lib/features/booking/booking_slot_screen.dart
-- -----------------------------------------------------------------------------
create table public.staff (
  id           uuid primary key default gen_random_uuid(),
  salon_id     uuid not null references public.salons (id) on delete cascade,
  user_id      uuid references public.profiles (id) on delete set null,
  name         text not null,
  title        text default 'Stylist',
  specialties  text[] not null default '{}',
  image_url    text,
  phone        text,
  is_active    boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index staff_salon_idx on public.staff (salon_id) where is_active;

-- -----------------------------------------------------------------------------
-- staff_availability — weekday working windows.
-- weekday: 0 = Sunday .. 6 = Saturday (Postgres extract(dow) convention).
-- A staff member with no rows for a weekday is treated as OFF that day.
-- -----------------------------------------------------------------------------
create table public.staff_availability (
  id         uuid primary key default gen_random_uuid(),
  staff_id   uuid not null references public.staff (id) on delete cascade,
  weekday    int not null check (weekday between 0 and 6),
  start_time time not null default '09:00',
  end_time   time not null default '20:00',
  created_at timestamptz not null default now(),
  constraint availability_window_check check (end_time > start_time),
  constraint availability_unique unique (staff_id, weekday, start_time)
);

create index staff_availability_staff_idx on public.staff_availability (staff_id, weekday);

-- -----------------------------------------------------------------------------
-- bookings — the core table behind the whole booking funnel.
-- `booking_date_time` is denormalised from booking_date + start_time by trigger
-- so lib/shared/models/booking_model.dart keeps working unchanged.
-- -----------------------------------------------------------------------------
create table public.bookings (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references public.profiles (id) on delete cascade,
  salon_id         uuid not null references public.salons (id) on delete cascade,
  staff_id         uuid references public.staff (id) on delete set null,
  booking_date     date not null,
  start_time       time not null,
  end_time         time not null,
  booking_date_time timestamptz,          -- trigger-maintained, see 0002
  total_price      numeric(10,2) not null default 0 check (total_price >= 0),
  status           public.booking_status not null default 'pending',
  payment_status   public.payment_status not null default 'pending',
  payment_provider public.payment_provider,
  otp_code         text,
  notes            text,
  cancelled_reason text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint bookings_window_check check (end_time > start_time)
);

create index bookings_user_idx  on public.bookings (user_id, booking_date desc);
create index bookings_salon_idx on public.bookings (salon_id, booking_date);
create index bookings_staff_idx on public.bookings (staff_id, booking_date, start_time)
  where status in ('pending', 'confirmed');
create index bookings_status_idx on public.bookings (status);

-- -----------------------------------------------------------------------------
-- booking_services — cart line items. Snapshot name/price so historical
-- bookings survive a later price change.
-- -----------------------------------------------------------------------------
create table public.booking_services (
  booking_id       uuid not null references public.bookings (id) on delete cascade,
  service_id       uuid references public.services (id) on delete set null,
  service_name     text not null,
  unit_price       numeric(10,2) not null check (unit_price >= 0),
  quantity         int not null default 1 check (quantity > 0),
  duration_minutes int not null default 30,
  primary key (booking_id, service_id)
);

-- -----------------------------------------------------------------------------
-- payments — Nepal-first. eSewa / Khalti / ConnectIPS / IME Pay / Fonepay / cash.
-- Client may only ever insert a `pending` row; status transitions belong to a
-- server-side verification function (edge function, service role).
-- -----------------------------------------------------------------------------
create table public.payments (
  id              uuid primary key default gen_random_uuid(),
  booking_id      uuid references public.bookings (id) on delete cascade,
  user_id         uuid not null references public.profiles (id) on delete cascade,
  amount          numeric(10,2) not null check (amount > 0),
  currency        text not null default 'NPR',
  provider        public.payment_provider not null,
  status          public.payment_status not null default 'pending',
  provider_ref    text,
  provider_payload jsonb not null default '{}'::jsonb,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index payments_user_idx    on public.payments (user_id, created_at desc);
create index payments_booking_idx on public.payments (booking_id);
create index payments_ref_idx     on public.payments (provider_ref) where provider_ref is not null;

-- -----------------------------------------------------------------------------
-- reviews
-- -----------------------------------------------------------------------------
create table public.reviews (
  id          uuid primary key default gen_random_uuid(),
  salon_id    uuid not null references public.salons (id) on delete cascade,
  user_id     uuid not null references public.profiles (id) on delete cascade,
  booking_id  uuid unique references public.bookings (id) on delete set null,
  rating      int not null check (rating between 1 and 5),
  comment     text check (char_length(comment) <= 2000),
  reply       text,
  is_visible  boolean not null default true,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index reviews_salon_idx on public.reviews (salon_id, created_at desc) where is_visible;
create index reviews_user_idx  on public.reviews (user_id, created_at desc);
create index reviews_comment_trgm_idx on public.reviews using gin (comment gin_trgm_ops);

-- -----------------------------------------------------------------------------
-- favourites — backs lib/features/favourites/favourites_screen.dart
-- -----------------------------------------------------------------------------
create table public.favourites (
  user_id    uuid not null references public.profiles (id) on delete cascade,
  salon_id   uuid not null references public.salons (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, salon_id)
);

create index favourites_salon_idx on public.favourites (salon_id);

-- -----------------------------------------------------------------------------
-- notifications — backs lib/features/notifications/notifications_screen.dart
-- Rows are written server-side (edge function / dashboard); clients only read
-- and mark read.
-- -----------------------------------------------------------------------------
create table public.notifications (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles (id) on delete cascade,
  title        text not null,
  body         text not null,
  type         text not null default 'general',
  reference_id text,
  is_read      boolean not null default false,
  created_at   timestamptz not null default now()
);

create index notifications_user_idx on public.notifications (user_id, created_at desc);
create index notifications_unread_idx on public.notifications (user_id) where not is_read;

-- -----------------------------------------------------------------------------
-- coupons — backs the promocodes sheet in profile_screen.dart
-- -----------------------------------------------------------------------------
create table public.coupons (
  id               uuid primary key default gen_random_uuid(),
  code             text not null unique check (code = upper(code)),
  salon_id         uuid references public.salons (id) on delete cascade,
  discount_percent numeric(5,2) not null check (discount_percent between 1 and 100),
  max_discount     numeric(10,2),
  valid_from       timestamptz not null default now(),
  valid_to         timestamptz,
  max_uses         int,
  used_count       int not null default 0,
  is_active        boolean not null default true,
  created_at       timestamptz not null default now()
);

create index coupons_active_idx on public.coupons (is_active) where is_active;

-- ==========================================================================
-- FILE: supabase/migrations/20261006000002_functions.sql
-- ==========================================================================

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

-- ==========================================================================
-- FILE: supabase/migrations/20261006000003_rls.sql
-- ==========================================================================

-- =============================================================================
-- Salon App — Row Level Security
--
-- Model:  anon      -> can browse salons, services, coupons (public catalogue)
--         authenticated -> can read/write ONLY their own rows
--         service role  -> unrestricted (seed data, edge functions, webhooks)
-- =============================================================================

alter table public.profiles          enable row level security;
alter table public.salons            enable row level security;
alter table public.services          enable row level security;
alter table public.staff             enable row level security;
alter table public.staff_availability enable row level security;
alter table public.bookings          enable row level security;
alter table public.booking_services  enable row level security;
alter table public.payments          enable row level security;
alter table public.reviews           enable row level security;
alter table public.favourites        enable row level security;
alter table public.notifications     enable row level security;
alter table public.coupons           enable row level security;

-- -----------------------------------------------------------------------------
-- profiles
-- Column-level privileges: the whole table is never readable by other users,
-- so phone/email can only ever be read by their owner.
-- -----------------------------------------------------------------------------
revoke all on public.profiles from anon, authenticated;

grant select (id, name, email, phone, profile_image_url, city, persona, created_at, updated_at)
      on public.profiles to authenticated;
grant insert (id, name, email, phone, updated_at)
      on public.profiles to authenticated;
grant update (name, phone, email, profile_image_url, city, updated_at)
      on public.profiles to authenticated;

create policy "profiles_select_own"
  on public.profiles for select
  to authenticated
  using (id = (select auth.uid()));

create policy "profiles_insert_own"
  on public.profiles for insert
  to authenticated
  with check (id = (select auth.uid()));

create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- Public projection of a profile: display name + avatar only, no PII.
-- Used when rendering reviewer names on the salon detail page.
-- Owner (postgres) owns the table and RLS is not FORCEd, so this view reads
-- through without applying row policies: it is the sanctioned public projection.
create or replace view public.profiles_public
with (security_invoker = false) as
  select id, name, profile_image_url, city, persona, created_at
  from public.profiles;

revoke all on public.profiles_public from public, anon, authenticated;
grant select on public.profiles_public to anon, authenticated;

-- -----------------------------------------------------------------------------
-- salons / services / staff / staff_availability — public catalogue, read-only
-- for customers. Writes belong to the salon owner (later admin phase) or the
-- service role (manual seeding, as decided for this release).
-- -----------------------------------------------------------------------------
create policy "salons_public_read"
  on public.salons for select
  to anon, authenticated
  using (is_active or owner_id = (select auth.uid()));

create policy "salons_owner_write"
  on public.salons for update
  to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create policy "services_public_read"
  on public.services for select
  to anon, authenticated
  using (is_active);

create policy "services_owner_write"
  on public.services for all
  to authenticated
  using (exists (select 1 from public.salons s
                 where s.id = salon_id and s.owner_id = (select auth.uid())))
  with check (exists (select 1 from public.salons s
                      where s.id = salon_id and s.owner_id = (select auth.uid())));

create policy "staff_public_read"
  on public.staff for select
  to anon, authenticated
  using (is_active);

create policy "staff_owner_write"
  on public.staff for all
  to authenticated
  using (exists (select 1 from public.salons s
                 where s.id = salon_id and s.owner_id = (select auth.uid())))
  with check (exists (select 1 from public.salons s
                      where s.id = salon_id and s.owner_id = (select auth.uid())));

create policy "availability_public_read"
  on public.staff_availability for select
  to anon, authenticated
  using (true);

create policy "availability_owner_write"
  on public.staff_availability for all
  to authenticated
  using (exists (select 1 from public.staff st
                 join public.salons s on s.id = st.salon_id
                 where st.id = staff_id and s.owner_id = (select auth.uid())))
  with check (exists (select 1 from public.staff st
                      join public.salons s on s.id = st.salon_id
                      where st.id = staff_id and s.owner_id = (select auth.uid())));

-- -----------------------------------------------------------------------------
-- bookings — a customer sees and creates only their own.
-- -----------------------------------------------------------------------------
create policy "bookings_select_own"
  on public.bookings for select
  to authenticated
  using (user_id = (select auth.uid()));

create policy "bookings_insert_own"
  on public.bookings for insert
  to authenticated
  with check (user_id = (select auth.uid()) and status = 'pending');

create policy "bookings_update_own"
  on public.bookings for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- Guard: a customer may only cancel their own booking. They may not reassign it
-- to another user/salon, nor mark it completed (that is the salon's call).
create or replace function public.guard_booking_update()
returns trigger
language plpgsql
as $$
begin
  if auth.uid() is null then
    return new;                            -- service role: unrestricted
  end if;

  if new.id         is distinct from old.id
  or new.user_id    is distinct from old.user_id
  or new.salon_id   is distinct from old.salon_id
  or new.created_at is distinct from old.created_at then
    raise exception 'Bookings cannot be reassigned';
  end if;

  if new.status in ('completed', 'no_show') and old.status not in ('completed', 'no_show') then
    raise exception 'Only the salon can mark an appointment completed';
  end if;

  if new.status = 'cancelled' and old.status not in ('pending', 'confirmed') then
    raise exception 'This appointment can no longer be cancelled';
  end if;

  return new;
end;
$$;

drop trigger if exists guard_booking_update on public.bookings;
create trigger guard_booking_update
  before update on public.bookings
  for each row execute function public.guard_booking_update();

-- -----------------------------------------------------------------------------
-- booking_services — visible/editable only through an owned booking
-- -----------------------------------------------------------------------------
create policy "booking_services_select_owned"
  on public.booking_services for select
  to authenticated
  using (exists (select 1 from public.bookings b
                 where b.id = booking_id and b.user_id = (select auth.uid())));

create policy "booking_services_insert_owned"
  on public.booking_services for insert
  to authenticated
  with check (exists (select 1 from public.bookings b
                      where b.id = booking_id and b.user_id = (select auth.uid())));

create policy "booking_services_delete_owned"
  on public.booking_services for delete
  to authenticated
  using (exists (select 1 from public.bookings b
                 where b.id = booking_id and b.user_id = (select auth.uid())));

-- -----------------------------------------------------------------------------
-- payments — customers create and read `pending` payments only.
-- Status transitions (paid/failed/refunded) happen server-side; there is
-- deliberately no UPDATE policy for clients.
-- -----------------------------------------------------------------------------
create policy "payments_select_own"
  on public.payments for select
  to authenticated
  using (user_id = (select auth.uid()));

create policy "payments_insert_pending"
  on public.payments for insert
  to authenticated
  with check (user_id = (select auth.uid()) and status = 'pending');

-- -----------------------------------------------------------------------------
-- reviews
-- -----------------------------------------------------------------------------
create policy "reviews_public_read"
  on public.reviews for select
  to anon, authenticated
  using (is_visible or user_id = (select auth.uid()));

create policy "reviews_insert_own_with_booking"
  on public.reviews for insert
  to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.bookings b
      where b.user_id = (select auth.uid())
        and b.salon_id = salon_id
        and b.status in ('completed', 'confirmed')
    )
    and (booking_id is null or exists (
      select 1 from public.bookings b2
      where b2.id = booking_id and b2.user_id = (select auth.uid())
    ))
  );

create policy "reviews_update_own"
  on public.reviews for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "reviews_delete_own"
  on public.reviews for delete
  to authenticated
  using (user_id = (select auth.uid()));

-- -----------------------------------------------------------------------------
-- favourites
-- -----------------------------------------------------------------------------
create policy "favourites_select_own"
  on public.favourites for select
  to authenticated
  using (user_id = (select auth.uid()));

create policy "favourites_insert_own"
  on public.favourites for insert
  to authenticated
  with check (user_id = (select auth.uid()));

create policy "favourites_delete_own"
  on public.favourites for delete
  to authenticated
  using (user_id = (select auth.uid()));

-- -----------------------------------------------------------------------------
-- notifications — read + mark-read only. Rows are created server-side.
-- -----------------------------------------------------------------------------
create policy "notifications_select_own"
  on public.notifications for select
  to authenticated
  using (user_id = (select auth.uid()));

create policy "notifications_update_own"
  on public.notifications for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "notifications_delete_own"
  on public.notifications for delete
  to authenticated
  using (user_id = (select auth.uid()));

-- -----------------------------------------------------------------------------
-- coupons — publicly readable while valid, never client-writable
-- -----------------------------------------------------------------------------
create policy "coupons_public_read"
  on public.coupons for select
  to anon, authenticated
  using (
    is_active
    and valid_from <= now()
    and (valid_to is null or valid_to >= now())
  );

-- ==========================================================================
-- FILE: supabase/migrations/20261006000005_backfill_profiles.sql
-- ==========================================================================

-- =============================================================================
-- Salon App — Backfill profiles for pre-existing auth users
-- Run this LAST, after the schema and function migrations.
--
-- The old schema had no trigger on auth.users, so anyone who signed up before
-- the rebuild has an auth.users row but no profiles row — which means
-- AuthProvider.updateProfile() would try to INSERT and could mis-route the
-- "profile incomplete" flow. This creates the missing rows once.
-- =============================================================================
insert into public.profiles (id, name, email, persona)
select
  u.id,
  coalesce(
    nullif(trim(coalesce(u.raw_user_meta_data ->> 'name',
                         u.raw_user_meta_data ->> 'full_name')), ''),
    split_part(coalesce(u.email, 'user'), '@', 1)
  ),
  u.email,
  'customer'
from auth.users u
where not exists (select 1 from public.profiles p where p.id = u.id)
on conflict (id) do nothing;

-- Report what we found
select
  (select count(*) from auth.users)               as auth_users,
  (select count(*) from public.profiles)          as profiles_after_backfill;

-- ==========================================================================
-- FILE: supabase/seed.sql
-- ==========================================================================

-- =============================================================================
-- Salon App — Seed data (customer-app release)
--
-- Manually seeded salons across Nepal's 7 provinces, as agreed for this phase
-- (admin panel comes later). Run this AFTER the migrations:
--
--   supabase db reset          # or: supabase db push, then run this in SQL Editor
--
-- Images point at picsum.photos placeholders keyed by salon name so they are
-- stable across re-seeds. Replace with storage://salons/... uploads before
-- launch.
-- =============================================================================

create or replace function public.seed_salon(
  p_name     text,
  p_city     text,
  p_province text,
  p_address  text,
  p_lat      double precision,
  p_lng      double precision,
  p_phone    text,
  p_open     time default '09:00',
  p_close    time default '20:00',
  p_pack     text default 'unisex',        -- gents | unisex | beauty
  p_tags     text[] default '{}'
) returns uuid
language plpgsql
as $$
declare
  v_id       uuid;
  v_img      text;
  v_staff    int;
  v_names    text[] := array[
    'Bikash Tamang','Ramesh Gurung','Sita Lama','Anjali Shrestha','Prakash Rai',
    'Sunita Magar','Rajesh Thapa','Kiran BK','Bishal CK','Sabina Ansari',
    'Nabin Poudel','Menuka Sherpa','Dipak Yadav','Sarita Karki','Pramila Neupane',
    'Sujata Bista','Himal Tamang','Tenzing Sherpa','Gopal Chaudhary','Asha Kumari'
  ];
begin
  select 'https://picsum.photos/seed/' ||
         lower(regexp_replace(p_name, '\s+', '-', 'g')) || '/900/600'
    into v_img;

  insert into public.salons (
    name, description, address, city, province, latitude, longitude,
    phone, image_url, opening_time, closing_time, tags, is_active, is_verified
  ) values (
    p_name,
    case p_pack
      when 'gents'  then 'Men''s grooming studio — precision haircuts, beard sculpting and grooming.'
      when 'beauty' then 'Full-service beauty parlour — bridal makeup, facials, spa and styling.'
      else 'Unisex salon & spa — hair, skin, nails and grooming for everyone.'
    end,
    p_address, p_city, p_province, p_lat, p_lng,
    p_phone, v_img, p_open, p_close,
    case when p_tags[1] is null
         then array[p_pack] || array['walk-ins']
         else p_tags end,
    true, (random() < 0.5)
  ) returning id into v_id;

  -- ---- services by pack (prices in NPR) ------------------------------------
  if p_pack = 'gents' then
    insert into public.services (salon_id, name, description, price, duration_minutes, category, image_url)
    select v_id, x.n, x.d, x.p, x.m, x.c::public.service_category, v_img
    from (values
      ('Haircut',            'Professional haircut & styling',                        350::numeric, 30, 'hair'),
      ('Kids Haircut',       'Haircut for children under 12',                         250::numeric, 30, 'hair'),
      ('Beard Trim & Shape', 'Beard trimming, shaping and line-up',                   200::numeric, 20, 'beard'),
      ('Clean Shave',        'Razor shave with hot towel finish',                     150::numeric, 15, 'beard'),
      ('Head Massage',       'Relaxing head, neck & shoulder massage',                300::numeric, 30, 'massage'),
      ('Hair Colouring',     'Global colour / grey coverage',                        1000::numeric, 90, 'hair'),
      ('Facial & Cleanup',   'Deep cleansing facial for men',                         500::numeric, 45, 'skin'),
      ('Threading',          'Eyebrows, upper lip and forehead',                      150::numeric, 15, 'skin')
    ) as x(n, d, p, m, c);

  elsif p_pack = 'beauty' then
    insert into public.services (salon_id, name, description, price, duration_minutes, category, image_url)
    select v_id, x.n, x.d, x.p, x.m, x.c::public.service_category, v_img
    from (values
      ('Haircut & Blow Dry', 'Haircut, wash and professional blow dry',               600::numeric, 45, 'hair'),
      ('Hair Spa',           'Nourishing keratin hair spa treatment',                 700::numeric, 45, 'spa'),
      ('Hair Colouring',     'Full head global colour',                              1200::numeric, 90, 'hair'),
      ('Hair Highlighting',  'Highlights / streaks with toner',                       1500::numeric, 120,'hair'),
      ('Hair Straightening', 'Smoothening / rebonding treatment',                     3500::numeric,180, 'hair'),
      ('Facial & Cleanup',   'Deep cleansing & glow facial',                          600::numeric, 45, 'skin'),
      ('Threading',          'Eyebrows, upper lip, forehead, chin',                   150::numeric, 15, 'skin'),
      ('Manicure',           'Nail care, cuticle work and polish',                    400::numeric, 30, 'nails'),
      ('Pedicure',           'Foot care, scrub and polish',                           500::numeric, 40, 'nails'),
      ('Bridal Makeup',      'Complete bridal makeup & hair package',                3500::numeric,180, 'makeup'),
      ('Party Makeup',       'Party / reception makeup',                             1500::numeric, 75, 'makeup'),
      ('Head Massage',       'Relaxing head, neck & shoulder massage',                350::numeric, 30, 'massage')
    ) as x(n, d, p, m, c);

  else -- unisex
    insert into public.services (salon_id, name, description, price, duration_minutes, category, image_url)
    select v_id, x.n, x.d, x.p, x.m, x.c::public.service_category, v_img
    from (values
      ('Haircut',            'Professional unisex haircut & styling',                 400::numeric, 30, 'hair'),
      ('Kids Haircut',       'Haircut for children under 12',                         250::numeric, 30, 'hair'),
      ('Beard Trim & Shape', 'Beard trimming, shaping and line-up',                   200::numeric, 20, 'beard'),
      ('Hair Spa',           'Nourishing keratin hair spa treatment',                 700::numeric, 45, 'spa'),
      ('Hair Colouring',     'Full head global colour',                              1100::numeric, 90, 'hair'),
      ('Facial & Cleanup',   'Deep cleansing & glow facial',                          600::numeric, 45, 'skin'),
      ('Threading',          'Eyebrows, upper lip and forehead',                      150::numeric, 15, 'skin'),
      ('Manicure',           'Nail care, cuticle work and polish',                    400::numeric, 30, 'nails'),
      ('Pedicure',           'Foot care, scrub and polish',                           500::numeric, 40, 'nails'),
      ('Head Massage',       'Relaxing head, neck & shoulder massage',                300::numeric, 30, 'massage'),
      ('Bridal Makeup',      'Complete bridal makeup & hair package',                3500::numeric,180, 'makeup')
    ) as x(n, d, p, m, c);
  end if;

  -- ---- stylists ------------------------------------------------------------
  v_staff := case p_pack when 'gents' then 3 when 'beauty' then 4 else 3 end;

  insert into public.staff (salon_id, name, title, specialties)
  select v_id,
         v_names[1 + ((abs(hashtext(v_id::text)) + i) % array_length(v_names, 1))],
         case p_pack
           when 'gents'  then (array['Senior Barber','Beard Specialist','Hair Stylist'])[1 + (i % 3)]
           when 'beauty' then (array['Senior Stylist','Makeup Artist','Skin Specialist','Hair Colourist'])[1 + (i % 4)]
           else (array['Senior Stylist','Hair Colourist','Beauty Therapist'])[1 + (i % 3)]
         end,
         case p_pack
           when 'gents'  then array['hair','beard']
           when 'beauty' then array['hair','skin','makeup','nails']
           else array['hair','skin','nails']
         end
  from generate_series(1, v_staff) i;

  -- ---- working hours: every day, salon hours -------------------------------
  insert into public.staff_availability (staff_id, weekday, start_time, end_time)
  select st.id, d, p_open, p_close
  from public.staff st
  cross join generate_series(0, 6) d
  where st.salon_id = v_id
  on conflict do nothing;

  return v_id;
end;
$$;

-- =============================================================================
-- Salons — 7 provinces, 28 cities/towns
-- =============================================================================
do $$
declare c record;
begin
  for c in
    select * from (values
      -- name, city, province, address, lat, lng, phone, open, close, pack, tags
      ('Style Hub Unisex Salon',   'Kathmandu',  'Bagmati',     'New Baneshwor Chowk, Kathmandu 44600',      27.6930, 85.3310, '+977-1-4101234', '09:00', '20:00', 'unisex', array['walk-ins','parking']),
      ('Kathmandu Grooming Co.',   'Kathmandu',  'Bagmati',     'Jhamsikhel Road, Lalitpur 44600',            27.6780, 85.3150, '+977-1-5523344', '10:00', '21:00', 'gents',  array['mens-only','beard']),
      ('Aakriti Beauty Parlour',   'Lalitpur',   'Bagmati',     'Pulchowk Main Road, Lalitpur',              27.6740, 85.3200, '+977-1-5534455', '09:30', '19:30', 'beauty', array['bridal','women-only']),
      ('Bhaktapur Hair Studio',    'Bhaktapur',  'Bagmati',     'Durbar Square Road, Bhaktapur 44800',        27.6710, 85.4290, '+977-1-6215566', '09:00', '19:00', 'unisex', array['walk-ins']),
      ('Hetauda Style Point',      'Hetauda',    'Bagmati',     'Jamal Road, Hetauda 45300',                 27.4240, 85.0320, '+977-1-6321177', '09:00', '19:00', 'gents',  array['mens-only']),
      ('Nagarkot Spa & Salon',     'Nagarkot',   'Bagmati',     'Hill Road, Nagarkot 44610',                 27.7150, 85.5230, '+977-1-6680099', '10:00', '18:00', 'beauty', array['spa','resort']),
      ('Bharatpur Beauty Care',    'Bharatpur',  'Bagmati',     'Station Chowk, Bharatpur 44200',            27.6760, 84.4350, '+977-56-520111', '09:00', '20:00', 'beauty', array['bridal']),
      ('Pokhara Hair Lounge',      'Pokhara',    'Gandaki',     'Lakeside Road, Pokhara 33700',              28.2090, 83.9560, '+977-61-460111', '09:00', '21:00', 'unisex', array['tourist-area','walk-ins']),
      ('Annapurna Grooming Bar',   'Pokhara',    'Gandaki',     'Mahendrapul, Pokhara 33700',                28.2260, 83.9690, '+977-61-462222', '10:00', '20:00', 'gents',  array['mens-only','beard']),
      ('Gorkha Style House',       'Gorkha',     'Gandaki',     'Arubari Bazaar, Gorkha 34000',              28.0000, 84.6330, '+977-64-412233', '09:00', '19:00', 'unisex', array['walk-ins']),
      ('Bandipur Beauty Salon',    'Bandipur',   'Gandaki',     'Main Street, Bandipur 34500',               27.9390, 84.4110, '+977-65-690111', '10:00', '18:00', 'beauty', array['heritage']),
      ('Besisahar Hair & Beauty',  'Besisahar',  'Gandaki',     'Lamjung Bazaar, Beshisahar 44800',          28.2360, 84.3830, '+977-66-520111', '09:00', '19:00', 'unisex', array['walk-ins']),
      ('Damauli Salon & Spa',      'Damauli',    'Gandaki',     'Highway Chowk, Damauli 44200',              27.9830, 84.5830, '+977-56-412233', '09:00', '19:00', 'beauty', array['spa']),
      ('Butwal Grooming Studio',   'Butwal',     'Lumbini',     'Traffic Chowk, Butwal 32900',               27.7000, 83.4480, '+977-71-545111', '09:00', '20:00', 'gents',  array['mens-only']),
      ('Bhairahawa Beauty Lounge', 'Bhairahawa', 'Lumbini',     'Siddhartha Marg, Bhairahawa 32900',         27.5000, 83.4500, '+977-71-522333', '09:30', '19:30', 'beauty', array['bridal']),
      ('Tansen Style Parlour',     'Tansen',     'Lumbini',     'Dado Bazaar, Tansen 32500',                 27.8670, 83.5500, '+977-75-521111', '09:00', '19:00', 'unisex', array['walk-ins']),
      ('Tulsipur Hair Creations',  'Tulsipur',   'Lumbini',     'Rajmarg Chowk, Tulsipur 32900',             28.1330, 82.3000, '+977-82-521111', '09:00', '19:00', 'unisex', array['walk-ins']),
      ('Nepalgunj Hair & Beauty',  'Nepalgunj',  'Lumbini',     'Mahendra Chowk, Nepalgunj 32900',           28.0500, 81.6170, '+977-81-525111', '09:00', '20:00', 'beauty', array['bridal']),
      ('Biratnagar Barber Club',   'Biratnagar', 'Koshi',       'Main Road, Biratnagar 56600',               26.4520, 87.2640, '+977-21-470111', '09:00', '20:00', 'gents',  array['mens-only','beard']),
      ('Dharan Style Corner',      'Dharan',     'Koshi',       'Bhanu Chowk, Dharan 56700',                 26.8100, 87.2830, '+977-25-520111', '09:00', '20:00', 'unisex', array['walk-ins']),
      ('Itahari Beauty Zone',      'Itahari',    'Koshi',       'Dharan Road, Itahari 56705',                26.6660, 87.2830, '+977-25-580111', '09:30', '19:30', 'beauty', array['bridal']),
      ('Damak Hair Studio',        'Damak',      'Koshi',       'Birat Road, Damak 56705',                   26.6640, 87.3510, '+977-26-590111', '09:00', '19:00', 'unisex', array['walk-ins']),
      ('Ilam Tea Garden Salon',    'Ilam',       'Koshi',       'Ilam Bazaar, Ilam 57300',                   26.9090, 87.9300, '+977-27-520111', '09:00', '18:00', 'beauty', array['hill-station']),
      ('Birgunj Grooming House',   'Birgunj',    'Madhesh',     'Adarsh Nagar, Birgunj 44300',               27.0360, 84.8770, '+977-51-412222', '09:00', '20:00', 'gents',  array['mens-only']),
      ('Janakpur Beauty Court',    'Janakpur',   'Madhesh',     'Campus Road, Janakpur 45600',               26.7280, 85.9250, '+977-41-522111', '09:00', '20:00', 'beauty', array['bridal','saree-styling']),
      ('Rajbiraj Style Hub',       'Rajbiraj',   'Madhesh',     'Ghantaghar Road, Rajbiraj 56000',           26.5400, 86.7470, '+977-45-572111', '09:00', '19:00', 'unisex', array['walk-ins']),
      ('Birendranagar Salon',      'Birendranagar','Karnali',   'Surkhet Bazaar, Birendranagar 21900',       28.6000, 82.0700, '+977-84-412111', '09:00', '19:00', 'unisex', array['walk-ins']),
      ('Dhangadhi Hair & Beauty',  'Dhangadhi',  'Sudurpashchim','Godawari Road, Dhangadhi 57500',          28.7000, 80.6000, '+977-91-522111', '09:00', '20:00', 'beauty', array['bridal']),
      ('Bhimdatta Grooming Point', 'Bhimdatta',  'Sudurpashchim','Mahakali Chowk, Bhimdatta 57500',         28.9640, 80.3320, '+977-91-412111', '09:00', '19:00', 'gents',  array['mens-only'])
    ) as t(name, city, province, address, lat, lng, phone, open, close, pack, tags)
  loop
    perform public.seed_salon(c.name, c.city, c.province, c.address, c.lat, c.lng,
                              c.phone, c.open::time, c.close::time, c.pack, c.tags);
  end loop;
end;
$$;

-- =============================================================================
-- Coupons — backs the promocodes sheet in profile_screen.dart
-- =============================================================================
insert into public.coupons (code, discount_percent, max_discount, valid_to, max_uses, is_active) values
  ('NEPAL10',  10, 300,  now() + interval '1 year', 10000, true),
  ('FIRST20',  20, 500,  now() + interval '1 year',  5000, true),
  ('FESTIVE25',25, 750,  now() + interval '6 months',2000, true),
  ('WELCOME50',50,1000,  now() + interval '3 months',1000, true)
on conflict (code) do nothing;

-- =============================================================================
-- Cleanup — remove the seeding helper from the schema
-- =============================================================================
drop function public.seed_salon(text, text, text, text, double precision,
                                 double precision, text, time, time, text, text[]);

-- Verification
select city, province, count(*) as salons, sum((select count(*) from public.services s where s.salon_id = salons.id)) as services
from public.salons
group by city, province
order by province, city;
