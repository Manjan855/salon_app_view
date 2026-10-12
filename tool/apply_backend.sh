#!/usr/bin/env bash
# =============================================================================
# apply_backend.sh — run the two remaining live Supabase steps in one command
# =============================================================================
#
# This wraps the Supabase **Management API** with a Personal Access Token (PAT),
# so you do not need the Supabase CLI, Docker, Deno, or the dashboard:
#
#   1. Apply migrations/20261006000006_service_gender.sql   (idempotent DDL)
#   2. Deploy the `payments` Edge Function with JWT verify OFF
#   3. Re-run tool/check_backend.sh to prove both are live
#
# The PAT is read from, in order:
#   • $SUPABASE_ACCESS_TOKEN (or $SUPABASE_PAT) — export it for one shell, or
#   • supabase/.env (gitignored) — a line `SUPABASE_ACCESS_TOKEN=sbp_…`, or
#   • an interactive prompt (hidden input) if stdin is a terminal. You are then
#     offered to save it to supabase/.env for next time.
#
# The token is never printed and never written anywhere except the gitignored
# supabase/.env (only if you say yes). The project ref is read from
# config/supabase.json unless you pass --project-ref.
#
# Usage:
#   bash tool/apply_backend.sh
#   bash tool/apply_backend.sh --project-ref zhnfhkahspsqbfjetwlt
#   bash tool/apply_backend.sh --dry-run        # show the plan, send nothing
#
# Create / rotate a PAT:  https://supabase.com/dashboard/account/tokens
# Management API docs:    https://supabase.com/docs/reference/api
# =============================================================================
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

API="https://api.supabase.com/v1"
FN_SLUG="payments"
FN_ENTRYPOINT="index.ts"
MIG_REL="supabase/migrations/20261006000006_service_gender.sql"
FN_REL="supabase/functions/payments/index.ts"
CFG="config/supabase.json"

usage() {
  sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'
}

ref="${SUPABASE_PROJECT_REF:-}"
dry=0
while [ $# -gt 0 ]; do
  case "$1" in
    --project-ref)   ref="${2:-}"; shift 2 ;;
    --project-ref=*) ref="${1#*=}"; shift ;;
    --dry-run)       dry=1; shift ;;
    -h|--help)       usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; echo >&2; usage >&2; exit 2 ;;
  esac
done

# ---- required files ---------------------------------------------------------
[ -f "$MIG_REL" ] || { echo "ERROR: $MIG_REL not found (run this from the repo)." >&2; exit 2; }
[ -f "$FN_REL" ]  || { echo "ERROR: $FN_REL not found." >&2; exit 2; }

py="$(command -v python || command -v python3 || true)"
[ -n "$py" ] || { echo "ERROR: python is required to JSON-encode the request bodies." >&2; exit 2; }

# ---- project ref ------------------------------------------------------------
if [ -z "$ref" ] && [ -f "$CFG" ]; then
  url="$(sed -n 's/.*"SUPABASE_URL"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$CFG" | head -1)"
  if [ -n "$url" ]; then
    ref="${url#http://}"; ref="${ref#https://}"; ref="${ref%%/*}"; ref="${ref%.supabase.co}"
  fi
fi
[ -n "$ref" ] || { echo "ERROR: could not determine the project ref. Pass --project-ref <ref>." >&2; exit 2; }

# ---- token ------------------------------------------------------------------
token="${SUPABASE_ACCESS_TOKEN:-${SUPABASE_PAT:-}}"
if [ -z "$token" ] && [ -f "supabase/.env" ]; then
  token="$(sed -n 's/^[[:space:]]*SUPABASE_ACCESS_TOKEN[[:space:]]*=[[:space:]]*//p' "supabase/.env" \
           | tail -1 | tr -d "\r\"' ")"
fi
if [ -z "$token" ] && [ -t 0 ]; then
  printf 'Paste your Supabase Personal Access Token (sbp_...): ' >&2
  IFS= read -rs token || true
  echo >&2
  if [ -n "$token" ]; then
    printf 'Save it to the gitignored supabase/.env for next time? [y/N] ' >&2
    IFS= read -r ans || true
    case "$ans" in
      y|Y|yes|YES)
        # Append, never truncate — supabase/.env may already hold function
        # secrets (SB_SECRET_KEY, KHALTI_SECRET_KEY, ...).
        printf 'SUPABASE_ACCESS_TOKEN=%s\n' "$token" >> "supabase/.env"
        echo "Saved to supabase/.env (gitignored)." >&2 ;;
    esac
  fi
