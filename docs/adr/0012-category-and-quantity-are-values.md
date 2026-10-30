# Category and Quantity are values, not entities

An Item's Category and Quantity are free-text values ("Dairy", "2 L") written by the person capturing the Item, deduped by name within the Household when a picker wants suggestions. We rejected a per-Household `categories` table: v1 has no verbs for it — no rename, no merge, no reorder — and a table implies them.

Consequences: taxonomy growth (merge, rename, autocomplete ranking) stays post-v1 fog; a Purchase Line copies the text it saw, so history never resolves through a mutable row (**superseded by [ADR-0017](0017-purchase-lines-reference-rows-and-every-delete-cascades.md)**: a Line carries no copied text, so a Purchase Line reads the Item's current Quantity, and deleting the Item deletes the Line); and ordering a Kinetic View by Category is a string sort.
