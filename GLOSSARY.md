# Kinetic Lists

Shopping lists that know where you are: items are tagged with the stores they're bought at, and the app surfaces the ones that matter for the store you're standing in.

## Language

### Household

**Household**:
The unit that owns everything the app records, created at sign-up and grown by Inviting other Members. A user belongs to exactly one Household.
_Avoid_: Family, home, circle, group, team, account

**Member**:
A person in a Household, with full powers over everything it owns — including removing other Members. Members are equal; there is no role hierarchy.
_Avoid_: Owner, admin, collaborator, editor, user

**Invite**:
An email offer to join a Household, accepted by the signed-in user it was sent to. Joining requires an empty Household, so an Invite reaches a person who has not started yet.
_Avoid_: Join code, share link, membership request

### Lists, Items and Status

**List**:
A named collection of Items owned by a Household. Every Member sees and edits every List in it.
_Avoid_: Board, cart, pantry

**Item**:
A Household's catalogue record naming a thing it buys, carrying a Category, a Quantity, and its Store Tags. Created by capture; one Item per name within a Household.
_Avoid_: Product, SKU, entry, row

**Catalogue**:
The Items a Household has captured. Grows by capture, never by browsing.
_Avoid_: Inventory, stock, pantry

**List Item**:
An Item as it appears in a specific List — the thing a Member Checks and Buys, and the unit history is measured in.
_Avoid_: Line, task, card

**Status**:
One List Item's standing, shared by every Member of its Household: **Needed**, **In Basket** or **Stocked**.
_Avoid_: State, stage, condition, flag

**Needed**:
A List Item the Household wants, and the only Status the Kinetic View shows.
_Avoid_: Want, missing, to-buy

**In Basket**:
A List Item the Household has committed to its next shop.
_Avoid_: Checked, selected, marked

**Stocked**:
A List Item the Household last bought, resting until it is Needed again.
_Avoid_: Bought, purchased, done, out

**Check**:
The act of moving a List Item from Needed to In Basket. Not terminal: the same List Item is Checked and Needed again across many shops.
_Avoid_: Tick, mark, flag

**Need**:
The act of moving a Stocked List Item back to Needed.
_Avoid_: Refill, reorder, restock, add back

### Shopping

**Basket**:
A Household's List Items that are In Basket, across all its Lists — a view over shared Status, never a record of its own.
_Avoid_: Cart, trolley, trip

**Buy**:
The act of buying the Basket at the Active Store: it records a Purchase with one Purchase Line per List Item and marks them Stocked.
_Avoid_: Clear Basket, checkout, complete, finish, settle

**Purchase**:
An append-only record of a Basket bought at a Store: the Member who bought it, the Store, and the time. Visible to every Member.
_Avoid_: Order, transaction, receipt, basket event

**Purchase Line**:
One List Item as a Buy recorded it — its name, Quantity and Store at that moment, surviving renames and deletions.
_Avoid_: Receipt line, basket line, order line

### Stores and Tags

**Store**:
A Household's place things are bought at, with coordinates and a Geofence. A thing Members travel *to*.
_Avoid_: Location, shop, venue, address, place

**Store Tag**:
A link marking that an Item can be bought at a Store. An Item may carry many, and may carry none.
_Avoid_: Location tag, label, keyword

**Tag**:
The act of adding the Store a Buy happened at to a bought Item's Store Tags, offered when the tag is missing and never replacing the tags the Item has.
_Avoid_: Retag, reassign, auto-tag

**Category**:
A Household's free-text value on an Item, used to order a List. A value, not a record: v1 has no rename and no merge.
_Avoid_: Aisle, section, group, tag

**Quantity**:
An Item's free-text default of how it is bought ("2 L", "a dozen"), copied into each Purchase Line.
_Avoid_: Amount, count, unit (a unit is part of the value, never a record)

### Being there

**Position**:
A device-reported coordinate, read in the browser and never persisted.
_Avoid_: Location, coordinates, GPS, geolocation (reserve "geolocation" for the act of reading a Position)

**Inside**:
The state of a Position falling within a Store's Geofence.
_Avoid_: Nearby, at, arrived (use as verbs, not states)

**Arrival**:
A recorded moment a Member was Inside a Store, with the Member, the Store and the time — and no Position, and no copy of the Geofence that judged it.
_Avoid_: Visit, geofence event, check-in

**Geofence**:
The radius around a Store's coordinates within which a Member counts as Inside it. Default 150 m, editable per Store by any Member.
_Avoid_: Radius, fence, area

**Active Store**:
The Store the Kinetic View and the Basket are showing. Set by Picking, never automatic.
_Avoid_: Current location, selected store

**Pick**:
The hand-set act of choosing the Active Store. An Arrival only suggests a Pick.
_Avoid_: Select, choose, switch, detect

**Kinetic View**:
The Household's cross-List view of the List Items Needed at the Active Store, the app's reason for existing.
_Avoid_: Location view, store view, nearby view
