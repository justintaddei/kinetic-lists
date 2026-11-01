CREATE TABLE "public"."list_items" (
  "list_id"      uuid                     NOT NULL,
  "item_id"      uuid                     NOT NULL,
  "household_id" uuid                     NOT NULL,
  "status"       text                     NOT NULL DEFAULT 'needed'::text,
  "stocked_at"   timestamp with time zone,
  CONSTRAINT "list_items_list_id_item_id_key" UNIQUE (list_id, item_id),
  CONSTRAINT "list_items_status_check" CHECK ((status = ANY (ARRAY['needed'::text, 'in_basket'::text, 'stocked'::text]))),
  CONSTRAINT "list_items_item_id_household_id_fkey" FOREIGN KEY (household_id, item_id) REFERENCES public.items(household_id, id) ON DELETE CASCADE,
  CONSTRAINT "list_items_list_id_household_id_fkey" FOREIGN KEY (household_id, list_id) REFERENCES public.lists(household_id, id) ON DELETE CASCADE
);

ALTER TABLE "public"."list_items"
  ENABLE ROW LEVEL SECURITY;

CREATE INDEX list_items_household_id_list_id_idx ON public.list_items USING btree (household_id, list_id);

CREATE INDEX list_items_household_id_status_idx ON public.list_items USING btree (household_id, status);

CREATE INDEX list_items_item_id_idx ON public.list_items USING btree (item_id);

CREATE POLICY "list_items_add_by_member" ON "public"."list_items"
  FOR INSERT
  TO "authenticated"
  WITH CHECK ((private.is_member(household_id) AND (status = ANY (ARRAY['needed'::text, 'in_basket'::text]))));

CREATE POLICY "list_items_move_status_by_member" ON "public"."list_items"
  FOR UPDATE
  TO "authenticated"
  USING (private.is_member(household_id))
  WITH CHECK ((private.is_member(household_id) AND (status = ANY (ARRAY['needed'::text, 'in_basket'::text]))));

CREATE POLICY "list_items_read_by_member" ON "public"."list_items"
  FOR SELECT
  TO "authenticated"
  USING (private.is_member(household_id));

ALTER TABLE "public"."list_items"
  ADD COLUMN "id" uuid NOT NULL DEFAULT public.uuidv7();

ALTER TABLE "public"."list_items"
  ADD CONSTRAINT "list_items_household_id_id_key" UNIQUE (household_id, id);

ALTER TABLE "public"."list_items"
  ADD CONSTRAINT "list_items_id_item_id_key" UNIQUE (id, item_id);

ALTER TABLE "public"."list_items"
  ADD CONSTRAINT "list_items_pkey" PRIMARY KEY (id);

CREATE TRIGGER list_items_ownership_keys_are_immutable
  BEFORE UPDATE OF id, household_id, list_id, item_id ON public.list_items
  FOR EACH ROW
  EXECUTE FUNCTION private.ownership_keys_are_immutable();

REVOKE ALL ON TABLE "public"."list_items" FROM "authenticated";

GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE ON TABLE "public"."list_items" TO "authenticated";

REVOKE ALL ON TABLE "public"."list_items" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."list_items" TO "postgres";

REVOKE ALL ON TABLE "public"."list_items" FROM "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."list_items" TO "service_role";

REVOKE ALL ON TABLE "public"."list_items" FROM "anon";
