-- #4 (2/2) - the grant that makes the policies reachable, and the vocabulary the baseline missed.
--
-- THE FINDING, measured on hosted 2026-11-03 (PR #25's review): `authenticated` holds
-- `references, select, trigger, truncate` on every one of the twelve tables and **no `insert`, `update`
-- or `delete` anywhere**. RLS decides which rows a verb may touch; it never confers the verb. A policy
-- without its grant is a row filter on a table the role cannot write: every Capture, Check, Need, Mint,
-- Rename, Tag, Record, Revoke, Join write answers `42501` permission denied. Buy survives it only
-- because `buy_basket` is `security definer`, running as its owner - the one path the grant gap
-- cannot show. This migration grants the verbs, one line per table, from the policies as shipped:
--
--   households         read + rename        -> update
--   household_members  read + rename self   -> update
--   household_invites  read + mint + revoke -> insert, delete
--   stores             read + create + rename + delete
--   store_locations    read + create + update position + delete
--   lists              read + create + rename                -> insert, update
--   items              read + create + update + delete
--   list_items         read + add + move status               -> insert, update (no delete: #20, ADR-0022)
--   item_store_tags    tag + untag                          -> insert, delete
--   arrivals           read + record own                    -> insert
--   purchases, purchase_lines - append-only, `using (false)`: no grant, and none appears here.
--
-- SELECT is already granted by the baseline (`20261101000000_...:371, :484, :711, :881`), TRUNCATE /
-- REFERENCES / TRIGGER / MAINTAIN come from `public/default_privileges.sql`, so only the three DML
-- verbs are new. `anon` stays what the posture says it is: REVOKE.
--
-- THE SECOND FINDING: the baseline names three things with words the Glossary bans. `household_invites`
-- has `accepted_by`/`accepted_at` while **Join** bans *accept* (GLOSSARY:16); the Invitation-minting
-- policy is `household_invites_mint_by_member` while **Mint** is the act of creating a **Store**
-- (GLOSSARY:44); the roster views grant `select` to `anon` while the register's posture is that a
-- signed-out app is blind (#3's grill answer: anon's reach is the **Preview** call only - the views are
-- `security invoker`, so anon's read on them errors today, and this revoke makes the ACL say what the
-- posture means). Renames are a migration, not an edit: the two RPCs whose bodies name the old columns
-- are re-created here from the generated tree's own text (`supabase/schemas/public/functions/`), so no
-- function is left naming a column that no longer exists - in the declarative tree, in the database,
-- and in `app/types/database.types.ts`, which regenerates after the push.
--
-- WHY A SECOND MIGRATION. `20261101000000` is applied: hosted's
-- `supabase_migrations.schema_migrations` carries it, and an applied version never runs again. The
-- baseline file stays exactly as applied (history is the record of what ran, not a draft), so the fix
-- appends. Minted by hand for the same measured reason as the baseline - the shadow stack's Docker
-- engine answers `500 Internal Server Error` on `npipe:////./pipe/dockerDesktopLinuxEngine`, so
-- `sync --no-apply` cannot run here (advisors.md, "the minting fallback").


-- The verbs the policies open (measured grantee: `authenticated`).
grant update on "public"."households" to "authenticated";
grant update on "public"."household_members" to "authenticated";
grant insert, delete on "public"."household_invites" to "authenticated";
grant insert, update, delete on "public"."stores" to "authenticated";
grant insert, update, delete on "public"."store_locations" to "authenticated";
grant insert, update on "public"."lists" to "authenticated";
grant insert, update, delete on "public"."items" to "authenticated";
grant insert, update on "public"."list_items" to "authenticated";
grant insert, delete on "public"."item_store_tags" to "authenticated";
grant insert on "public"."arrivals" to "authenticated";

-- `anon` reads nothing, in the ACL as well as in the posture.
revoke select on "public"."roster_stores", "public"."roster_items" from "anon";

-- The Join vocabulary, on the table the Invitation lives on.
alter table "public"."household_invites"
  rename constraint "household_invites_accepted_by_fkey" to "household_invites_joined_by_fkey";
alter table "public"."household_invites" rename column "accepted_at" to "joined_at";
alter table "public"."household_invites" rename column "accepted_by" to "joined_by";
alter index "household_invites_accepted_by_idx" rename to "household_invites_joined_by_idx";
alter policy "household_invites_mint_by_member"
  on "public"."household_invites" rename to "household_invites_create_by_member";

-- The RPCs that name those columns, re-created from the tree's text.

CREATE OR REPLACE FUNCTION public.join_household (
  p_token uuid
)
  RETURNS jsonb
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'pg_catalog'
  AS $function$
declare
  v_user uuid := (select "auth"."uid"());
  v_invite record;
  v_home record;
  v_display_name text;
begin
  if "v_user" is null then
    raise exception 'Joining needs a signed-in user' using errcode = '28000';
  end if;

  select "i"."household_id", "i"."expires_at", "i"."joined_at", "h"."name"
    into "v_invite"
  from "public"."household_invites" "i"
  join "public"."households" "h" on "h"."id" = "i"."household_id"
  where "i"."token" = "p_token";

  if not found then
    raise exception 'This invitation does not exist';
  end if;

  if "v_invite"."joined_at" is not null then
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
     set "joined_by" = "v_user",
         "joined_at" = "now"()
   where "token" = "p_token";

  return jsonb_build_object(
    'household_id', "v_invite"."household_id",
    'name', "v_invite"."name",
    'display_name', "v_display_name"
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.preview_invitation (
  p_token uuid
)
  RETURNS jsonb
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'pg_catalog'
  AS $function$
declare
  v_invite record;
begin
  select "i"."household_id", "i"."expires_at", "i"."joined_at", "h"."name"
    into "v_invite"
  from "public"."household_invites" "i"
  join "public"."households" "h" on "h"."id" = "i"."household_id"
  where "i"."token" = "p_token";

  if not found then
    return jsonb_build_object('state', 'missing');
  end if;

  return jsonb_build_object(
    'state', case
      when "v_invite"."joined_at" is not null then 'used'
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
$function$;


-- A strict prefix of `purchase_lines_list_item_id_item_id_key`, and covered for the cascade by
-- `purchase_lines_household_id_list_item_id_idx` (advisor `0005`: unused index).
drop index "public"."purchase_lines_list_item_id_idx";

