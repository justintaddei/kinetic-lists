# Items are per-user, shared by list

> **Superseded by [ADR-0009](0009-households-own-everything.md):** Items belong to a Household, deduped by name within it. The rejection of a canonical global catalogue survives unchanged.

An Item (name, category, default quantity, Store Tags) belongs to the user who created it; adding it to a shared List makes it visible to that List's other Owners, and an Item created inside a shared List is owned by its creator and shared with that List. We rejected a global canonical catalogue (one shared "milk" record): it needs moderation, a product vocabulary, and writes by strangers, and buys nothing for a handful of users.

Consequence: the same physical product can exist as two Items with the same name in one shared List, from two creators. Dedupe is by name within a user, not across users.
