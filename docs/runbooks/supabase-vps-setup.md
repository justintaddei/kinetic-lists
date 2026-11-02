# Hosted Supabase and the VPS: setup runbook

Setup (GLOSSARY) is the one-time, human-only configuration of the hosted Supabase
project, the GitHub OAuth App, and the VPS runtime — no secrets live in git, and
none of it is reproducible from the repo. The wayfinder ticket is
[#10](https://github.com/justintaddei/kinetic-lists/issues/10); its notes are the
decision record, this file is the procedure, and
`scripts/setup-supabase-vps.sh` is the wizard that walks it
(`.agents/skills/supabase-vps-setup`).

## What the wizard is for, and what it refuses

The wizard is operator-facing: it makes a human faster, never supersedes the
operator. It opens the browser at the right page, prints the exact strings to type,
captures the values you copy back, and verifies by read-only probes. It never
provisions: `nginx` + `certbot` are already on the box, Node 20.19.1+ and
pnpm 10.20.0 are already installed, and the wizard only probes those and stops if
a probe fails.

It never runs `supabase db reset`, `supabase db push`, or `supabase config push`.
Hosted migration history is append-only with **nothing queued**: as measured
2026-11-02, hosted and local both report
`20261030005109 · 20261031000000 · 20261101000000 · 20261103000000`
(`pnpm exec supabase migration list`), because the baseline landed in hosted with
#25 and the grant repair landed as `20261103000000` (#23). A `db reset` would drop
production data from a machine that is not the authoritative stack, and
`config push` would overwrite hosted config from `supabase/config.toml`.

## The strings, recorded

| What | Value |
| --- | --- |
| Origin (Site URL) | `https://kinetic-lists.justintaddei.com` — nginx + certbot already front it |
| OAuth callback | `https://ohbrawtgcyngyhaqtddy.supabase.co/auth/v1/callback` |
| Redirect URLs | `https://kinetic-lists.justintaddei.com/confirm` · `http://localhost:3000/confirm` · `http://localhost:3000` |
| OAuth App | **Device Flow off** (the wizard names the box to untick) |
| Where the secret goes | Studio only. GoTrue exchanges the code server-side, so the Client Secret is **never** in `.env`, CI, the VPS, or the repo |

A single `*` in a redirect pattern stops at `/` — it cannot reach `/confirm`, so
each path is its own entry. Wildcards are not the tool here.

`/confirm` reads the session from the URL hash client-side
(`app/pages/confirm.vue`), so the nginx block for it must not cache and must pass
the query string through untouched.

## CI contract this runbook mints (ticket #27 builds the job)

The deploy box is **not a git remote**: git-over-SSH deploy keys are out, so CI
builds the artifact and rsyncs it. The wizard mints the key pair under
`.secrets/deploy_key` (gitignored) and sets, via `gh`:

| Kind | Name | Notes |
| --- | --- | --- |
| secret | `SSH_PRIVATE_KEY` | the deploy private key; the only secret in the deploy path |
| var | `SSH_HOST` | the box's SSH host, usually `kinetic-lists.justintaddei.com` |
| var | `SSH_USER` | unprivileged deploy user; `User=` of the service |
| var | `APP_ROOT` | release root, e.g. `/opt/kinetic-lists` (`releases/`, `shared/`, `current` symlink) |
| var | `RUNTIME_PORT` | port Nitro listens on behind nginx, e.g. `3000` |

Deploy shape: `pnpm build` on `ubuntu-latest` (Node 22) → `actions/upload-artifact`
(**pin `retention-days`** — the default is 7) → rsync with `--delete` into
`$APP_ROOT/releases/<build-id>` → flip the `current` symlink in place (atomic on a
single box; no rolling) → `systemctl restart kinetic-lists` → probe `GET /api/health`.
A failed probe reports loudly on the run, not in a log.

## Runtime on the box

Nitro's `node-server` preset reads **no `.env` at runtime**, and the VPS is not a
NixOS a11y stack — the runtime env is a systemd `EnvironmentFile`:

- service `/etc/systemd/system/kinetic-lists.service`, `User=`/`Group=` the deploy
  user, `WorkingDirectory=$APP_ROOT/current`,
  `ExecStart=/usr/bin/env node .output/server/index.mjs`,
  `EnvironmentFile=/etc/kinetic-lists/env`, `Restart=always`
- env file `/etc/kinetic-lists/env`, mode `0640`, owner `root:<deploy user>` —
  `HOST`, `PORT`, `NUXT_PUBLIC_SUPABASE_URL`,
  `NUXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`, `NUXT_PUBLIC_GITHUB_CLIENT_ID`
- nginx fronts it with the WebSocket upgrade headers Realtime needs
  (`Upgrade`/`Connection`), and `location = /confirm { add_header Cache-Control "no-store"; }`
- set `NUXT_PUBLIC_SUPABASE_URL` on the box (it defaults to `API_URL`, which is
  unset in production); **do not set `SUPABASE_PUBLIC_URL` in production** — the
  cookie-name prefix would change between `/login` and `/confirm`
  (`@supabase/ssr` README). Production runs no middleware at all, per #9.
- Realtime's WS path `wss://ohbrawtgcyngyhaqtddy.supabase.co/realtime/v1/websocket`
  through this nginx is **#9's last unverified fact** — verify it with a real
  subscription, not by the page loading.

## Local sign-in (ADR-0008)

Hosted sign-in is GitHub-only: `GET {project}/auth/v1/settings` with the
publishable key returned `"github": true, "email": false` on 2026-11-02. So the
local stack is the only place email sign-in exists, and the wizard mints the
account:

| Key (in `.env`, gitignored) | Value |
| --- | --- |
| `DEV_LOGIN_EMAIL` | `<sha256(local part) hex>@example.com` — GoTrue derives it from the password's local part (`generateEmailForSSO`) |
| `DEV_LOGIN_PASSWORD` | the password whose **local part** is hashed to that email (`apps/auth/internal/cast/generate_hash.go`) |
| `DEV_LOGIN_SERVICE_ROLE_KEY` | local only, from `pnpm exec supabase status -o env` |

The **dev sign-in card and its server route are app code and belong to
[#27]** — the wizard's Stage 2 records why, and #27's comments carry the two file
shapes. Hosted sign-in stays GitHub-only in production.

## Local grant drift, settled by the wizard's read-only probes

`supabase/db/Dockerfile` starts Postgres from `postgres:17.6` with no
`ALTER DEFAULT PRIVILEGES`, so a fresh `db reset` grants **less** than hosted
(measured 2026-11-02 on a throwaway stack: at `20261101000000` alone,
`private.buy_basket` is `hasm/hasg = false` and `private.item_catalog` has no
`create_view`). They are equivalent **only with `20261103000000` applied**, because
grant posture is carried by the manifest-tracked ADPs
(`supabase/schemas/public/adp_wipes.sql`, `public/default_privileges.sql`) plus
that repair migration — and `[db.migrations] schema_paths = []`, so the ADPs are
**not** replayed per `db reset`. That is why grant drift shows up as a `db diff`
surprise, never as an advisor: the wizard's Stage 5 runs `migration list`,
`db advisors`, `db lint` against `--linked` and requires them clean.

## Recorded run

Paste the wizard's Stage 9 block here after a run and commit it — the box's paths,
the client id, the service and env-file names, and the deploy secrets. Nothing else
in the repo records them, and a restore needs them.

## Unverified on purpose (list lives on #9)

RS256 vs the HS256 the manifest implies · session/token expiry · signing-key
rotation (the OAuth Client Secret, and the box's SSH keypair) · backups
(`supabase db backups list`) · the Realtime WS path through nginx.
