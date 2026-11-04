-- Seed data for local development. Runs after migrations on every `supabase db reset`.
-- Declarative schema files only describe DDL, so all DML belongs here (or in a
-- hand-written versioned migration).

-- Stable local-only account so seeded rows have an owner the app can sign in as.
-- Only set the required columns: the rest (instance_id, aud, role, …) default,
-- and instance_id is a uuid in current Auth versions.
insert into auth.users (
  id, email, encrypted_password, email_confirmed_at, created_at, updated_at
)
values (
  '11111111-1111-1111-1111-111111111111',
  'demo@kinetic.test',
  '$2a$10$BxsTkLq9hZ0Y6hs2Aik6E.CnkKRT3n6k1qk6QZGxrXpXqGxkCRGYe',
  now(),
  now(),
  now()
)
on conflict (id) do nothing;

insert into public.todos (title, is_complete, user_id)
values
  ('Install the Supabase CLI', true, '11111111-1111-1111-1111-111111111111'),
  ('Declare the schema in supabase/schemas', true, '11111111-1111-1111-1111-111111111111'),
  ('Run pnpm schema:sync -f <migration-name>', false, '11111111-1111-1111-1111-111111111111'),
  ('pnpm db:reset, then pnpm db:types', false, '11111111-1111-1111-1111-111111111111');
