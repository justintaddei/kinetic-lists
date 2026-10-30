# Deploy facts: OAuth config, redirect URLs, VPS topology, geocoder

Ticket question, verbatim:

> **Deploy facts: OAuth config, redirect URLs, VPS topology, geocoder**

Research for the wayfinder map. Everything below is from primary documentation (GitHub,
Supabase, Nuxt/Nitro, Geoapify) plus this repo's own files, which are cited by path. Nothing
here was verified by running a deploy; the items I could not pin to a docs page are listed in
[Unverified](#unverified).

Topology assumed throughout (ADR-0006, `docs/adr/0006-app-on-vps-database-on-hosted-supabase.md`):
the Nuxt app runs on Justin's VPS; database, auth and Realtime stay on the hosted Supabase
project `ohbrawtgcyngyhaqtddy`.

## 1. GitHub OAuth App for the hosted Supabase project

- **Ownership: the app may live under a personal account.** "You can create and register an OAuth
  app under your personal account or under any organization you have administrative access to",
  and "A user or organization can own up to 100 OAuth apps." Registration is at
  `https://github.com/settings/applications/new`.
  → https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/creating-an-oauth-app
- **Everything in the app's registration is public.** "Only use information in your OAuth app that
  you consider public. Avoid using sensitive data, such as internal URLs, when creating an OAuth
  app." So the production hostname is visible to anyone browsing GitHub.
  → https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/creating-an-oauth-app
- **The callback URL is Supabase's, not the app's.** Supabase: the callback "looks like this:
  `https://<project-ref>.supabase.co/auth/v1/callback`", and the exact string is on Dashboard →
  Authentication → Sign In / Providers → GitHub → Callback URL (Copy). GitHub allows up to 10
  callback URLs per OAuth app, so the app registered for
  `https://ohbrawtgcyngyhaqtddy.supabase.co/auth/v1/callback` is reusable across environments.
  → https://supabase.com/docs/guides/auth/social-login/auth-github
  → https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/creating-an-oauth-app
- **Local CLI development uses a different callback**: `http://localhost:54321/auth/v1/callback`
  (the local API port). To exercise GitHub OAuth against local Supabase, that URL has to be
  registered as an additional callback.
  → https://supabase.com/docs/guides/auth/social-login/auth-github
- **Leave "Enable Device Flow" unchecked**; Supabase's own registration walk-through says so.
  → https://supabase.com/docs/guides/auth/social-login/auth-github
- **Disable wildcard matching on the callback.** GitHub: "When wildcard matching is disabled, the
  redirect URL must exactly match the callback URL", and "Apps that had a single callback URL
  enabled prior to August 3, 2026 have wildcard matching enabled for that callback URL … If your
  app does not need wildcard matching, we recommend that you disable it." Wildcards let an attacker
  push codes "to any subdomain or subdirectory of the callback URL". The Supabase callback has no
  subpaths to allow.
  → https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps
  → https://docs.github.com/en/apps/oauth-apps/maintaining-oauth-apps/modifying-an-oauth-app
- **If `redirect_uri` is omitted, GitHub uses the first configured callback URL.** Supabase sends
  its own; the ordering of callback entries matters only if that ever changes.
  → https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps
- **The client secret is only used server-side, by GoTrue.** The token exchange
  `POST https://github.com/login/oauth/access_token` requires `client_id` + `client_secret` +
  `code` (+ `code_verifier` for PKCE), and the browser is never sent to that endpoint — the app
  sends the user to `https://github.com/login/oauth/authorize` (with `code_challenge` +
  `code_challenge_method=S256`) and the code comes back to Supabase.
  → https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps
- **Where the pair lives**: Client ID + Client Secret pasted into Supabase → Authentication →
  Sign In / Providers → GitHub (Enabled on). Same thing via Management API:
  `PATCH https://api.supabase.com/v1/projects/$PROJECT_REF/config/auth` with
  `external_github_enabled`, `external_github_client_id`, `external_github_secret`. It is a hosted
  project secret: it never enters the VPS, `.env`, or the client bundle.
  → https://supabase.com/docs/guides/auth/social-login/auth-github
- **Local stack has no GitHub provider at all**, by design: `supabase/config.toml` contains only a
  `[auth.external.apple]` block (`enabled = false`), and Playwright/E2E sign in through email
  (ADR-0008, `docs/adr/0008-e2e-tests-sign-in-with-local-email.md`). GitHub OAuth is exercised
  manually against the hosted project. Repo evidence: `supabase/config.toml`.
- **Signing in from code**: `signInWithOAuth(credentials)` "Log in an existing user via a
  third-party provider. This method supports the PKCE flow… It works by redirecting your
  application to the provider's authorization screen, before bringing back the user to your app."
  Server-side it returns `data.url`; the callback page calls `exchangeCodeForSession(code)`.
  → https://supabase.com/docs/reference/javascript/auth-signinwithoauth
  → https://supabase.com/docs/guides/auth/social-login/auth-github
- **The PKCE verifier is a cookie, and that is the classic failure mode.** Caution from Supabase's
  server-side example: "Use a server client from `@supabase/ssr`, and send its cookies with the
  redirect. `signInWithOAuth` stores the PKCE code verifier in a cookie. When that `Set-Cookie`
  header doesn't reach the browser, the callback can't exchange the code for a session." This repo
  sidesteps it: `@nuxtjs/supabase` forces `ssr: false` on the callback route so the exchange
  happens in the browser. Repo evidence: `nuxt.config.ts` (`redirectOptions.callback`), `README.md`
  ("the OAuth callback lands on `/confirm`, where the PKCE `code` is exchanged for a session in
  the browser").
  → https://supabase.com/docs/guides/auth/social-login/auth-github

## 2. Redirect URLs and Site URL on the hosted project

- **Site URL is the default landing point, not just a cosmetic field.** It is "the default redirect
  URL when no `redirectTo` is provided" and is "critical for email confirmations and password
  resets"; the docs explicitly say to change it from `http://localhost:3000` to the production URL.
  → https://supabase.com/docs/guides/auth/redirect-urls
- **There is exactly one Site URL per project**, and "Additional Redirect URLs" is the allow list for
  every other destination. Our OAuth callback target is `/confirm`, set by the module
  (`redirectOptions.callback: "/confirm"`), so each environment's `/confirm` must be on the list.
  Repo evidence: `nuxt.config.ts`.
  → https://supabase.com/docs/guides/auth/redirect-urls
- **A single `*` does not reach `/confirm`.** Wildcard semantics: `*` matches "any sequence of
  characters, excluding separators"; separators are `.` and `/`; `**` matches any character
  including separators. `http://localhost:3000/*` matches `/foo` and `/bar` but not `/foo/bar` and
  not `/foo/`; `**` matches `/foo/bar`.
  → https://supabase.com/docs/guides/auth/redirect-urls
- **Docs recommendation for production is the exact path**: "While the 'globstar' (`**`) is useful
  for local development and preview URLs, we recommend setting the exact redirect URL path for
  your site URL in production." A signed-in GitHub user should see zero redirect surprises.
  → https://supabase.com/docs/guides/auth/redirect-urls
- **Redirects are validated against the allow list** — "`redirectTo` must match one of the redirect
  URLs configured for your project" — and auth failures come back with details in the URL hash
  (`error_code`, `error_description`), which is the debugging surface on `/confirm`.
  → https://supabase.com/docs/guides/auth/redirect-urls
- **Dev and prod share one project, so dev and prod URLs coexist in one allow list.** The Site URL
  field holds only one value, and the repo's dev origin is `http://localhost:3000`
  (`README.md`), with `site_url = "http://127.0.0.1:3000"` for the local stack
  (`supabase/config.toml`). Every origin that signs in needs its entry.
  → https://supabase.com/docs/guides/auth/redirect-urls
- **`saveRedirectToCookie: true` (already on) is the "where do I go after login" mechanism**: the
  module "will automatically save the current path to a cookie when the user is redirected to the
  login page", and `/confirm` reads it with `useSupabaseCookieRedirect().pluck()`. The cookie name
  is the `cookiePrefix` (default `sb`) plus `-redirect-path`.
  → https://supabase.nuxtjs.org/getting-started/authentication
  → https://supabase.nuxtjs.org/getting-started/introduction
- **Local `config.toml` values are pushable to the hosted project, which is a footgun.**
  `supabase config push` "Updates the configurations of a linked Supabase project with the local
  `supabase/config.toml` file" — the same file that currently carries
  `site_url = "http://127.0.0.1:3000"` and
  `additional_redirect_urls = ["https://127.0.0.1:3000"]`.
  → https://supabase.com/docs/reference/cli/supabase-config-push
  → `supabase/config.toml`
- **Behind a reverse proxy, the callback origin must be rebuilt from forwarded headers.**
  Supabase's server-side callback example reconstructs the redirect URL from `x-forwarded-host`
  ("to support Next.js Middleware … the request URL is not the original one") — i.e. the proxy has
  to hand the VPS the public host, or the app computes the wrong `redirectTo`.
  → https://supabase.com/docs/guides/auth/social-login/auth-github

## 3. Nuxt on a self-managed VPS

- **Production artifact is a standalone Node server, and Node is the default preset.** "Node.js is
  the default Nitro output preset for production builds"; build with `nitro build` (i.e.
  `pnpm run build`), then "deploy the fully standalone `.output` directory", run it with
  `node .output/server/index.mjs`, which prints `Listening on http://localhost:3000`.
  → https://nitro.build/deploy/runtimes/node
- **The repo has no start script** — `package.json` scripts are `dev`, `build`, `generate`,
  `preview`, `db:types`, `postinstall`. Production start is `node .output/server/index.mjs` on the
  box. Repo evidence: `package.json`.
- **Port/host come from env vars**: `NITRO_PORT` or `PORT` (default `3000`), `NITRO_HOST` or `HOST`;
  `NITRO_UNIX_SOCKET` replaces them (path or Windows named pipe). Cluster mode is a separate preset
  (`node_cluster`, `NITRO_CLUSTER_WORKERS`), not the default.
  → https://nitro.build/deploy/runtimes/node
- **TLS belongs to the proxy, not to Nitro.** `NITRO_SSL_CERT`/`NITRO_SSL_KEY` exist, but: "This is
  intended for testing only; in production, run the Nitro server behind a reverse proxy that
  terminates SSL, such as nginx or Cloudflare."
  → https://nitro.build/deploy/runtimes/node
- **Restarts are graceful by default**, which is what a process manager wants: signals
  `SIGINT SIGTERM` (`NITRO_SHUTDOWN_SIGNALS`), 30 s timeout (`NITRO_SHUTDOWN_TIMEOUT`),
  `NITRO_SHUTDOWN_FORCE`, `NITRO_SHUTDOWN_DISABLED`.
  → https://nitro.build/deploy/runtimes/node
- **`.env` is not read by the built server.** "The Nuxt CLI has built-in support for reading your
  `.env` file in development, build and generate. But when you run your built server, your `.env`
  file will not be read." Variables must exist in the process environment of the running service
  (systemd `EnvironmentFile=`/`Environment=`, shell export, etc.).
  → https://nuxt.com/docs/4.x/guide/going-further/runtime-config
- **Only `NUXT_`-shaped names override config, and only keys declared in `nuxt.config` are
  overridable**: "Custom runtime config variables must be defined in your `nuxt.config`… Only a
  specially-named environment variable can override a runtime config property. That is, an
  uppercase environment variable starting with `NUXT_` which uses `_` to separate keys and case
  changes." So `NUXT_PUBLIC_SUPABASE_URL` / `NUXT_PUBLIC_SUPABASE_KEY` (the names in
  `.env.example`, consumed by `@nuxtjs/supabase`) work at runtime; a name like
  `SUPABASE_URL` would not.
  → https://nuxt.com/docs/4.x/guide/going-further/runtime-config
  → `.env.example`
