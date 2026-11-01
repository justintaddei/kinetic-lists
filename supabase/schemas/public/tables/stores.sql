CREATE TABLE "public"."stores" (
  "household_id" uuid NOT NULL,
  "name"         text NOT NULL,
  CONSTRAINT "stores_household_id_fkey" FOREIGN KEY (household_id) REFERENCES public.households(id) ON DELETE CASCADE
);

ALTER TABLE "public"."stores"
  ENABLE ROW LEVEL SECURITY;

CREATE UNIQUE INDEX stores_name_household_idx ON public.stores USING btree (household_id, lower(btrim(name)));

CREATE POLICY "stores_create_by_member" ON "public"."stores"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (private.is_member(household_id));

CREATE POLICY "stores_delete_by_member" ON "public"."stores"
  FOR DELETE
  TO "authenticated"
  USING (private.is_member(household_id));

CREATE POLICY "stores_read_by_member" ON "public"."stores"
  FOR SELECT
  TO "authenticated"
  USING (private.is_member(household_id));

CREATE POLICY "stores_rename_by_member" ON "public"."stores"
  FOR UPDATE
  TO "authenticated"
  USING (private.is_member(household_id))
  WITH CHECK (private.is_member(household_id));

ALTER TABLE "public"."stores"
  ADD COLUMN "id" uuid NOT NULL DEFAULT public.uuidv7();

ALTER TABLE "public"."stores"
  ADD CONSTRAINT "stores_household_id_id_key" UNIQUE (household_id, id);

ALTER TABLE "public"."stores"
  ADD CONSTRAINT "stores_pkey" PRIMARY KEY (id);

CREATE TRIGGER stores_ownership_keys_are_immutable
  BEFORE UPDATE OF id, household_id ON public.stores
  FOR EACH ROW
  EXECUTE FUNCTION private.ownership_keys_are_immutable();

REVOKE ALL ON TABLE "public"."stores" FROM "authenticated";

GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE ON TABLE "public"."stores" TO "authenticated";

REVOKE ALL ON TABLE "public"."stores" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."stores" TO "postgres";

REVOKE ALL ON TABLE "public"."stores" FROM "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."stores" TO "service_role";

REVOKE ALL ON TABLE "public"."stores" FROM "anon";
