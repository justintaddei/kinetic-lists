CREATE TABLE "public"."arrivals" (
  "household_id" uuid                     NOT NULL,
  "user_id"      uuid                     NOT NULL,
  "location_id"  uuid                     NOT NULL,
  "arrived_at"   timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT "arrivals_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT "arrivals_household_id_location_id_fkey" FOREIGN KEY (household_id, location_id) REFERENCES public.store_locations(household_id, id) ON DELETE CASCADE
);

ALTER TABLE "public"."arrivals"
  ENABLE ROW LEVEL SECURITY;

CREATE INDEX arrivals_arrived_at_idx ON public.arrivals USING btree (arrived_at);

CREATE INDEX arrivals_household_id_idx ON public.arrivals USING btree (household_id);

CREATE INDEX arrivals_location_id_idx ON public.arrivals USING btree (location_id);

CREATE POLICY "arrivals_read_by_member" ON "public"."arrivals"
  FOR SELECT
  TO "authenticated"
  USING (private.is_member(household_id));

CREATE POLICY "arrivals_record_own_by_member" ON "public"."arrivals"
  FOR INSERT
  TO "authenticated"
  WITH CHECK ((private.is_member(household_id) AND (user_id = ( SELECT auth.uid() AS uid))));

ALTER TABLE "public"."arrivals"
  ADD COLUMN "id" uuid NOT NULL DEFAULT public.uuidv7();

ALTER TABLE "public"."arrivals"
  ADD CONSTRAINT "arrivals_pkey" PRIMARY KEY (id);

REVOKE ALL ON TABLE "public"."arrivals" FROM "authenticated";

GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE ON TABLE "public"."arrivals" TO "authenticated";

REVOKE ALL ON TABLE "public"."arrivals" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."arrivals" TO "postgres";

REVOKE ALL ON TABLE "public"."arrivals" FROM "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."arrivals" TO "service_role";

REVOKE ALL ON TABLE "public"."arrivals" FROM "anon";
