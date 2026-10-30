-- Declarative schema: pg-delta diffs this file against `supabase/migrations/`
-- and generates the migration SQL. Never edit the database by hand and expect
-- the change to be picked up.

create table "lists" (
  "id" bigint generated always as identity primary key,
  "name" text not null
);

-- `public` is exposed through the Data API, so RLS is required on every table
-- in it. No policy for `anon` means signed-out visitors see zero rows.
alter table "lists" enable row level security;

-- TEMPORARY MULTI-TENANT POLICY: a shared table has no owner column, so every
-- signed-in user can read and modify every list. When lists become
-- per-user, add an owner column and replace `true` with
-- `(select auth.uid()) = user_id`.
create policy "lists_full_access_for_authenticated" on "lists"
  for all
  to authenticated
  using (true)
  with check (true);
