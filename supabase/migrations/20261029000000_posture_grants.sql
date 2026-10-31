-- The grant posture, said out loud, and put into history. [ADR-0023] invented it:
-- "the browser role is `authenticated` with RLS doing the tenancy, plus three granted
-- RPCs; `anon`'s reach is `preview_invitation` and nothing else."
--
-- It lives in two places, and both are load-bearing:
--   `supabase/schemas/_custom/posture.sql` — the reserved directory pg-delta reads
--     but never generates, because `alter default privileges` is a step it does not
--     model. That is what the declarative files are diffed against.
--   this file — the versioned migration carrying the same statements, which sorts
--     before the generated migration that depends on them. `docs/agents/advisors.md`
--     states the rule: a `_custom/` rule with no migration of its own is wiped by
--     `db reset`, so CI's shadow database and the hosted baseline drift apart.
--
-- Every statement here is `revoke`/`alter default privileges`, which is why it is
-- safe to run at any point: an empty database is unchanged by it, and re-running it
-- after a `db pull` is idempotent. It is the same statement pair Supabase's own
-- baseline sequence runs (revoke everything → `db pull` → sync → grant per object);
-- putting it in history is what keeps the baseline reproducible by `db reset`.
--
-- Supabase's default privileges hand `select` on every new table, `usage` on every
-- new sequence, `execute` on every new function to `anon` and `authenticated`, and
-- Postgres' own default is `execute` to `PUBLIC`, so the app's reads travel by
-- default unless said otherwise. Postgres has no role for "a signed-in Member of
-- this Household" — RLS expresses that, and an RLS policy is not a grant.

revoke all on all tables in schema "public" from "anon";
revoke all on all sequences in schema "public" from "anon";
revoke all on all functions in schema "public" from "anon", public;

alter default privileges in schema "public" revoke select on tables from "anon";
alter default privileges in schema "public" revoke usage on sequences from "anon";
alter default privileges in schema "public" revoke execute on functions from "anon", public;
