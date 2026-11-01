CREATE OR REPLACE FUNCTION public.join_household (
  p_token uuid
)
  RETURNS jsonb
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'pg_catalog'
  AS $function$
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
$function$;

GRANT EXECUTE ON FUNCTION "public"."join_household"(uuid) TO "authenticated";

REVOKE ALL ON FUNCTION "public"."join_household"(uuid) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."join_household"(uuid) TO "postgres";

REVOKE ALL ON FUNCTION "public"."join_household"(uuid) FROM PUBLIC, "anon", "service_role";
