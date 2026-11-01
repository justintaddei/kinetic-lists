CREATE OR REPLACE FUNCTION private.ownership_keys_are_immutable()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'pg_catalog'
  AS $function$
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
$function$;

REVOKE ALL ON FUNCTION "private"."ownership_keys_are_immutable"() FROM PUBLIC;
