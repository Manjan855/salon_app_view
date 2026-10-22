#!/usr/bin/env bash
# =============================================================================
# new_project_debug_keystore.sh — mint an app-scoped debug SHA-1 (opt-in)
# =============================================================================
#
# Use this when Google Cloud refuses to register this app's Android client with
# "the fingerprint you specified is already used ... in this project or another
# project", or when [28444] "developer console is not set up correctly" refuses
# to go away even though package + SHA-1 look correct in the console.
#
# A (package name, SHA-1) pair may be registered only ONCE across all Firebase
# and Google Cloud projects. This script writes a fresh RSA key to
#
#     android/app/debug.keystore
#
# which `android/app/build.gradle.kts` automatically picks up for debug builds
# (and the debug-signed release build). Because the keystore lives inside this
# project, your machine-wide ~/.android/debug.keystore — and therefore every
# other Android app on this machine — is left untouched.
#
# The generated file matches the *.keystore rule in .gitignore, so it is never
# committed. Keep it: it is now this app's debug identity.
#
# Usage:
#   bash tool/new_project_debug_keystore.sh          # dry run, show the plan
#   bash tool/new_project_debug_keystore.sh --yes    # create the keystore
# =============================================================================
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

KS="android/app/debug.keystore"
ALIAS="androiddebugkey"
STOREPASS="android"
KEYPASS="android"

section() { printf '\n== %s ==\n' "$1"; }

fingerprint() {
  keytool -list -v -keystore "$1" -alias "$ALIAS" \
    -storepass "$STOREPASS" -keypass "$KEYPASS" 2>/dev/null \
    | grep -iE 'SHA1:|SHA256:' | sed 's/^[[:space:]]*/  /'
}

android_id="$(grep -E 'applicationId[[:space:]]*=' android/app/build.gradle.kts 2>/dev/null | head -1 | sed 's/.*"\(.*\)".*/\1/')"

section "App identifier"
echo "  Android package : ${android_id:-<not found>}"
echo "  Keystore path   : $KS  (project-scoped, gitignored)"

section "Current project keystore"
if [ -f "$KS" ]; then
  fingerprint "$KS"
else
  echo "  (none yet — a project-local key is not in use)"
fi

if [ "${1:-}" != "--yes" ]; then
  cat <<EOF

== Nothing changed (dry run) ==
Re-run with --yes to create "$KS":

  bash tool/new_project_debug_keystore.sh --yes

Then register the printed SHA-1 as a NEW Android OAuth client for
"${android_id:-com.salon.salon_app_view}" in the SAME Google Cloud project as
the web client, and rebuild:

  flutter clean
  flutter run --dart-define-from-file=config/supabase.json
EOF
  exit 0
fi

if ! command -v keytool >/dev/null 2>&1; then
  echo "keytool not found on PATH — install a JDK or use Android Studio's JBR." >&2
  exit 1
fi

section "Creating project-scoped debug keystore"

if [ -f "$KS" ]; then
  bak="${KS}.bak.$(date +%Y%m%d%H%M%S)"
  cp "$KS" "$bak"
  echo "  Backed up existing key -> $bak"
  rm -f "$KS"
fi

keytool -genkeypair -v \
  -keystore "$KS" \
  -alias "$ALIAS" \
  -storepass "$STOREPASS" -keypass "$KEYPASS" \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=Android Debug,O=Android,C=US" >/dev/null

echo "  New keystore created."

section "New SHA-1 (register this in Google Cloud Console)"
fingerprint "$KS"

cat <<EOF

== Next steps ==
1. Google Cloud Console -> Credentials -> Create credentials -> OAuth client ID
     Type         : Android
     Package name : ${android_id:-com.salon.salon_app_view}
     SHA-1        : (the SHA1 above)
     Project      : the SAME project as the web client
2. flutter clean
3. flutter run --dart-define-from-file=config/supabase.json

This pair has never been registered anywhere, so the global uniqueness rule
cannot block it. Only this app's debug signature changed — ~/.android/debug.keystore
is untouched.
EOF
