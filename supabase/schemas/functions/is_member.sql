create or replace function private.is_member (
  p_household_id uuid
)
  returns boolean
  language plpgsql
  stable
  security definer
  set search_path to 'pg_catalog'
  as $function$
begin
  return exists (
    select 1
    from "public"."household_members" "m"
    where "m"."household_id" = "p_household_id"
      and "m"."user_id" = (select "auth"."uid"())
  );
end;
$function$;

grant execute on function "private"."is_member"(uuid) to "authenticated";

revoke all on function "private"."is_member"(uuid) from public;
