-- Stores and their Store Locations.
--
-- ADR-0011: a Store belongs to a Household, with no sharing between
-- Households. ADR-0013: a Store has Locations; a Location's coordinates come
-- from a Position the app read off the map, and `geofence_m` is the only
-- judgement it carries. A Location is nameless. ADR-0018: a Store's name is
-- unique per Household. ADR-0017: deleting a Location erases the history that
-- names it, so every reference to a Location cascades.
--
-- Pair-validity is an index, not a trigger: `unique (household_id, "id")` /
-- `unique (store_id, "id")` are the targets the composite foreign keys point
-- at, so a row can only ever name a Store and a Household that agree
-- (ADR-0023). `store_locations` carries `household_id` denormalized from its
-- Store for exactly that reason, and its own composite key is the target for
-- Arrivals and Purchases.

create table "stores" (
  "id" uuid primary key default "extensions"."uuidv7"(),
  "household_id" uuid not null,
  "name" text not null,
  -- The composite target for every `(..., store_id)` pair foreign key.
  unique ("household_id", "id"),
  constraint "stores_household_id_fkey"
    foreign key ("household_id") references "households"("id") on delete cascade
);

-- ADR-0018: unique per Household, by index. Trim- and case-insensitive, which
-- PostgREST can pre-check with `?name=eq.x`; the index is the backstop.
create unique index "stores_name_household_idx"
  on "stores" ("household_id", "lower"("trim"("name")));

alter table "stores" enable row level security;

-- Stores are shared; every verb is a Member's verb (ADR-0011, ADR-0022).
create policy "stores_read_by_member"
  on "stores" for select to "authenticated"
  using ("private"."is_member"("household_id"));

-- A Store and its first Location arrive in one nested insert, which PostgREST
-- compiles to a single SQL statement: atomic by construction, no transaction
-- preference involved (ADR-0023).
create policy "stores_create_by_member"
  on "stores" for insert to "authenticated"
  with check ("private"."is_member"("household_id"));

create policy "stores_rename_by_member"
  on "stores" for update to "authenticated"
  using ("private"."is_member"("household_id"))
  with check ("private"."is_member"("household_id"));

create trigger "stores_ownership_keys_are_immutable"
  before update of "id", "household_id" on "stores"
  for each row execute function "private"."ownership_keys_are_immutable"();

-- ADR-0022: Store delete is the one cascade that needs a confirmation, because
-- it erases Locations and the Purchases recorded at them.
create policy "stores_delete_by_member"
  on "stores" for delete to "authenticated"
  using ("private"."is_member"("household_id"));

-- ----------------------------------------------------------- store_locations

create table "store_locations" (
  "id" uuid primary key default "extensions"."uuidv7"(),
  "store_id" uuid not null,
  "household_id" uuid not null,
  "lat" double precision not null check ("lat" between -90 and 90),
  "lng" double precision not null check ("lng" between -180 and 180),
  "geofence_m" integer not null default 150
    check ("geofence_m" > 0 and "geofence_m" <= 20000),
  -- The composite targets: for the Household's own pair, and for every
  -- `(..., location_id)` pair foreign key.
  unique ("household_id", "id"),
  unique ("store_id", "id"),
  constraint "store_locations_store_id_household_id_fkey"
    foreign key ("store_id", "household_id")
    references "stores" ("household_id", "id") on delete cascade
);

create index "store_locations_store_id_household_id_idx"
  on "store_locations" ("store_id", "household_id");

alter table "store_locations" enable row level security;

create policy "store_locations_read_by_member"
  on "store_locations" for select to "authenticated"
  using ("private"."is_member"("household_id"));

create policy "store_locations_create_by_member"
  on "store_locations" for insert to "authenticated"
  with check ("private"."is_member"("household_id"));

-- Coordinates and the geofence are re-captured from the map; the Location's
-- identity and its Store never move (ADR-0013), which is the trigger below - a
-- policy cannot name the columns it restricts.
create policy "store_locations_update_position_by_member"
  on "store_locations" for update to "authenticated"
  using ("private"."is_member"("household_id"))
  with check ("private"."is_member"("household_id"));

create trigger "store_locations_ownership_keys_are_immutable"
  before update of "id", "household_id", "store_id" on "store_locations"
  for each row execute function "private"."ownership_keys_are_immutable"();

revoke all on "stores", "store_locations" from "anon", public;
grant select on "stores", "store_locations" to "authenticated";

-- ADR-0017: the Location's Purchases and Arrivals go with it.
create policy "store_locations_delete_by_member"
  on "store_locations" for delete to "authenticated"
  using ("private"."is_member"("household_id"));
