-- Lists, Items, the Rows that join them, and Store Tags.
--
-- ADR-0001: a List is a standing set, so a Row is a per-List membership, not an
-- occurrence - which is why `list_items` keys on the (List, Item) pair.
-- ADR-0002: an Item is per-user and shared by name; ADR-0012: Category and
-- Quantity are free-text values on the Item, not tables. ADR-0010: a Row has one
-- Status, shared by every Member. ADR-0015: Store Tags are written at capture
-- and an Arrival only selects the Active Store. ADR-0018: Item names are unique
-- per Household, by index.
--
-- `household_id` is denormalized onto Rows so a tenancy check is one column, and
-- so the composite pair keys can point at it (ADR-0023).

create table "lists" (
  "id" uuid primary key default "extensions"."uuidv7"(),
  "household_id" uuid not null,
  "name" text not null,
  unique ("household_id", "id"),
  constraint "lists_household_id_fkey"
    foreign key ("household_id") references "households"("id") on delete cascade
);

alter table "lists" enable row level security;

-- Lists are shared; there is no Personal List in v1.
create policy "lists_read_by_member"
  on "lists" for select to "authenticated"
  using ("private"."is_member"("household_id"));

create policy "lists_create_by_member"
  on "lists" for insert to "authenticated"
  with check ("private"."is_member"("household_id"));

create policy "lists_rename_by_member"
  on "lists" for update to "authenticated"
  using ("private"."is_member"("household_id"))
  with check ("private"."is_member"("household_id"));

create trigger "lists_ownership_keys_are_immutable"
  before update of "id", "household_id" on "lists"
  for each row execute function "private"."ownership_keys_are_immutable"();

-- No DELETE policy on lists: [ADR-0022] refused the List delete verb as fog, so
-- a List is renamed and read, and its Rows leave only with the List row itself
-- (which v1 never deletes).

-- ------------------------------------------------------------------- items

create table "items" (
  "id" uuid primary key default "extensions"."uuidv7"(),
  "household_id" uuid not null,
  "name" text not null,
  "category" text,
  "quantity" text,
  unique ("household_id", "id"),
  constraint "items_household_id_fkey"
    foreign key ("household_id") references "households"("id") on delete cascade
);

-- ADR-0018: the Item name is unique per Household. Capture reads this index as
-- the Merge/Make choice; the insert fails with 23505 and the UI re-offers Merge.
create unique index "items_name_household_idx"
  on "items" ("household_id", "lower"("trim"("name")));

alter table "items" enable row level security;

create policy "items_read_by_member"
  on "items" for select to "authenticated"
  using ("private"."is_member"("household_id"));

create policy "items_create_by_member"
  on "items" for insert to "authenticated"
  with check ("private"."is_member"("household_id"));

create policy "items_update_by_member"
  on "items" for update to "authenticated"
  using ("private"."is_member"("household_id"))
  with check ("private"."is_member"("household_id"));

create trigger "items_ownership_keys_are_immutable"
  before update of "id", "household_id" on "items"
  for each row execute function "private"."ownership_keys_are_immutable"();

-- ADR-0022: Item delete is a confirm because it cascades Rows and Lines.
create policy "items_delete_by_member"
  on "items" for delete to "authenticated"
  using ("private"."is_member"("household_id"));

-- -------------------------------------------------------------- list_items

create table "list_items" (
  "id" uuid primary key default "extensions"."uuidv7"(),
  "list_id" uuid not null,
  "item_id" uuid not null,
  "household_id" uuid not null,
  "status" text not null default 'needed'
    check ("status" in ('needed', 'in_basket', 'stocked')),
  "stocked_at" timestamp with time zone,
  -- A Row is one per (List, Item): a standing set (ADR-0001).
  unique ("list_id", "item_id"),
  -- The composite targets for Purchase Lines.
  unique ("household_id", "id"),
  unique ("id", "item_id"),
  constraint "list_items_list_id_household_id_fkey"
    foreign key ("household_id", "list_id")
    references "lists" ("household_id", "id") on delete cascade,
  constraint "list_items_item_id_household_id_fkey"
    foreign key ("household_id", "item_id")
    references "items" ("household_id", "id") on delete cascade
);

create index "list_items_item_id_idx" on "list_items" ("item_id");
create index "list_items_household_id_list_id_idx"
  on "list_items" ("household_id", "list_id");

