create table public.list_items (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  item_id uuid not null references public.items (id) on delete cascade,
  list_id uuid not null references public.lists (id) on delete cascade,
  constraint list_items_unique unique (item_id, list_id)
);

alter table public.list_items
  enable row level security;

create policy "User's own list_items"
on public.list_items
as permissive
for all
to public
using (private.is_member(household_id))
with check (private.is_member(household_id));

grant select, insert, update, delete on table public.list_items to authenticated;
