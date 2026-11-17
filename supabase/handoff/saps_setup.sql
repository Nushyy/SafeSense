-- =====================================================================
-- SafeSense · SAPS case desk · database setup
-- Run in Supabase: SQL Editor > New query > paste > Run.
-- Owner: whoever owns the database. Read the ASSUMPTIONS first.
--
-- ASSUMPTIONS (change names below if your teammates used different ones):
--   public.reports    : id uuid, title text, description text, area text,
--                       lat float8, lng float8, status text default 'pending',
--                       created_at timestamptz, reporter_id uuid, is_anonymous bool
--   public.sos_alerts : id uuid, area text, lat float8, lng float8,
--                       status text default 'active', created_at timestamptz,
--                       user_id uuid, battery int
--   Report statuses : pending | verified | resolved | rejected
--   SOS statuses    : active | responding | resolved | false_alarm | cancelled
-- =====================================================================

-- 1. Roles ------------------------------------------------------------
create table if not exists public.profiles (
  id        uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone     text
);
alter table public.profiles add column if not exists role    text not null default 'citizen';
alter table public.profiles add column if not exists station text;
alter table public.profiles add column if not exists phone   text;
alter table public.profiles drop constraint if exists profiles_role_check;
alter table public.profiles add constraint profiles_role_check
  check (role in ('citizen', 'saps', 'admin'));
alter table public.profiles enable row level security;

-- Nobody signed in through the app can change a role. Only the SQL editor
-- or the service key can (that is how an administrator makes an officer).
create or replace function public.block_role_change() returns trigger
language plpgsql as $$
begin
  if new.role is distinct from old.role and auth.role() = 'authenticated' then
    raise exception 'role cannot be changed from the app';
  end if;
  return new;
end $$;
drop trigger if exists profiles_block_role_change on public.profiles;
create trigger profiles_block_role_change before update on public.profiles
  for each row execute function public.block_role_change();

-- Anyone signing up can only ever create a citizen profile.
drop policy if exists "own profile read"   on public.profiles;
drop policy if exists "own profile insert" on public.profiles;
drop policy if exists "own profile update" on public.profiles;
create policy "own profile read"   on public.profiles for select using (id = auth.uid());
create policy "own profile insert" on public.profiles for insert with check (id = auth.uid() and role = 'citizen');
create policy "own profile update" on public.profiles for update using (id = auth.uid());

-- 2. The one check every SAPS rule uses ---------------------------------
-- To also require two-step verification, add:
--   and coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
create or replace function public.is_saps() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('saps', 'admin')
  );
$$;
revoke all on function public.is_saps() from public, anon;
grant execute on function public.is_saps() to authenticated;

drop policy if exists "saps read profiles" on public.profiles;
create policy "saps read profiles" on public.profiles for select using (public.is_saps());

-- 3. Officers may READ cases. They never write the tables directly. -----
alter table public.reports    enable row level security;
alter table public.sos_alerts enable row level security;
drop policy if exists "saps read reports"    on public.reports;
drop policy if exists "saps read sos alerts" on public.sos_alerts;
create policy "saps read reports"    on public.reports    for select using (public.is_saps());
create policy "saps read sos alerts" on public.sos_alerts for select using (public.is_saps());

-- 4. One list for the desk. security_invoker = the caller's RLS applies,
--    so a citizen who queries this view gets nothing back.
--    Anonymous reports never expose the reporter.
create or replace view public.saps_cases with (security_invoker = true) as
  select r.id, 'report'::text as kind, coalesce(r.title, 'Report') as title,
         r.description, r.area, r.lat, r.lng, r.status, r.created_at,
         case when r.is_anonymous then null else p.full_name end as reporter_name,
         case when r.is_anonymous then null else p.phone     end as reporter_phone,
         null::int as battery
  from public.reports r
  left join public.profiles p on p.id = r.reporter_id
  union all
  select s.id, 'sos'::text, 'SOS alert', null, s.area, s.lat, s.lng, s.status,
         s.created_at, p.full_name, p.phone, s.battery
  from public.sos_alerts s
  left join public.profiles p on p.id = s.user_id;
revoke all on public.saps_cases from anon;
grant select on public.saps_cases to authenticated;

-- 5. Audit log: officers can read it, nobody can edit or delete it. -----
create table if not exists public.case_audit (
  id         bigint generated always as identity primary key,
  case_kind  text not null check (case_kind in ('report', 'sos')),
  case_id    uuid not null,
  officer_id uuid not null references public.profiles(id) default auth.uid(),
  action     text not null,
  reason     text,
  created_at timestamptz not null default now()
);
create index if not exists case_audit_case_idx on public.case_audit (case_id, created_at desc);
alter table public.case_audit enable row level security;
drop policy if exists "saps read audit" on public.case_audit;
create policy "saps read audit" on public.case_audit for select using (public.is_saps());
-- (no insert/update/delete policies on purpose: only the functions below write)

-- 6. The only two ways an officer changes anything ------------------------
create or replace function public.saps_set_status(
  p_kind text, p_id uuid, p_status text, p_reason text default null
) returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_saps() then
    raise exception 'not authorised' using errcode = '42501';
  end if;
  if p_kind = 'report' then
    if p_status not in ('pending', 'verified', 'resolved', 'rejected') then
      raise exception 'invalid report status'; end if;
    update public.reports set status = p_status where id = p_id;
  elsif p_kind = 'sos' then
    if p_status not in ('active', 'responding', 'resolved', 'false_alarm') then
      raise exception 'invalid sos status'; end if;
    update public.sos_alerts set status = p_status where id = p_id;
  else
    raise exception 'invalid kind';
  end if;
  insert into public.case_audit (case_kind, case_id, officer_id, action, reason)
  values (p_kind, p_id, auth.uid(), 'status:' || p_status, p_reason);
end $$;

create or replace function public.saps_log_open(p_kind text, p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_saps() then
    raise exception 'not authorised' using errcode = '42501';
  end if;
  insert into public.case_audit (case_kind, case_id, officer_id, action)
  values (p_kind, p_id, auth.uid(), 'opened');
end $$;

revoke all on function public.saps_set_status(text, uuid, text, text) from public, anon;
revoke all on function public.saps_log_open(text, uuid)               from public, anon;
grant execute on function public.saps_set_status(text, uuid, text, text) to authenticated;
grant execute on function public.saps_log_open(text, uuid)               to authenticated;

-- 7. Live updates (the desk refreshes when these tables change) ----------
alter publication supabase_realtime add table public.reports;
alter publication supabase_realtime add table public.sos_alerts;
-- If you get "already member of publication", that is fine.

-- =====================================================================
-- MAKING AN OFFICER (administrator only, never from the app)
--  1. Supabase > Authentication > Users > Add user (email + password,
--     tick "Auto confirm user").
--  2. Run, with the officer's email:
--
--   insert into public.profiles (id, full_name, role, station)
--   select id, 'Sgt. M. Dlamini', 'saps', 'Soweto'
--   from auth.users where email = 'm.dlamini@station.example'
--   on conflict (id) do update
--     set role = 'saps', full_name = excluded.full_name, station = excluded.station;
--
-- REMOVING ACCESS:  update public.profiles set role = 'citizen' where id = '...';
-- =====================================================================
