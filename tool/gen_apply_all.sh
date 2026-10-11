#!/usr/bin/env bash
# Regenerates supabase/apply_all.sql from the migrations + seed, preserving the
# exact banner format of the existing file (verified by diff below).
set -euo pipefail
cd "$(dirname "$0")/../supabase"

BANNER="-- =========================================================================="

out="apply_all.sql"
cat > "$out" <<'EOF'
-- ==========================================================================
-- Salon App - CORE BUILD SCRIPT (paste #1 of 2)
-- ==========================================================================
-- Paste this ENTIRE file into the Supabase SQL Editor and click RUN.
-- Runs as ONE transaction: it either fully succeeds or fully rolls back.
-- 
-- Files, in dependency order:
--   supabase/migrations/20261005235959_archive_legacy_schema.sql
--   supabase/migrations/20261006000001_schema.sql
--   supabase/migrations/20261006000002_functions.sql
--   supabase/migrations/20261006000003_rls.sql
--   supabase/migrations/20261006000005_backfill_profiles.sql
--   supabase/migrations/20261006000006_service_gender.sql
--   supabase/seed.sql
EOF

files=(
  migrations/20261005235959_archive_legacy_schema.sql
  migrations/20261006000001_schema.sql
  migrations/20261006000002_functions.sql
  migrations/20261006000003_rls.sql
  migrations/20261006000005_backfill_profiles.sql
  migrations/20261006000006_service_gender.sql
  seed.sql
)

for f in "${files[@]}"; do
  {
    printf '\n\n%s\n' "$BANNER"
    printf -- "-- FILE: supabase/%s\n" "$f"
    printf '%s\n' "$BANNER"
    printf '\n'
    cat "$f"
  } >> "$out"
done

# trailing blank line so the file ends with a newline after content
printf '\n' >> "$out"

echo "regenerated $out ($(grep -c '' "$out") lines)"