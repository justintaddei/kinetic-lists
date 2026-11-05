create or replace function private.handle_new_auth_user()
  returns trigger
  language plpgsql
  security definer
  set search_path to 'pg_catalog'
  as $function$
declare
  v_display_name text;
  v_household uuid;
begin
  -- the name chain adr-0019 fixes: raw_user_meta_data->>'name', then
  -- preferred_username, full_name, user_name, then the email local part.
  -- identity_data is never read (adr-0019's warning about raw_app_meta_data).
  select coalesce(
    nullif("raw_user_meta_data" ->> 'name', e''),
    nullif("raw_user_meta_data" ->> 'preferred_username', e''),
    nullif("raw_user_meta_data" ->> 'full_name', e''),
    nullif("raw_user_meta_data" ->> 'user_name', e''),
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

grant execute on function "private"."handle_new_auth_user"() to "supabase_auth_admin";

revoke all on function "private"."handle_new_auth_user"() from public;

create trigger "on_auth_user_created"
  after insert on "auth"."users"
  for each row
  execute function "private"."handle_new_auth_user"();