- **Values are type-coerced.** "Environment variable values are automatically cast to their
  JavaScript type using `destr`… `NUXT_MY_VAR=4848e0` becomes the number `4848`. To keep a value a
  string, the environment variable value itself must contain literal double quotes." A key that
  looks numeric must be quoted in the unit file.
  → https://nuxt.com/docs/4.x/guide/going-further/runtime-config
- **Set `NUXT_APP_SECRET` per environment.** "Builds never generate one: set `NUXT_APP_SECRET` in
  every environment you deploy to", keep it "stable across deployments and server instances within
  that environment", because "Changing the value invalidates any sessions or signatures that depend
  on it." Generate with `openssl rand -base64 32`.
  → https://nuxt.com/docs/4.x/guide/going-further/runtime-config
- **Cookie `Secure` is correct on TLS** — the repo already notes cookies default to `Secure`,
  accepted on `localhost`, and `supabase.cookieOptions.secure: false` for http-over-LAN testing
  (`README.md`). Nothing to change for an https production origin.
- **Outbound traffic is the only topology fact that matters for the hosted project.** The Node
  process is a client of `https://ohbrawtgcyngyhaqtddy.supabase.co` (Auth, Data API, Realtime) and
  of `https://api.geoapify.com`; no inbound port is needed for Supabase. Realtime runs over a
  WebSocket from the browser/supabase-js to the hosted project
  (`wss://<ref>.supabase.co/realtime/v1/websocket` — see Unverified), so the proxy only needs to
  carry normal HTTPS/HTTP/2 app traffic; WebSocket upgrades are needed on the box only for
  app-served sockets, which this app does not have. Supabase-js also authenticates Realtime by
  putting the key in the upgrade URL ("For Realtime WebSocket connections, the API key is sent as a
  `?apikey=` query parameter in the upgrade URL instead of an `apikey` header") — worth knowing when
  proxy access logs are kept, since the publishable key appears in a URL.
  → https://supabase.com/docs/guides/realtime
  → https://supabase.com/docs/guides/self-hosting/self-hosted-auth-keys
- **Auth failures arrive in the URL hash on `/confirm`** (see §2), and `/confirm` is client-rendered
  — so VPS caching/proxy rules must not cache `/confirm`, and must not strip the hash (hashes are
  never sent to the server anyway).
  → https://supabase.com/docs/guides/auth/redirect-urls

## 4. Geoapify Geocoding API (ADR-0007's geocoder)

- **Endpoint**: `GET https://api.geoapify.com/v1/geocode/search?REQUEST_PARAMS`, `apiKey` required.
  → https://apidocs.geoapify.com/docs/geocoding/forward-geocoding/
- **One input mode only**: `text` for free-form, *or* structured params (`name`, `housenumber`,
  `street`, `postcode`, `city`, `state`, `country`). "Do not combine `text` with structured address
  parameters."
  → https://apidocs.geoapify.com/docs/geocoding/forward-geocoding/
- **Params that matter for a Store picker**: `type`
  (`country|state|city|postcode|street|amenity|locality`), `lang` (2-letter ISO 639-1), `limit`
  (default 5), `format` (`json` | `xml` | `geojson`, **geojson is the default** — ask for `json` if
  the app reads `results[]`), `filter`, `bias`.
  → https://apidocs.geoapify.com/docs/geocoding/forward-geocoding/
- **Hidden default bias, and it is IP-based**: "The default bias for the geocoding requests is
  `countrycode:auto`. The API detects a country by IP address and provides the search there first.
  Set bias to `countrycode:none` to avoid prioritization by country." A request made by the VPS has
  the VPS's country as bias — not the country the person typing the Store address is thinking
  about. Either pin `filter=countrycode:<iso2>`/`bias` explicitly, or set `bias=countrycode:none`.
  → https://apidocs.geoapify.com/docs/geocoding/forward-geocoding/
- **`filter` vs `bias` semantics** — filter restricts (circle/rect/countrycode/place, AND logic,
  pipe-separated), bias only prioritises (circle/rect/countrycode/`proximity:lon,lat`, OR logic).
  Both can carry `proximity`, which is how a picker stays near the user's location.
  → https://apidocs.geoapify.com/docs/geocoding/forward-geocoding/
- **Response fields for a Store row**: `lat`, `lon`, `formatted`, `address_line1`, `address_line2`,
  `name`, `housenumber`, `street`, `city`, `postcode`, `state`, `state_code`, `country`,
  `country_code`, `result_type`
  (`unknown|amenity|building|street|suburb|district|postcode|city|county|state|country`),
  `rank.confidence` (0–1) with `confidence_city_level` / `confidence_street_level` /
  `confidence_building_level` and `rank.match_type`, `datasource`, `category`, `place_id`. "Depending
  on the type of returned location, some fields may be missing."
  → https://apidocs.geoapify.com/docs/geocoding/forward-geocoding/
- **Confidence is the acceptance dial**: `rank.confidence` 0–1; low confidence "doesn't mean that
  it's incorrect, but it means that we doubt whether it indeed corresponds to the input address";
  `rank.match_type` only reports the matched address level. Docs show an accept/decline pattern
  (`ACCEPT_LEVEL = 0.95`, `DECLINE_LEVEL = 0.2`) with per-level thresholds.
  → https://apidocs.geoapify.com/docs/geocoding/forward-geocoding/
- **Attribution is in the payload**: `datasource.attribution` = `© OpenStreetMap contributors`,
  `datasource.license` = Open Database License, url `https://www.openstreetmap.org/copyright`.
  → https://apidocs.geoapify.com/docs/geocoding/forward-geocoding/
- **Credits**: "One Geocoding API / Reverse Geocoding API / Autocomplete API request is equal to one
  credit"; batch geocoding counts 0.5 credits per address (job + result request cost 1 credit each,
  up to 1000 addresses per job, asynchronous).
  → https://apidocs.geoapify.com/docs/geocoding/forward-geocoding/
  → https://www.geoapify.com/pricing-details/
