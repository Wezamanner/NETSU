-- Residents upload report photos only into their own folder.
-- Apply after 20261121120000_profiles_and_areas.sql.

drop policy if exists "report images own upload" on storage.objects;
create policy "report images own upload"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'report-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "report images read" on storage.objects;
create policy "report images read"
on storage.objects for select to authenticated
using (
  bucket_id = 'report-images'
  and (
    (storage.foldername(name))[1] = auth.uid()::text
    or public.auth_role() = 'admin'
  )
);
