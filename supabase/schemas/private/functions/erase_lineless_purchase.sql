CREATE OR REPLACE FUNCTION private.erase_lineless_purchase()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'pg_catalog'
  AS $function$
begin
  delete from "public"."purchases" "p"
  where "p"."id" = "old"."purchase_id"
    and not exists (
      select 1 from "public"."purchase_lines" "l"
      where "l"."purchase_id" = "old"."purchase_id"
    );
  return null;
end;
$function$;

REVOKE ALL ON FUNCTION "private"."erase_lineless_purchase"() FROM PUBLIC;
