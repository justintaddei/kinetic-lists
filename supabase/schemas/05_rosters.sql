-- The two rosters the hygiene surfaces read, as security-invoker views.
--
-- ADR-0022: a Store's own surface is a Location list plus Store Tags; an Item's
-- own surface is Lists and Store Tags. Both are counts of owned rows, which the
-- app would otherwise reconstruct from three tables per row. A view is the
-- cheap shape, and `security_invoker = on` is what keeps it out of the definer
-- set: the view runs the querying role's own Row-Level Security (lint 0010), so
-- it cannot leak a row the Member's policies would not show.
--
-- The Kinetic View is NOT here, and is not a view: it is one app-side read of
-- `list_items` for one Household in one Status (ADR-0023).

-- The Store roster: a Store with its Locations and its Store Tags.
create view "roster_stores"
with (security_invoker = on)
as
select
  "s"."id",
  "s"."household_id",
  "s"."name",
  (select count(*)::int from "store_locations" "l" where "l"."store_id" = "s"."id") as "location_count",
  (select count(*)::int from "item_store_tags" "t" where "t"."store_id" = "s"."id") as "tag_count"
from "stores" "s";

grant select on "roster_stores" to "anon", "authenticated";

-- The Item roster: an Item with the Lists it stands on and the Stores tagged on it.
create view "roster_items"
with (security_invoker = on)
as
select
  "i"."id",
  "i"."household_id",
  "i"."name",
  "i"."category",
  "i"."quantity",
  (select count(*)::int from "list_items" "li" where "li"."item_id" = "i"."id") as "list_count",
  (select coalesce(array_agg("s"."name" order by "s"."name"), array[]::text[])
     from "item_store_tags" "t"
     join "stores" "s" on "s"."id" = "t"."store_id"
    where "t"."item_id" = "i"."id") as "store_names"
from "items" "i";

grant select on "roster_items" to "anon", "authenticated";
revoke all on "roster_stores", "roster_items" from public;
