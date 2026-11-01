CREATE TABLE "public"."items" (
  "household_id" uuid NOT NULL,
  "name"         text NOT NULL,
  "category"     text,
  "quantity"     text,
  CONSTRAINT "items_household_id_fkey" FOREIGN KEY (household_id) REFERENCES public.households(id) ON DELETE CASCADE
);

ALTER TABLE "public"."items"
  ENABLE ROW LEVEL SECURITY;

CREATE UNIQUE INDEX items_name_household_idx ON public.items USING btree (household_id, lower(btrim(name)));

CREATE POLICY "items_create_by_member" ON "public"."items"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (private.is_member(household_id));

CREATE POLICY "items_delete_by_member" ON "public"."items"
  FOR DELETE
  TO "authenticated"
  USING (private.is_member(household_id));

CREATE POLICY "items_read_by_member" ON "public"."items"
  FOR SELECT
  TO "authenticated"
  USING (private.is_member(household_id));

CREATE POLICY "items_update_by_member" ON "public"."items"
  FOR UPDATE
  TO "authenticated"
  USING (private.is_member(household_id))
  WITH CHECK (private.is_member(household_id));

ALTER TABLE "public"."items"
  ADD COLUMN "id" uuid NOT NULL DEFAULT public.uuidv7();

ALTER TABLE "public"."items"
  ADD CONSTRAINT "items_household_id_id_key" UNIQUE (household_id, id);

ALTER TABLE "public"."items"
  ADD CONSTRAINT "items_pkey" PRIMARY KEY (id);

CREATE TRIGGER items_ownership_keys_are_immutable
  BEFORE UPDATE OF id, household_id ON public.items
  FOR EACH ROW
  EXECUTE FUNCTION private.ownership_keys_are_immutable();

REVOKE ALL ON TABLE "public"."items" FROM "authenticated";

GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE ON TABLE "public"."items" TO "authenticated";

REVOKE ALL ON TABLE "public"."items" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."items" TO "postgres";

REVOKE ALL ON TABLE "public"."items" FROM "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."items" TO "service_role";

REVOKE ALL ON TABLE "public"."items" FROM "anon";
