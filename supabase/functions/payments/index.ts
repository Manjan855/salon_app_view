// =============================================================================
// payments — eSewa / Khalti checkout for salon bookings
// =============================================================================
//
// One deployable Edge Function that owns the whole Nepal payment handshake:
//
//   POST  /functions/v1/payments/initiate          (app → here, user JWT)
//   GET   /functions/v1/payments/checkout?token=…  (browser → here)
//   GET   /functions/v1/payments/callback/esewa    (eSewa → here)
//   GET   /functions/v1/payments/callback/khalti   (Khalti → here)
//
// Design rules (match the DB contract in migrations/…_rls.sql):
//   • The client never writes a payment status. It may only *ask* for a
//     checkout; the money-changing UPDATEs happen here, under the service key.
//   • The amount always comes from the booking row server-side — never from
//     the request body — so a tampered app cannot pay Rs 1 for a Rs 5000 slot.
//   • Every provider callback is re-verified against the provider's own
//     status/lookup API before the booking is marked paid.
//
// Admin access: the function bypasses RLS to update `payments` / `bookings`.
// Supabase automatically injects `SUPABASE_SECRET_KEYS` (a JSON map of the
// project's new-style secret keys), so no key has to be copied by hand —
// deploying the function is enough. Set `SB_SECRET_KEY` only to override
// which key is used (handy for local runs).
//
// Required function secrets (Dashboard → Edge Functions → Secrets):
//   APP_WEBSITE_URL       https://…        ← Khalti `website_url` (any valid URL)
//   APP_PAYMENT_REDIRECT_URL               ← default salonappview://payment-result
//
// Optional — override the sandbox defaults below:
//
// eSewa (sandbox defaults shown; override for production):
//   ESEWA_PRODUCT_CODE    EPAYTEST
//   ESEWA_SECRET_KEY      8gBm/:&EnhH.1/q
//   ESEWA_FORM_URL        https://rc-epay.esewa.com.np/api/epay/main/v2/form
//   ESEWA_STATUS_URL      https://rc.esewa.com.np/api/epay/transaction/status/
//
// Khalti (no sandbox key ships in the repo — set your own):
//   KHALTI_SECRET_KEY     live_secret_key_… (test-admin.khalti.com for sandbox)
//   KHALTI_BASE_URL       https://dev.khalti.com/api/v2
//
// Deploy either from the Dashboard (Edge Functions → Deploy a new function →
// Via Editor → name it `payments` → paste this file → turn OFF JWT
// verification) or with the CLI:
//   supabase functions deploy payments --no-verify-jwt
// (config.toml already sets verify_jwt = false; callbacks cannot carry a JWT.)
// =============================================================================

import { createClient } from "npm:@supabase/supabase-js@2";

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";

/**
 * Resolve a key that bypasses RLS. Preference order:
 *   1. SB_SECRET_KEY              — explicit override (function secret)
 *   2. SUPABASE_SECRET_KEYS JSON  — auto-injected by Supabase, e.g.
 *                                   {"default":"sb_secret_…"}; no manual copy
 *   3. SUPABASE_SERVICE_ROLE_KEY  — legacy fallback (disabled on this project)
 */
function resolveServiceKey(): string {
  const explicit = Deno.env.get("SB_SECRET_KEY");
  if (explicit) return explicit;

  const bundled = Deno.env.get("SUPABASE_SECRET_KEYS");
  if (bundled) {
    try {
      const parsed = JSON.parse(bundled) as Record<string, unknown>;
      const first = parsed["default"] ?? Object.values(parsed)[0];
      if (typeof first === "string" && first) return first;
    } catch {
      // malformed JSON — fall through to the legacy variable
    }
  }

  return Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
}

const SERVICE_KEY = resolveServiceKey();

const APP_WEBSITE_URL =
  Deno.env.get("APP_WEBSITE_URL") ?? "https://salonappview.example";
const APP_PAYMENT_REDIRECT_URL =
  Deno.env.get("APP_PAYMENT_REDIRECT_URL") ?? "salonappview://payment-result";

const ESEWA_PRODUCT_CODE = Deno.env.get("ESEWA_PRODUCT_CODE") ?? "EPAYTEST";
const ESEWA_SECRET_KEY = Deno.env.get("ESEWA_SECRET_KEY") ?? "8gBm/:&EnhH.1/q";
const ESEWA_FORM_URL =
  Deno.env.get("ESEWA_FORM_URL") ??
  "https://rc-epay.esewa.com.np/api/epay/main/v2/form";
