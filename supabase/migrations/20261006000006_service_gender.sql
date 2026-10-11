-- =============================================================================
-- Salon App — Service gender facet
--
-- Adds a `gender` audience column to `public.services` so the Explore
-- "Gender" sheet and the Home "Services for Men / Women" tiles can filter on
-- real data instead of being cosmetic.
--
-- Idempotent and safe against both a fresh project and one that already ran
-- every earlier migration:
--   1. creates `service_gender` enum if missing,
--   2. adds the `gender` column (default 'unisex'),
--   3. backfills existing rows from the salon-level tags the seed writes
--      ('gents'/'mens-only' → men, 'beauty'/'women-only' → women),
--   4. applies name-based corrections for rows whose tags are ambiguous.
--
-- Fresh installs: `seed.sql` now sets `gender` explicitly when inserting
-- services, so step 3 is a no-op there and the data is exact from the start.
-- =============================================================================

-- ---- enum: service_gender ------------------------------------------------
do $$
begin
  if not exists (
    select 1
      from pg_type t
      join pg_namespace n on n.oid = t.typnamespace
     where n.nspname = 'public' and t.typname = 'service_gender'
  ) then
    create type public.service_gender as enum ('men', 'women', 'unisex');
  end if;
end $$;

-- ---- column -----------------------------------------------------------------
alter table public.services
  add column if not exists gender public.service_gender not null default 'unisex';

-- ---- backfill from salon tags (live project already has the seed applied) ---
update public.services s
   set gender = case
     when exists (select 1 from unnest(sal.tags) t where t in ('gents','mens-only'))
       then 'men'
     when exists (select 1 from unnest(sal.tags) t where t in ('beauty','women-only'))
       then 'women'
     else 'unisex'
   end
  from public.salons sal
 where sal.id = s.salon_id
   and s.gender = 'unisex';

-- ---- corrections for ambiguously-tagged or untagged rows -------------------
update public.services s
   set gender = 'men'
 where s.gender = 'unisex'
   and lower(s.name) in ('beard trim & shape', 'clean shave');

update public.services s
   set gender = 'women'
 where s.gender = 'unisex'
   and (lower(s.name) like '%bridal%'
        or lower(s.name) like '%makeup%'
        or lower(s.name) like '%manicure%'
        or lower(s.name) like '%pedicure%');

-- ---- index ------------------------------------------------------------------
create index if not exists services_gender_idx
  on public.services (gender) where is_active;

-- ---- verification ------------------------------------------------------------
select s.gender, count(*)
  from public.services s
 group by s.gender
 order by 1;