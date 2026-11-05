create table public.basket_items (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  item_id uuid not null references public.items (id) on delete cascade,
  basket_id uuid not null references public.baskets (id) on delete cascade,
  constraint basket_items_unique unique (item_id, basket_id),
  quantity int not null default 1,
  constraint basket_items_quantity_is_positive check (quantity > 0)
);

alter table public.basket_items
  enable row level security;

create policy "User's own basket_items"
on public.basket_items
as permissive
for all
to public
using (private.is_member(household_id))
with check (private.is_member(household_id));

grant select, insert, update, delete on table public.basket_items to authenticated;
