create table public.lists (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  name text not null,
  constraint households_name_length_check check (char_length(name) > 0 and char_length(name) <= 50)
);

alter table public.lists
  enable row level security;

create policy "User's own lists"
on public.lists
as permissive
for all
to public
using (private.is_member(household_id))
with check (private.is_member(household_id));

grant select, insert, update, delete on table public.lists to authenticated;