const ESEWA_STATUS_URL =
  Deno.env.get("ESEWA_STATUS_URL") ??
  "https://rc.esewa.com.np/api/epay/transaction/status/";

const KHALTI_SECRET_KEY = Deno.env.get("KHALTI_SECRET_KEY") ?? "";
const KHALTI_BASE_URL =
  Deno.env.get("KHALTI_BASE_URL") ?? "https://dev.khalti.com/api/v2";

const CHECKOUT_TTL_MINUTES = 60;

const admin = createClient(SUPABASE_URL, SERVICE_KEY, {
  auth: { persistSession: false, autoRefreshToken: false },
});

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

type Provider = "esewa" | "khalti";
type Json = Record<string, unknown>;

// ---------------------------------------------------------------------------
// Small helpers
// ---------------------------------------------------------------------------
function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS, "Content-Type": "application/json" },
  });
}

function html(body: string, status = 200): Response {
  return new Response(body, {
    status,
    headers: { ...CORS, "Content-Type": "text/html; charset=utf-8" },
  });
}

/** 302 the browser back into the app (custom scheme) or to a provider. */
function redirect(location: string): Response {
  return new Response(null, {
    status: 302,
    headers: { ...CORS, Location: location },
  });
}

/** Append query params to the deep link without assuming URL parser support. */
function deepLink(params: Record<string, string | null>): string {
  const clean: Record<string, string> = {};
  for (const [k, v] of Object.entries(params)) if (v != null) clean[k] = v;
  const qs = new URLSearchParams(clean).toString();
  const sep = APP_PAYMENT_REDIRECT_URL.includes("?") ? "&" : "?";
  return `${APP_PAYMENT_REDIRECT_URL}${sep}${qs}`;
}

function pageFor(title: string, message: string): Response {
  return html(`<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${title}</title>
<style>body{font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;
background:#1a0b2e;color:#fff;display:flex;min-height:100vh;align-items:center;
justify-content:center;margin:0}.card{max-width:420px;padding:32px;text-align:center}
h1{font-size:20px;margin:0 0 8px}p{color:#b9a5d6;font-size:14px;line-height:1.6}</style>
</head><body><div class="card"><h1>${title}</h1><p>${message}</p></div></body></html>`);
}

function getBearerToken(req: Request): string | null {
  const header = req.headers.get("Authorization") ?? "";
  const match = header.match(/^Bearer\s+(.+)$/i);
  return match ? match[1] : null;
}

/** Base64 of HMAC-SHA256(message, key) — exactly what eSewa signs with. */
async function hmacSha256Base64(message: string, key: string): Promise<string> {
  const enc = new TextEncoder();
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    enc.encode(key),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", cryptoKey, enc.encode(message));
  return btoa(String.fromCharCode(...new Uint8Array(sig)));
}

/** Constant-time-ish string compare (both inputs are short here). */
function safeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

function decodeBase64Json(data: string): Json {
  const normalized = data.replace(/-/g, "+").replace(/_/g, "/");
  const bytes = Uint8Array.from(atob(normalized), (c) => c.charCodeAt(0));
  return JSON.parse(new TextDecoder().decode(bytes));
}

function money(value: unknown): string {
  // PostgREST returns numeric(10,2) as a JSON number; normalise to "150".
  const n = Number(value);
  if (!Number.isFinite(n)) throw new Error("invalid amount");
  return String(n);
}

// ---------------------------------------------------------------------------
// eSewa helpers
// ---------------------------------------------------------------------------
function esewaSignature(totalAmount: string, uuid: string): Promise<string> {
  const message =
    `total_amount=${totalAmount},transaction_uuid=${uuid}` +
    `,product_code=${ESEWA_PRODUCT_CODE}`;
  return hmacSha256Base64(message, ESEWA_SECRET_KEY);
}

async function verifyEsewaSignature(payload: Json): Promise<boolean> {
  const signedFields = String(payload["signed_field_names"] ?? "");
  const signature = String(payload["signature"] ?? "");
  if (!signedFields || !signature) return false;

  const message = signedFields
    .split(",")
    .map((field) => `${field}=${payload[field] ?? ""}`)
    .join(",");

  const expected = await hmacSha256Base64(message, ESEWA_SECRET_KEY);
  return safeEqual(expected, signature);
}

