#!/usr/bin/env bash
# =============================================================================
# check_backend.sh — verify the two live Supabase steps the app depends on
# =============================================================================
#
# Reads config/supabase.json (URL + publishable key) and reports:
#   1. Is the `payments` Edge Function deployed and answering?
#   2. Did migration 20261006000006 (services.gender) actually apply?
#
# Usage:  bash tool/check_backend.sh
# Exit code: 0 when both are OK, 1 otherwise.
# =============================================================================
set -uo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cfg="$root/config/supabase.json"

if [ ! -f "$cfg" ]; then
  echo "ERROR: $cfg not found. Copy config/supabase.example.json to config/supabase.json." >&2
  exit 2
fi

URL=$(sed -n 's/.*"SUPABASE_URL"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$cfg")
KEY=$(sed -n 's/.*"SUPABASE_PUBLISHABLE_KEY"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$cfg")

if [ -z "$URL" ] || [ -z "$KEY" ]; then
  echo "ERROR: could not read SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY from $cfg" >&2
  exit 2
fi

echo "Project: $URL"
echo

ok=0
hdr() { printf '%s\n' "$1"; }

# ---- 1. payments Edge Function ----------------------------------------------
code=$(curl -s -o /tmp/pay_body.$$ -w '%{http_code}' "$URL/functions/v1/payments" 2>/dev/null || echo 000)
body=$(cat /tmp/pay_body.$$ 2>/dev/null); rm -f /tmp/pay_body.$$

hdr "[1] payments Edge Function"
case "$code" in
  000) echo "    ?  network error (could not reach Supabase)";;
  404) echo "    X  NOT DEPLOYED (HTTP 404) — deploy per supabase/DEPLOY_PAYMENTS.md";;
  200) echo "    OK DEPLOYED (HTTP 200): $(printf '%s' "$body" | head -c 160)";;
  *)   echo "    ~  responded HTTP $code (deployed but check secrets): $(printf '%s' "$body" | head -c 160)";;
esac
[ "$code" = "200" ] || ok=1
echo

# ---- 2. services.gender migration -------------------------------------------
hdr "[2] services.gender migration"
gend=$(curl -s "$URL/rest/v1/services?select=gender&limit=1" \
        -H "apikey: $KEY" -H "Authorization: Bearer $KEY" 2>/dev/null || echo '')
case "$gend" in
  *"does not exist"*)
    echo "    X  NOT APPLIED — run supabase/migrations/20261006000006_service_gender.sql";;
  \[*)
    echo "    OK APPLIED"
    dist=$(curl -s "$URL/rest/v1/services?select=gender" \
            -H "apikey: $KEY" -H "Authorization: Bearer $KEY" 2>/dev/null)
    for g in men women unisex; do
      n=$(printf '%s' "$dist" | grep -o "\"$g\"" | wc -l | tr -d ' ')
      printf '       %-7s %s\n' "$g" "$n"
    done;;
  "")  echo "    ?  empty/blocked response (check RLS or key)"; ok=1;;
  *)   echo "    ?  unexpected response: $(printf '%s' "$gend" | head -c 160)"; ok=1;;
esac
[ "$gend" != "${gend#\[}" ] || ok=1
echo

if [ "$ok" = "0" ]; then
  echo "All backend checks passed."
else
  echo "One or more backend steps are still outstanding (see above)."
fi
exit "$ok"
