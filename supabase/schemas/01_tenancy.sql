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
      replace(gen_random_uuid()::text, '-', '') as "r"
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
set search_path = ''
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
set search_path = ''
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
set search_path = ''
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
set search_path = ''
as $$
declare
  v_display_name text;
  v_household uuid;
begin
  -- The name chain ADR-0019 fixes: raw_user_meta_data->>'name', then
  -- preferred_username, full_name, user_name, then the email local part.
  -- identity_data is never read (ADR-0019's warning about raw_app_meta_data).
  select coalesce(
    nullif("raw_user_meta_data" ->> 'name', ''),
    nullif("raw_user_meta_data" ->> 'preferred_username', ''),
    nullif("raw_user_meta_data" ->> 'full_name', ''),
    nullif("raw_user_meta_data" ->> 'user_name', ''),
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
