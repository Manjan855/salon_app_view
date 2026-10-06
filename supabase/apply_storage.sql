-- ==========================================================================
-- Salon App - STORAGE BUCKETS (paste #2 of 2)
-- ==========================================================================
-- Run this SECOND, as its own query.
-- Kept separate on purpose: creating policies on storage.objects needs
-- elevated privileges in some projects, and a failure here must NOT
-- roll back the core schema from paste #1.


-- ==========================================================================
-- FILE: supabase/migrations/20261006000004_storage.sql
-- ==========================================================================

-- =============================================================================
-- Salon App — Storage buckets & object policies
--
-- buckets:
--   avatars  -> customer / staff profile pictures (own-folder write)
--   salons   -> salon cover + gallery images (public catalogue)
--   services -> service thumbnails (public catalogue)
-- =============================================================================
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars',  'avatars',  true, 5242880, array['image/jpeg','image/png','image/webp']),
  ('salons',   'salons',   true, 5242880, array['image/jpeg','image/png','image/webp']),
  ('services', 'services', true, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

-- Public read of catalogue images (and avatars shown in reviews)
drop policy if exists "catalogue_public_read" on storage.objects;
create policy "catalogue_public_read"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id in ('avatars','salons','services'));

-- A signed-in user may upload only into their own folder: avatars/<uid>/...
drop policy if exists "avatars_own_folder_write" on storage.objects;
create policy "avatars_own_folder_write"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = 'avatars'
    and (storage.foldername(name))[2] = (select auth.uid())::text
  );

drop policy if exists "avatars_own_folder_update" on storage.objects;
create policy "avatars_own_folder_update"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = 'avatars'
    and (storage.foldername(name))[2] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = 'avatars'
    and (storage.foldername(name))[2] = (select auth.uid())::text
  );

drop policy if exists "avatars_own_folder_delete" on storage.objects;
create policy "avatars_own_folder_delete"
  on storage.objects for delete
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = 'avatars'
    and (storage.foldername(name))[2] = (select auth.uid())::text
  );

-- salons/ + services/ are written by the service role only (manual seeding for
-- this release, admin panel in a later phase). No client policy on purpose.
