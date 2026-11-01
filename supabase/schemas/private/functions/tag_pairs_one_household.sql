CREATE OR REPLACE FUNCTION private.tag_pairs_one_household()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'pg_catalog'
  AS $function$
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
$function$;

REVOKE ALL ON FUNCTION "private"."tag_pairs_one_household"() FROM PUBLIC;
