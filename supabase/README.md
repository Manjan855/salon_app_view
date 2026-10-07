# Supabase backend — `salon_app_view`

Nepal-first production schema for the customer-facing Flutter app.

```
supabase/
├── apply_all.sql                      # ← PASTE #1: everything except storage
├── apply_storage.sql                  # ← PASTE #2: storage buckets + policies
├── migrations/
│   ├── 20261005235959_archive_legacy_schema.sql   # 1. move the old hand-made tables aside
│   ├── 20261006000001_schema.sql                  # 2. extensions, enums, 12 tables, indexes
│   ├── 20261006000002_functions.sql               # 3. triggers, availability RPC, search RPC
│   ├── 20261006000003_rls.sql                     # 4. row level security + write guards
│   ├── 20261006000004_storage.sql                 # 5. avatars / salons / services buckets
│   └── 20261006000005_backfill_profiles.sql       # 6. profiles for pre-existing auth users
└── seed.sql                                       # 7. 29 salons across all 7 provinces + coupons
```

`apply_all.sql` and `apply_storage.sql` are generated concatenations of the
migrations — edit the `migrations/` files and re-generate rather than editing
the concatenated files directly.

## What was already in the live project

Read via the PostgREST API on 2026-10-06 — **8 hand-made tables, all returning
0 rows, and zero stored functions**:

| Existing table | Columns found | Problem |
|---|---|---|
| `profiles` | `id, full_name, role, avatar_url, created_at, updated_at` | **no `email`, no `phone`, no `city`** — the register/personal-info flows write columns that don't exist |
| `salons` | `id, owner_id, name, description, address, city, latitude, longitude, phone, image_url, opening_time, closing_time, created_at` | closest match; missing rating / `is_active` / province / `slot_minutes` |
| `services` | `id, salon_id, name, description, price, duration_minutes, category, image_url, created_at` | good; missing `is_active` |
| `staff_profiles` | `id, salon_id, user_id, title, is_active, created_at` | **no `name`** — a stylist table you cannot display |
| `staff_services` | `staff_id, service_id` | staff↔service join, different purpose from `booking_services` |
| `bookings` | `id, user_id, salon_id, booking_date_time, total_price, status, created_at` | **no stylist, no date/time, no OTP, no payment** — cannot drive the booking funnel |
| `appointments` | `id, customer_id, salon_id, staff_id, service_id, appointment_date, start_time, end_time, total_price, status, notes, created_at` | duplicates the `bookings` concept |
| `payments` | `id, customer_id, amount, payment_method, status, transaction_id, created_at` | missing `currency`, `provider`, booking link |

Missing entirely: `staff_availability`, `booking_services`, `reviews`,
`favourites`, `coupons`, `notifications`.

4 of the 8 are structurally unusable, everything is empty, and no functions or
policies exist — so the whole thing is **archived, not dropped** (migration 1).
Nothing is destroyed: `auth.users` is untouched and every registered account
survives.

## Applying the schema

### Ready-to-run scripts (recommended)