- **Free plan is 3,000 credits/day at up to 5 requests/second, no card required**
  ("Free 3,000 credits / day … Up to 5 requests/second"), i.e. 1 geocode = 1 credit against a
  3,000/day budget. ADR-0007's numbers check out.
  → https://www.geoapify.com/pricing/
  → https://apidocs.geoapify.com/docs/geocoding/forward-geocoding/
- **Production/commercial use on the Free plan is explicitly allowed**: "You can use the Free plan
  for commercial websites, apps, and business projects, including in production. Stay within the
  Free plan's credit quota, rate limits, and API feature limits, and provide the required Geoapify
  and data-source attribution."
  → https://www.geoapify.com/pricing/
- **Attribution, verbatim requirement**: "For Geoapify attribution, include a follow-link such as
  `Powered by <a href="https://www.geoapify.com/">Geoapify</a>` near the map or information provided
  by the service." Terms: "When using the Services, you must always provide OpenStreetMap
  attribution. Geoapify attribution is mandatory when using Free subscription plan."
  → https://www.geoapify.com/pricing/
  → https://www.geoapify.com/terms-and-conditions/
- **Storing the geocoded coordinates on the Store row is allowed**: "Our services are based on Open
  Data. So we do not restrict you from storing results. However, you have to keep all the
  attributions to the data source with the stored object or make it visible in some other way when
  you reuse the data."
  → https://www.geoapify.com/geocoding-api/
