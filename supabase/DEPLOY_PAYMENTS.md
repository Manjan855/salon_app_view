# Deploy the `payments` Edge Function (no CLI, no Deno install)

This is the exact, click-by-click path to get eSewa/Khalti checkout working.
Everything happens in the Supabase Dashboard — you do **not** need the Supabase
CLI, Docker, Deno, or Node on this machine.

Project: **`zhnfhkahspsqbfjetwlt`** (<https://supabase.com/dashboard/project/zhnfhkahspsqbfjetwlt>)

> **What "done" looks like:** opening
> `https://zhnfhkahspsqbfjetwlt.supabase.co/functions/v1/payments` in a browser
> returns JSON like `{"ok":true,"service":"payments",...}` instead of `404`.

---

## Why you don't need to create a secret key by hand

The function needs one thing: a key that bypasses RLS so it can flip
`payments.status` and `bookings.payment_status`. Supabase **auto-injects**
`SUPABASE_SECRET_KEYS` (a JSON map of the project's new-style secret keys) into
every hosted function, and `index.ts` now reads it (`resolveServiceKey()`).

So the only secrets you must set are the payment details below. (`SB_SECRET_KEY`
is still honoured as an override if you ever want to set one.)

---

## Part 1 — Deploy the function

1. Open **Edge Functions**:
   <https://supabase.com/dashboard/project/zhnfhkahspsqbfjetwlt/functions>
2. Click **Deploy a new function** → choose **Via Editor**.
3. Set the function **name** to exactly:

   ```
   payments
   ```

   (lower-case, no spaces — the app calls `payments/initiate`)
4. The editor loads a template. Select **all** of it (`Ctrl+A`) and replace it
   with the **entire contents** of:

   ```
   supabase/functions/payments/index.ts
   ```

   (open the file, `Ctrl+A`, `Ctrl+C`, paste — do not paste the file path.)
5. **Turn OFF JWT verification for this function.** This is required: eSewa and
   Khalti redirect the *user's browser* to `/callback/…` with no Supabase JWT,
   and the gateway would reject them with `401`.
   - If the editor shows a **Verify JWT** / **Enforce JWT verification** toggle,
     switch it **off** before deploying.
   - Otherwise deploy first, then open the function’s **Settings** tab and
     switch **Verify JWT** off (and save). No redeploy is needed for this flag.
6. Click **Deploy function** (bottom of the editor). Wait for “deployed”.

> The app’s call to `/initiate` still works with JWT verification off because
> `index.ts` validates the caller’s user token itself against Supabase Auth.

---

## Part 2 — Set the function secrets

Open **Edge Functions → Secrets**:
<https://supabase.com/dashboard/project/zhnfhkahspsqbfjetwlt/functions/secrets>

You can paste several rows at once. Add these:

| Key | Value | Required? |
|---|---|---|
| `APP_WEBSITE_URL` | `https://salonappview.example` (any valid URL) | yes — Khalti requires it |
| `APP_PAYMENT_REDIRECT_URL` | `salonappview://payment-result` | optional (this is the default) |
| `KHALTI_SECRET_KEY` | your Khalti key (`live_secret_key_…`; sandbox from `test-admin.khalti.com`) | only if testing Khalti |
| `ESEWA_PRODUCT_CODE` | `EPAYTEST` | optional — sandbox default |
| `ESEWA_SECRET_KEY` | `8gBm/:&EnhH.1/q` | optional — sandbox default |
| `ESEWA_FORM_URL` | `https://rc-epay.esewa.com.np/api/epay/main/v2/form` | optional — sandbox default |
| `ESEWA_STATUS_URL` | `https://rc.esewa.com.np/api/epay/transaction/status/` | optional — sandbox default |

Notes:
- **Do not** prefix any name with `SUPABASE_` — the dashboard rejects names
  starting with that reserved prefix.
- eSewa sandbox works with the built-in defaults, so for a first test you only
  strictly need `APP_WEBSITE_URL`. Khalti needs its own key.
- Secrets are read immediately; you do **not** redeploy after saving them.

---

## Part 3 — Verify it’s live (copy/paste)

### 3a. Base URL → should be JSON, not 404

Paste into a browser:

```
https://zhnfhkahspsqbfjetwlt.supabase.co/functions/v1/payments
```

Expected:

```json
{"ok":true,"service":"payments","providers":["esewa","khalti"],"routes":["POST /initiate","GET /checkout","GET /callback/esewa","GET /callback/khalti"]}
```

- `404` → function not deployed, or the name isn’t exactly `payments`.
- `503` with `"missing SB_SECRET_KEY"` → deployed, but the admin key didn’t
  resolve (see Part 5).

### 3b. `/initiate` with no token → should be 401

PowerShell:

```powershell
curl.exe -i "https://zhnfhkahspsqbfjetwlt.supabase.co/functions/v1/payments/initiate"
```

Expected: `HTTP/1.1 401` and `{"error":"Missing Authorization header"}`.
That proves the route exists and is enforcing auth.

---

## Part 4 — End-to-end sandbox test (eSewa)

1. In the app, sign in and create a booking (Home → salon → services → slot →
   confirm). This writes a real `bookings` row.
2. On **Payment options**, choose **eSewa** and pay.
3. The browser opens the eSewa sandbox page. Use the sandbox test wallet:
   - eSewa ID: `9711111111`
   - Password: `Nepal@123`
   - OTP: `123456`
4. After eSewa completes, the browser is bounced back to
   `salonappview://payment-result?status=paid&…` and the app shows
   “Payment successful”.

Confirm in the SQL Editor:

```sql
select p.status, p.provider, p.provider_ref, b.payment_status
from public.payments p
join public.bookings b on b.id = p.booking_id
order by p.created_at desc
limit 5;
```

You want the newest row: `status = paid` and `payment_status = paid`.

---

## Part 5 — Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Base URL `404` | Not deployed, or wrong function name | Re-deploy; the name must be exactly `payments` |
| `/initiate` returns `401` from the **app** (not curl) | User session expired | Sign out/in and retry |
| `503 {"error":"Payments function is missing SB_SECRET_KEY"}` | Admin key didn’t resolve | Confirm your project has the auto-injected key by redeploying; or create a secret key (Settings → API Keys → Create new secret key) and set it as the function secret `SB_SECRET_KEY` |
| eSewa/Khalti callback ends in `401` | JWT verification is still ON | Function → Settings → turn **Verify JWT** off |
| `{"error":"Khalti is not configured (KHALTI_SECRET_KEY missing)"}` | No Khalti key set | Set `KHALTI_SECRET_KEY`, or test eSewa instead |
| Checkout page says “Link expired” | You opened the old checkout URL after 60 min | Start the payment again from the app |
| App shows “Payment was not completed” | Provider status wasn’t `COMPLETE`/`Completed` or the amount didn’t match | Re-test; check the `payments.provider_payload` column for the provider response |

---

## Part 6 — CLI alternative (optional)

If you later install the Supabase CLI, you can deploy without Docker:

```bash
supabase link --project-ref zhnfhkahspsqbfjetwlt
supabase functions deploy payments --no-verify-jwt --use-api
```

`config.toml` already sets `verify_jwt = false` for `payments`, so `--no-verify-jwt`
is belt-and-braces.

---

## Part 7 — Going to production (later)

Replace the sandbox values with live merchant values (as function secrets):

- `ESEWA_PRODUCT_CODE`, `ESEWA_SECRET_KEY`, `ESEWA_FORM_URL`,
  `ESEWA_STATUS_URL` → your live eSewa merchant credentials.
- `KHALTI_BASE_URL` → `https://khalti.com/api/v2` (sandbox is
  `https://dev.khalti.com/api/v2`).
