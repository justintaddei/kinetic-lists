---
name: supabase-vps-setup
description: Run the one-time Supabase + VPS setup for Kinetic Lists — GitHub OAuth App, hosted auth config, VPS runtime, deploy secrets. Use when asked to run setup, configure the hosted project, ship a migration to the VPS, mint deploy secrets, "the box is new", sign GitHub sign-in in, "the app 502s", a new OAuth client secret, a new service-role key, "sign-in redirect fails, Studio shows nothing", a Realtime WS test, "the deploy job has no key", a restore, secrets leaking from `.env`, unapproved Studio Advisor changes.
---

Kinetic Lists runs on a VPS with hosted Supabase (ADR-0006), and Setup is human-only:
none of it is reproducible from the repo. Run the wizard, do not freelance the steps.

```bash
scripts/setup-supabase-vps.sh
```

Read `docs/runbooks/supabase-vps-setup.md` before the first stage; the wizard's Stage 1
gates on having read it. The wizard walks: local dev sign-in (ADR-0008) → GitHub OAuth
App → hosted provider + Site URL + Redirect URLs → hosted schema, read-only → deploy
secrets → the box → the first deploy → the record.

Rules the wizard enforces, and the reason each exists:

- **no `supabase db reset`, no `db push`, no `config push`** — hosted history is
  append-only with nothing queued (#25, `20261103000000`), and `config push` would
  overwrite hosted config from `supabase/config.toml`.
- **the OAuth Client Secret and the local `SERVICE_ROLE_KEY` never enter this repo**,
  `.env`, CI, or the VPS. A client secret pasted into a public repo is a
  "sign in as this user" primitive. GoTrue exchanges the code server-side, so the app
  needs neither.
- **the wizard provisions nothing** — nginx, certbot, Node 20.19.1+, pnpm 10.20.0
  already exist; it probes and aborts (`node -v`, `nginx -t`, `certbot certificates`).
- **SSH only, no git-over-SSH** — the VPS is not a git remote; CI rsyncs a built
  `.output` behind the `current` symlink.
- **grant drift is a probe, not an advisor** — `migration list`, `db advisors`,
  `db lint` against `--linked`, all three clean, because a fresh local stack grants
  less than hosted until `20261103000000` (ADPs live above `db reset`).
- **the OAuth App leaves Device Flow off**, and every redirect URL is an exact entry:
  `*` does not cross `/`, so `/confirm` needs its own line.
- the deploy job itself is ticket **#27**'s deliverable; this wizard mints the contract
  (`SSH_PRIVATE_KEY` secret; `SSH_HOST`, `SSH_USER`, `APP_ROOT`, `RUNTIME_PORT` vars)
  and refuses Stage 8 until the workflow exists.

Unverified by design and listed on #9: RS256 vs HS256, session/token expiry, key
rotation, backups, the Realtime WS path through nginx.

- `docs/runbooks/supabase-vps-setup.md` — the strings, the paths, the CI contract
- `docs/agents/advisors.md`, `docs/adr/0006-app-on-vps-database-on-hosted-supabase.md`,
  `docs/adr/0008-e2e-tests-sign-in-with-local-email.md`
- `supabase/config.toml` — `[db.migrations] schema_paths = []` (never add a path)