- **Over-quota and over-rate are soft**: "Our limits are 'soft'. If your usage constantly goes over
  the quota we contact you and ask for an upgrade" / exceeding rate limits may get requests
  "block[ed] or limit[ed] … temporarily", judged on average request rate.
  → https://www.geoapify.com/pricing/
  → https://www.geoapify.com/pricing-details/
- **Autocomplete is a sibling endpoint at the same price**: `GET
  https://api.geoapify.com/v1/geocode/autocomplete?REQUEST_PARAMS` (`text` required, plus `type`,
  `lang`, `filter`, `bias`, `limit`, `format`), 1 request = 1 credit, with official
  `@geoapify/geocoder-autocomplete` npm package. A Store picker typing suggestion is a per-keystroke
  credit burn — a real cost driver for the Free plan's 3,000/day.
  → https://apidocs.geoapify.com/docs/geocoding/address-autocomplete/
  → https://apidocs.geoapify.com/docs/geocoding/forward-geocoding/
- **Key hygiene**: keys are per-project in MyProjects, "Optionally, you can protect the API key by
  listing allowed IP addresses, HTTP referrers, origins, and CORS" — allow-listing the VPS egress IP
  is the lever that keeps a server-side key server-side. GDPR/EU: "Our default API endpoints only
  use European data centers."
  → https://apidocs.geoapify.com/docs/geocoding/forward-geocoding/
  → https://www.geoapify.com/geocoding-api/