Two files, two pastes into the [SQL Editor](https://supabase.com/dashboard/project/zhnfhkahspsqbfjetwlt/sql):

| # | File | Contains |
|---|---|---|
| 1 | **`supabase/apply_all.sql`** | archive → schema → functions → RLS → backfill → seed |
| 2 | **`supabase/apply_storage.sql`** | storage buckets + object policies |

Paste the **contents** of the file (open it, `Ctrl+A` / `Ctrl+C`) — not the file
path — and click **Run**. Paste #1 runs as a single transaction: it either fully
succeeds or fully rolls back, so a failure leaves the project unchanged.

Storage is split out deliberately — `create policy on storage.objects` needs
elevated privileges in some projects, and a failure there must not roll back the
core schema.

**Pre-existing enums are handled.** The hand-made legacy schema owns a
`payment_status` type in `public` (enum types are invisible to PostgREST, so
the original audit could not see them). A plain `create type` therefore fails
with `42710: type "payment_status" already exists`. The enum block now checks
`pg_type` first: matching type → reuse it, differing/non-enum type →
`alter type ... rename to <name>_legacy` (never dropped, legacy columns keep
working), missing type → create it. If a run fails, the whole paste rolls
back — the database is left untouched and the script can be re-run as-is.

Afterwards, run the verification query at the bottom of this file.

### Manual (7 separate runs)

Run these one at a time, in order:

1. `migrations/20261005235959_archive_legacy_schema.sql`
2. `migrations/20261006000001_schema.sql`
3. `migrations/20261006000002_functions.sql`
4. `migrations/20261006000003_rls.sql`
5. `migrations/20261006000004_storage.sql`
6. `migrations/20261006000005_backfill_profiles.sql`
7. `seed.sql`

> Paste the **file contents**, not the file path. The SQL Editor treats anything
> you paste as SQL — a path like `supabase/migrations/...` fails with
> `syntax error at or near "supabase"`.

### Option B — Supabase CLI

```bash
supabase link --project-ref zhnfhkahspsqbfjetwlt
supabase db push                      # applies migrations/ in filename order
psql "$SUPABASE_DB_URL" -f supabase/seed.sql
```

### After confirming the app works

```sql
drop schema archive cascade;   -- removes the old hand-made tables for good
```

## Verification

```sql
-- 12 tables expected in public, 8 archived
select table_name from information_schema.tables
 where table_schema = 'public' and table_type = 'BASE TABLE' order by 1;

-- every table MUST show relrowsecurity = true
select relname, relrowsecurity
  from pg_class
 where relnamespace = 'public'::regnamespace and relkind = 'r'
 order by relname;

-- seeded data
select count(*) from public.salons;
select province, count(*) from public.salons group by province order by 1;

-- old tables parked, not destroyed
select table_name from information_schema.tables
 where table_schema = 'archive' order by 1;
```

## Tables

| Table | Purpose | Who can read | Who can write |
|---|---|---|---|
| `profiles` | name / phone / persona | owner only (column-level grants) | owner, via `profiles_public` for display |
| `salons` | catalogue + rating rollup | public | owner + service role |
| `services` | price list per salon | public (active only) | owner + service role |
| `staff` | barbers / stylists | public (active only) | owner + service role |
| `staff_availability` | weekday working windows | public | owner + service role |
| `bookings` | the core appointment row | owner only | owner (cancel/reschedule), service role |
| `booking_services` | cart line items | via owned booking | owner, service role |
| `payments` | NPR ledger — cash/eSewa/Khalti/ConnectIPS/IME/Fonepay | owner only | insert `pending` only; status changes are server-side |
| `reviews` | ratings + comments | public (visible) | owner (must have a booking at that salon) |
| `favourites` | wishlist | owner only | owner |
| `notifications` | push/in-app inbox | owner only | service role only |
| `coupons` | promocodes | public while valid | service role only |

## Key behaviours baked in

- **`profiles.name`** — the column is `name`, *not* `full_name`. This matches
  `AuthProvider.updateProfile`. Do not rename it.
- **Auto profile on signup** — `handle_new_user` creates the row from
  `raw_user_meta_data.name`, so the login "profile incomplete" path resolves.
- **`bookings.booking_date_time`** — a trigger-maintained denormalisation of
  `booking_date + start_time` in `Asia/Kathmandu` (UTC+05:45, no DST).
  Never write it directly; write `booking_date`, `start_time`, `end_time`.
- **OTP code** — 6 digits, auto-generated on insert for `pending`/`confirmed`.
- **Double-booking is impossible** — `prevent_double_booking` takes an advisory
  transaction lock on the stylist before checking overlaps.
- **Availability** — `get_available_slots(salon, date, staff, minutes, include_unavailable)`
  honours salon hours, the stylist's weekday window, existing bookings, and
  past-time slots.
- **RLS cannot be bypassed by clients** — `protect_profile` forces
  `id`/`email` to the calling user; `guard_booking_update` stops a customer
  reassigning or self-completing a booking; `payments` has no client `UPDATE`
  policy at all.

## Seeded data

29 salons across Koshi, Madhesh, Bagmati, Gandaki, Lumbini, Karnali and
Sudurpashchim — Kathmandu, Lalitpur, Bhaktapur, Pokhara, Biratnagar, Dharan,
Butwal, Janakpur, Birgunj, Dhangadhi and more. Each has 8–12 services priced in
NPR, 3–4 stylists, and full-week availability.

Coupons: `NEPAL10`, `FIRST20`, `FESTIVE25`, `WELCOME50`.

Salon/service images point at `picsum.photos` placeholders keyed by salon name.
Replace with real uploads to the `salons` bucket before launch.

## Post-launch checklist for this layer

- [x] Replace hardcoded Supabase URL + anon key in `lib/main.dart` with
      `--dart-define` (done: `lib/app_env.dart` +
      `--dart-define-from-file=config/supabase.json`, local file gitignored)
- [x] Rotate the anon key — legacy `anon` JWT keys can't be re-minted, so the
      Supabase migration path was followed: a **publishable key**
      (`sb_publishable_...`) now lives in the local `config/supabase.json`
      under `SUPABASE_PUBLISHABLE_KEY` (renamed from `SUPABASE_ANON_KEY` in
      `lib/app_env.dart`), verified against `rest/v1` on both the `apikey` and
      `Authorization: Bearer` headers with the `anon` role intact
- [ ] **Deactivate the legacy `anon` key** in Settings → API Keys — it is still
      in git history, so it stays live (and usable by anyone reading the repo)
      until switched off; deactivation is reversible
- [ ] Configure the OAuth redirect scheme (PKCE is on, but neither
      `AndroidManifest.xml` nor `Info.plist` declares one) — Google sign-in
      will fail on a real device without it
- [ ] Set a real Google `serverClientId` for production
- [ ] Wire eSewa / Khalti merchant credentials through an edge function so
      `payments.status` can never be flipped by a client
