-- =============================================================================
-- Salon App — Archive legacy hand-made schema
-- Run this FIRST, before 20261006000001_schema.sql
--
-- Why this and not DROP:
--   The live project already contains 8 hand-made tables. They return 0 rows to
--   the anon key, but that could be row-level security hiding rows rather than
--   the tables genuinely being empty — so we cannot prove from outside that
--   there is no data worth keeping.
--
--   Moving them to the `archive` schema takes them out of the API entirely
--   (PostgREST only exposes `public`) while keeping them recoverable.
--
--   Once you have confirmed nothing is needed:
--       drop schema archive cascade;
--
-- Idempotent: skips any table that no longer exists.
-- =============================================================================
create schema if not exists archive;

do $$
declare t text;
begin
  foreach t in array array[
    'staff_services', 'staff_profiles', 'appointments', 'payments',
    'bookings', 'services', 'salons', 'profiles'
  ] loop
    if to_regclass('public.' || t) is not null then
      execute format('alter table public.%I set schema archive', t);
      raise notice 'archived public.%', t;
    else
      raise notice 'skipped public.% (does not exist)', t;
    end if;
  end loop;
end;
$$;

comment on schema archive is
  'Pre-existing hand-made salon schema, archived 2026-10-06. Drop once the rebuilt schema is confirmed.';
