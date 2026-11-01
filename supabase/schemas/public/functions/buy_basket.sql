CREATE OR REPLACE FUNCTION public.buy_basket (
  p_store_id      uuid,
  p_location_id   uuid,
  p_sold_at       date,
  p_session_token text
)
  RETURNS jsonb
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'pg_catalog'
  AS $function$
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
$function$;

GRANT EXECUTE ON FUNCTION "public"."buy_basket"(uuid, uuid, date, text) TO "authenticated";

REVOKE ALL ON FUNCTION "public"."buy_basket"(uuid, uuid, date, text) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."buy_basket"(uuid, uuid, date, text) TO "postgres";

REVOKE ALL ON FUNCTION "public"."buy_basket"(uuid, uuid, date, text) FROM PUBLIC, "anon", "service_role";
