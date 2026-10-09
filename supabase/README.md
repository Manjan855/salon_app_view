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

## Payments Edge Function (`supabase/functions/payments`)

`payments/index.ts` is the only code allowed to move money. It implements the
whole Nepal checkout handshake and re-verifies every transaction against the
provider's own API before flipping a status:

| Route | Called by | Purpose |
|---|---|---|
| `POST /initiate` | the app (user JWT) | validates booking ownership, creates a `pending` payment, returns a `checkout_url` |
| `GET /checkout?token=…` | the browser | eSewa: self-submitting form POST · Khalti: 302 to `payment_url` |
| `GET /callback/esewa` | eSewa | verifies HMAC, then calls eSewa's status API |
| `GET/POST /callback/khalti` | Khalti | calls Khalti's lookup API |

The amount is always read from `bookings.total_price` server-side, and the app
never writes `payments.status` — it only asks for a checkout. After verifying,
the function marks `payments.status = 'paid'` and `bookings.payment_status =
'paid'`, then 302s the browser to `salonappview://payment-result?…`, which the
app-links listener in `lib/run_app.dart` picks up.

### One-time setup

1. **Create a secret key** — Dashboard → Project Settings → API Keys →
   *Publishable and secret keys* → **Create new secret key** (`sb_secret_…`).
   (Required: the legacy `service_role` JWT is disabled on this project, so the
   auto-injected `SUPABASE_SERVICE_ROLE_KEY` no longer works.)
2. **Set the function secrets** (Dashboard → Edge Functions → Secrets, or CLI):
   ```sh
   supabase secrets set SB_SECRET_KEY=sb_secret_… \
     APP_WEBSITE_URL=https://your-site.example \
     ESEWA_PRODUCT_CODE=EPAYTEST \
     ESEWA_SECRET_KEY=8gBm/:&EnhH.1/q \
     ESEWA_FORM_URL=https://rc-epay.esewa.com.np/api/epay/main/v2/form \
     ESEWA_STATUS_URL=https://rc.esewa.com.np/api/epay/transaction/status/ \
     KHALTI_SECRET_KEY=live_secret_key_…
   ```
3. **Deploy** (config.toml already sets `verify_jwt = false` so the provider
   callbacks work; `/initiate` verifies the user JWT itself):
   ```sh
   supabase functions deploy payments --no-verify-jwt
   ```
   No CLI? Paste `index.ts` into the dashboard's Edge Functions editor and set
   the same secrets there.

Production switch = replace the three `ESEWA_*` URL/code values and
`KHALTI_BASE_URL` (`https://khalti.com/api/v2`) with the live merchant values.
eSewa sandbox test wallet: id `9711111111` / password `Nepal@123` / OTP `123456`.

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
- [x] Configure the OAuth redirect scheme — `salonappview://auth-callback` is
      now declared in `android/app/src/main/AndroidManifest.xml`
      (VIEW / BROWSABLE intent-filter on `MainActivity`) and
      `ios/Runner/Info.plist` (`CFBundleURLTypes`), exposed as
      `AppEnv.authRedirectUrl` and passed as `emailRedirectTo` from
      `AuthProvider.signUp`. `supabase_flutter` starts its deep-link observer
      automatically (`detectSessionInUri` defaults to true), so a `?code=`
      arriving on that link is exchanged for the session. The *native* Google
      path (`google_sign_in` → `signInWithIdToken`) never leaves the app and
      does not use this link; the scheme covers the browser flows — OAuth
      fallback, magic link, password reset, confirmation link.
      `test/deep_link_test.dart` fails if the three declarations drift apart.
- [x] **Add `salonappview://auth-callback` to the redirect allow list** —
      Authentication → URL Configuration → Redirect URLs. Supabase rejects
      any redirect that is not listed, so the link above only starts working
      after this dashboard step (same hands-on step as the key flip).
      **Done:** saved in the Supabase dashboard.
- [ ] Set a real Google `serverClientId` for production — Android also needs
      that value as `defaultWebClientId`, iOS needs `GIDClientID` plus the
      client ID's reversed form (`com.googleusercontent.apps.<CLIENT_ID>`)
      as a `CFBundleURLSchemes` entry
- [x] Wire eSewa / Khalti merchant credentials through an edge function so
      `payments.status` can never be flipped by a client — **done:**
      `supabase/functions/payments/index.ts` (see *Payments Edge Function*
      above). The app now only requests a checkout; the function re-verifies
      each transaction with the provider before writing `paid`.
- [ ] **Create the `sb_secret_…` key and set the function secrets**, then
      deploy `payments` (see *One-time setup* above). Until this is done the
      function is not reachable — `/initiate` returns 404.
- [x] **Rebuild the booking funnel on real data** — **done for the
      services → slots → booking → appointment path.** The entrance lists
      (Home "Salons near you" and Explore) now read live rows from
      `public.salons`; `SalonServicesScreen` loads `public.services`;
      `SlotsAvailabilityScreen` calls the `get_available_slots()` RPC for a
      picked date; `BookingSlotsScreen` loads `public.staff`, queries each
      stylist's slots, and on confirm inserts the `bookings` row plus its
      `booking_services` lines via `BookingProvider.createBooking()`. The new
      `bookings.id` is passed to `PaymentOptionsScreen`, so online payment is
      reachable. `MyAppointmentsScreen` renders the user's real bookings and
      wires cancel. The mock data still remains as an offline/demo fallback
      when a screen is opened without a real `salon.id`.
- [x] **Wire the remaining static screens** — **done.** Wishlist/favourites now
      read and write `public.favourites` (heart toggles on the Explore cards and
      the salon header); the notifications inbox reads `public.notifications`
      (unread badge on Home, mark-read / mark-all); the Home offers row and the
      Profile "My promocodes" sheet read active `public.coupons` (the sample
      list is kept as an offline fallback); Explore's search and sort now filter
      the live salon list locally.
- [ ] **Men/Women service tiles & the Gender filter** — the Home service tiles
      now jump to Explore but cannot filter by service category (there is no
      gender/category column on `salons`), and the Gender sheet is still
      cosmetic. Wire these once a category/price facet exists on the salons
      query (or drop the Gender filter).
- [ ] **Drop the archived legacy schema** after launch:
      `drop schema archive cascade;` — removes the old hand-made tables for
      good (nothing is currently lost by leaving it in place).
