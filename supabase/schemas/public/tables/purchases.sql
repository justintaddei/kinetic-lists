CREATE TABLE "public"."purchases" (
  "household_id"  uuid                     NOT NULL,
  "store_id"      uuid                     NOT NULL,
  "location_id"   uuid,
  "bought_by"     uuid                     NOT NULL,
  "bought_at"     timestamp with time zone NOT NULL,
  "sold_at"       date                     NOT NULL,
  "session_token" text                     NOT NULL,
  CONSTRAINT "purchases_bought_by_fkey" FOREIGN KEY (bought_by) REFERENCES auth.users(id) ON DELETE CASCADE,
  CONSTRAINT "purchases_household_id_session_token_key" UNIQUE (household_id, session_token),
  CONSTRAINT "purchases_household_id_fkey" FOREIGN KEY (household_id) REFERENCES public.households(id) ON DELETE CASCADE,
  CONSTRAINT "purchases_household_id_location_id_fkey" FOREIGN KEY (household_id, location_id) REFERENCES public.store_locations(household_id, id) ON DELETE CASCADE,
  CONSTRAINT "purchases_household_id_store_id_fkey" FOREIGN KEY (household_id, store_id) REFERENCES public.stores(household_id, id) ON DELETE CASCADE
);

ALTER TABLE "public"."purchases"
  ENABLE ROW LEVEL SECURITY;

CREATE INDEX purchases_bought_at_idx ON public.purchases USING btree (bought_at);

CREATE INDEX purchases_bought_by_idx ON public.purchases USING btree (bought_by);

CREATE INDEX purchases_household_id_location_id_idx ON public.purchases USING btree (household_id, location_id);

CREATE INDEX purchases_household_id_store_id_idx ON public.purchases USING btree (household_id, store_id);

CREATE INDEX purchases_location_id_idx ON public.purchases USING btree (location_id);

CREATE INDEX purchases_session_token_idx ON public.purchases USING btree (session_token);

CREATE INDEX purchases_sold_at_idx ON public.purchases USING btree (sold_at);

CREATE INDEX purchases_store_id_idx ON public.purchases USING btree (store_id);

CREATE POLICY "purchases_append_only" ON "public"."purchases"
  FOR ALL
  TO "authenticated"
  USING (false)
  WITH CHECK (false);

ALTER TABLE "public"."purchases"
  ADD COLUMN "id" uuid NOT NULL DEFAULT public.uuidv7();

ALTER TABLE "public"."purchases"
  ADD CONSTRAINT "purchases_id_store_id_key" UNIQUE (id, store_id);

ALTER TABLE "public"."purchases"
  ADD CONSTRAINT "purchases_pkey" PRIMARY KEY (id);

REVOKE ALL ON TABLE "public"."purchases" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."purchases" TO "postgres";

REVOKE ALL ON TABLE "public"."purchases" FROM "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."purchases" TO "service_role";

REVOKE ALL ON TABLE "public"."purchases" FROM "anon", "authenticated";
