-- Bucket privé : chaque utilisateur n'accède qu'à son dossier <user_id>/...
insert into storage.buckets (id, name, public) values ('imports', 'imports', false) on conflict do nothing;
create policy imports_upload on storage.objects for insert to authenticated
  with check (bucket_id = 'imports' and (storage.foldername(name))[1] = auth.uid()::text);
create policy imports_read on storage.objects for select to authenticated
  using (bucket_id = 'imports' and (storage.foldername(name))[1] = auth.uid()::text);
