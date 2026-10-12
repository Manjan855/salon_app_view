#!/usr/bin/env bash
# =============================================================================
# google_signin_check.sh — print the values Google Cloud Console needs
# =============================================================================
#
# "Unexpected error occurred" right after picking a Google account is almost
# always a native config mismatch, not an app bug: Google cannot find an
# Android OAuth client whose package name + SHA-1 match this build (or an iOS
# client for the bundle id), so it returns `clientConfigurationError`.
#
# This is the usual fallout of renaming the app id (com.example.* -> com.salon.*)
# without re-registering the new one. Run this and copy the values into:
#   https://console.cloud.google.com/apis/credentials
#   (same project as the "Web application" client used by Supabase)
#
# Usage:  bash tool/google_signin_check.sh
# =============================================================================
set -uo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

section() { printf '\n== %s ==\n' "$1"; }

# --- App identifiers ---------------------------------------------------------
section "App identifiers"
android_id="$(grep -E 'applicationId[[:space:]]*=' android/app/build.gradle.kts 2>/dev/null | head -1 | sed 's/.*"\(.*\)".*/\1/')"
ios_id="$(grep -m1 -E 'PRODUCT_BUNDLE_IDENTIFIER = ' ios/Runner.xcodeproj/project.pbxproj 2>/dev/null | sed 's/.*= \(.*\);/\1/' | tr -d ' ')"
echo "Android package : ${android_id:-<not found>}"
echo "iOS bundle id   : ${ios_id:-<not found>}"

# --- Debug keystore ----------------------------------------------------------
section "Android debug keystore fingerprint"
ks="$HOME/.android/debug.keystore"
if [ -f "$ks" ]; then
  keytool -list -v -keystore "$ks" -alias androiddebugkey \
    -storepass android -keypass android 2>/dev/null \
    | grep -iE 'SHA1:|SHA256:' | sed 's/^[[:space:]]*/  /'
  echo "  (add every SHA-1 above; use 'flutter build apk --release' keystore"
  echo "   SHA-1 for release builds)"
else
  echo "  (no debug.keystore yet — run the app once to create it)"
fi

# --- Injected client IDs -----------------------------------------------------
section "Google client IDs (config/supabase.json)"
cfg="config/supabase.json"
if [ -f "$cfg" ]; then
  web="$(sed -n 's/.*"GOOGLE_SERVER_CLIENT_ID"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$cfg")"
  ios="$(sed -n 's/.*"GOOGLE_IOS_CLIENT_ID"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$cfg")"
  url="$(sed -n 's/.*"SUPABASE_URL"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$cfg")"
  key="$(sed -n 's/.*"SUPABASE_PUBLISHABLE_KEY"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$cfg")"
  echo "Web/server client : ${web:-<MISSING>}"
  echo "iOS client        : ${ios:-<MISSING>}"
else
  echo "  config/supabase.json not found"
  web=""; url=""; key=""
fi

# --- Supabase provider -------------------------------------------------------
section "Supabase Google provider"
if [ -n "${url:-}" ] && [ -n "${key:-}" ]; then
  curl -s "$url/auth/v1/settings" -H "apikey: $key" -H "Authorization: Bearer $key" 2>/dev/null \
    | python -c "import sys,json; e=json.load(sys.stdin).get('external',{}); print('  google enabled :', e.get('google'))" 2>/dev/null \
    || echo "  (could not read auth settings)"
fi

# --- iOS plist ---------------------------------------------------------------
section "iOS Info.plist"
if grep -q 'REPLACE_WITH_IOS_CLIENT_ID' ios/Runner/Info.plist 2>/dev/null; then
  echo "  Google keys are still commented/placeholder — iOS Google sign-in"
  echo "  will fail until you uncomment and fill them (docs/google_signin.md §3)."
else
  echo "  Google keys look filled in."
fi

# --- Checklist ---------------------------------------------------------------
cat <<EOF

== What to fix ==
Open https://console.cloud.google.com/apis/credentials in the SAME project as
the web client above, then create/verify:

  1. Android OAuth client
       Package name : ${android_id:-<android package>}
       SHA-1        : (each fingerprint listed above)
  2. iOS OAuth client  (iOS builds only)
       Bundle ID    : ${ios_id:-<ios bundle id>}
  3. Web application client (already used by Supabase — leave as-is)
       Authorized redirect URI:
         ${url:-https://<project>.supabase.co}/auth/v1/callback

Renaming the app id (com.example.* -> com.salon.*) leaves the console holding
the OLD package, which is exactly what produces the error right after you pick
an account. Re-registering step 1 fixes it.
EOF
