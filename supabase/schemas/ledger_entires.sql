create table public.ledger_entries (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households (id) on delete cascade,
  store_id uuid not null references public.stores (id) on delete cascade,
  created_at timestamp not null default now()
);

alter table public.ledger_entries
  enable row level security;

create policy "User's own ledger_entries"
on public.ledger_entries
as permissive
for all
to public
using (private.is_member(household_id))
with check (private.is_member(household_id));

grant select, insert, update, delete on table public.ledger_entries to authenticated;
