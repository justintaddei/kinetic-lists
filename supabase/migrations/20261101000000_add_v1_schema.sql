-- #3 / #4 - the v1 baseline, as one migration: the declarative tree concatenated in file order.
--
-- THE CLAIM: this file is `supabase/schemas/01_tenancy.sql` through
-- `supabase/schemas/06_rpc.sql`, concatenated in file order, with nothing added and
-- nothing reordered - and for this destination that concatenation *is* what
-- `supabase db schema declarative sync --no-apply` would plan, so pushing it is the
-- baseline #4 needs.
--
-- WHY IT IS NOT `sync`'s OWN FILE. `sync` plans its diff on a shadow database booted by
-- Docker Desktop (supabase/schemas/01_tenancy.sql:15-21 - that is why the tree is
-- declaration-only). This machine's Docker engine answers `500 Internal Server Error`
-- on `\\.\pipe\dockerDesktopLinuxEngine`: `docker info` fails on the same pipe, and
-- `supabase migration list --local` reports `ECONNREFUSED 127.0.0.1:54322`. So the plan
-- is derived by hand and verified by the checks below, and the steady-state tree that
-- `sync` acts on comes from `db schema declarative generate --linked` in the same PR.
--
-- WHY THE CONCATENATION IS THE PLAN, MEASURED ON THE DESTINATION 2026-11-01:
--   * history `20261030005109` + `20261031000000` on BOTH sides (local folder and
--     `supabase_migrations.schema_migrations`);
--   * hosted `public` holds no tables at all (`information_schema.tables` is empty - the
--     demo `lists` table is retired by pushing this), `auth.users` is empty, and the
--     advisory defaults sit on `anon`/`authenticated`/`service_role` as `Dxtm`;
--   * `db push --linked --dry-run` on this file is the only thing it would apply.
-- With an empty target and an applied history, every statement here is a create with no
-- prior to depend on, and no drop is needed: a push is one transaction, so the earlier
-- failed push of this file left hosted at the same 0 tables and the same 2 applied
-- versions (measured after the fact).
--
-- WHY FILE ORDER IS DEPENDENCY ORDER, MEASURED OVER THE 140 PARSED STATEMENTS (pglast
-- v8.7, libpg_query PG 17): 12 tables, 2 views, 10 functions, 11 triggers, 32 policies,
-- 27 `create index`, 30 grants, 13 `alter table`, 1 `create schema`, 1 `alter owner`,
-- 1 `comment`; every relation a statement references, every trigger function, and every
-- grant target is created earlier in this file; the only relation outside it, at any
-- depth, is `auth.users`, whose trigger `on_auth_user_created` follows its function.
--
-- THE FILE DECLARES NO EXTENSION AND NEEDS NONE. The ids default to `public.uuidv7()`
-- (supabase/schemas/01_tenancy.sql:36-66), which this file creates:
-- `pg_available_extensions` on hosted names `pgcrypto` and `uuid-ossp` only - no
-- `pg_uuidv7` - and Postgres 17 has no built-in `uuidv7` (it lands in Postgres 18). The
-- generator is invoker's rights, granted to `authenticated` and `service_role` and
-- revoked from `public`, so id minting needs no definer and the granted-to-`anon`
-- surface stays the three RPCs.
--
-- WHAT #4 DOES WITH IT: push it, then `db schema declarative generate --linked
-- --overwrite` snapshots hosted into the steady-state tree (`.pgdelta-export.json`
-- included), the six seed files delete in that commit, and every later change is a
-- declarative diff. ADOPT-5 names the drift check: run `sync` against the snapshot and
-- expect an empty plan - any statement this file got wrong shows up there.
--
-- WHAT THE PUSH TAUGHT THE TREE TO WRITE (measured on hosted; every rule below is a
-- Postgres answer to a statement this file has carried):
--   * `db query --linked` splits on `;` and does not understand a dollar-quoted body, so
--     a function body with semicolons cannot be submitted there. plpgsql is validated by
--     the push, which reports `At statement: N`.
--   * `row_count` is a keyword, not an identifier: the printer writes
--     `get diagnostics "v" = "row_count"` and Postgres answers `unrecognized GET
--     DIAGNOSTICS item`, so the item is written bare.
--   * A keyword form is not a function call and cannot be qualified: 1-arg trim is
--     written `btrim(x)`; `extract(epoch from x)` needs search_path = 'pg_catalog',
--     which is why no function sets search_path = ''.
--   * `(select auth.uid())` prints as ("select auth"."uid"()) and Postgres reads that as
--     an unterminated quoted identifier; the tree writes (select "auth"."uid"()) - six
--     sites.
--   * String literals survive the printer: an empty string is written E''.

-- ---- 01_tenancy.sql ----
-- Tenancy: the Household, its Members, its Invitations.
--
-- ADR-0009: every noun hangs off a Household. ADR-0014: a user belongs to one
-- Household, and joins by consuming an Invitation token. ADR-0019: a sign-up
-- seeds its own Household by a trigger on auth.users, and a Household dies with
-- its last Membership. ADR-0023: the shapes here - uuidv7 ids, the denormalized
-- `household_id` every owned row carries, and the definer contract below.
--
-- Tenancy is read by a definer helper, not by a policy that selects from
-- `household_members` directly: a policy on `household_members` reading
-- `household_members` is a recursive policy (Postgres 42P17) and RLS cannot see
-- a row to decide whether to show it. `private` is not an exposed PostgREST
-- schema (config.toml `[api] schemas = ["public", "graphql_public"]`), so this
-- function has no HTTP surface, and lints `0028`/`0029` - the SECURITY DEFINER
-- warns - never fire on it. The three RPCs the browser calls live in `public`
-- instead, and are the deliberate, suppressed `0028`/`0029` set (ADR-0023).

-- ---------------------------------------------------------------- ids
--
-- ADR-0023's ids are uuidv7: 48 bits of millisecond clock, then entropy, so
-- `order by "id"` is `order by the moment the row was born`, and a B-tree over
-- ids stays append-friendly. Hosted has no uuidv7 to call: Postgres 17 has no
-- such function (it lands in Postgres 18), and the linked project's available
-- extensions are `pgcrypto` and `uuid-ossp` - measured 2026-11-01 over
-- `pg_available_extensions`, with no `pg_uuidv7`, and uuid-ossp's generators
-- stop at v1/v3/v4/v5. So the shape is ours, built from the text form of
-- `gen_random_uuid()` (v4, ACL `NULL` = PUBLIC execute) and the server clock:
-- 12 hex chars of big-endian milliseconds, `7` in the version nibble, `10xx` in
-- the variant nibble, and 74 of the v4 bits left over (RFC 9562).
--
-- Invoker, not definer: a column default runs as the inserting role, so `execute`
-- is the whole surface. The search_path has to be `pg_catalog`, not `''`, because
-- `extract(epoch from ...)` is a keyword form that does not parse schema-qualified
-- - the advisor's search-path warning stays off either way.

create function "public"."uuidv7"()
returns "pg_catalog"."uuid"
language 'sql'
volatile
set search_path = 'pg_catalog'
as $$
  with "s" as (
    select
      floor(extract(epoch from clock_timestamp()) * 1000)::bigint as "ms",
      replace(gen_random_uuid()::text, '-', E'') as "r"
  )
  select
    (
      right('000000000000' || to_hex("s"."ms"), 12) ||
      '7' ||
      substr("s"."r", 14, 3) ||
      substr('89ab', ((position(substr("s"."r", 17, 1) in '0123456789abcdef') - 1) % 4) + 1, 1) ||
      substr("s"."r", 18, 15)
    )::"pg_catalog"."uuid"
  from "s"
$$;

alter function "public"."uuidv7"() owner to "postgres";

-- Grants: not to `anon`. The writers are `authenticated` members, and the definer
-- paths run as the owner; holding it back from `anon` keeps the granted-to-`anon`
-- function surface at the count the advisory register carries.
revoke execute on function "public"."uuidv7"() from public;
grant execute on function "public"."uuidv7"() to "authenticated", "service_role";

comment on function "public"."uuidv7"() is 'UUIDv7 from the server clock (RFC 9562): the id default of every household-owned row.';

create schema if not exists "private";

grant usage on schema "private" to "authenticated", "supabase_auth_admin";

create function "private"."is_member"("p_household_id" uuid)
returns boolean
language 'plpgsql'
security definer
set search_path = 'pg_catalog'
stable
as $$
begin
  return exists (
    select 1
    from "public"."household_members" "m"
    where "m"."household_id" = "p_household_id"
      and "m"."user_id" = (select "auth"."uid"())
  );
end;
$$;

revoke execute on function "private"."is_member"(uuid) from public, anon;
grant execute on function "private"."is_member"(uuid) to "authenticated";

-- A row's ownership keys never move. `CREATE POLICY` cannot restrict which
-- columns an UPDATE writes (Postgres has no column list on a policy), so the
-- pair keys [ADR-0023] builds are guarded where the policy cannot reach: a
-- before-update trigger raising when the row's Household, its Store, its User,
-- its List or its Item changes under it. Moving a Location to a sibling Store,
-- re-homing a List, or sliding your own Membership into a Household you were
-- never invited to are all the same act in the schema's eyes: not one.
create function "private"."ownership_keys_are_immutable"()
returns trigger
language 'plpgsql'
security definer
set search_path = 'pg_catalog'
as $$
declare
  v_old jsonb := "to_jsonb"("old");
  v_new jsonb := "to_jsonb"("new");
  v_key text;
begin
  foreach "v_key" in array array[
    'id', 'household_id', 'store_id', 'user_id', 'list_id', 'item_id'
  ] loop
    if "v_old" ? "v_key" and "v_new" ? "v_key"
       and "v_old" -> "v_key" is distinct from "v_new" -> "v_key" then
      raise exception 'a % row cannot move to another owner', "tg_table_name"
        using errcode = '42501';
    end if;
  end loop;
  return "new";
end;
$$;

revoke execute on function "private"."ownership_keys_are_immutable"() from public, anon, "authenticated";

-- ---------------------------------------------------------------- households

create table "households" (
  "id" uuid primary key default "public"."uuidv7"(),
  "name" text not null default 'My Household'
);

-- No INSERT policy: a Household row arrives only from the sign-up trigger, and
-- the trigger runs as the function owner, past RLS (ADR-0019).
alter table "households" enable row level security;

create policy "households_read_by_member"
  on "households" for select to "authenticated"
  using ("private"."is_member"("id"));

-- ADR-0022: the Household surface is a name and a roster. Renaming is the only
-- verb the Household table serves its Members.
create policy "households_rename_by_member"
  on "households" for update to "authenticated"
  using ("private"."is_member"("id"))
  with check ("private"."is_member"("id"));

create trigger "households_ownership_keys_are_immutable"
  before update of "id" on "households"
  for each row execute function "private"."ownership_keys_are_immutable"();

-- ------------------------------------------------------- household_members

create table "household_members" (
  "household_id" uuid not null,
  "user_id" uuid not null,
  "display_name" text not null,
  primary key ("household_id", "user_id"),
  -- ADR-0014: a user is a Member of exactly one Household.
  unique ("user_id"),
  constraint "household_members_household_id_fkey"
    foreign key ("household_id") references "households"("id") on delete cascade,
  constraint "household_members_user_id_fkey"
    foreign key ("user_id") references "auth"."users"("id") on delete cascade
);

alter table "household_members" enable row level security;

-- Display Names are shared: the Kinetic View and the Buy toast name the
-- Household's Members out loud (ADR-0014, ADR-0016, ADR-0022's roster).
create policy "household_members_read_by_member"
  on "household_members" for select to "authenticated"
  using ("private"."is_member"("household_id"));

-- Your own Display Name is yours to change; no other column, no other row.
-- No column list exists on a policy, so this policy is exactly what it looks
-- like: your own Membership row, writable in its one free column - its keys are
-- the trigger below, and Join is the only door into another Household.
create policy "household_members_rename_self"
  on "household_members" for update to "authenticated"
  using ((select "auth"."uid"()) = "user_id")
  with check ((select "auth"."uid"()) = "user_id");

create trigger "household_members_ownership_keys_are_immutable"
  before update of "household_id", "user_id" on "household_members"
  for each row execute function "private"."ownership_keys_are_immutable"();

-- ADR-0019: a Household dies with its last Membership. The cascade in the other
-- direction is the same rule - a deleted auth.users row takes its Membership,
-- and this trigger takes the Households left with nobody.
create function "private"."erase_empty_household"()
returns trigger
language 'plpgsql'
security definer
set search_path = 'pg_catalog'
as $$
begin
  delete from "public"."households" "h"
  where "h"."id" = "old"."household_id"
    and not exists (
      select 1 from "public"."household_members" "m"
      where "m"."household_id" = "old"."household_id"
    );
  return null;
end;
$$;

revoke execute on function "private"."erase_empty_household"() from public, anon, "authenticated";

create trigger "household_members_erase_household"
  after delete on "household_members"
  for each row execute function "private"."erase_empty_household"();

-- ------------------------------------------------------- household_invites

create table "household_invites" (
  "token" uuid primary key default "gen_random_uuid"(),
  "household_id" uuid not null,
  "created_by" uuid not null,
  "created_at" timestamp with time zone not null default "now"(),
  "expires_at" timestamp with time zone not null default "now"() + interval '7 days',
  "accepted_by" uuid,
  "accepted_at" timestamp with time zone,
  constraint "household_invites_household_id_fkey"
    foreign key ("household_id") references "households"("id") on delete cascade,
  constraint "household_invites_created_by_fkey"
    foreign key ("created_by") references "auth"."users"("id") on delete cascade,
  constraint "household_invites_accepted_by_fkey"
    foreign key ("accepted_by") references "auth"."users"("id") on delete cascade
);

-- The token is the primary key, so the link a Visitor reads is indexed by it.
create index "household_invites_household_id_idx" on "household_invites" ("household_id");
create index "household_invites_created_by_idx" on "household_invites" ("created_by");
create index "household_invites_accepted_by_idx" on "household_invites" ("accepted_by");

alter table "household_invites" enable row level security;

create policy "household_invites_read_by_member"
  on "household_invites" for select to "authenticated"
  using ("private"."is_member"("household_id"));

-- ADR-0014: an Invitation is minted, listed, and revoked by Members; the token
-- is consumed by `public.join_household`, which is the only writer of
-- `accepted_by`/`accepted_at` and of the Membership it inserts.
create policy "household_invites_mint_by_member"
  on "household_invites" for insert to "authenticated"
  with check (
    "private"."is_member"("household_id")
    and "created_by" = (select "auth"."uid"())
  );

create policy "household_invites_revoke_by_member"
  on "household_invites" for delete to "authenticated"
  using ("private"."is_member"("household_id"));

-- ------------------------------------------------ ADR-0019's sign-up trigger

-- No exception handler: a trigger that raises aborts the INSERT into
-- `auth.users`, which aborts the sign-up. A half a Household is worse than no
-- sign-up, and the raw_email/identity_data chain is deliberately NOT `raw_user_meta_data`.
create function "private"."handle_new_user"()
returns trigger
language 'plpgsql'
security definer
set search_path = 'pg_catalog'
as $$
declare
  v_display_name text;
  v_household uuid;
begin
  -- The name chain ADR-0019 fixes: raw_user_meta_data->>'name', then
  -- preferred_username, full_name, user_name, then the email local part.
  -- identity_data is never read (ADR-0019's warning about raw_app_meta_data).
  select coalesce(
    nullif("raw_user_meta_data" ->> 'name', E''),
    nullif("raw_user_meta_data" ->> 'preferred_username', E''),
    nullif("raw_user_meta_data" ->> 'full_name', E''),
    nullif("raw_user_meta_data" ->> 'user_name', E''),
    split_part("email", '@', 1)
  )
  into "v_display_name"
  from "auth"."users" "u"
  where "u"."id" = "new"."id";

  insert into "public"."households" default values
  returning "id" into "v_household";

  insert into "public"."household_members" ("household_id", "user_id", "display_name")
  values ("v_household", "new"."id", "v_display_name");

  return "new";
end;
$$;

-- GoTrue owns auth.users and inserts as supabase_auth_admin.
grant execute on function "private"."handle_new_user"() to "supabase_auth_admin";
revoke execute on function "private"."handle_new_user"() from public, anon, "authenticated";

-- The grants, said out loud. Supabase's default privileges hand `select` on
-- every new `public` table to `anon` and `authenticated`; the row level security
-- above means `anon` would read zero rows, and this says so in the ACL. Reads
-- are `select` for Members only - the verbs live in the policies, not here.
revoke all on "households", "household_members", "household_invites"
  from "anon", public;
grant select on "households", "household_members", "household_invites"
  to "authenticated";

create trigger "on_auth_user_created"
  after insert on "auth"."users"
  for each row execute function "private"."handle_new_user"();

-- ---- 02_stores.sql ----
-- Stores and their Store Locations.
--
-- ADR-0011: a Store belongs to a Household, with no sharing between
-- Households. ADR-0013: a Store has Locations; a Location's coordinates come
-- from a Position the app read off the map, and `geofence_m` is the only
-- judgement it carries. A Location is nameless. ADR-0018: a Store's name is
-- unique per Household. ADR-0017: deleting a Location erases the history that
-- names it, so every reference to a Location cascades.
--
-- Pair-validity is an index, not a trigger: `unique (household_id, "id")` /
-- `unique (store_id, "id")` are the targets the composite foreign keys point
-- at, so a row can only ever name a Store and a Household that agree
-- (ADR-0023). `store_locations` carries `household_id` denormalized from its
-- Store for exactly that reason, and its own composite key is the target for
-- Arrivals and Purchases.

create table "stores" (
  "id" uuid primary key default "public"."uuidv7"(),
  "household_id" uuid not null,
  "name" text not null,
  -- The composite target for every `(..., store_id)` pair foreign key.
  unique ("household_id", "id"),
  constraint "stores_household_id_fkey"
    foreign key ("household_id") references "households"("id") on delete cascade
);

-- ADR-0018: unique per Household, by index. Trim- and case-insensitive, which
-- PostgREST can pre-check with `?name=eq.x`; the index is the backstop.
create unique index "stores_name_household_idx"
  on "stores" ("household_id", "lower"("btrim"("name")));

alter table "stores" enable row level security;

-- Stores are shared; every verb is a Member's verb (ADR-0011, ADR-0022).
create policy "stores_read_by_member"
  on "stores" for select to "authenticated"
  using ("private"."is_member"("household_id"));

-- A Store and its first Location arrive in one nested insert, which PostgREST
-- compiles to a single SQL statement: atomic by construction, no transaction
-- preference involved (ADR-0023).
create policy "stores_create_by_member"
  on "stores" for insert to "authenticated"
  with check ("private"."is_member"("household_id"));

create policy "stores_rename_by_member"
  on "stores" for update to "authenticated"
  using ("private"."is_member"("household_id"))
  with check ("private"."is_member"("household_id"));

create trigger "stores_ownership_keys_are_immutable"
  before update of "id", "household_id" on "stores"
  for each row execute function "private"."ownership_keys_are_immutable"();

-- ADR-0022: Store delete is the one cascade that needs a confirmation, because
-- it erases Locations and the Purchases recorded at them.
create policy "stores_delete_by_member"
  on "stores" for delete to "authenticated"
  using ("private"."is_member"("household_id"));

-- ----------------------------------------------------------- store_locations

create table "store_locations" (
  "id" uuid primary key default "public"."uuidv7"(),
  "store_id" uuid not null,
  "household_id" uuid not null,
  "lat" double precision not null check ("lat" between -90 and 90),
  "lng" double precision not null check ("lng" between -180 and 180),
  "geofence_m" integer not null default 150
    check ("geofence_m" > 0 and "geofence_m" <= 20000),
  -- The composite targets: for the Household's own pair, and for every
  -- `(..., location_id)` pair foreign key.
  unique ("household_id", "id"),
  unique ("store_id", "id"),
  constraint "store_locations_store_id_household_id_fkey"
    foreign key ("store_id", "household_id")
    references "stores" ("household_id", "id") on delete cascade
);

create index "store_locations_store_id_household_id_idx"
  on "store_locations" ("store_id", "household_id");

alter table "store_locations" enable row level security;

create policy "store_locations_read_by_member"
  on "store_locations" for select to "authenticated"
  using ("private"."is_member"("household_id"));

create policy "store_locations_create_by_member"
  on "store_locations" for insert to "authenticated"
  with check ("private"."is_member"("household_id"));

-- Coordinates and the geofence are re-captured from the map; the Location's
-- identity and its Store never move (ADR-0013), which is the trigger below - a
-- policy cannot name the columns it restricts.
create policy "store_locations_update_position_by_member"
  on "store_locations" for update to "authenticated"
  using ("private"."is_member"("household_id"))
  with check ("private"."is_member"("household_id"));

create trigger "store_locations_ownership_keys_are_immutable"
  before update of "id", "household_id", "store_id" on "store_locations"
  for each row execute function "private"."ownership_keys_are_immutable"();

revoke all on "stores", "store_locations" from "anon", public;
grant select on "stores", "store_locations" to "authenticated";

-- ADR-0017: the Location's Purchases and Arrivals go with it.
create policy "store_locations_delete_by_member"
  on "store_locations" for delete to "authenticated"
  using ("private"."is_member"("household_id"));

-- ---- 03_lists.sql ----
-- Lists, Items, the Rows that join them, and Store Tags.
--
-- ADR-0001: a List is a standing set, so a Row is a per-List membership, not an
-- occurrence - which is why `list_items` keys on the (List, Item) pair.
-- ADR-0002: an Item is per-user and shared by name; ADR-0012: Category and
-- Quantity are free-text values on the Item, not tables. ADR-0010: a Row has one
-- Status, shared by every Member. ADR-0015: Store Tags are written at capture
-- and an Arrival only selects the Active Store. ADR-0018: Item names are unique
-- per Household, by index.
--
-- `household_id` is denormalized onto Rows so a tenancy check is one column, and
-- so the composite pair keys can point at it (ADR-0023).

create table "lists" (
  "id" uuid primary key default "public"."uuidv7"(),
  "household_id" uuid not null,
  "name" text not null,
  unique ("household_id", "id"),
  constraint "lists_household_id_fkey"
    foreign key ("household_id") references "households"("id") on delete cascade
);

alter table "lists" enable row level security;

-- Lists are shared; there is no Personal List in v1.
create policy "lists_read_by_member"
  on "lists" for select to "authenticated"
  using ("private"."is_member"("household_id"));

create policy "lists_create_by_member"
  on "lists" for insert to "authenticated"
  with check ("private"."is_member"("household_id"));

create policy "lists_rename_by_member"
  on "lists" for update to "authenticated"
  using ("private"."is_member"("household_id"))
  with check ("private"."is_member"("household_id"));

create trigger "lists_ownership_keys_are_immutable"
  before update of "id", "household_id" on "lists"
  for each row execute function "private"."ownership_keys_are_immutable"();

-- No DELETE policy on lists: [ADR-0022] refused the List delete verb as fog, so
-- a List is renamed and read, and its Rows leave only with the List row itself
-- (which v1 never deletes).

-- ------------------------------------------------------------------- items

create table "items" (
  "id" uuid primary key default "public"."uuidv7"(),
  "household_id" uuid not null,
  "name" text not null,
  "category" text,
  "quantity" text,
  unique ("household_id", "id"),
  constraint "items_household_id_fkey"
    foreign key ("household_id") references "households"("id") on delete cascade
);

-- ADR-0018: the Item name is unique per Household. Capture reads this index as
-- the Merge/Make choice; the insert fails with 23505 and the UI re-offers Merge.
create unique index "items_name_household_idx"
  on "items" ("household_id", "lower"("btrim"("name")));

alter table "items" enable row level security;

create policy "items_read_by_member"
  on "items" for select to "authenticated"
  using ("private"."is_member"("household_id"));

create policy "items_create_by_member"
  on "items" for insert to "authenticated"
  with check ("private"."is_member"("household_id"));

create policy "items_update_by_member"
  on "items" for update to "authenticated"
  using ("private"."is_member"("household_id"))
  with check ("private"."is_member"("household_id"));

create trigger "items_ownership_keys_are_immutable"
  before update of "id", "household_id" on "items"
  for each row execute function "private"."ownership_keys_are_immutable"();

-- ADR-0022: Item delete is a confirm because it cascades Rows and Lines.
create policy "items_delete_by_member"
  on "items" for delete to "authenticated"
  using ("private"."is_member"("household_id"));

-- -------------------------------------------------------------- list_items

create table "list_items" (
  "id" uuid primary key default "public"."uuidv7"(),
  "list_id" uuid not null,
  "item_id" uuid not null,
  "household_id" uuid not null,
  "status" text not null default 'needed'
    check ("status" in ('needed', 'in_basket', 'stocked')),
  "stocked_at" timestamp with time zone,
  -- A Row is one per (List, Item): a standing set (ADR-0001).
  unique ("list_id", "item_id"),
  -- The composite targets for Purchase Lines.
  unique ("household_id", "id"),
  unique ("id", "item_id"),
  constraint "list_items_list_id_household_id_fkey"
    foreign key ("household_id", "list_id")
    references "lists" ("household_id", "id") on delete cascade,
  constraint "list_items_item_id_household_id_fkey"
    foreign key ("household_id", "item_id")
    references "items" ("household_id", "id") on delete cascade
);

create index "list_items_item_id_idx" on "list_items" ("item_id");
create index "list_items_household_id_list_id_idx"
  on "list_items" ("household_id", "list_id");

-- The Kinetic View read: every Row of one Household in a given Status
-- (ADR-0015's Standing Set, and the Basket a Buy claims).
create index "list_items_household_id_status_idx"
  on "list_items" ("household_id", "status");

alter table "list_items" enable row level security;

-- Rows are shared: one Status per Row, read and moved by every Member
-- (ADR-0010). Check and Need are Status updates on this table (ADR-0022).
create policy "list_items_read_by_member"
  on "list_items" for select to "authenticated"
  using ("private"."is_member"("household_id"));

-- The two Statuses a Member's own hand can put a Row into. Stocked arrives
-- only from `public.buy_basket`, on the server's clock (ADR-0016), and a policy
-- cannot name columns - so the check names the values instead, which is the
-- stronger sentence: the app has no way to write `stocked` at all.
create policy "list_items_add_by_member"
  on "list_items" for insert to "authenticated"
  with check (
    "private"."is_member"("household_id")
    and "status" in ('needed', 'in_basket')
  );

create policy "list_items_move_status_by_member"
  on "list_items" for update to "authenticated"
  using ("private"."is_member"("household_id"))
  with check (
    "private"."is_member"("household_id")
    and "status" in ('needed', 'in_basket')
  );

create trigger "list_items_ownership_keys_are_immutable"
  before update of "id", "household_id", "list_id", "item_id" on "list_items"
  for each row execute function "private"."ownership_keys_are_immutable"();

-- No DELETE policy: a Member un-Checks a Row (Status back to 'needed'), they do
-- not delete the Household's standing membership outside List hygiene.
-- Deleting the List deletes its Rows (ADR-0022).

-- ---------------------------------------------------------- item_store_tags

create table "item_store_tags" (
  "item_id" uuid not null,
  "store_id" uuid not null,
  "created_by" uuid not null,
  "created_at" timestamp with time zone not null default "now"(),
  primary key ("item_id", "store_id"),
  constraint "item_store_tags_item_id_fkey"
    foreign key ("item_id") references "items"("id") on delete cascade,
  constraint "item_store_tags_store_id_fkey"
    foreign key ("store_id") references "stores"("id") on delete cascade,
  constraint "item_store_tags_created_by_fkey"
    foreign key ("created_by") references "auth"."users"("id") on delete cascade
);

create index "item_store_tags_store_id_idx" on "item_store_tags" ("store_id");
create index "item_store_tags_created_by_idx" on "item_store_tags" ("created_by");

alter table "item_store_tags" enable row level security;

-- The composite primary key is invisible to a Realtime DELETE event unless the
-- full row is the replica identity (ticket #8's seam).
alter table "item_store_tags" replica identity full;

-- The tag pair crosses two tables, so it gets the one guard RLS cannot
-- expression: a before-trigger owned by the migration role, which reads Items
-- and Stores past RLS (ADR-0023). A Tag may never pair an Item of one Household
-- with a Store of another; the tenancy of a Tag is read through its Store.
create function "private"."tag_pairs_one_household"()
returns trigger
language 'plpgsql'
security definer
set search_path = 'pg_catalog'
as $$
declare
  v_item_household uuid;
  v_store_household uuid;
begin
  select "household_id" into "v_item_household"
  from "public"."items" where "id" = "new"."item_id";

  select "household_id" into "v_store_household"
  from "public"."stores" where "id" = "new"."store_id";

  if "v_item_household" is null or "v_store_household" is null
     or "v_item_household" <> "v_store_household" then
    raise exception 'a Store Tag pairs an Item and a Store from different Households'
      using errcode = '23514';
  end if;

  return "new";
end;
$$;

revoke execute on function "private"."tag_pairs_one_household"() from public, anon, "authenticated";

create trigger "item_store_tags_pair_one_household"
  before insert or update of "item_id", "store_id" on "item_store_tags"
  for each row execute function "private"."tag_pairs_one_household"();

-- The Shopping surface is a Member's `select`; every write is a policy verb.
revoke all on "lists", "items", "list_items", "item_store_tags"
  from "anon", public;
grant select on "lists", "items", "list_items", "item_store_tags"
  to "authenticated";

-- ADR-0015: Tags are written at capture, listed, and un-tagged. Buy reads them
-- inside `public.buy_basket`, definer past RLS.
create policy "item_store_tags_read_by_member"
  on "item_store_tags" for select to "authenticated"
  using (exists (
    select 1 from "public"."stores" "s"
    where "s"."id" = "store_id"
      and "private"."is_member"("s"."household_id")
  ));

create policy "item_store_tags_tag_by_member"
  on "item_store_tags" for insert to "authenticated"
  with check (exists (
    select 1 from "public"."stores" "s"
    where "s"."id" = "store_id"
      and "private"."is_member"("s"."household_id")
  ));

create policy "item_store_tags_untag_by_member"
  on "item_store_tags" for delete to "authenticated"
  using (exists (
    select 1 from "public"."stores" "s"
    where "s"."id" = "store_id"
      and "private"."is_member"("s"."household_id")
  ));

-- ---- 04_history.sql ----
-- Arrivals, Purchases, Purchase Lines: the history a Household writes and never
-- edits.
--
-- ADR-0005: Arrival is client-side and only suggests, so an Arrival is a row the
-- phone writes - the server keeps no geofence state and judges nothing.
-- ADR-0004 / ADR-0016: a Purchase is an append-only snapshot, claims Rows on
-- the server's clock, and carries the user's `sold_at`; it is never rewritten,
-- and the app is granted no verb on it at all.
-- ADR-0017: Lines reference the Rows they claimed, every delete cascades, and a
-- Purchase with no Lines is not a Purchase.
--
-- A Purchase spans Lists - a Buy takes the whole In-Basket basket at the Active
-- Store, cross-List (ADR-0015) - so `list_id` is not a column of `purchases`.
-- It lives on each Line, through the Row the Line names.

create table "arrivals" (
  "id" uuid primary key default "public"."uuidv7"(),
  "household_id" uuid not null,
  "user_id" uuid not null,
  "location_id" uuid not null,
  "arrived_at" timestamp with time zone not null default "now"(),
  -- The Arrival's Household is its Location's Household, by pair key (ADR-0023).
  constraint "arrivals_household_id_location_id_fkey"
    foreign key ("household_id", "location_id")
    references "store_locations" ("household_id", "id") on delete cascade,
  constraint "arrivals_user_id_fkey"
    foreign key ("user_id") references "auth"."users"("id") on delete cascade
);

create index "arrivals_household_id_idx" on "arrivals" ("household_id");
create index "arrivals_location_id_idx" on "arrivals" ("location_id");
create index "arrivals_arrived_at_idx" on "arrivals" ("arrived_at");

alter table "arrivals" enable row level security;

-- The log is read by Members, and written only by the phone that made the
-- Arrival. The House tab is a read of `arrivals` - it judges nothing (ADR-0005).
create policy "arrivals_read_by_member"
  on "arrivals" for select to "authenticated"
  using ("private"."is_member"("household_id"));

create policy "arrivals_record_own_by_member"
  on "arrivals" for insert to "authenticated"
  with check (
    "private"."is_member"("household_id")
    and "user_id" = (select "auth"."uid"())
  );

-- ---------------------------------------------------------------- purchases

create table "purchases" (
  "id" uuid primary key default "public"."uuidv7"(),
  "household_id" uuid not null,
  "store_id" uuid not null,
  "location_id" uuid,
  "bought_by" uuid not null,
  "bought_at" timestamp with time zone not null,
  "sold_at" date not null,
  "session_token" text not null,
  -- The Buy's whole basket is one Purchase, cross-List: `purchases` has no
  -- `list_id`. The composite target for a Line's (purchase, store) pair.
  unique ("id", "store_id"),
  -- Idempotency: (Household, session token) is claimed once. A replay of a
  -- token returns the Purchase that was recorded and writes nothing (ADR-0016).
  unique ("household_id", "session_token"),
  constraint "purchases_household_id_fkey"
    foreign key ("household_id") references "households"("id") on delete cascade,
  constraint "purchases_household_id_store_id_fkey"
    foreign key ("household_id", "store_id")
    references "stores" ("household_id", "id") on delete cascade,
  constraint "purchases_household_id_location_id_fkey"
    foreign key ("household_id", "location_id")
    references "store_locations" ("household_id", "id") on delete cascade,
  constraint "purchases_bought_by_fkey"
    foreign key ("bought_by") references "auth"."users"("id") on delete cascade
);

create index "purchases_household_id_store_id_idx" on "purchases" ("household_id", "store_id");
create index "purchases_household_id_location_id_idx" on "purchases" ("household_id", "location_id");
create index "purchases_store_id_idx" on "purchases" ("store_id");
create index "purchases_location_id_idx" on "purchases" ("location_id");
create index "purchases_bought_by_idx" on "purchases" ("bought_by");
create index "purchases_bought_at_idx" on "purchases" ("bought_at");
create index "purchases_sold_at_idx" on "purchases" ("sold_at");
create index "purchases_session_token_idx" on "purchases" ("session_token");

alter table "purchases" enable row level security;

-- The pair guard the app cannot be trusted with runs inside `public.buy_basket`
-- (ADR-0017), so the app has no verb here at all, and this is the intent written
-- out rather than left to RLS's default deny (lint 0008).
create policy "purchases_append_only"
  on "purchases" for all to "authenticated"
  using (false)
  with check (false);

-- ----------------------------------------------------------- purchase_lines

create table "purchase_lines" (
  "id" uuid primary key default "public"."uuidv7"(),
  "purchase_id" uuid not null,
  "household_id" uuid not null,
  "item_id" uuid not null,
  "store_id" uuid not null,
  "list_item_id" uuid not null,
  -- A Line names the Row it claimed (ADR-0017 as amended by ADR-0023), and the
  -- (Row, Item) pair key makes that naming a fact the index enforces.
  unique ("list_item_id", "item_id"),
  constraint "purchase_lines_purchase_id_store_id_fkey"
    foreign key ("purchase_id", "store_id")
    references "purchases" ("id", "store_id") on delete cascade,
  constraint "purchase_lines_household_id_list_item_id_fkey"
    foreign key ("household_id", "list_item_id")
    references "list_items" ("household_id", "id") on delete cascade,
  constraint "purchase_lines_household_id_item_id_fkey"
    foreign key ("household_id", "item_id")
    references "items" ("household_id", "id") on delete cascade
);

create index "purchase_lines_purchase_id_idx" on "purchase_lines" ("purchase_id");
create index "purchase_lines_household_id_list_item_id_idx"
  on "purchase_lines" ("household_id", "list_item_id");
create index "purchase_lines_item_id_idx" on "purchase_lines" ("item_id");
create index "purchase_lines_store_id_idx" on "purchase_lines" ("store_id");
create index "purchase_lines_list_item_id_idx" on "purchase_lines" ("list_item_id");

alter table "purchase_lines" enable row level security;

create policy "purchase_lines_append_only"
  on "purchase_lines" for all to "authenticated"
  using (false)
  with check (false);

-- Supabase's default privileges give `anon` and `authenticated` select on every
-- table in `public`. The history takes none of it back: the app writes a
-- Purchase through `public.buy_basket` and reads it through that RPC's result,
-- so lints 0006/0007 stay green here (ADR-0023).
-- Arrivals are read by Members, and written by their own phones; the Purchase
-- ledger is closed to the browser entirely.
revoke all on "arrivals" from "anon", public;
grant select on "arrivals" to "authenticated";

revoke all on "purchases" from "anon", "authenticated", public;
revoke all on "purchase_lines" from "anon", "authenticated", public;

-- ADR-0017: a Purchase is recorded with at least one Line, so the cascade of
-- the Lines it named - a Row deleted with its List, an Item deleted, a Store's
-- Locations erased - leaves no Line-less Purchase standing. The eraser is a
-- trigger so no verb is needed on a table the app is granted nothing.
create function "private"."erase_lineless_purchase"()
returns trigger
language 'plpgsql'
security definer
set search_path = 'pg_catalog'
as $$
begin
  delete from "public"."purchases" "p"
  where "p"."id" = "old"."purchase_id"
    and not exists (
      select 1 from "public"."purchase_lines" "l"
      where "l"."purchase_id" = "old"."purchase_id"
    );
  return null;
end;
$$;

revoke execute on function "private"."erase_lineless_purchase"() from public, anon, "authenticated";

create trigger "purchase_lines_erase_purchase"
  after delete on "purchase_lines"
  for each row execute function "private"."erase_lineless_purchase"();

-- ---- 05_rosters.sql ----
-- The two rosters the hygiene surfaces read, as security-invoker views.
--
-- ADR-0022: a Store's own surface is a Location list plus Store Tags; an Item's
-- own surface is Lists and Store Tags. Both are counts of owned rows, which the
-- app would otherwise reconstruct from three tables per row. A view is the
-- cheap shape, and `security_invoker = on` is what keeps it out of the definer
-- set: the view runs the querying role's own Row-Level Security (lint 0010), so
-- it cannot leak a row the Member's policies would not show.
--
-- The Kinetic View is NOT here, and is not a view: it is one app-side read of
-- `list_items` for one Household in one Status (ADR-0023).

-- The Store roster: a Store with its Locations and its Store Tags.
create view "roster_stores"
with (security_invoker = on)
as
select
  "s"."id",
  "s"."household_id",
  "s"."name",
  (select count(*)::int from "store_locations" "l" where "l"."store_id" = "s"."id") as "location_count",
  (select count(*)::int from "item_store_tags" "t" where "t"."store_id" = "s"."id") as "tag_count"
from "stores" "s";

grant select on "roster_stores" to "anon", "authenticated";

-- The Item roster: an Item with the Lists it stands on and the Stores tagged on it.
create view "roster_items"
with (security_invoker = on)
as
select
  "i"."id",
  "i"."household_id",
  "i"."name",
  "i"."category",
  "i"."quantity",
  (select count(*)::int from "list_items" "li" where "li"."item_id" = "i"."id") as "list_count",
  (select coalesce(array_agg("s"."name" order by "s"."name"), array[]::text[])
     from "item_store_tags" "t"
     join "stores" "s" on "s"."id" = "t"."store_id"
    where "t"."item_id" = "i"."id") as "store_names"
from "items" "i";

grant select on "roster_items" to "anon", "authenticated";
revoke all on "roster_stores", "roster_items" from public;

-- ---- 06_rpc.sql ----
-- The definer set the browser calls: three RPCs in `public`, the exposed
-- PostgREST schema.
--
-- ADR-0019 puts definer functions out of the exposed API schemas and revokes
-- them from `anon` and `authenticated`. That is right for every function in this
-- schema except these three: PostgREST only reaches functions in an exposed
-- schema, and only for a role it grants. A `private` RPC is unreachable from a
-- phone, so the three verbs the app has no policy shape for live here, granted,
-- and are the deliberate `0028`/`0029` suppressions - the app's own API surface,
-- written down in ADR-0023 as lint contract.
--
-- The rule they keep: the definer is the narrowest window that lets a write read
-- a row its own policy needs to see (tenancy, the token's Household before the
-- caller is a Member), never a general door.

-- -------------------------------------------------------------------- Buy

-- ADR-0016: Buy takes the whole In-Basket basket at one Store, claims Rows on
-- the server's clock at the transaction's start, records the user's `sold_at`,
-- and is idempotent on (Household, session token). `location_id` is optional
-- (an Arrival whose geofence never matched records the trip with no Location),
-- and a named Location must be a Location of this Store: the pair guard runs
-- inside the write, where the app cannot talk past it (ADR-0017).
create function "public"."buy_basket"(
  "p_store_id" uuid,
  "p_location_id" uuid,
  "p_sold_at" date,
  "p_session_token" text
)
returns jsonb
language 'plpgsql'
security definer
set search_path = 'pg_catalog'
as $$
declare
  v_user uuid := (select "auth"."uid"());
  v_household uuid;
  v_store_name text;
  v_purchase_id uuid;
  v_clock timestamp with time zone := "transaction_timestamp"();
  v_claimed integer;
  v_replay boolean := false;
begin
  if "v_user" is null then
    raise exception 'Buy needs a signed-in Member' using errcode = '28000';
  end if;

  select "s"."household_id", "s"."name"
    into "v_household", "v_store_name"
  from "public"."stores" "s"
  where "s"."id" = "p_store_id";

  if "v_household" is null or not (select "private"."is_member"("v_household")) then
    raise exception 'Buy names a Store your Household does not own' using errcode = '42501';
  end if;

  if "p_location_id" is not null and not exists (
    select 1 from "public"."store_locations" "l"
    where "l"."id" = "p_location_id" and "l"."store_id" = "p_store_id"
  ) then
    raise exception 'Buy names a Location of another Store' using errcode = '23514';
  end if;

  -- Idempotency: the token is claimed once per Household. A replay returns the
  -- Purchase recorded the first time and writes nothing.
  select "p"."id" into "v_purchase_id"
  from "public"."purchases" "p"
  where "p"."household_id" = "v_household" and "p"."session_token" = "p_session_token";

  if "v_purchase_id" is not null then
    "v_replay" := true;
  else
    insert into "public"."purchases"
      ("household_id", "store_id", "location_id", "bought_by", "bought_at", "sold_at", "session_token")
    values
      ("v_household", "p_store_id", "p_location_id", "v_user", "v_clock", "p_sold_at", "p_session_token")
    returning "id" into "v_purchase_id";

    with "claimed" as (
      update "public"."list_items" "li"
         set "status" = 'stocked',
             "stocked_at" = "v_clock"
        where "li"."household_id" = "v_household"
          and "li"."status" = 'in_basket'
          and ("li"."stocked_at" is null or "li"."stocked_at" <= "v_clock")
          and exists (
            select 1 from "public"."item_store_tags" "t"
            where "t"."item_id" = "li"."item_id"
              and "t"."store_id" = "p_store_id"
          )
      returning "li"."id", "li"."item_id"
    )
    insert into "public"."purchase_lines"
      ("purchase_id", "household_id", "item_id", "store_id", "list_item_id")
    select "v_purchase_id", "v_household", "c"."item_id", "p_store_id", "c"."id"
    from "claimed" "c";

    get diagnostics "v_claimed" = row_count;

    if "v_claimed" = 0 then
      -- ADR-0017: a Purchase is recorded with at least one Line, so this raises
      -- and the insert above goes with it.
      raise exception 'Nothing is In Basket at this Store' using errcode = '23514';
    end if;
  end if;

  -- The recorded Purchase, and the rows this Buy skipped: stocked after this
  -- Buy's clock by a co-Member whose Buy won the race (ADR-0016's toast).
  return (
    select jsonb_build_object(
      'replay', "v_replay",
      'purchase', (
        select "to_jsonb"("p") from "public"."purchases" "p" where "p"."id" = "v_purchase_id"
      ),
      'lines', (
        select coalesce(jsonb_agg(jsonb_build_object(
                 'item_name', "i"."name",
                 'category', "i"."category",
                 'quantity', "i"."quantity"
               ) order by "i"."name"), '[]'::jsonb)
        from "public"."purchase_lines" "l"
        join "public"."items" "i" on "i"."id" = "l"."item_id"
        where "l"."purchase_id" = "v_purchase_id"
      ),
      'skipped', (
        select coalesce(jsonb_agg(jsonb_build_object(
                 'item_name', "i"."name",
                 'store_name', "s"."name",
                 'claimed_by', "m"."display_name",
                 'stocked_at', "li"."stocked_at"
               ) order by "i"."name"), '[]'::jsonb)
        from "public"."list_items" "li"
        join "public"."items" "i" on "i"."id" = "li"."item_id"
        join "public"."stores" "s" on "s"."id" = "p_store_id"
        left join "public"."purchase_lines" "l" on "l"."list_item_id" = "li"."id"
        left join "public"."purchases" "pu" on "pu"."id" = "l"."purchase_id"
        left join "public"."household_members" "m" on "m"."user_id" = "pu"."bought_by"
        where "li"."household_id" = "v_household"
          and "li"."status" = 'stocked'
          and "li"."stocked_at" > "v_clock"
          and "l"."id" is null
      )
    )
  );
end;
$$;

revoke execute on function "public"."buy_basket"(uuid, uuid, date, text) from public, anon;
grant execute on function "public"."buy_basket"(uuid, uuid, date, text) to "authenticated";

-- -------------------------------------------------------------- Join

-- ADR-0014: one Household per user, admission by consuming the token, the
-- emptiness check, and a refusal that names the Household and its Members.
create function "public"."join_household"("p_token" uuid)
returns jsonb
language 'plpgsql'
security definer
set search_path = 'pg_catalog'
as $$
declare
  v_user uuid := (select "auth"."uid"());
  v_invite record;
  v_home record;
  v_display_name text;
begin
  if "v_user" is null then
    raise exception 'Joining needs a signed-in user' using errcode = '28000';
  end if;

  select "i"."household_id", "i"."expires_at", "i"."accepted_at", "h"."name"
    into "v_invite"
  from "public"."household_invites" "i"
  join "public"."households" "h" on "h"."id" = "i"."household_id"
  where "i"."token" = "p_token";

  if not found then
    raise exception 'This invitation does not exist';
  end if;

  if "v_invite"."accepted_at" is not null then
    raise exception 'This invitation has already been used';
  end if;

  if "v_invite"."expires_at" <= "now"() then
    raise exception 'This invitation has expired';
  end if;

  select "h"."id", "h"."name" into "v_home"
  from "public"."household_members" "m"
  join "public"."households" "h" on "h"."id" = "m"."household_id"
  where "m"."user_id" = "v_user";

  if "v_home"."id" is not null then
    raise exception 'You already belong to %', "v_home"."name"
      using hint = format('Ask a Member of "%s" to invite you instead', "v_home"."name");
  end if;

  select coalesce(
    nullif("raw_user_meta_data" ->> 'name', E''),
    nullif("raw_user_meta_data" ->> 'preferred_username', E''),
    nullif("raw_user_meta_data" ->> 'full_name', E''),
    nullif("raw_user_meta_data" ->> 'user_name', E''),
    split_part("email", '@', 1)
  )
  into "v_display_name"
  from "auth"."users" "u"
  where "u"."id" = "v_user";

  insert into "public"."household_members" ("household_id", "user_id", "display_name")
  values ("v_invite"."household_id", "v_user", "v_display_name");

  update "public"."household_invites"
     set "accepted_by" = "v_user",
         "accepted_at" = "now"()
   where "token" = "p_token";

  return jsonb_build_object(
    'household_id', "v_invite"."household_id",
    'name', "v_invite"."name",
    'display_name', "v_display_name"
  );
end;
$$;

revoke execute on function "public"."join_household"(uuid) from public, anon;
grant execute on function "public"."join_household"(uuid) to "authenticated";

-- ---------------------------------------------------------- Preview

-- The `/join/<token>` screen reads this before its visitor has any identity that
-- matches the Household: `anon` has no policy on `household_invites`, and the
-- row a signed-out browser must see is a row its own RLS would never show.
-- This is the definer that admits the door (ADR-0014).
create function "public"."preview_invitation"("p_token" uuid)
returns jsonb
language 'plpgsql'
security definer
set search_path = 'pg_catalog'
as $$
declare
  v_invite record;
begin
  select "i"."household_id", "i"."expires_at", "i"."accepted_at", "h"."name"
    into "v_invite"
  from "public"."household_invites" "i"
  join "public"."households" "h" on "h"."id" = "i"."household_id"
  where "i"."token" = "p_token";

  if not found then
    return jsonb_build_object('state', 'missing');
  end if;

  return jsonb_build_object(
    'state', case
      when "v_invite"."accepted_at" is not null then 'used'
      when "v_invite"."expires_at" <= "now"() then 'expired'
      else 'open'
    end,
    'name', "v_invite"."name",
    'expires_at', "v_invite"."expires_at",
    'members', (
      select coalesce(jsonb_agg("m"."display_name" order by "m"."display_name"), '[]'::jsonb)
      from "public"."household_members" "m"
      where "m"."household_id" = "v_invite"."household_id"
    )
  );
end;
$$;

revoke execute on function "public"."preview_invitation"(uuid) from public;
grant execute on function "public"."preview_invitation"(uuid) to "anon", "authenticated";
