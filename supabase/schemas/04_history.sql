-- Arrivals, Purchases, Purchase Lines: the history a Household writes and never
-- edits.
--
-- ADR-0005: Arrival is client-side and only suggests, so an Arrival is a row the
-- phone writes - the server keeps no geofence state and judges nothing.
-- ADR-0004 / ADR-0016: a Purchase is an append-only snapshot, claims Rows on
-- the server's clock, and carries the user's `sold_at`; it is never rewritten,
-- and the app is granted no verb on it at all.
-- ADR-0017: Lines reference the Rows they claimed, every delete cascades, and a
-- Purchase with no Lines is not a Purchase.
--
-- A Purchase spans Lists - a Buy takes the whole In-Basket basket at the Active
-- Store, cross-List (ADR-0015) - so `list_id` is not a column of `purchases`.
-- It lives on each Line, through the Row the Line names.

create table "arrivals" (
  "id" uuid primary key default "public"."uuidv7"(),
  "household_id" uuid not null,
  "user_id" uuid not null,
  "location_id" uuid not null,
  "arrived_at" timestamp with time zone not null default "now"(),
  -- The Arrival's Household is its Location's Household, by pair key (ADR-0023).
  constraint "arrivals_household_id_location_id_fkey"
    foreign key ("household_id", "location_id")
    references "store_locations" ("household_id", "id") on delete cascade,
  constraint "arrivals_user_id_fkey"
    foreign key ("user_id") references "auth"."users"("id") on delete cascade
);

create index "arrivals_household_id_idx" on "arrivals" ("household_id");
create index "arrivals_location_id_idx" on "arrivals" ("location_id");
create index "arrivals_arrived_at_idx" on "arrivals" ("arrived_at");

alter table "arrivals" enable row level security;

-- The log is read by Members, and written only by the phone that made the
-- Arrival. The House tab is a read of `arrivals` - it judges nothing (ADR-0005).
create policy "arrivals_read_by_member"
  on "arrivals" for select to "authenticated"
  using ("private"."is_member"("household_id"));

create policy "arrivals_record_own_by_member"
  on "arrivals" for insert to "authenticated"
  with check (
    "private"."is_member"("household_id")
    and "user_id" = ("select auth"."uid"())
  );

-- ---------------------------------------------------------------- purchases

create table "purchases" (
  "id" uuid primary key default "public"."uuidv7"(),
  "household_id" uuid not null,
  "store_id" uuid not null,
  "location_id" uuid,
  "bought_by" uuid not null,
  "bought_at" timestamp with time zone not null,
  "sold_at" date not null,
  "session_token" text not null,
  -- The Buy's whole basket is one Purchase, cross-List: `purchases` has no
  -- `list_id`. The composite target for a Line's (purchase, store) pair.
  unique ("id", "store_id"),
  -- Idempotency: (Household, session token) is claimed once. A replay of a
  -- token returns the Purchase that was recorded and writes nothing (ADR-0016).
  unique ("household_id", "session_token"),
  constraint "purchases_household_id_fkey"
    foreign key ("household_id") references "households"("id") on delete cascade,
  constraint "purchases_household_id_store_id_fkey"
    foreign key ("household_id", "store_id")
    references "stores" ("household_id", "id") on delete cascade,
  constraint "purchases_household_id_location_id_fkey"
    foreign key ("household_id", "location_id")
    references "store_locations" ("household_id", "id") on delete cascade,
  constraint "purchases_bought_by_fkey"
    foreign key ("bought_by") references "auth"."users"("id") on delete cascade
);

create index "purchases_household_id_store_id_idx" on "purchases" ("household_id", "store_id");
create index "purchases_household_id_location_id_idx" on "purchases" ("household_id", "location_id");
create index "purchases_store_id_idx" on "purchases" ("store_id");
create index "purchases_location_id_idx" on "purchases" ("location_id");
create index "purchases_bought_by_idx" on "purchases" ("bought_by");
create index "purchases_bought_at_idx" on "purchases" ("bought_at");
create index "purchases_sold_at_idx" on "purchases" ("sold_at");
create index "purchases_session_token_idx" on "purchases" ("session_token");

alter table "purchases" enable row level security;

-- The pair guard the app cannot be trusted with runs inside `public.buy_basket`
-- (ADR-0017), so the app has no verb here at all, and this is the intent written
-- out rather than left to RLS's default deny (lint 0008).
create policy "purchases_append_only"
  on "purchases" for all to "authenticated"
  using (false)
  with check (false);

-- ----------------------------------------------------------- purchase_lines

create table "purchase_lines" (
  "id" uuid primary key default "public"."uuidv7"(),
  "purchase_id" uuid not null,
  "household_id" uuid not null,
  "item_id" uuid not null,
  "store_id" uuid not null,
  "list_item_id" uuid not null,
  -- A Line names the Row it claimed (ADR-0017 as amended by ADR-0023), and the
  -- (Row, Item) pair key makes that naming a fact the index enforces.
  unique ("list_item_id", "item_id"),
  constraint "purchase_lines_purchase_id_store_id_fkey"
    foreign key ("purchase_id", "store_id")
    references "purchases" ("id", "store_id") on delete cascade,
  constraint "purchase_lines_household_id_list_item_id_fkey"
    foreign key ("household_id", "list_item_id")
    references "list_items" ("household_id", "id") on delete cascade,
  constraint "purchase_lines_household_id_item_id_fkey"
    foreign key ("household_id", "item_id")
    references "items" ("household_id", "id") on delete cascade
);

create index "purchase_lines_purchase_id_idx" on "purchase_lines" ("purchase_id");
create index "purchase_lines_household_id_list_item_id_idx"
  on "purchase_lines" ("household_id", "list_item_id");
create index "purchase_lines_item_id_idx" on "purchase_lines" ("item_id");
create index "purchase_lines_store_id_idx" on "purchase_lines" ("store_id");
create index "purchase_lines_list_item_id_idx" on "purchase_lines" ("list_item_id");

alter table "purchase_lines" enable row level security;

create policy "purchase_lines_append_only"
  on "purchase_lines" for all to "authenticated"
  using (false)
  with check (false);

-- Supabase's default privileges give `anon` and `authenticated` select on every
-- table in `public`. The history takes none of it back: the app writes a
-- Purchase through `public.buy_basket` and reads it through that RPC's result,
-- so lints 0006/0007 stay green here (ADR-0023).
-- Arrivals are read by Members, and written by their own phones; the Purchase
-- ledger is closed to the browser entirely.
revoke all on "arrivals" from "anon", public;
grant select on "arrivals" to "authenticated";

revoke all on "purchases" from "anon", "authenticated", public;
revoke all on "purchase_lines" from "anon", "authenticated", public;

-- ADR-0017: a Purchase is recorded with at least one Line, so the cascade of
-- the Lines it named - a Row deleted with its List, an Item deleted, a Store's
-- Locations erased - leaves no Line-less Purchase standing. The eraser is a
-- trigger so no verb is needed on a table the app is granted nothing.
create function "private"."erase_lineless_purchase"()
returns trigger
language 'plpgsql'
security definer
set search_path = ''
as $$
begin
  delete from "public"."purchases" "p"
  where "p"."id" = "old"."purchase_id"
    and not exists (
      select 1 from "public"."purchase_lines" "l"
      where "l"."purchase_id" = "old"."purchase_id"
    );
  return null;
end;
$$;

revoke execute on function "private"."erase_lineless_purchase"() from public, anon, "authenticated";

create trigger "purchase_lines_erase_purchase"
  after delete on "purchase_lines"
  for each row execute function "private"."erase_lineless_purchase"();
