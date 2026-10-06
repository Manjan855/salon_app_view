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
-- -----------------------------------------------------------------------------
create type public.persona_type as enum ('customer', 'salon_owner', 'stylist', 'admin');
create type public.booking_status as enum ('pending', 'confirmed', 'completed', 'cancelled', 'no_show');
create type public.payment_status as enum ('pending', 'paid', 'failed', 'refunded', 'expired');
create type public.payment_provider as enum ('cash', 'esewa', 'khalti', 'connect_ips', 'ime_pay', 'fonepay');
create type public.service_category as enum ('hair', 'beard', 'skin', 'spa', 'nails', 'makeup', 'massage', 'other');

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
