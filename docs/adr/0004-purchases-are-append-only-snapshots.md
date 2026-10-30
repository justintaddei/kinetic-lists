# Purchases are append-only and snapshot their items

Clearing a Basket writes a Purchase row (Owner, Store, time) plus one row per checked List Item, capturing the name, quantity and Store at that moment; the List Items are then unchecked. History is append-only and never edited, visible to every Owner of the Lists those items belonged to. Snapshotting is deliberate: we want "what did we buy at Walmart in March" to survive renames, category edits and Item deletion, so the Purchase does not resolve through mutable Item rows.
