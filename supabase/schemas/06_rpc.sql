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

  if "v_household" is null or not ("select "private"."is_member"("v_household")) then
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

    get diagnostics "v_claimed" = "row_count";

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
