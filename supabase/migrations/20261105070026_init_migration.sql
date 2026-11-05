SET local check_function_bodies = off;

CREATE SCHEMA "private";

CREATE EXTENSION "postgis" SCHEMA "extensions";

CREATE TABLE "public"."household_members" (
  "household_id" uuid NOT NULL,
  "user_id"      uuid NOT NULL,
  "display_name" text NOT NULL,
  CONSTRAINT "household_members_pkey" PRIMARY KEY (household_id, user_id),
  CONSTRAINT "household_members_user_id_key" UNIQUE (user_id)
);

ALTER TABLE "public"."household_members"
  ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE "public"."household_members" FROM "anon";

CREATE TABLE "public"."households" (
  "id"   uuid NOT NULL DEFAULT gen_random_uuid(),
  "name" text NOT NULL,
  CONSTRAINT "households_name_length_check" CHECK (((char_length(name) > 0) AND (char_length(name) <= 50))),
  CONSTRAINT "households_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."households"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."items" (
  "id"           uuid NOT NULL DEFAULT gen_random_uuid(),
  "household_id" uuid NOT NULL,
  "name"         text NOT NULL,
  CONSTRAINT "items_name_valid_length_check" CHECK (((char_length(name) > 0) AND (char_length(name) < 50))),
  CONSTRAINT "items_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."items"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."list_items" (
  "id"           uuid NOT NULL DEFAULT gen_random_uuid(),
  "household_id" uuid NOT NULL,
  "item_id"      uuid NOT NULL,
  "list_id"      uuid NOT NULL,
  CONSTRAINT "list_items_pkey" PRIMARY KEY (id),
  CONSTRAINT "list_items_unique" UNIQUE (item_id, list_id)
);

ALTER TABLE "public"."list_items"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."lists" (
  "id"           uuid NOT NULL DEFAULT gen_random_uuid(),
  "household_id" uuid NOT NULL,
  "name"         text NOT NULL,
  CONSTRAINT "households_name_length_check" CHECK (((char_length(name) > 0) AND (char_length(name) <= 50))),
  CONSTRAINT "lists_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."lists"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."locations" (
  "id"           uuid                             NOT NULL DEFAULT gen_random_uuid(),
  "household_id" uuid                             NOT NULL,
  "store_id"     uuid                             NOT NULL,
  "location"     extensions.geography(Point,4326) NOT NULL,
  "accuracy_m"   real,
  CONSTRAINT "locations_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."locations"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."stores" (
  "id"           uuid NOT NULL DEFAULT gen_random_uuid(),
  "household_id" uuid NOT NULL,
  "name"         text NOT NULL,
  CONSTRAINT "store_name_length_check" CHECK (((char_length(name) > 0) AND (char_length(name) <= 50))),
  CONSTRAINT "stores_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."stores"
  ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION private.handle_new_auth_user()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'pg_catalog'
  AS $function$
declare
  v_display_name text;
  v_household uuid;
begin
  -- the name chain adr-0019 fixes: raw_user_meta_data->>'name', then
  -- preferred_username, full_name, user_name, then the email local part.
  -- identity_data is never read (adr-0019's warning about raw_app_meta_data).
  select coalesce(
    nullif("raw_user_meta_data" ->> 'name', e''),
    nullif("raw_user_meta_data" ->> 'preferred_username', e''),
    nullif("raw_user_meta_data" ->> 'full_name', e''),
    nullif("raw_user_meta_data" ->> 'user_name', e''),
    split_part("email", '@', 1)
  )
  into "v_display_name"
  from "auth"."users" "u"
  where "u"."id" = "new"."id";

  insert into "public"."households" default values
  returning "id" into "v_household";

  insert into "public"."household_members" ("household_id", "user_id", "display_name")
  values ("v_household", "new"."id", "v_display_name");

  return "new";
end;
$function$;

CREATE OR REPLACE FUNCTION private.is_member (
  p_household_id uuid
)
  RETURNS boolean
  LANGUAGE plpgsql
  STABLE
  SECURITY DEFINER
  SET search_path TO 'pg_catalog'
  AS $function$
begin
  return exists (
    select 1
    from "public"."household_members" "m"
    where "m"."household_id" = "p_household_id"
      and "m"."user_id" = (select "auth"."uid"())
  );
end;
$function$;

CREATE OR REPLACE FUNCTION public.nearby_stores (
  lat      double precision,
  lng      double precision,
  accuracy real             DEFAULT 0,
  radius_m real             DEFAULT 150
)
  RETURNS TABLE (
    id         uuid,
    name       text,
    distance_m double precision
  )
  LANGUAGE sql
  STABLE
  AS $function$
select
  s.id,
  s.name,
  st_distance(s.location, cast(st_point(lng, lat) as geography)) as distance_m
from
  stores as s
where
  st_dwithin(
    s.location,
    cast(st_point(lng, lat) as geography),
    radius_m + least(accuracy, 100) + least(coalesce(s.accuracy_m, 0), 100)
  )
order by distance_m;
$function$;

ALTER TABLE "public"."household_members"
  ADD CONSTRAINT "household_members_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE "public"."household_members"
  ADD CONSTRAINT "household_members_household_id_fkey" FOREIGN KEY (household_id) REFERENCES public.households(id) ON DELETE CASCADE;

ALTER TABLE "public"."items"
  ADD CONSTRAINT "items_household_id_fkey" FOREIGN KEY (household_id) REFERENCES public.households(id) ON DELETE CASCADE;

ALTER TABLE "public"."list_items"
  ADD CONSTRAINT "list_items_household_id_fkey" FOREIGN KEY (household_id) REFERENCES public.households(id) ON DELETE CASCADE;

ALTER TABLE "public"."list_items"
  ADD CONSTRAINT "list_items_item_id_fkey" FOREIGN KEY (item_id) REFERENCES public.items(id) ON DELETE CASCADE;

ALTER TABLE "public"."lists"
  ADD CONSTRAINT "lists_household_id_fkey" FOREIGN KEY (household_id) REFERENCES public.households(id) ON DELETE CASCADE;

ALTER TABLE "public"."list_items"
  ADD CONSTRAINT "list_items_list_id_fkey" FOREIGN KEY (list_id) REFERENCES public.lists(id) ON DELETE CASCADE;

ALTER TABLE "public"."locations"
  ADD CONSTRAINT "locations_household_id_fkey" FOREIGN KEY (household_id) REFERENCES public.households(id) ON DELETE CASCADE;

ALTER TABLE "public"."stores"
  ADD CONSTRAINT "stores_household_id_fkey" FOREIGN KEY (household_id) REFERENCES public.households(id) ON DELETE CASCADE;

ALTER TABLE "public"."locations"
  ADD CONSTRAINT "locations_store_id_fkey" FOREIGN KEY (store_id) REFERENCES public.stores(id) ON DELETE CASCADE;

CREATE INDEX locations_location_idx ON public.locations USING gist (location);

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION private.handle_new_auth_user();

CREATE POLICY "household_members_read_by_member" ON "public"."household_members"
  FOR SELECT
  TO "authenticated"
  USING (private.is_member(household_id));

CREATE POLICY "household_members_rename_self" ON "public"."household_members"
  FOR UPDATE
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = user_id))
  WITH CHECK ((( SELECT auth.uid() AS uid) = user_id));

