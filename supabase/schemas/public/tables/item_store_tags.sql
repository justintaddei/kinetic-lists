CREATE TABLE "public"."item_store_tags" (
  "item_id"    uuid                     NOT NULL,
  "store_id"   uuid                     NOT NULL,
  "created_by" uuid                     NOT NULL,
  "created_at" timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "item_store_tags_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT "item_store_tags_pkey" PRIMARY KEY (item_id, store_id),
  CONSTRAINT "item_store_tags_item_id_fkey" FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE,
  CONSTRAINT "item_store_tags_store_id_fkey" FOREIGN KEY (store_id) REFERENCES public.stores(id) ON DELETE CASCADE
);

ALTER TABLE "public"."item_store_tags"
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."item_store_tags"
  REPLICA IDENTITY FULL;

CREATE INDEX item_store_tags_created_by_idx ON public.item_store_tags USING btree (created_by);

CREATE INDEX item_store_tags_store_id_idx ON public.item_store_tags USING btree (store_id);

CREATE TRIGGER item_store_tags_pair_one_household
  BEFORE INSERT OR UPDATE OF item_id, store_id ON public.item_store_tags
  FOR EACH ROW
  EXECUTE FUNCTION private.tag_pairs_one_household();

CREATE POLICY "item_store_tags_read_by_member" ON "public"."item_store_tags"
  FOR SELECT
  TO "authenticated"
  USING ((EXISTS ( SELECT 1
   FROM public.stores s
  WHERE ((s.id = item_store_tags.store_id) AND private.is_member(s.household_id)))));

CREATE POLICY "item_store_tags_tag_by_member" ON "public"."item_store_tags"
  FOR INSERT
  TO "authenticated"
  WITH CHECK ((EXISTS ( SELECT 1
   FROM public.stores s
  WHERE ((s.id = item_store_tags.store_id) AND private.is_member(s.household_id)))));

CREATE POLICY "item_store_tags_untag_by_member" ON "public"."item_store_tags"
  FOR DELETE
  TO "authenticated"
  USING ((EXISTS ( SELECT 1
   FROM public.stores s
  WHERE ((s.id = item_store_tags.store_id) AND private.is_member(s.household_id)))));

REVOKE ALL ON TABLE "public"."item_store_tags" FROM "authenticated";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE ON TABLE "public"."item_store_tags" TO "authenticated";

REVOKE ALL ON TABLE "public"."item_store_tags" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."item_store_tags" TO "postgres";

REVOKE ALL ON TABLE "public"."item_store_tags" FROM "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."item_store_tags" TO "service_role";

REVOKE ALL ON TABLE "public"."item_store_tags" FROM "anon";