- **Terms fine print for a Free-plan production app**: "The commercial use of the Free-package is
  allowed in the development and, with some limitations, in the production phase. Please contact us
  for details", and distributing requests "across multiple accounts/projects" to stay on a lower plan
  is prohibited; governing law is Cyprus.
  → https://www.geoapify.com/terms-and-conditions/

## 5. Browser on the production domain → hosted Supabase

- **Publishable key is the browser key, and it is not a secret.** Docs table: `anon` → publishable
  key, "Used by: Browsers, mobile and desktop apps, CLIs, public source"; `service_role` → secret
  key, "Used by: Servers, Edge Functions, workers, other backend code". Legacy `anon`/`service_role`
  are deprecated "by the end of 2026". Format: `sb_publishable_<22-char-random>_<8-char-checksum>`.
  → https://supabase.com/docs/guides/getting-started/migrating-to-new-api-keys
  → https://supabase.com/docs/guides/self-hosting/self-hosted-auth-keys
- **Consequence for the deploy**: `NUXT_PUBLIC_SUPABASE_KEY` is public by design and ships in the
  page payload; the secret key has no place on the VPS today because the app talks to Supabase from
  the browser. `.env.example` calls the value `your-anon-public-key`, which is the legacy name for
  what is now a publishable key. Repo evidence: `.env.example`.