CREATE POLICY "members_select_auth_admin" ON "public"."household_members"
  FOR SELECT
  TO "supabase_auth_admin"
  USING (true);

CREATE POLICY "User's own household" ON "public"."households"
  FOR ALL
  TO "authenticated"
  USING (private.is_member(id));

CREATE POLICY "User's' own items" ON "public"."items"
  FOR ALL
  TO "authenticated"
  USING (private.is_member(household_id));

CREATE POLICY "User's own list_items" ON "public"."list_items"
  FOR ALL
  TO PUBLIC
  USING (private.is_member(household_id))
  WITH CHECK (private.is_member(household_id));

CREATE POLICY "User's own lists" ON "public"."lists"
  FOR ALL
  TO PUBLIC
  USING (private.is_member(household_id))
  WITH CHECK (private.is_member(household_id));

CREATE POLICY "User's own locations" ON "public"."locations"
  FOR ALL
  TO PUBLIC
  USING (private.is_member(household_id))
  WITH CHECK (private.is_member(household_id));

CREATE POLICY "User's own stores" ON "public"."stores"
  FOR ALL
  TO PUBLIC
  USING (private.is_member(household_id))
  WITH CHECK (private.is_member(household_id));

COMMENT ON EXTENSION "postgis" IS 'PostGIS geometry and geography spatial types and functions';

REVOKE ALL ON FUNCTION "private"."handle_new_auth_user"() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION "private"."handle_new_auth_user"() TO "supabase_auth_admin";

REVOKE ALL ON FUNCTION "private"."is_member"(uuid) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION "private"."is_member"(uuid) TO "authenticated";

GRANT EXECUTE ON FUNCTION "public"."nearby_stores"(double precision, double precision, real, real) TO PUBLIC, "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."nearby_stores"(double precision, double precision, real, real) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."nearby_stores"(double precision, double precision, real, real) TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."nearby_stores"(double precision, double precision, real, real) TO "service_role";

GRANT USAGE ON SCHEMA "private" TO "authenticated", "supabase_auth_admin";

REVOKE ALL ON TABLE "public"."household_members" FROM "authenticated";

GRANT MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."household_members" TO "authenticated";

REVOKE ALL ON TABLE "public"."household_members" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."household_members" TO "postgres";

REVOKE ALL ON TABLE "public"."household_members" FROM "service_role";

GRANT MAINTAIN, REFERENCES, TRIGGER, TRUNCATE ON TABLE "public"."household_members" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."households" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."households" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."households" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."households" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."items" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."items" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."items" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."items" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."list_items" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."list_items" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."list_items" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."list_items" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."lists" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."lists" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."lists" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."lists" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."locations" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."locations" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."locations" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."locations" TO "service_role";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."stores" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."stores" FROM "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."stores" TO "postgres";

GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."stores" TO "service_role";
