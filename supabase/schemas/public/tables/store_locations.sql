CREATE TABLE "public"."store_locations" (
  "store_id"     uuid             NOT NULL,
  "household_id" uuid             NOT NULL,
  "lat"          double precision NOT NULL,
  "lng"          double precision NOT NULL,
  "geofence_m"   integer          NOT NULL DEFAULT 150,
  CONSTRAINT "store_locations_geofence_m_check" CHECK (((geofence_m > 0) AND (geofence_m <= 20000))),
  CONSTRAINT "store_locations_lat_check" CHECK (((lat >= ('-90'::integer)::double precision) AND (lat <= (90)::double precision))),
  CONSTRAINT "store_locations_lng_check" CHECK (((lng >= ('-180'::integer)::double precision) AND (lng <= (180)::double precision))),
  CONSTRAINT "store_locations_store_id_household_id_fkey" FOREIGN KEY (store_id, household_id) REFERENCES public.stores(household_id, id) ON DELETE CASCADE
);

ALTER TABLE "public"."store_locations"
  ENABLE ROW LEVEL SECURITY;

CREATE INDEX store_locations_store_id_household_id_idx ON public.store_locations USING btree (store_id, household_id);

CREATE POLICY "store_locations_create_by_member" ON "public"."store_locations"
  FOR INSERT
  TO "authenticated"
  WITH CHECK (private.is_member(household_id));

CREATE POLICY "store_locations_delete_by_member" ON "public"."store_locations"
  FOR DELETE
  TO "authenticated"
  USING (private.is_member(household_id));

CREATE POLICY "store_locations_read_by_member" ON "public"."store_locations"
  FOR SELECT
  TO "authenticated"
  USING (private.is_member(household_id));

CREATE POLICY "store_locations_update_position_by_member" ON "public"."store_locations"
  FOR UPDATE
  TO "authenticated"
  USING (private.is_member(household_id))
  WITH CHECK (private.is_member(household_id));

ALTER TABLE "public"."store_locations"
  ADD COLUMN "id" uuid NOT NULL DEFAULT public.uuidv7();

ALTER TABLE "public"."store_locations"
  ADD CONSTRAINT "store_locations_household_id_id_key" UNIQUE (household_id, id);

ALTER TABLE "public"."store_locations"
  ADD CONSTRAINT "store_locations_pkey" PRIMARY KEY (id);

ALTER TABLE "public"."store_locations"
  ADD CONSTRAINT "store_locations_store_id_id_key" UNIQUE (store_id, id);

CREATE TRIGGER store_locations_ownership_keys_are_immutable
  BEFORE UPDATE OF id, household_id, store_id ON public.store_locations
  FOR EACH ROW
  EXECUTE FUNCTION private.ownership_keys_are_immutable();

REVOKE ALL ON TABLE "public"."store_locations" FROM "authenticated";

GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE ON TABLE "public"."store_locations" TO "authenticated";

REVOKE ALL ON TABLE "public"."store_locations" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."store_locations" TO "postgres";

REVOKE ALL ON TABLE "public"."store_locations" FROM "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."store_locations" TO "service_role";

REVOKE ALL ON TABLE "public"."store_locations" FROM "anon";
