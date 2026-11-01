-- The grant posture, kept where the CLI keeps what pg-delta cannot diff.
--
-- `alter default privileges` is not an object, so declarative schemas have no
-- way to state it (the Advisors doc names this class of object and points here:
-- the reserved `supabase/schemas/_custom/`). `db schema declarative sync` loads
-- this directory so dependent objects resolve, and never diffs it.
--
-- Because the diff runs FROM the state this file produces, the same statements
-- ship as a hand-written versioned migration that sorts BEFORE the generated
-- migration they shape: [`20261029000000_posture_grants.sql`](../../migrations/20261029000000_posture_grants.sql).
-- Both files are kept in step by hand; if one changes, the other changes in the
-- same PR. [`docs/agents/advisors.md`](../../../docs/agents/advisors.md) is the
-- contract this posture exists to keep.
--
-- Supabase's default privileges hand `select` on every new `public` table, and
-- `execute` on every new `public` function, to `anon` and `authenticated`. Row
-- level security makes `anon` read zero rows, and lint `0026`/`0027`/`0028`
-- measure the shape of the surface, not the rows. The v1 read surface for `anon`
-- is exactly two roster views and `public.preview_invitation`.
revoke all on all tables in schema "public" from "anon";
revoke all on all sequences in schema "public" from "anon";
revoke all on all functions in schema "public" from "anon", public;

alter default privileges in schema "public"
  revoke select on tables from "anon";
alter default privileges in schema "public"
  revoke usage on sequences from "anon";
alter default privileges in schema "public"
  revoke execute on functions from "anon", public;
