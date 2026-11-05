-- Declarative schema: this file is the source of truth for the `items` table.
-- Edit it, then generate a migration with `pnpm schema:sync -f <migration-name>`.
create table public.items (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  name text not null,
  constraint items_name_valid_length_check check (char_length(name) > 0 and char_length(name) < 50)
);

alter table public.items
  enable row level security;

create policy "User's' own items"
on public.items
as permissive
for all
to authenticated
using (private.is_member(household_id));

-- Explicit Data API grants so `db push` works even if `api.auto_expose_new_tables` is disabled.
-- No `anon` grant: an anonymous key must not reach this table at all.
grant select, insert, update, delete on table public.items to authenticated;
