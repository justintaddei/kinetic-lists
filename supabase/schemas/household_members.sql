create table "public"."household_members" (
  "household_id" uuid not null,
  "user_id"      uuid not null,
  "display_name" text not null,
  constraint "household_members_pkey" primary key (household_id, user_id),
  constraint "household_members_user_id_fkey" foreign key (user_id) references auth.users(id) on delete cascade,
  constraint "household_members_user_id_key" unique (user_id),
  constraint "household_members_household_id_fkey" foreign key (household_id) references public.households(id) on delete cascade
);


alter table "public"."household_members"
  enable row level security;

create policy "household_members_read_by_member" on "public"."household_members"
  for select
  to "authenticated"
  using (private.is_member(household_id));

create policy "household_members_rename_self" on "public"."household_members"
  for update
  to "authenticated"
  using ((( select auth.uid() as uid) = user_id))
  with check ((( select auth.uid() as uid) = user_id));

revoke all on table "public"."household_members" from "authenticated";

grant maintain, references, select, trigger, truncate, update on table "public"."household_members" to "authenticated";

revoke all on table "public"."household_members" from "postgres";

grant delete, insert, maintain, references, select, trigger, truncate, update on table "public"."household_members" to "postgres";

revoke all on table "public"."household_members" from "service_role";

grant maintain, references, trigger, truncate on table "public"."household_members" to "service_role";

revoke all on table "public"."household_members" from "anon";

create policy "members_select_auth_admin" on "public"."household_members"
  for select
  to "supabase_auth_admin"
  using (true);
