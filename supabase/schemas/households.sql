create table public.households (
  id uuid primary key default gen_random_uuid(),
  name text not null default 'My Household',
  constraint households_name_length_check check (char_length(name) > 0 and char_length(name) <= 50)
);

alter table public.households
  enable row level security;

create policy "User's own household"
on public.households
as permissive
for all
to authenticated
using (private.is_member(id));

grant select, insert, update, delete on table public.households to authenticated;
