-- Expert verification documents move from name-only metadata to real files an
-- admin can open. A PRIVATE bucket (unlike avatars) holds identity + cert
-- uploads; only the owner and admins can read them. The web expert-application
-- flow uploads to expert-docs/{user_id}/… once the new account has a session,
-- then records the object path on the doc row.

alter table expert_verification_documents
  add column if not exists storage_path text;   -- null = legacy name-only row

insert into storage.buckets (id, name, public)
values ('expert-docs', 'expert-docs', false)     -- PRIVATE — ID documents
on conflict (id) do nothing;

-- Owner may upload only inside their own folder (expert-docs/{uid}/…).
drop policy if exists expert_docs_owner_write on storage.objects;
create policy expert_docs_owner_write on storage.objects
  for insert to authenticated
  with check (bucket_id = 'expert-docs'
              and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists expert_docs_owner_update on storage.objects;
create policy expert_docs_owner_update on storage.objects
  for update to authenticated
  using (bucket_id = 'expert-docs'
         and (storage.foldername(name))[1] = auth.uid()::text);

-- Read: the owner (their own folder) OR any admin. No anon, no other users —
-- these are identity documents. Signed URLs the admin mints inherit this.
drop policy if exists expert_docs_read on storage.objects;
create policy expert_docs_read on storage.objects
  for select to authenticated
  using (bucket_id = 'expert-docs'
         and ((storage.foldername(name))[1] = auth.uid()::text or is_admin()));
