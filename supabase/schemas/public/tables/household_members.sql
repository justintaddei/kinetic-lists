CREATE TABLE "public"."household_members" (
  "household_id" uuid NOT NULL,
  "user_id"      uuid NOT NULL,
  "display_name" text NOT NULL,
  CONSTRAINT "household_members_pkey" PRIMARY KEY (household_id, user_id),
  CONSTRAINT "household_members_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT "household_members_user_id_key" UNIQUE (user_id),
  CONSTRAINT "household_members_household_id_fkey" FOREIGN KEY (household_id) REFERENCES public.households(id) ON DELETE CASCADE
);

ALTER TABLE "public"."household_members"
  ENABLE ROW LEVEL SECURITY;

CREATE TRIGGER household_members_erase_household
  AFTER DELETE ON public.household_members
  FOR EACH ROW
  EXECUTE FUNCTION private.erase_empty_household();

CREATE TRIGGER household_members_ownership_keys_are_immutable
  BEFORE UPDATE OF household_id, user_id ON public.household_members
  FOR EACH ROW
  EXECUTE FUNCTION private.ownership_keys_are_immutable();

CREATE POLICY "household_members_read_by_member" ON "public"."household_members"
  FOR SELECT
  TO "authenticated"
  USING (private.is_member(household_id));

CREATE POLICY "household_members_rename_self" ON "public"."household_members"
  FOR UPDATE
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = user_id))
  WITH CHECK ((( SELECT auth.uid() AS uid) = user_id));

REVOKE ALL ON TABLE "public"."household_members" FROM "authenticated";

GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."household_members" TO "authenticated";

REVOKE ALL ON TABLE "public"."household_members" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."household_members" TO "postgres";

REVOKE ALL ON TABLE "public"."household_members" FROM "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."household_members" TO "service_role";

REVOKE ALL ON TABLE "public"."household_members" FROM "anon";
