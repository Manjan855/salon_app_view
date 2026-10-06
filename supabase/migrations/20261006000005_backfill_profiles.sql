-- =============================================================================
-- Salon App — Backfill profiles for pre-existing auth users
-- Run this LAST, after the schema and function migrations.
--
-- The old schema had no trigger on auth.users, so anyone who signed up before
-- the rebuild has an auth.users row but no profiles row — which means
-- AuthProvider.updateProfile() would try to INSERT and could mis-route the
-- "profile incomplete" flow. This creates the missing rows once.
-- =============================================================================
insert into public.profiles (id, name, email, persona)
select
  u.id,
  coalesce(
    nullif(trim(coalesce(u.raw_user_meta_data ->> 'name',
                         u.raw_user_meta_data ->> 'full_name')), ''),
    split_part(coalesce(u.email, 'user'), '@', 1)
  ),
  u.email,
  'customer'
from auth.users u
where not exists (select 1 from public.profiles p where p.id = u.id)
on conflict (id) do nothing;

-- Report what we found
select
  (select count(*) from auth.users)               as auth_users,
  (select count(*) from public.profiles)          as profiles_after_backfill;
