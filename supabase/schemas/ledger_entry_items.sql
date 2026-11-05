create table public.ledger_entry_items (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  item_id uuid not null references public.items (id) on delete cascade,
  entry_id uuid not null references public.ledger_entries (id) on delete cascade,
  constraint ledger_entry_items_unique unique (item_id, entry_id),
  quantity int not null default 1,
  constraint ledger_entry_items_quantity_is_positive check (quantity > 0)
);

alter table public.ledger_entry_items
  enable row level security;

create policy "User's own ledger_entry_items"
on public.ledger_entry_items
as permissive
for all
to public
using (private.is_member(household_id))
with check (private.is_member(household_id));

grant select, insert, update, delete on table public.ledger_entry_items to authenticated;
