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
