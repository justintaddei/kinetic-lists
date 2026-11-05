create extension if not exists postgis with schema extensions;

create table locations (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  store_id uuid not null references public.stores (id) on delete cascade,
  location geography(point, 4326) not null,
  accuracy_m real -- accuracy of the reading when it was saved
);

create index on public.locations using gist (location);

alter table public.locations
  enable row level security;

create policy "User's own locations"
on public.locations
as permissive
for all
to public
using (private.is_member(household_id))
with check (private.is_member(household_id));

grant select, insert, update, delete on table public.locations to authenticated;
