create table public.baskets (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  store_id uuid not null references public.stores (id) on delete cascade,
  constraint baskets_store_unique unique (store_id, household_id)
);

alter table public.baskets
  enable row level security;

create policy "User's own baskets"
on public.baskets
as permissive
for all
to public
using (private.is_member(household_id))
with check (private.is_member(household_id));

grant select, insert, update, delete on table public.baskets to authenticated;
