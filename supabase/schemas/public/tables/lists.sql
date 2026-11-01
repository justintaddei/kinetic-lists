CREATE TABLE "public"."lists" (
  "household_id" uuid NOT NULL,
  "name"         text NOT NULL,
  CONSTRAINT "lists_household_id_fkey" FOREIGN KEY (household_id) REFERENCES public.households(id) ON DELETE CASCADE
);

ALTER TABLE "public"."lists"
  ENABLE ROW LEVEL SECURITY;

CREATE POLICY "lists_create_by_member" ON "public"."lists"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (private.is_member(household_id));

CREATE POLICY "lists_read_by_member" ON "public"."lists"
  FOR SELECT
  TO "authenticated"
  USING (private.is_member(household_id));

CREATE POLICY "lists_rename_by_member" ON "public"."lists"
  FOR UPDATE
  TO "authenticated"
  USING (private.is_member(household_id))
  WITH CHECK (private.is_member(household_id));

ALTER TABLE "public"."lists"
  ADD COLUMN "id" uuid NOT NULL DEFAULT public.uuidv7();

ALTER TABLE "public"."lists"
  ADD CONSTRAINT "lists_household_id_id_key" UNIQUE (household_id, id);

ALTER TABLE "public"."lists"
  ADD CONSTRAINT "lists_pkey" PRIMARY KEY (id);

CREATE TRIGGER lists_ownership_keys_are_immutable
  BEFORE UPDATE OF id, household_id ON public.lists
  FOR EACH ROW
  EXECUTE FUNCTION private.ownership_keys_are_immutable();

REVOKE ALL ON TABLE "public"."lists" FROM "authenticated";

GRANT INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."lists" TO "authenticated";

REVOKE ALL ON TABLE "public"."lists" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."lists" TO "postgres";

REVOKE ALL ON TABLE "public"."lists" FROM "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."lists" TO "service_role";

REVOKE ALL ON TABLE "public"."lists" FROM "anon";
