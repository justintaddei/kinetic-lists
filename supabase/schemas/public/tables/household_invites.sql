CREATE TABLE "public"."household_invites" (
  "token"        uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "household_id" uuid                     NOT NULL,
  "created_by"   uuid                     NOT NULL,
  "created_at"   timestamp with time zone NOT NULL DEFAULT now(),
  "expires_at"   timestamp with time zone NOT NULL DEFAULT (now() + '7 days'::interval),
  "accepted_by"  uuid,
  "accepted_at"  timestamp with time zone,
  CONSTRAINT "household_invites_accepted_by_fkey" FOREIGN KEY (accepted_by) REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT "household_invites_created_by_fkey" FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT "household_invites_pkey" PRIMARY KEY (token),
  CONSTRAINT "household_invites_household_id_fkey" FOREIGN KEY (household_id) REFERENCES public.households(id) ON DELETE CASCADE
);

ALTER TABLE "public"."household_invites"
  ENABLE ROW LEVEL SECURITY;

CREATE INDEX household_invites_accepted_by_idx ON public.household_invites USING btree (accepted_by);

CREATE INDEX household_invites_created_by_idx ON public.household_invites USING btree (created_by);

CREATE INDEX household_invites_household_id_idx ON public.household_invites USING btree (household_id);

CREATE POLICY "household_invites_mint_by_member" ON "public"."household_invites"
  FOR INSERT
  TO "authenticated"
  WITH CHECK ((private.is_member(household_id) AND (created_by = ( SELECT auth.uid() AS uid))));

CREATE POLICY "household_invites_read_by_member" ON "public"."household_invites"
  FOR SELECT
  TO "authenticated"
  USING (private.is_member(household_id));

CREATE POLICY "household_invites_revoke_by_member" ON "public"."household_invites"
  FOR DELETE
  TO "authenticated"
  USING (private.is_member(household_id));

REVOKE ALL ON TABLE "public"."household_invites" FROM "authenticated";

GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE ON TABLE "public"."household_invites" TO "authenticated";

REVOKE ALL ON TABLE "public"."household_invites" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."household_invites" TO "postgres";

REVOKE ALL ON TABLE "public"."household_invites" FROM "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."household_invites" TO "service_role";

REVOKE ALL ON TABLE "public"."household_invites" FROM "anon";
