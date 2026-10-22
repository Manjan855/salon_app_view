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
# Prefer the app-scoped key when present (build.gradle.kts uses it automatically).
if [ -f android/app/debug.keystore ]; then
  ks="android/app/debug.keystore"
  ks_label="project-scoped (android/app/debug.keystore)"
else
  ks="$HOME/.android/debug.keystore"
  ks_label="machine-wide (~/.android/debug.keystore)"
fi
ks_sha1=""
echo "  Keystore: $ks_label"
if [ -f "$ks" ]; then
  ks_sha1="$(keytool -list -v -keystore "$ks" -alias androiddebugkey \
    -storepass android -keypass android 2>/dev/null \
    | tr -d '\r' | sed -n 's/^[[:space:]]*SHA1:[[:space:]]*//p' | head -1)"
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
  proj="$(printf '%s' "$web" | sed -n 's/^\([0-9][0-9]*\)-.*/\1/p')"
  echo "Project number    : ${proj:-<unknown>}  (create the Android client HERE)"
else
  echo "  config/supabase.json not found"
  web=""; url=""; key=""; proj=""
fi

# --- Built APK: what the device actually installs ----------------------------
section "Built APK (the signer + client id the device really uses)"
norm_sha1() { printf '%s' "$1" | tr -d ':' | tr '[:lower:]' '[:upper:]'; }

apk="build/app/outputs/flutter-apk/app-debug.apk"
[ -f "$apk" ] || apk="build/app/outputs/apk/debug/app-debug.apk"
if [ -f "$apk" ]; then
  echo "APK            : $apk"

  apksigner="$(command -v apksigner 2>/dev/null || true)"
  if [ -z "$apksigner" ]; then
    for sdk in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" \
               "$HOME/AppData/Local/Android/Sdk" "$HOME/Library/Android/sdk" \
               "$HOME/Android/Sdk"; do
      [ -n "$sdk" ] || continue
      cand="$(find "$sdk/build-tools" -maxdepth 2 -name 'apksigner*' 2>/dev/null | sort -V | tail -1)"
      [ -n "$cand" ] && { apksigner="$cand"; break; }
    done
  fi

  apk_sha1=""
  if [ -n "$apksigner" ]; then
    cert="$("$apksigner" verify --print-certs "$apk" 2>/dev/null)"
    apk_sha1="$(printf '%s\n' "$cert" | tr -d '\r' \
      | sed -n 's/^Signer #1 certificate SHA-1 digest: //p' | head -1)"
    printf '%s\n' "$cert" | grep -iE 'SHA-1 digest|SHA-256 digest' | sed 's/^/  /'
  else
    echo "  (apksigner not found — install Android build-tools to read the APK signer)"
  fi

  # Dump the client ID baked in at compile time (String.fromEnvironment).
  baked="$(python - "$apk" <<'PY' 2>/dev/null
import re, sys, zipfile
try:
    with zipfile.ZipFile(sys.argv[1]) as z:
        data = z.read("assets/flutter_assets/kernel_blob.bin")
except Exception:
    sys.exit(0)
seen = []
for m in re.findall(rb"[0-9]{6,}-[a-z0-9]+\.apps\.googleusercontent\.com", data):
    s = m.decode()
    if s not in seen:
        seen.append(s)
print(", ".join(seen))
PY
)"
  echo "  baked client id : ${baked:-<not found>}"

  if [ -n "${ks_sha1:-}" ] && [ -n "$apk_sha1" ]; then
    if [ "$(norm_sha1 "$ks_sha1")" = "$(norm_sha1 "$apk_sha1")" ]; then
      echo "  signer verdict : APK MATCHES the debug keystore above"
    else
      echo "  signer verdict : APK DIFFERS from the debug keystore above"
      echo "                   (rebuild after changing keys)"
    fi
  fi

  if [ -n "$baked" ] && [ -n "${web:-}" ]; then
    if [ "$baked" = "$web" ]; then
      echo "  client verdict : APK MATCHES config/supabase.json"
    else
      echo "  client verdict : APK DIFFERS from config/supabase.json — rebuild it"
    fi
  fi
else
  echo "  (no debug APK yet — run:)"
  echo "    flutter build apk --debug --dart-define-from-file=config/supabase.json"
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
       Project      : ${proj:-<same project as the web client>}
         ^ the client MUST be created in this project. An Android client in a
           different project fails with [28444] "developer console is not set up
           correctly" even when the package name and SHA-1 are correct.
  2. iOS OAuth client  (iOS builds only)
       Bundle ID    : ${ios_id:-<ios bundle id>}
  3. Web application client (already used by Supabase — leave as-is)
       Authorized redirect URI:
         ${url:-https://<project>.supabase.co}/auth/v1/callback

Renaming the app id (com.example.* -> com.salon.*) leaves the console holding
the OLD package, which is exactly what produces the error right after you pick
an account. Re-registering step 1 fixes it.
EOF
