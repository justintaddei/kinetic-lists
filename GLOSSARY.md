# Kinetic Lists

Shopping lists that know where you are: items are tagged with the stores they're bought at, and the app surfaces the ones that matter for the store you're standing in.

## Language

**List**:
A named collection of Items maintained by one or more Owners.
_Avoid_: Board, cart, pantry

**Owner**:
A user with full powers over a List — including deleting it, removing other Owners, and removing any Item. Owners are equal; there is no role hierarchy.
_Avoid_: Member, admin, collaborator, editor

**Item**:
A reusable per-user catalogue record naming a thing you buy, carrying its Category, default quantity/unit, and Store Tags. Created by one user, shared with every Owner of a List it joins.
_Avoid_: Product, SKU, entry, row

**Catalogue**:
The set of Items a user has created. Grows by capture, never by browsing.
_Avoid_: Inventory, stock, pantry

**List Item**:
An Item as it appears in a specific List — the thing you can check, and the unit history is measured in.
_Avoid_: Line, task, card

**Check**:
Marking a List Item as wanted for your next shop. Not terminal: the same List Item is checked and unchecked across many shops.
_Avoid_: Tick, done, complete, bought

**Basket**:
One user's checked List Items across all their Lists. Cleared as a single act.
_Avoid_: Cart, trolley, trip

**Clear Basket**:
Recording the Basket as a Purchase at a Store, which unchecks its List Items.
_Avoid_: Checkout, complete, finish

**Purchase**:
An append-only record of a Basket cleared at a Store: its List Items, the Store, and the time. Visible to all Owners.
_Avoid_: Order, transaction, receipt, basket event

**Store**:
A first-class place things are bought at, with coordinates and a geofence radius. A thing users travel *to*.
_Avoid_: Location, shop, venue, address, place

**Store Tag**:
A link marking that an Item can be bought at a Store. An Item may carry many.
_Avoid_: Location tag, label, keyword

**Category**:
A per-user free-text grouping on an Item, used to order a List.
_Avoid_: Aisle, section, group, tag

**Position**:
A device-reported coordinate, read in the browser and never persisted.
_Avoid_: Location, coordinates, GPS, geolocation (reserve "geolocation" for the act of reading a Position)

**Inside**:
The state of a Position falling within a Store's Geofence.
_Avoid_: Nearby, at, arrived (use as verbs, not states)

**Arrival**:
A recorded moment a user was Inside a Store, with the Store and time — and no Position.
_Avoid_: Visit, geofence event, check-in

**Geofence**:
The radius around a Store's coordinates within which a user counts as Inside it. Default 150 m, editable per Store.
_Avoid_: Radius, fence, area

**Active Store**:
The Store the app is currently showing items for. Set by picking, never automatically.
_Avoid_: Current location, selected store

**Kinetic View**:
The cross-List view of List Items tagged with a Store, the app's reason for existing.
_Avoid_: Location view, store view, nearby view
