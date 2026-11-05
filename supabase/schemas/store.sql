create table public.stores (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  name text not null,
  constraint store_name_length_check check (char_length(name) > 0 and char_length(name) <= 50)
);

alter table public.stores
  enable row level security;

create policy "User's own stores"
on public.stores
as permissive
for all
to public
using (private.is_member(household_id))
with check (private.is_member(household_id));

grant select, insert, update, delete on table public.stores to authenticated;