-- The Kinetic View read: every Row of one Household in a given Status
-- (ADR-0015's Standing Set, and the Basket a Buy claims).
create index "list_items_household_id_status_idx"
  on "list_items" ("household_id", "status");

alter table "list_items" enable row level security;

-- Rows are shared: one Status per Row, read and moved by every Member
-- (ADR-0010). Check and Need are Status updates on this table (ADR-0022).
create policy "list_items_read_by_member"
  on "list_items" for select to "authenticated"
  using ("private"."is_member"("household_id"));

-- The two Statuses a Member's own hand can put a Row into. Stocked arrives
-- only from `public.buy_basket`, on the server's clock (ADR-0016), and a policy
-- cannot name columns - so the check names the values instead, which is the
-- stronger sentence: the app has no way to write `stocked` at all.
create policy "list_items_add_by_member"
  on "list_items" for insert to "authenticated"
  with check (
    "private"."is_member"("household_id")
    and "status" in ('needed', 'in_basket')
  );

create policy "list_items_move_status_by_member"
  on "list_items" for update to "authenticated"
  using ("private"."is_member"("household_id"))
  with check (
    "private"."is_member"("household_id")
    and "status" in ('needed', 'in_basket')
  );

create trigger "list_items_ownership_keys_are_immutable"
  before update of "id", "household_id", "list_id", "item_id" on "list_items"
  for each row execute function "private"."ownership_keys_are_immutable"();

-- No DELETE policy: a Member un-Checks a Row (Status back to 'needed'), they do
-- not delete the Household's standing membership outside List hygiene.
-- Deleting the List deletes its Rows (ADR-0022).

-- ---------------------------------------------------------- item_store_tags

create table "item_store_tags" (
  "item_id" uuid not null,
  "store_id" uuid not null,
  "created_by" uuid not null,
  "created_at" timestamp with time zone not null default "now"(),
  primary key ("item_id", "store_id"),
  constraint "item_store_tags_item_id_fkey"
    foreign key ("item_id") references "items"("id") on delete cascade,
  constraint "item_store_tags_store_id_fkey"
    foreign key ("store_id") references "stores"("id") on delete cascade,
  constraint "item_store_tags_created_by_fkey"
    foreign key ("created_by") references "auth"."users"("id") on delete cascade
);

create index "item_store_tags_store_id_idx" on "item_store_tags" ("store_id");
create index "item_store_tags_created_by_idx" on "item_store_tags" ("created_by");

alter table "item_store_tags" enable row level security;

-- The composite primary key is invisible to a Realtime DELETE event unless the
-- full row is the replica identity (ticket #8's seam).
alter table "item_store_tags" replica identity full;

-- The tag pair crosses two tables, so it gets the one guard RLS cannot
-- expression: a before-trigger owned by the migration role, which reads Items
-- and Stores past RLS (ADR-0023). A Tag may never pair an Item of one Household
-- with a Store of another; the tenancy of a Tag is read through its Store.
create function "private"."tag_pairs_one_household"()
returns trigger
language 'plpgsql'
security definer
set search_path = ''
as $$
declare
  v_item_household uuid;
  v_store_household uuid;
begin
  select "household_id" into "v_item_household"
  from "public"."items" where "id" = "new"."item_id";

  select "household_id" into "v_store_household"
  from "public"."stores" where "id" = "new"."store_id";

  if "v_item_household" is null or "v_store_household" is null
     or "v_item_household" <> "v_store_household" then
    raise exception 'a Store Tag pairs an Item and a Store from different Households'
      using errcode = '23514';
  end if;

  return "new";
end;
$$;

revoke execute on function "private"."tag_pairs_one_household"() from public, anon, "authenticated";

create trigger "item_store_tags_pair_one_household"
  before insert or update of "item_id", "store_id" on "item_store_tags"
  for each row execute function "private"."tag_pairs_one_household"();

-- The Shopping surface is a Member's `select`; every write is a policy verb.
revoke all on "lists", "items", "list_items", "item_store_tags"
  from "anon", public;
grant select on "lists", "items", "list_items", "item_store_tags"
  to "authenticated";

-- ADR-0015: Tags are written at capture, listed, and un-tagged. Buy reads them
-- inside `public.buy_basket`, definer past RLS.
create policy "item_store_tags_read_by_member"
  on "item_store_tags" for select to "authenticated"
  using (exists (
    select 1 from "public"."stores" "s"
    where "s"."id" = "store_id"
      and "private"."is_member"("s"."household_id")
  ));

create policy "item_store_tags_tag_by_member"
  on "item_store_tags" for insert to "authenticated"
  with check (exists (
    select 1 from "public"."stores" "s"
    where "s"."id" = "store_id"
      and "private"."is_member"("s"."household_id")
  ));

create policy "item_store_tags_untag_by_member"
  on "item_store_tags" for delete to "authenticated"
  using (exists (
    select 1 from "public"."stores" "s"
    where "s"."id" = "store_id"
      and "private"."is_member"("s"."household_id")
  ));
