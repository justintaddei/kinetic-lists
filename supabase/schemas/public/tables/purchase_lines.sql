CREATE TABLE "public"."purchase_lines" (
  "purchase_id"  uuid NOT NULL,
  "household_id" uuid NOT NULL,
  "item_id"      uuid NOT NULL,
  "store_id"     uuid NOT NULL,
  "list_item_id" uuid NOT NULL,
  CONSTRAINT "purchase_lines_list_item_id_item_id_key" UNIQUE (list_item_id, item_id),
  CONSTRAINT "purchase_lines_household_id_item_id_fkey" FOREIGN KEY (household_id, item_id) REFERENCES public.items(household_id, id) ON DELETE CASCADE,
  CONSTRAINT "purchase_lines_household_id_list_item_id_fkey" FOREIGN KEY (household_id, list_item_id) REFERENCES public.list_items(household_id, id) ON DELETE CASCADE,
  CONSTRAINT "purchase_lines_purchase_id_store_id_fkey" FOREIGN KEY (purchase_id, store_id) REFERENCES public.purchases(id, store_id) ON DELETE CASCADE
);

ALTER TABLE "public"."purchase_lines"
  ENABLE ROW LEVEL SECURITY;

CREATE INDEX purchase_lines_household_id_list_item_id_idx ON public.purchase_lines USING btree (household_id, list_item_id);

CREATE INDEX purchase_lines_item_id_idx ON public.purchase_lines USING btree (item_id);

CREATE INDEX purchase_lines_list_item_id_idx ON public.purchase_lines USING btree (list_item_id);

CREATE INDEX purchase_lines_purchase_id_idx ON public.purchase_lines USING btree (purchase_id);

CREATE INDEX purchase_lines_store_id_idx ON public.purchase_lines USING btree (store_id);

CREATE TRIGGER purchase_lines_erase_purchase
  AFTER DELETE ON public.purchase_lines
  FOR EACH ROW
  EXECUTE FUNCTION private.erase_lineless_purchase();

CREATE POLICY "purchase_lines_append_only" ON "public"."purchase_lines"
  FOR ALL
  TO "authenticated"
  USING (false)
  WITH CHECK (false);

ALTER TABLE "public"."purchase_lines"
  ADD COLUMN "id" uuid NOT NULL DEFAULT public.uuidv7();

ALTER TABLE "public"."purchase_lines"
  ADD CONSTRAINT "purchase_lines_pkey" PRIMARY KEY (id);

REVOKE ALL ON TABLE "public"."purchase_lines" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."purchase_lines" TO "postgres";

REVOKE ALL ON TABLE "public"."purchase_lines" FROM "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."purchase_lines" TO "service_role";

REVOKE ALL ON TABLE "public"."purchase_lines" FROM "anon", "authenticated";
