CREATE OR REPLACE FUNCTION private.handle_new_user()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'pg_catalog'
  AS $function$
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
$function$;

GRANT EXECUTE ON FUNCTION "private"."handle_new_user"() TO "supabase_auth_admin";

REVOKE ALL ON FUNCTION "private"."handle_new_user"() FROM PUBLIC;
