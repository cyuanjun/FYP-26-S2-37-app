#!/usr/bin/env bash
# Uploads Noah Reyes' sample verification documents into the private
# expert-docs bucket and links them on his pending application, so
# /admin/applications has a *viewable* pending application after a reseed.
# A pure-SQL seed can't ship file bytes, so run this after seed-demo.sql
# (e.g. after `supabase db reset`). Local stack only.
#
#   ./supabase/seed-expert-docs.sh      # run from the app/ directory
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
api="http://127.0.0.1:55321"
sr="$(cd "$here/.." && supabase status 2>/dev/null | grep -iE 'service_role' | grep -oE 'eyJ[A-Za-z0-9._-]+' | head -1)"
psql() { docker exec -i supabase_db_app psql -U postgres -d postgres "$@"; }
noah="$(psql -tAc "select id from profiles where email='noah@wiseworkout.test';" | tr -d '[:space:]')"
if [ -z "$noah" ]; then echo "Noah not seeded — run seed-demo.sql first."; exit 1; fi

upload() { # doc_type  object_key  local_file
  curl -s -X POST "$api/storage/v1/object/expert-docs/$noah/$2" \
    -H "apikey: $sr" -H "Authorization: Bearer $sr" \
    -H "Content-Type: application/pdf" -H "x-upsert: true" \
    --data-binary "@$here/seed-assets/$3" >/dev/null
  psql -c "update expert_verification_documents set storage_path='$noah/$2' where user_id='$noah' and doc_type='$1';" >/dev/null
}
upload identity      identity-nric.pdf       nric-sample.pdf
upload certification certification-uesca.pdf uesca-cert-sample.pdf
echo "Uploaded Noah's sample verification documents."