// ---------------------------------------------------------------------------
// Route: POST /initiate  — create a `pending` payment, hand back a checkout URL
// ---------------------------------------------------------------------------
async function handleInitiate(req: Request): Promise<Response> {
  const token = getBearerToken(req);
  if (!token) return json({ error: "Missing Authorization header" }, 401);

  const { data: userData, error: userError } = await admin.auth.getUser(token);
  if (userError || !userData.user) {
    return json({ error: "Invalid or expired session" }, 401);
  }
  const user = userData.user;

  let body: Json;
  try {
    body = (await req.json()) as Json;
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const bookingId = String(body["booking_id"] ?? "");
  const provider = String(body["provider"] ?? "") as Provider;
  if (!bookingId) return json({ error: "booking_id is required" }, 400);
  if (provider !== "esewa" && provider !== "khalti") {
    return json({ error: "provider must be 'esewa' or 'khalti'" }, 400);
  }
  if (provider === "khalti" && !KHALTI_SECRET_KEY) {
    return json({ error: "Khalti is not configured (KHALTI_SECRET_KEY missing)" }, 503);
  }

  const { data: booking, error: bookingError } = await admin
    .from("bookings")
    .select("id, user_id, total_price, status, payment_status")
    .eq("id", bookingId)
    .maybeSingle();

  if (bookingError) return json({ error: bookingError.message }, 500);
  if (!booking) return json({ error: "Booking not found" }, 404);
  if (booking.user_id !== user.id) {
    return json({ error: "You do not own this booking" }, 403);
  }
  if (booking.payment_status === "paid") {
    return json({ error: "Booking is already paid" }, 409);
  }
  if (booking.status === "cancelled" || booking.status === "no_show") {
    return json({ error: "Booking is no longer payable" }, 409);
  }

  const amount = money(booking.total_price);
  if (Number(amount) <= 0) return json({ error: "Booking has no payable amount" }, 400);

  const checkoutToken = crypto.randomUUID();

  const { data: payment, error: insertError } = await admin
    .from("payments")
    .insert({
      booking_id: bookingId,
      user_id: user.id,
      amount: Number(amount),
      currency: "NPR",
      provider,
      status: "pending",
      provider_payload: { checkout_token: checkoutToken },
    })
    .select("id")
    .single();

  if (insertError) return json({ error: insertError.message }, 500);

  const checkoutUrl =
    `${SUPABASE_URL}/functions/v1/payments/checkout?token=${checkoutToken}`;

  return json({
    payment_id: payment.id,
    checkout_url: checkoutUrl,
    amount: Number(amount),
    currency: "NPR",
    provider,
  });
}

// ---------------------------------------------------------------------------
// Route: GET /checkout?token=…  — browser lands here, we hand off to provider
// ---------------------------------------------------------------------------
async function handleCheckout(req: Request): Promise<Response> {
  const token = new URL(req.url).searchParams.get("token") ?? "";
  if (!token) return pageFor("Invalid link", "This checkout link is missing its token.");

  const { data: payment, error } = await admin
    .from("payments")
    .select("id, booking_id, amount, provider, status, created_at, provider_payload")
    .contains("provider_payload", { checkout_token: token })
    .maybeSingle();

  if (error) return pageFor("Something went wrong", error.message);
  if (!payment) return pageFor("Link not found", "We could not find that checkout.");

  if (payment.status !== "pending") {
    return pageFor("Already processed", `This payment is marked "${payment.status}".`);
  }

  const ageMinutes =
    (Date.now() - new Date(payment.created_at).getTime()) / 60000;
  if (ageMinutes > CHECKOUT_TTL_MINUTES) {
    await admin.from("payments").update({ status: "expired" }).eq("id", payment.id);
    return pageFor("Link expired", "Please start the payment again from the app.");
  }

  return payment.provider === "esewa"
    ? await checkoutEsewa(payment)
    : await checkoutKhalti(payment);
}

async function checkoutEsewa(payment: Json): Promise<Response> {
  const uuid = String(payment.id);
  const amount = money(payment.amount);
  const signature = await esewaSignature(amount, uuid);
  const callback = `${SUPABASE_URL}/functions/v1/payments/callback/esewa`;

  await admin
    .from("payments")
    .update({
      provider_ref: uuid,
      provider_payload: {
        ...((payment.provider_payload as Json) ?? {}),
        transaction_uuid: uuid,
      },
    })
    .eq("id", payment.id);

  const fields: Record<string, string> = {
    amount,
    tax_amount: "0",
    total_amount: amount,
    transaction_uuid: uuid,
    product_code: ESEWA_PRODUCT_CODE,
    product_service_charge: "0",
    product_delivery_charge: "0",
    success_url: callback,
    failure_url: callback,
    signed_field_names: "total_amount,transaction_uuid,product_code",
    signature,
  };

  const inputs = Object.entries(fields)
    .map(
      ([k, v]) =>
        `<input type="hidden" name="${k}" value="${v.replace(/"/g, "&quot;")}">`,
    )
    .join("");

  // eSewa v2 only accepts a form POST, so we self-submit from the browser.
  return html(`<!doctype html><html><head><meta charset="utf-8">
<title>Redirecting to eSewa…</title></head>
<body onload="document.forms[0].submit()">
<form method="POST" action="${ESEWA_FORM_URL}">${inputs}
<noscript><button type="submit">Continue to eSewa</button></noscript>
</form></body></html>`);
}

async function checkoutKhalti(payment: Json): Promise<Response> {
  const amountPaisa = Math.round(Number(money(payment.amount)) * 100);
  const returnUrl = `${SUPABASE_URL}/functions/v1/payments/callback/khalti`;

  const res = await fetch(`${KHALTI_BASE_URL}/epayment/initiate/`, {
    method: "POST",
    headers: {
      Authorization: `key ${KHALTI_SECRET_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      return_url: returnUrl,
      website_url: APP_WEBSITE_URL,
      amount: amountPaisa,
      purchase_order_id: String(payment.id),
      purchase_order_name: "Salon appointment",
    }),
  });

  const data = (await res.json().catch(() => ({}))) as Json;
  if (!res.ok || !data["payment_url"] || !data["pidx"]) {
    return pageFor(
      "Khalti error",
      `We could not start the Khalti payment. ${data["detail"] ?? res.status}`,
    );
  }

  await admin
    .from("payments")
    .update({
      provider_ref: String(data["pidx"]),
      provider_payload: {
        ...((payment.provider_payload as Json) ?? {}),
        pidx: data["pidx"],
      },
    })
    .eq("id", payment.id);

  return redirect(String(data["payment_url"]));
}

// ---------------------------------------------------------------------------
// Finalisation — the only place a payment status changes
// ---------------------------------------------------------------------------
async function finalize(
  paymentId: string,
  ok: boolean,
  providerRef: string | null,
  payload: Json,
): Promise<{ bookingId: string | null }> {
  const { data: payment } = await admin
    .from("payments")
    .update({
      status: ok ? "paid" : "failed",
      provider_ref: providerRef,
      provider_payload: payload,
    })
    .eq("id", paymentId)
    .select("booking_id")
    .maybeSingle();

  const bookingId = payment?.booking_id ?? null;
  if (bookingId && ok) {
    await admin
      .from("bookings")
      .update({ payment_status: "paid" })
      .eq("id", bookingId);
  }
  return { bookingId };
}

function failureLink(provider: Provider, paymentId: string | null, bookingId: string | null, reason: string): Response {
  return redirect(
    deepLink({
      status: "failed",
      provider,
      payment_id: paymentId,
      booking_id: bookingId,
      reason,
    }),
  );
}

// ---------------------------------------------------------------------------
// Route: GET /callback/esewa?data=…
// ---------------------------------------------------------------------------
async function handleEsewaCallback(req: Request): Promise<Response> {
  const data = new URL(req.url).searchParams.get("data");
  if (!data) return failureLink("esewa", null, null, "missing_data");

  let payload: Json;
  try {
    payload = decodeBase64Json(data);
  } catch {
    return failureLink("esewa", null, null, "bad_payload");
  }

  if (!(await verifyEsewaSignature(payload))) {
    return failureLink("esewa", null, null, "bad_signature");
  }

  const uuid = String(payload["transaction_uuid"] ?? "");
  if (!uuid) return failureLink("esewa", null, null, "missing_uuid");

  // payment.id was used as transaction_uuid
  const { data: payment } = await admin
    .from("payments")
    .select("id, booking_id, amount, status")
    .eq("provider_ref", uuid)
    .maybeSingle();

  if (!payment) return failureLink("esewa", null, null, "unknown_payment");
  if (payment.status === "paid") {
    return redirect(
      deepLink({
        status: "paid",
        provider: "esewa",
        payment_id: payment.id,
        booking_id: payment.booking_id,
      }),
    );
  }

  // Never trust the callback alone — ask eSewa for the authoritative status.
  const verifyUrl = new URL(ESEWA_STATUS_URL);
  verifyUrl.searchParams.set("product_code", ESEWA_PRODUCT_CODE);
  verifyUrl.searchParams.set("total_amount", money(payment.amount));
  verifyUrl.searchParams.set("transaction_uuid", uuid);

  let verified: Json = {};
  try {
    verified = (await (await fetch(verifyUrl.toString())).json()) as Json;
  } catch {
    return failureLink("esewa", payment.id, payment.booking_id, "verify_unreachable");
  }

  const providerRef = String(verified["ref_id"] ?? payload["transaction_code"] ?? "");
  const ok =
    verified["status"] === "COMPLETE" &&
    String(verified["total_amount"] ?? "") === money(payment.amount);

  if (!ok) {
    await finalize(payment.id, false, providerRef || null, { esewa: verified });
    return failureLink("esewa", payment.id, payment.booking_id, "not_complete");
  }

  await finalize(payment.id, true, providerRef || uuid, { esewa: verified });
  return redirect(
    deepLink({
      status: "paid",
      provider: "esewa",
      payment_id: payment.id,
      booking_id: payment.booking_id,
    }),
  );
}

// ---------------------------------------------------------------------------
// Route: GET/POST /callback/khalti
// ---------------------------------------------------------------------------
async function handleKhaltiCallback(req: Request): Promise<Response> {
  const url = new URL(req.url);
  const params = new URLSearchParams(url.search);
  if (req.method === "POST") {
    const form = await req.formData().catch(() => null);
    if (form) for (const [k, v] of form.entries()) params.set(k, String(v));
  }

  const pidx = params.get("pidx") ?? "";
  const orderId = params.get("purchase_order_id") ?? "";
  if (!pidx) return failureLink("khalti", null, null, "missing_pidx");

  const { data: payment } = await admin
    .from("payments")
    .select("id, booking_id, amount, status")
    .or(
      `provider_ref.eq.${pidx}${orderId ? `,id.eq.${orderId}` : ""}`,
    )
    .maybeSingle();

  if (!payment) return failureLink("khalti", null, null, "unknown_payment");
  if (payment.status === "paid") {
    return redirect(
      deepLink({
        status: "paid",
        provider: "khalti",
        payment_id: payment.id,
        booking_id: payment.booking_id,
      }),
    );
  }

  let lookup: Json = {};
  try {
    const res = await fetch(`${KHALTI_BASE_URL}/epayment/lookup/`, {
      method: "POST",
      headers: {
        Authorization: `key ${KHALTI_SECRET_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ pidx }),
    });
    lookup = (await res.json()) as Json;
  } catch {
    return failureLink("khalti", payment.id, payment.booking_id, "verify_unreachable");
  }

  const expectedPaisa = Math.round(Number(money(payment.amount)) * 100);
  const ok =
    lookup["status"] === "Completed" &&
    Number(lookup["total_amount"] ?? -1) === expectedPaisa;

  const providerRef = String(lookup["transaction_id"] ?? pidx);
  if (!ok) {
    await finalize(payment.id, false, providerRef, { khalti: lookup });
    return failureLink("khalti", payment.id, payment.booking_id, "not_completed");
  }

  await finalize(payment.id, true, providerRef, { khalti: lookup });
  return redirect(
    deepLink({
      status: "paid",
      provider: "khalti",
      payment_id: payment.id,
      booking_id: payment.booking_id,
    }),
  );
}

// ---------------------------------------------------------------------------
// Router
// ---------------------------------------------------------------------------
Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  if (!SERVICE_KEY) {
    return json(
      {
        error:
          "Payments function has no admin key (set SB_SECRET_KEY or rely on the auto-injected SUPABASE_SECRET_KEYS)",
      },
      503,
    );
  }

  const { pathname } = new URL(req.url);
  const action = pathname.split("/").filter(Boolean).join("/");
  const route = action.slice(action.indexOf("payments") + "payments".length);

  try {
    if (route === "/initiate" || route === "/initiate/") return await handleInitiate(req);
    if (route === "/checkout" || route === "/checkout/") return await handleCheckout(req);
    if (route.startsWith("/callback/esewa")) return await handleEsewaCallback(req);
    if (route.startsWith("/callback/khalti")) return await handleKhaltiCallback(req);

    return json({
      ok: true,
      service: "payments",
      providers: ["esewa", "khalti"],
      routes: ["POST /initiate", "GET /checkout", "GET /callback/esewa", "GET /callback/khalti"],
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return json({ error: message }, 500);
  }
});
