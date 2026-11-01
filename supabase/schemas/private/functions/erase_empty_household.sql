CREATE OR REPLACE FUNCTION private.erase_empty_household()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'pg_catalog'
  AS $function$
begin
  delete from "public"."households" "h"
  where "h"."id" = "old"."household_id"
    and not exists (
      select 1 from "public"."household_members" "m"
      where "m"."household_id" = "old"."household_id"
    );
  return null;
end;
$function$;

REVOKE ALL ON FUNCTION "private"."erase_empty_household"() FROM PUBLIC;
