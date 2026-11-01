CREATE OR REPLACE FUNCTION private.is_member (
  p_household_id uuid
)
  RETURNS boolean
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
  SET search_path TO 'pg_catalog'
  AS $function$
begin
  return exists (
    select 1
    from "public"."household_members" "m"
    where "m"."household_id" = "p_household_id"
      and "m"."user_id" = (select "auth"."uid"())
  );
end;
$function$;

GRANT EXECUTE ON FUNCTION "private"."is_member"(uuid) TO "authenticated";

REVOKE ALL ON FUNCTION "private"."is_member"(uuid) FROM PUBLIC;
