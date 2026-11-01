CREATE TABLE "public"."households" (
  "name" text NOT NULL DEFAULT 'My Household'::text
);

ALTER TABLE "public"."households"
  ENABLE ROW LEVEL SECURITY;

ALTER TABLE "public"."households"
  ADD COLUMN "id" uuid NOT NULL DEFAULT public.uuidv7();

ALTER TABLE "public"."households"
  ADD CONSTRAINT "households_pkey" PRIMARY KEY (id);

CREATE TRIGGER households_ownership_keys_are_immutable
  BEFORE UPDATE OF id ON public.households
  FOR EACH ROW
  EXECUTE FUNCTION private.ownership_keys_are_immutable();

CREATE POLICY "households_read_by_member" ON "public"."households"
  FOR SELECT
  TO "authenticated"
  USING (private.is_member(id));

CREATE POLICY "households_rename_by_member" ON "public"."households"
  FOR UPDATE
  TO "authenticated"
  USING (private.is_member(id))
  WITH CHECK (private.is_member(id));

REVOKE ALL ON TABLE "public"."households" FROM "authenticated";

GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE ON TABLE "public"."households" TO "authenticated";

REVOKE ALL ON TABLE "public"."households" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."households" TO "postgres";

REVOKE ALL ON TABLE "public"."households" FROM "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."households" TO "service_role";

REVOKE ALL ON TABLE "public"."households" FROM "anon";
