-- supabase/seed.sql -- data a local stack gets after `db reset`.
--
-- v1 seeds nothing: ADR-0019 makes sign-up seed its own Household by trigger, so a
-- fixture Household would be a second rule for the same fact, and the demo seeds lived
-- in the prototype that #4's baseline retires. The file exists because config.toml's
-- `[db.seed].sql_paths` names it: `db reset` (the CI harness of #4) fails on a missing
-- seed path. A ticket that needs local fixtures adds them here - and per
-- docs/agents/advisors.md, nothing hosted depends on it.

select 1;
