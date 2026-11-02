# Setup is a wizard that mints configuration and provisions nothing; a deploy ships a CI-built artifact behind a symlink, and its runtime config is a systemd EnvironmentFile

> **Records the answer to [#10](https://github.com/justintaddei/kinetic-lists/issues/10)** — the map's
> last human-only frontier ticket, answered by Justin HITL 2026-11-02 and built in
> [PR #33](https://github.com/justintaddei/kinetic-lists/pull/33). **Amends
> [ADR-0006](0006-app-on-vps-database-on-hosted-supabase.md)**, which fixed *where* the app runs but
> not *how it gets there* (its deploy sketch was a git checkout + build on the box) and left the
> runtime's environment unnamed. Depends on
> [ADR-0008](0008-e2e-tests-sign-in-with-local-email.md) (local email sign-in, which is why a hosted
> project with `"email": false` needs no hosted account), [ADR-0023](0023-the-v1-schema-is-ten-household-owned-tables-under-pair-keys-with-three-granted-definer-rpcs-as-its-whole-privileged-surface.md)
> and its grant-posture amendments.

**Setup is human-only, and the wizard is its operator-facing artifact** (GLOSSARY: *Setup*,
*Setup wizard*). Nothing in the repo reproduces the hosted project's config, the OAuth App, or the
box's state; a person with a browser performs them. `scripts/setup-supabase-vps.sh` opens the right
page, prints the exact strings to type, captures the values copied back, and verifies with **reads**
(`GET /auth/v1/settings`, `supabase migration list --linked`, `db advisors`, `db lint`). It is
bash, not a prompt file, because it opens URLs across platforms, hides secret entry, upserts `.env`
idempotently, and gates on `confirm`.

**The wizard mints; it never provisions.** nginx and certbot front
`https://kinetic-lists.justintaddei.com` already, and Node ≥ 20.19.1 and pnpm 10.20.0 are installed
on the box: the wizard probes (`node -v`, `nginx -t`, `certbot certificates`) and **aborts** rather
than installing, because the box is production and a provisioned dependency is a change nobody
reviewed. The commands that do touch the box (the deploy user, the `authorized_keys` entry, the
unit, the env file, the nginx block) are **printed with the captured values filled in**, run by a
person as root.

**Setup refuses three commands**: `supabase db reset` (a local rebuild has no authority over
production data), `supabase db push` (hosted history is append-only, and measured 2026-11-02
nothing is queued — `20261030005109 … 20261103000000` applied on both sides), and `supabase config
push` (it would write hosted config from `supabase/config.toml`, whose local values are dev values).
Site URL, the Redirect URLs and the provider credentials are set in Studio, by hand.

**The OAuth Client secret lives in Supabase Studio and nowhere else.** GoTrue exchanges the code
**server-side on the hosted project**, so the app never holds the pair: the Client ID is public and
rides `.env`/the env file as `NUXT_PUBLIC_GITHUB_CLIENT_ID`; the secret is typed into the dashboard,
enters no `.env`, no CI secret, no artifact. An OAuth client secret in a public repo is a "sign in as
this user" primitive. Redirect URLs are **exact entries** — `https://kinetic-lists.justintaddei.com/confirm`,
`http://localhost:3000/confirm`, `http://localhost:3000` — because a single `*` stops at `/` and
cannot reach `/confirm`; the App leaves **Device Flow off**.

**A deploy ships an artifact; the box is never a build host.** CI runs `pnpm build`, uploads the
Nitro `node-server` `.output` (`actions/upload-artifact` with **`retention-days` pinned** — 7 days by
default is a fact, not a plan), and rsyncs it into a **dated release directory** on the box with
`--delete`, then flips the **`current` symlink** and `systemctl restart kinetic-lists`, with a
**pre-rsync backup**. Git-over-SSH with a deploy key is **out**: the VPS is a runtime, not a git
remote, and a `git reset` on production makes the box's state untraceable to a commit that was
reviewed. A symlink flip is atomic on a single box (no rolling, no second host to sequence), and a
failed health probe fails the run loudly.

**The runtime environment is a systemd `EnvironmentFile`.** Nitro's `node-server` preset **reads no
`.env` at runtime**, so `/etc/kinetic-lists/env` (mode `0640`, `root:<deploy user>`) carries `HOST`,
`PORT`, `NUXT_PUBLIC_SUPABASE_URL`, `NUXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` and
`NUXT_PUBLIC_GITHUB_CLIENT_ID`, and the unit names `User=`/`Group=` and `EnvironmentFile=`. The
`User=`+chowned-file alternative was offered and **declined**: the env file is the one place the
runtime's config is written down. `SUPABASE_PUBLIC_URL` stays unset in production — the cookie-name
prefix must not differ between `/login` and `/confirm` — and production runs no middleware (ADR-0008,
#9).

**Grant posture is verified by probes, not by a local rebuild.** A fresh local stack starts from
`postgres:17.6` with no `alter default privileges`, and `[db.migrations] schema_paths = []` means the
manifest-tracked ADPs (`public/adp_wipes.sql`, `public/default_privileges.sql`) are **not replayed per
`db reset`**: at `20261101000000` alone `private.buy_basket` was not executable and
`private.item_catalog` had no view grant; with `20261103000000` applied, local and hosted grant
matrices align exactly (measured 2026-11-02 on a throwaway stack). So grant drift surfaces as a
`db diff` surprise, never as an advisor, and the wizard's hosted stage is three reads gated on
"clean".

**The wizard writes no app code.** Its own scope is configuration: an app page is a change a PR
reviews. ADR-0008's **dev sign-in affordance** (a dev-gated email/password card plus a loopback-pinned
`/api/dev-login` route) is therefore **#27**'s, with the measured fixture derivation handed over — the
wizard mints the account (`sha256(password local part)@example.com`, GoTrue's `generateEmailForSSO`)
and the `.env` trio only.

**The contract the wizard mints for the deploy job** (which **#27** builds): secrets
`SSH_PRIVATE_KEY`, `SSH_KNOWN_HOSTS`; vars `SSH_HOST`, `SSH_USER`, `APP_ROOT`, `RUNTIME_PORT`. The
private key is generated under gitignored `.secrets/`, the known-hosts block is scanned on the box and
pasted back, because a runner cannot answer a fingerprint prompt.

**Consequences.**
- `docs/runbooks/supabase-vps-setup.md` is the record of the strings, paths and names; its
  **Recorded run** section is filled by a human on the box, and **#10 closes on that run** — a
  human-only ticket does not close on a merge, and this ADR records the contract, not its execution.
- `.agents/skills/supabase-vps-setup` is the trigger surface (a new box, a rotated secret, a sign-in
  redirect that Studio knows nothing about, a deploy job with no key, a restore).
- `*.sh` is pinned to LF in `.gitattributes`: a checked-out wizard must run in bash on Windows.
- Still unverified and listed on #9: RS256 vs the HS256 the manifest implies, session/token expiry,
  signing-key rotation, backups, and Realtime's WebSocket path through this nginx.
