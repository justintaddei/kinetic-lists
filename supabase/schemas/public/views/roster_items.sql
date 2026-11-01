CREATE VIEW "public"."roster_items" WITH (security_invoker=on) AS  SELECT id,
    household_id,
    name,
    category,
    quantity,
    ( SELECT (count(*))::integer AS count
           FROM public.list_items li
          WHERE (li.item_id = i.id)) AS list_count,
    ( SELECT COALESCE(array_agg(s.name ORDER BY s.name), ARRAY[]::text[]) AS "coalesce"
           FROM (public.item_store_tags t
             JOIN public.stores s ON ((s.id = t.store_id)))
          WHERE (t.item_id = i.id)) AS store_names
   FROM public.items i;

REVOKE ALL ON TABLE "public"."roster_items" FROM "anon";

GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE ON TABLE "public"."roster_items" TO "anon";

REVOKE ALL ON TABLE "public"."roster_items" FROM "authenticated";

GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE ON TABLE "public"."roster_items" TO "authenticated";

REVOKE ALL ON TABLE "public"."roster_items" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."roster_items" TO "postgres";

REVOKE ALL ON TABLE "public"."roster_items" FROM "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."roster_items" TO "service_role";
