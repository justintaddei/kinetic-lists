# Purchases are append-only and snapshot their items

> **Superseded by [ADR-0017](0017-purchase-lines-reference-rows-and-every-delete-cascades.md):** the **snapshot half is gone** — a Purchase Line references the Item and Store by id and copies no text, and history is erased by cascade when its Item, Location or Store is deleted. *Append-only* survives as a write rule: no Member updates or deletes a Purchase, and deleting a whole Purchase is not a verb — "never edited" now reads "never edited by a Member".

> **Restated by [ADR-0010](0010-a-list-item-has-one-status.md):** **Buy** is the act, and a snapshot row is a **Purchase Line**; "the List Items are then unchecked" reads "marked Stocked".

Clearing a Basket writes a Purchase row (Owner, Store, time) plus one row per checked List Item, capturing the name, quantity and Store at that moment; the List Items are then unchecked. History is append-only and never edited, visible to every Owner of the Lists those items belonged to. Snapshotting is deliberate: we want "what did we buy at Walmart in March" to survive renames, category edits and Item deletion, so the Purchase does not resolve through mutable Item rows.
