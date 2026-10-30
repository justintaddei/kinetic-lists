# Shared lists have equal Owners, no roles

A List has many-to-many Owners with identical powers: any Owner can add or remove other Owners, remove any Item, and delete the List (last Owner leaving deletes it). We rejected owner/member role tiers because every hierarchy we sketched existed only to protect against a co-owner the user picked themselves, on a personal app. The accepted cost is destructive foot-guns, paid for with confirmation screens that name the other Owners.

Tenancy is a `list_owners` join table; RLS filters through it with `(select auth.uid())`, and the helper that breaks `lists`↔`list_owners` policy recursion is `security definer` with `set search_path = ''` in a non-exposed schema.
