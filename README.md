# Nuxt Minimal Starter

Look at the [Nuxt documentation](https://nuxt.com/docs/getting-started/introduction) to learn more.

## Setup

Make sure to install dependencies:

```bash
# npm
npm install

# pnpm
pnpm install

# yarn
yarn install

# bun
bun install
```

## Development Server

Start the development server on `http://localhost:3000`:

```bash
# npm
npm run dev

# pnpm
pnpm dev

# yarn
yarn dev

# bun
bun run dev
```

## Production

Build the application for production:

```bash
# npm
npm run build

# pnpm
pnpm build

# yarn
yarn build

# bun
bun run build
```

Locally preview production build:

```bash
# npm
npm run preview

# pnpm
pnpm preview

# yarn
yarn preview

# bun
bun run preview
```

Check out the [deployment documentation](https://nuxt.com/docs/getting-started/deployment) for more information.

## Supabase auth

Sign-in is GitHub OAuth, with sessions stored in cookies so server rendering sees the
user too. `@nuxtjs/supabase` guards `/app` and `/app/**`; signed-out visitors get sent
to `/login`, and the OAuth callback lands on `/confirm`, where the PKCE `code` is
exchanged for a session in the browser.

Routes: `/` public landing, `/login` sign-in picker, `/confirm` OAuth callback,
`/app` signed-in area.

Composables: `useSupabaseClient()`, `useSupabaseUser()` (JWT claims),
`useSupabaseSession()`. In server routes: `serverSupabaseUser(event)` from
`#supabase/server`.

### One-time dashboard setup

1. In GitHub → Settings → Developer settings → OAuth Apps → New OAuth App:
   - Homepage URL: `http://localhost:3000`
   - Authorization callback URL: `https://<project-ref>.supabase.co/auth/v1/callback`
     (copy it from Supabase → Authentication → Sign In / Providers → GitHub)
2. In Supabase → Authentication → Sign In / Providers → GitHub: paste the GitHub client
   ID and client secret, and enable the provider.
3. In Supabase → Authentication → URL Configuration:
   - Site URL: `http://localhost:3000` while developing, your production URL otherwise
   - Redirect URLs: add `http://localhost:3000/confirm` and `https://<your-domain>/confirm`
     as exact entries — a single `*` will not match the `confirm` path. Redirects that do
     not match an entry silently fall back to the Site URL.

Env vars live in `.env` (`NUXT_PUBLIC_SUPABASE_URL`, `NUXT_PUBLIC_SUPABASE_KEY`). Auth
cookies default to `Secure`, which browsers accept on `localhost`; set
`supabase.cookieOptions.secure: false` if you test through a LAN IP over http.

## Supabase database (declarative schemas)

`supabase/schemas/*.sql` is the source of truth. The pg-delta engine (`[experimental.pgdelta]
enabled = true` in `supabase/config.toml`) diffs those files against the database and writes the
difference to `supabase/migrations/`, which is generated output — never hand-edit it.

```bash
pnpm exec supabase start                                                # local stack (needs Docker)
# ... edit supabase/schemas/lists.sql ...
pnpm exec supabase db schema declarative sync -f add_slug_column --yes  # write + apply migration
pnpm exec supabase db reset                                             # rebuild from migrations + seeds
```

`--no-apply` generates the migration file without touching the local database. `--yes` matters in
non-interactive runs (agents, CI): the default JSON output mode refuses to prompt and dies with
`Cannot prompt for input in JSON output mode` after a full diff has already been paid for.

- Route every schema change through `supabase/schemas/` + sync. Edits made in Studio, the SQL
  editor, or psql are invisible to the diff engine and get reverted by the next `db reset`.
- `public` is exposed through the Data API, so every table in it must have RLS enabled.
- Generated migrations include GRANT/REVOKE chatter for default privileges. Leave it — trimming an
  applied migration makes local migration history diverge from remote.
- Keep `[db.migrations].schema_paths = []`; pg-delta resolves schema ordering itself.
- A diff run is not instant: it boots a shadow Postgres, grants a temporary `diff` role, and
  introspects both sides. Expect 30–90s on Windows + Docker, more with `--no-cache`.

### Deploying to the hosted project

Login and link are one-time; `db push` follows each new migration.

```bash
pnpm exec supabase login
pnpm exec supabase link --project-ref ohbrawtgcyngyhaqtddy   # prompts for the database password
pnpm exec supabase db push
```

Local stack endpoints: API `http://127.0.0.1:54321`, Postgres
`postgresql://postgres:postgres@127.0.0.1:54322/postgres`, Studio `http://127.0.0.1:54323`.

### Current schema

`public.lists (id bigint generated always as identity PK, name text)` with RLS and one
`for all to authenticated` policy using `true`, i.e. every signed-in user can read and write every
list and signed-out users see none. Checked against the local stack: an `anon` GET on
`/rest/v1/lists` returns `[]`, a signed-in user reads rows and inserts with `201`. When lists become
per-user, add an owner column and replace `true` with `(select auth.uid()) = user_id`.

`pnpm run db:types` regenerates `app/types/database.types.ts` from the local database, and
`supabase.types` (a **path**, not a boolean — `types: true` crashes `nuxt prepare` with
`Failed to load Supabase database types from "true"`) types `useSupabaseClient()` against it. Format
the generated file with `pnpm dlx oxfmt app/types/database.types.ts` — the CLI emits it unformatted.
