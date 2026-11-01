CREATE OR REPLACE FUNCTION public.uuidv7()
  RETURNS uuid
  LANGUAGE sql
  SET search_path TO 'pg_catalog'
  AS $function$
  with "s" as (
    select
      floor(extract(epoch from clock_timestamp()) * 1000)::bigint as "ms",
      replace(gen_random_uuid()::text, '-', E'') as "r"
  )
  select
    (
      right('000000000000' || to_hex("s"."ms"), 12) ||
      '7' ||
      substr("s"."r", 14, 3) ||
      substr('89ab', ((position(substr("s"."r", 17, 1) in '0123456789abcdef') - 1) % 4) + 1, 1) ||
      substr("s"."r", 18, 15)
    )::"pg_catalog"."uuid"
  from "s"
$function$;

GRANT EXECUTE ON FUNCTION "public"."uuidv7"() TO "authenticated";

GRANT EXECUTE ON FUNCTION "public"."uuidv7"() TO "service_role";

COMMENT ON FUNCTION "public"."uuidv7"() IS 'UUIDv7 from the server clock (RFC 9562): the id default of every household-owned row.';

REVOKE ALL ON FUNCTION "public"."uuidv7"() FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."uuidv7"() TO "postgres";

REVOKE ALL ON FUNCTION "public"."uuidv7"() FROM PUBLIC, "anon";