fi

echo "Project ref : $ref"
if [ "$dry" = 1 ]; then
  echo "Mode        : DRY RUN (no requests will be sent)"
elif [ -z "$token" ]; then
  cat >&2 <<'EOF'

ERROR: no Supabase Personal Access Token found.

Create one (it starts with sbp_):
  https://supabase.com/dashboard/account/tokens

Then do either:

  # one shell only
  export SUPABASE_ACCESS_TOKEN=sbp_xxx
  bash tool/apply_backend.sh

  # or store it once, gitignored
  echo 'SUPABASE_ACCESS_TOKEN=sbp_xxx' >> supabase/.env
EOF
  exit 2
else
  case "$token" in
    sbp_*) : ;;
    *) echo "WARNING: token does not start with 'sbp_' — expected a Personal Access Token." >&2 ;;
  esac
  echo "Token       : ${token:0:4}... (hidden)"
fi
echo

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

# =============================================================================
# 1. Apply the gender migration
# =============================================================================
echo "[1/3] Applying $MIG_REL"
q_payload="$("$py" -c 'import json,sys; print(json.dumps({"query": open(sys.argv[1], encoding="utf-8").read()}))' "$MIG_REL")"
if [ "$dry" = 1 ]; then
  echo "      POST $API/projects/$ref/database/query   (query = contents of $MIG_REL)"
else
  http="$(curl -sS -o "$tmp" -w '%{http_code}' -X POST "$API/projects/$ref/database/query" \
            -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json" \
            --data-binary "$q_payload" || true)"
  body="$(cat "$tmp" 2>/dev/null || true)"
  case "$http" in
    2*) echo "      OK (HTTP $http): $(printf '%s' "$body" | head -c 240)" ;;
    *)  echo "      FAILED (HTTP ${http:-000}): $(printf '%s' "$body" | head -c 400)" >&2; exit 1 ;;
  esac
fi
echo

# =============================================================================
# 2. Deploy the payments Edge Function (verify_jwt = false)
# =============================================================================
echo "[2/3] Deploying Edge Function '$FN_SLUG' (verify_jwt=false)"
meta="$("$py" -c 'import json,sys; print(json.dumps({"name":sys.argv[1],"entrypoint_path":sys.argv[2],"verify_jwt":False}))' \
        "$FN_SLUG" "$FN_ENTRYPOINT")"
if [ "$dry" = 1 ]; then
  echo "      POST $API/projects/$ref/functions/deploy?slug=$FN_SLUG"
  echo "      metadata : $meta"
  echo "      file     : $FN_REL  ->  $FN_ENTRYPOINT"
else
  http="$(curl -sS -o "$tmp" -w '%{http_code}' -X POST "$API/projects/$ref/functions/deploy?slug=$FN_SLUG" \
      -H "Authorization: Bearer $token" \
      -F "metadata=$meta;type=application/json" \
      -F "file=@$FN_REL;filename=$FN_ENTRYPOINT" || true)"
  body="$(cat "$tmp")"
  case "$http" in
    2*) echo "      OK (HTTP $http): $(printf '%s' "$body" | head -c 240)";;
    *)  echo "      FAILED (HTTP $http): $(printf '%s' "$body" | head -c 400)" >&2; exit 1 ;;
  esac
fi
echo

# =============================================================================
# 3. Verify
# =============================================================================
echo "[3/3] Verifying with tool/check_backend.sh"
if [ "$dry" = 1 ]; then
  echo "      (skipped in dry run)"
  echo
  echo "Dry run complete. Re-run without --dry-run to apply."
  exit 0
fi

if bash tool/check_backend.sh; then
  echo
  echo "Done — the gender migration and the payments function are both live."
else
  echo >&2
  echo "The steps reported success, but check_backend still shows work pending (above)." >&2
  exit 1
fi
