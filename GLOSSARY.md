# Kinetic Lists

Shopping lists that know where you are: items are tagged with the stores they're bought at, and the app surfaces the ones that matter for the store you're standing in.

## Language

### Household

**Household**:
The unit that owns everything the app records, created at sign-up and grown by **Join**. A user belongs to exactly one Household. It has a name — "My Household" until a Member renames it.
_Avoid_: Family, home, circle, group, team, account

**Member**:
A User as a Household sees them: their Membership in it, carrying a **Display Name**. Full powers over everything the Household owns; Members are equal, there is no role hierarchy. In v1 a Household only grows by Join — no Member removes another, leaves, dissolves a Household, or deletes one.
_Avoid_: Owner, admin, collaborator, editor, user

**Invitation**:
A Household's token offering **Join**, minted and revoked by any Member and shown as a link to paste to a person. It binds no address and no identity: whoever presents it while signed in Joins. It expires after 7 days and is consumed by the first Join.
_Avoid_: Invite, email invite, join code, share link, membership request

**Join**:
The act of presenting an Invitation and becoming a Member of its Household. It admits only a user whose own Household is empty, and vacates that Household.
_Avoid_: Redeem, accept, claim, enrol, sign up

**Display Name**:
A Member's name as their Household sees them, seeded from their sign-in provider — real name, then username, then the email local-part. Only the Member it belongs to may change it.
_Avoid_: Nickname, full name, username, handle, profile name

### Lists, Items and Status

**List**:
A named collection of Items owned by a Household. Every Member sees and edits every List in it.
_Avoid_: Board, cart, pantry

**Item**:
A Household's catalogue record naming a thing it buys, carrying a Category, a Quantity, and its Store Tags. Created by capture; one Item per name within a Household, names matched case- and whitespace-insensitively. Renamable (the new name takes the same collision rule), and deletable: deleting it takes its live List Items, its Store Tags and its history.
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
A List Item the Household has committed to its next shop. A Member who no longer wants it takes it out of the Basket, back to Needed — v1 names no act for that move, because Buy takes the whole Basket and the Basket is where she un-wants it.
_Avoid_: Checked, selected, marked, clear, undo, remove from basket (say it as a phrase, not an act)

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
The act of buying the whole Basket at the Active Store: it records a Purchase with one Purchase Line per List Item it claimed and marks those Stocked. It prompts for nothing — no Tag offer, no confirmation, no per-row selection — and it claims only the List Items still In Basket when the write opens, so what a co-Member Bought first is reported, never rewritten. Its only gate is owning no Store at all.
_Avoid_: Clear Basket, checkout, complete, finish, settle, partial Buy, tick-lines

**Purchase**:
An append-only record of a Basket bought at a Store, claimed once per Basket visit: the Member who bought it, the Store, the Location where one was known, and the time. Visible to every Member; surfaced to none of them in v1. A Buy that found nothing to claim records no Purchase, a Purchase never stands with no Purchase Lines, and a Purchase is erased when its Store is deleted. History is disposable: nothing in v1 reads it.
_Avoid_: Order, transaction, receipt, basket event

**Purchase Line**:
One List Item as a Buy claimed it, recorded **by reference** — the Item and the Store, read at whatever names those rows carry today. It copies no text, and it dies with the Item it names. Only the first Buy to claim a List Item writes that Item's Line.
_Avoid_: Receipt line, basket line, order line, snapshot (v1 snapshots nothing)

### Stores and Tags

**Store**:
A Household's name for where it shops — the thing a **Store Tag** points at and the Kinetic View is about. It is not a place: its **Locations** are the places Members travel to, and a Store may have many, or none. Its name is unique within the Household, case- and whitespace-insensitively; it is renamable, and deleting it takes its Locations, Tags, Arrivals and Purchases.
_Avoid_: Location, chain, brand, group, location group, basket, shop, venue, address, place

**Bare Store**:
A Store with no **Locations** — legal, Taggable, Pickable, Buys legal, and selectable by no Arrival, because it has a Geofence to be nothing inside of. Its Purchases name the Store and no Location.
_Avoid_: Empty store, unlocated store, placeholder store

**Location**:
A Store's place in the world — coordinates and a Geofence. Created where a Member is standing only when she asks for it (the app never mints a Location silently), typed in by hand for a place not visited, and deduped by Store name: capturing an existing name adds a Location to it rather than minting a second Store. Coordinates are editable in place; a deleted Location erases the Arrivals at it and the Purchases that named it, and two Locations are never merged.
_Avoid_: Outlet, branch, site, pin, geotag, coordinates (a Location has no name in v1)

**Store Tag**:
A link marking that an Item can be bought at a Store. An Item may carry many, and may carry none; a captured Item may arrive carrying them.
_Avoid_: Location tag, label, keyword

**Tag**:
The act of linking an Item to a Store it is bought at — written at capture (Store chips, the Store you are standing at pre-ticked), on the Item's screen, and on the Store's screen, and never replacing the tags the Item has. **Buy offers nothing**: after a Buy the app may report the bought Items with no Tag for that Store, and a report writes nothing.
_Avoid_: Retag, reassign, auto-tag, Tag offer, Tag prompt

**Category**:
A Household's free-text value on an Item, used to order a List. A value, not a record: v1 has no rename and no merge.
_Avoid_: Aisle, section, group, tag

**Quantity**:
An Item's free-text default of how it is bought ("2 L", "a dozen"). A value on the Item; a Purchase Line reads it from the Item and copies nothing.
_Avoid_: Amount, count, unit (a unit is part of the value, never a record)

### Being there

**Position**:
A device-reported coordinate, read in the browser and never persisted — and the only source of a Location's coordinates in v1.
_Avoid_: Location, coordinates, GPS, geolocation (reserve "geolocation" for the act of reading a Position). A **Location** is a Store's place in the world; a Position is a device's report of where you are.

**Inside**:
The state of a Position falling within a Location's Geofence.
_Avoid_: Nearby, at, arrived (use as verbs, not states)

**Arrival**:
A recorded moment a Member was Inside a Location, with the Member, the Location and the time — and no Position, and no copy of the Geofence that judged it. An Arrival **selects that Location's Store as the Active Store** and **moves no List Item**: nothing is Picked, no Status changes (ADR-0015). It is erased when its Location is deleted.
_Avoid_: Visit, geofence event, check-in, Arrival banner, "Pick it"

**Geofence**:
The radius around a Location's coordinates within which a Member counts as Inside it. Default 150 m, editable per Location by any Member — one shared judgement, not one per Member.
_Avoid_: Radius, fence, area

**Active Store**:
The Store the Kinetic View and the Basket are showing. An **Arrival** selects it by default; a Member overrides that by **Picking**, and their Pick stands until the next Arrival. When no Location matches a Position, the app offers a new Store from where the Member stands. A Household that owns no Store has **no Active Store** — the empty state its first Buy resolves by naming the shop, and the same state a Member lands in after deleting the Store they were standing at (ADR-0017: no re-Pick rule). A Store with no Location has no Geofence and can never be selected by an Arrival.
_Avoid_: Current location, selected store

**Pick**:
The act of making a Store the Active Store — by hand from the header, against an Arrival's default. It moves no List Item.
_Avoid_: Select, choose, switch, detect

**Kinetic View**:
The Household's cross-List view of the List Items Needed at the Active Store, the app's reason for existing.
_Avoid_: Location view, store view, nearby view