- **Browser→project traffic is unauthenticated at the network layer; RLS is the gate.** `public` is
  exposed through the Data API and every table in it needs RLS (`README.md`; current
  `public.lists` policy is `for all to authenticated using(true)`).
  → https://supabase.com/docs/guides/database/postgres/row-level-security
- **Network Restrictions gate Postgres connections, not the Data API.** Feature: "Restrict IP ranges
  that can connect to your database", "IP-based access control: Limit database connections to
  specific IPv4 and IPv6 ranges", "Pre-authentication barrier: Restrictions are enforced before
  database credential checks". CLI: `supabase network-restrictions get/update --project-ref <ref>
  --experimental [--db-allow-cidr <cidr>] [--append]`; with no restrictions ever applied, "All IPs
  can connect". The repo's local stack ships `[db.network_restrictions] enabled = false` with
  `allowed_cidrs = ["0.0.0.0/0"]`, and `[db.pooler] enabled = false`.
  → https://supabase.com/docs/guides/platform/network-restrictions
  → https://supabase.com/docs/reference/cli/supabase-network-restrictions-update
  → `supabase/config.toml`
- **Schema deploy path is `supabase db push`, and it needs a linked project.** "Pushes all local
  migrations to a remote database. Requires your local project to be linked to a remote database by
  running `supabase link`." First run creates `supabase_migrations.schema_migrations`; later runs
  skip already-applied migrations; `--dry-run` prints what would apply; `-p/--password` supplies the
  DB password.
  → https://supabase.com/docs/reference/cli/supabase-db-push
- **The interactive prompts are real**: `link` responds `Enter your database password (or leave
  blank to skip):` and saves it in native credentials storage; "If you do not want to be prompted
  for the database password, such as in a CI environment, you may specify it explicitly via the
  `SUPABASE_DB_PASSWORD` environment variable." `login` stores an access token ("Your access token is
  stored securely in native credentials storage. If native credentials storage is unavailable, it will
  be written to a plain text file at `~/.supabase/access-token`"), and `SUPABASE_ACCESS_TOKEN` skips
  login entirely. Global `--yes` "answer yes to all prompts", `--agent no` overrides agent detection.
  → https://supabase.com/docs/reference/cli/supabase-link
  → https://supabase.com/docs/reference/cli/supabase-login
  → https://supabase.com/docs/reference/cli/supabase-db-push
- **Generated migrations get pushed verbatim**, including GRANT/REVOKE chatter; trimming an applied
  migration makes local history diverge from remote (`README.md`), and the repo's generated
  `supabase/migrations/` is pg-delta output from `supabase/schemas/*.sql`.
  → https://supabase.com/docs/reference/cli/supabase-db-push
  → `README.md`

## 6. Local-repo deploy gotchas (repo evidence)

- **`.env` is a dev-only mechanism** (§3): the built server never reads it, so the VPS needs
  `NUXT_PUBLIC_SUPABASE_URL`, `NUXT_PUBLIC_SUPABASE_KEY`, `PORT`/`HOST` and `NUXT_APP_SECRET` in the
  service environment, not in a file next to `.output`.
  (`README.md`, `.env.example`,
  https://nuxt.com/docs/4.x/guide/going-further/runtime-config)
- **`.env.example` has no slot for the geocoder key**, and calls the Supabase key "anon" (see §5).
  A server-side geocode proxy needs a private runtime key (e.g. `NUXT_GEOAPIFY_KEY` — private,
  non-public `runtimeConfig`), which per §3 must be declared in `nuxt.config` to be overridable.
  (`.env.example`, https://nuxt.com/docs/4.x/guide/going-further/runtime-config)
- **README's Site URL guidance and `config.toml` disagree on the dev origin**: README says Site URL
  `http://localhost:3000`, config.toml has `site_url = "http://127.0.0.1:3000"` for the local stack.
  Both are dev-only values; the hosted project's Site URL is a Dashboard field and is the one the
  production deploy depends on. (`README.md`, `supabase/config.toml`)
- **Redirect URL allow-list entries are environment-scoped**: README already prescribes
  `http://localhost:3000/confirm` and `https://<your-domain>/confirm` as exact entries.
  (`README.md`)
- **The production deploy is not a schema deploy.** `pnpm exec supabase db push` ships schema; the
  app itself is `pnpm run build` + `node .output/server/index.mjs` on the VPS, and the GitHub OAuth
  App's Homepage URL / callback entries (`README.md` one-time setup) are the human-side step that
  has no repo artefact. (`README.md`, https://nitro.build/deploy/runtimes/node)
- **The OAuth App itself must move with the domain**: GitHub's app settings page is where Homepage
  URL and callback URLs are edited, and app registration fields are public (§1).
  → https://docs.github.com/en/apps/oauth-apps/maintaining-oauth-apps/modifying-an-oauth-app

## Unverified

I could not pin these to a docs page; treat them as open questions, not facts.

- **Realtime WebSocket endpoint path** — `wss://<project-ref>.supabase.co/realtime/v1/websocket` is
  my working assumption; `https://supabase.com/docs/guides/realtime/connections` 404s, and the
  Realtime guide pages I fetched state no endpoint. `UNVERIFIED`.
- **GitHub client-secret lifecycle** — rotating via "Generate a new client secret" (invalidating the
  old one immediately), any expiry window, and where Supabase stores the pasted secret. Docs pages
  I fetched describe the secret's use, not its rotation. `UNVERIFIED`.
- **Silent fallback behaviour**: README states "Redirects that do not match an entry silently fall
  back to the Site URL." Docs establish the allow-list requirement and Site URL as the default
  redirect target, but I found no docs describing the silent-fallback-on-reject behaviour.
  `UNVERIFIED` (repo-observed).
- **Exactly which `config.toml` keys `supabase config push` writes to a hosted project** (in
  particular whether `[auth] site_url` / `additional_redirect_urls` are included). The CLI docs
  describe the command, not the full key list. `UNVERIFIED`.
- **Free-plan attribution "some limitations" in the Terms** — the Terms say Free commercial
  production use is allowed "with some limitations. Please contact us for details"; the specific
  limitations are not published. `UNVERIFIED` (only the pricing-page wording is quotable).
- **Realtime Free-plan connection limits** (200 concurrent connections, 100 msgs/s) were verified in
  an earlier session against `https://supabase.com/docs/guides/realtime/limits`; not re-checked for
  this ticket's question. Not used as input to any claim above.

## So the map should know

- **The OAuth callback URL is fixed by the hosted project, not by the domain**: every environment's
  GitHub OAuth App must send codes to
  `https://ohbrawtgcyngyhaqtddy.supabase.co/auth/v1/callback`, with wildcard matching off; local
  stack OAuth needs the extra `http://localhost:54321/auth/v1/callback`. The Client ID/Secret live
  only in the Supabase project — GitHub OAuth cannot be exercised on the local stack today
  (ADR-0008: email flow in tests, OAuth verified manually).
- **Deploy checklist is dashboard-side and per-environment**: Site URL → production origin; Additional
  Redirect URLs → exact `<origin>/confirm` entries (a lone `*` cannot match `/confirm`, and dev
  origins stay listed because one project serves dev and prod).
- **App deploy = `pnpm run build` + `node .output/server/index.mjs` behind a TLS-terminating
  reverse proxy**; `PORT`/`HOST` and `NUXT_PUBLIC_*` + `NUXT_APP_SECRET` come from the service
  environment because the built server never reads `.env`. There is no start script in the repo, the
  box only makes outbound calls to Supabase (HTTPS, plus Realtime WebSockets) and Geoapify, and
  Nitro's own TLS flags are documented as testing-only.
- **Schema deploy stays `db push`**, which needs `login` + `link` and a database password prompt —
  a human step on this machine, not a CI step (the repo's own convention: `db push` follows each new
  migration, and generated migrations are pg-delta output).
- **Geoapify budget is 3,000 credits/day at ≤5 req/s, 1 credit per geocode and 1 credit per
  autocomplete request** — geocoding the Store address once and persisting the coordinates on the
  Store row (ADR-0007) is comfortably inside the Free plan; a keystroke-driven autocomplete picker
  is the shape that eats the quota.
- **Geoapify has two non-negotiables in the UI and one in the code**: ship "Powered by Geoapify" as
  a follow-link plus the `© OpenStreetMap contributors` attribution wherever a geocoded Store is
  shown (mandatory on Free, and retained with the stored row); keep the key server-side (allow-list
  the VPS egress IP), and neutralise the IP-based `countrycode:auto` default bias, which for this
  app is the VPS's country, not the user's.
