#!/usr/bin/env bash
# =============================================================================
# regen_debug_keystore.sh — mint a fresh Android debug SHA-1 for Google Sign-In
# =============================================================================
#
# Use this when Google Cloud refuses to register this build's Android client:
#
#   "The fingerprint you specified is already used by an Android OAuth2 client
#    ID in this project or another project."
#
# A (package name, SHA-1) pair may be registered only ONCE across all Firebase
# and Google Cloud projects, so a debug SHA-1 that was ever registered in an old
# project is locked forever. Regenerating `~/.android/debug.keystore` produces a
# brand-new, unused SHA-1 that the uniqueness rule cannot block. Then add that
# SHA-1 to a new Android OAuth client for `com.salon.salon_app_view` in the same
# project as the web client (see docs/google_signin.md §Troubleshooting).
#
# NOTE: the debug keystore is shared by EVERY Android project on this machine,
# so regenerating it changes the debug signature for all of them. Any other app
# that registered the old debug SHA-1 in Google will need the new one too.
#
# Usage:
#   bash tool/regen_debug_keystore.sh          # show the plan + current SHA-1
#   bash tool/regen_debug_keystore.sh --yes    # back up + regenerate, print SHA-1
# =============================================================================
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

KS="${ANDROID_DEBUG_KEYSTORE:-$HOME/.android/debug.keystore}"
ALIAS="androiddebugkey"
STOREPASS="android"
KEYPASS="android"

section() { printf '\n== %s ==\n' "$1"; }

fingerprint() {
  # $1 = keystore path
  keytool -list -v -keystore "$1" -alias "$ALIAS" \
    -storepass "$STOREPASS" -keypass "$KEYPASS" 2>/dev/null \
    | grep -iE 'SHA1:|SHA256:' | sed 's/^[[:space:]]*/  /'
}

section "App identifier"
android_id="$(grep -E 'applicationId[[:space:]]*=' android/app/build.gradle.kts 2>/dev/null | head -1 | sed 's/.*"\(.*\)".*/\1/')"
echo "  Android package : ${android_id:-<not found>}"
echo "  Debug keystore  : $KS"

section "Current debug fingerprint"
if [ -f "$KS" ]; then
  fingerprint "$KS"
else
  echo "  (no keystore at that path yet — regenerating will create one)"
fi

if [ "${1:-}" != "--yes" ]; then
  cat <<EOF

== Nothing changed (dry run) ==
Re-run with --yes to back up the current keystore and generate a fresh one:

  bash tool/regen_debug_keystore.sh --yes

Then register the printed SHA-1 in Google Cloud Console → Credentials → create
an Android OAuth client with package "${android_id:-com.salon.salon_app_view}" in
the SAME project as the web client.
EOF
  exit 0
fi

section "Regenerating"

if ! command -v keytool >/dev/null 2>&1; then
  echo "  keytool not found on PATH — install a JDK / use Android Studio's JBR." >&2
  exit 1
fi

mkdir -p "$(dirname "$KS")"

if [ -f "$KS" ]; then
  bak="${KS}.bak.$(date +%Y%m%d%H%M%S)"
  cp "$KS" "$bak"
  echo "  Backed up old keystore -> $bak"
  rm -f "$KS"
fi

keytool -genkeypair -v \
  -keystore "$KS" \
  -alias "$ALIAS" \
  -storepass "$STOREPASS" -keypass "$KEYPASS" \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=Android Debug,O=Android,C=US" >/dev/null

echo "  New keystore created."

section "New debug fingerprint (register this in Google Cloud Console)"
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
EOF
