CREATE OR REPLACE FUNCTION public.preview_invitation (
  p_token uuid
)
  RETURNS jsonb
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'pg_catalog'
  AS $function$
declare
  v_invite record;
begin
  select "i"."household_id", "i"."expires_at", "i"."accepted_at", "h"."name"
    into "v_invite"
  from "public"."household_invites" "i"
  join "public"."households" "h" on "h"."id" = "i"."household_id"
  where "i"."token" = "p_token";

  if not found then
    return jsonb_build_object('state', 'missing');
  end if;

  return jsonb_build_object(
    'state', case
      when "v_invite"."accepted_at" is not null then 'used'
      when "v_invite"."expires_at" <= "now"() then 'expired'
      else 'open'
    end,
    'name', "v_invite"."name",
    'expires_at', "v_invite"."expires_at",
    'members', (
      select coalesce(jsonb_agg("m"."display_name" order by "m"."display_name"), '[]'::jsonb)
      from "public"."household_members" "m"
      where "m"."household_id" = "v_invite"."household_id"
    )
  );
end;
$function$;

GRANT EXECUTE ON FUNCTION "public"."preview_invitation"(uuid) TO "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."preview_invitation"(uuid) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."preview_invitation"(uuid) TO "postgres";

REVOKE ALL ON FUNCTION "public"."preview_invitation"(uuid) FROM PUBLIC, "service_role";
