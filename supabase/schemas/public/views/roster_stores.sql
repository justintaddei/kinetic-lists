CREATE VIEW "public"."roster_stores" WITH (security_invoker=on) AS  SELECT id,
    household_id,
    name,
    ( SELECT (count(*))::integer AS count
           FROM public.store_locations l
          WHERE (l.store_id = s.id)) AS location_count,
    ( SELECT (count(*))::integer AS count
           FROM public.item_store_tags t
          WHERE (t.store_id = s.id)) AS tag_count
   FROM public.stores s;

REVOKE ALL ON TABLE "public"."roster_stores" FROM "anon";

GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE ON TABLE "public"."roster_stores" TO "anon";

REVOKE ALL ON TABLE "public"."roster_stores" FROM "authenticated";

GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE ON TABLE "public"."roster_stores" TO "authenticated";

REVOKE ALL ON TABLE "public"."roster_stores" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."roster_stores" TO "postgres";

REVOKE ALL ON TABLE "public"."roster_stores" FROM "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."roster_stores" TO "service_role";
