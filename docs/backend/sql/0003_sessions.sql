-- =============================================================================
-- 0003_sessions.sql · CherryLee & Co. backend · DRAFT MIGRATION
-- -----------------------------------------------------------------------------
-- Phase:      P2 (feature F2-01)
-- Gate:       G4 — a HUMAN applies this file through Lovable chat. Implementers never run it.
-- Purpose:    one row per Saturday/Sunday class day with a staff-set capacity (D14);
--             seats-left aggregate; the ONLY public read path get_open_sessions()
--             (service role only, never returns capacity); weekend generator for staff.
-- Depends on: 0001_foundation.sql, 0002_booking_requests.sql
-- Apply via Lovable chat:
--   "Apply this SQL migration exactly as written. Do not change it."
-- After applying: git pull --ff-only; types.ts must contain "sessions" and "get_open_sessions".
-- Rules: additive only. Safe to run twice.
-- Times: session_date is a Bangkok calendar date; starts_at/ends_at are Bangkok wall-clock
--        times (type time). "Today" = (now() at time zone 'Asia/Bangkok')::date.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- 1. Enum
-- -----------------------------------------------------------------------------

do $$
begin
  if not exists (select 1 from pg_type t join pg_namespace n on n.oid = t.typnamespace
                 where n.nspname = 'public' and t.typname = 'session_status') then
    create type public.session_status as enum ('draft', 'open', 'closed', 'cancelled');
  end if;
end
$$;


-- -----------------------------------------------------------------------------
-- 2. sessions
--    capacity NULL = not set yet → seats_left is NULL → the public page says "ask us on LINE".
--    seats_held_offline = seats promised on LINE but not yet entered as bookings.
-- -----------------------------------------------------------------------------

create table if not exists public.sessions (
  id                  uuid primary key default gen_random_uuid(),
  session_date        date not null,
  starts_at           time not null default '09:00',
  ends_at             time not null default '15:00',
  capacity            integer
                        constraint sessions_capacity_positive
                        check (capacity is null or capacity > 0),
  seats_held_offline  integer not null default 0
                        constraint sessions_seats_held_offline_nonneg
                        check (seats_held_offline >= 0),
  status              public.session_status not null default 'draft',
  public_note_th      text check (public_note_th is null or char_length(public_note_th) <= 200),
  public_note_en      text check (public_note_en is null or char_length(public_note_en) <= 200),
  staff_note          text check (staff_note is null or char_length(staff_note) <= 1000),
  created_by          uuid references auth.users (id) on delete set null,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  constraint sessions_time_order check (ends_at > starts_at),
  constraint sessions_date_start_key unique (session_date, starts_at)
);

comment on table public.sessions is
  'One class day (Sat/Sun 09:00–15:00 by default). Capacity is staff-set and NEVER public; the public only sees seats left via get_open_sessions().';
comment on column public.sessions.public_note_th is 'Short public note shown next to the date (Thai). No names, no policies the studio has not set.';

create index if not exists sessions_status_date_idx on public.sessions (status, session_date);
create index if not exists sessions_date_idx on public.sessions (session_date);

create or replace trigger sessions_set_updated_at
  before update on public.sessions
  for each row execute function public.set_updated_at();

alter table public.sessions enable row level security;
revoke all on table public.sessions from anon, authenticated;
grant select, insert, update, delete on table public.sessions to authenticated;
grant all on table public.sessions to service_role;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'sessions' and policyname = 'sessions_staff_select') then
    create policy "sessions_staff_select" on public.sessions
      for select to authenticated
      using ((select public.is_staff()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'sessions' and policyname = 'sessions_staff_insert') then
    create policy "sessions_staff_insert" on public.sessions
      for insert to authenticated
      with check ((select public.is_staff()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'sessions' and policyname = 'sessions_staff_update') then
    create policy "sessions_staff_update" on public.sessions
      for update to authenticated
      using ((select public.is_staff()))
      with check ((select public.is_staff()));
  end if;
  if not exists (select 1 from pg_policies where schemaname = 'public' and tablename = 'sessions' and policyname = 'sessions_owner_delete') then
    create policy "sessions_owner_delete" on public.sessions
      for delete to authenticated
      using ((select public.is_owner()));
  end if;
end
$$;


-- -----------------------------------------------------------------------------
-- 3. booking_requests.session_id — the date a parent picked on /book (optional)
-- -----------------------------------------------------------------------------

alter table public.booking_requests
  add column if not exists session_id uuid references public.sessions (id) on delete set null;

create index if not exists booking_requests_session_idx on public.booking_requests (session_id);

grant update (session_id) on table public.booking_requests to authenticated;


-- -----------------------------------------------------------------------------
-- 4. session_seats_left(p_session_id) — v1: capacity − seats_held_offline (never below 0)
--    NULL when capacity is not set. Replaced in 0004 to also subtract bookings.
-- -----------------------------------------------------------------------------

-- plpgsql so it can refuse signed-in users without a staff role (review R-20). Staff, the service role
-- (get_open_sessions) and pg_cron/SQL editor pass require_staff_or_server().
create or replace function public.session_seats_left(p_session_id uuid)
returns integer
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_left integer;
begin
  perform public.require_staff_or_server();
  select case
           when s.capacity is null then null
           else greatest(s.capacity - s.seats_held_offline, 0)
         end
    into v_left
    from public.sessions s
   where s.id = p_session_id;
  return v_left;
end;
$$;

revoke execute on function public.session_seats_left(uuid) from public, anon;
grant execute on function public.session_seats_left(uuid) to authenticated, service_role;


-- -----------------------------------------------------------------------------
-- 4b. get_sessions_with_seats(p_from, p_to) — ONE call for the /admin/sessions month list (review R-18,
--     no per-row RPC from a Worker). SECURITY INVOKER: sessions RLS applies (staff only see rows).
--     v1: booked is always 0 (there are no bookings yet). 0004 replaces it with the real count.
-- -----------------------------------------------------------------------------

create or replace function public.get_sessions_with_seats(p_from date, p_to date)
returns table (
  session_id          uuid,
  session_date        date,
  starts_at           time,
  ends_at             time,
  capacity            integer,
  seats_held_offline  integer,
  status              public.session_status,
  public_note_th      text,
  public_note_en      text,
  staff_note          text,
  seats_left          integer,
  booked              integer
)
language sql
stable
security invoker
set search_path = ''
as $$
  select s.id, s.session_date, s.starts_at, s.ends_at, s.capacity, s.seats_held_offline, s.status,
         s.public_note_th, s.public_note_en, s.staff_note,
         public.session_seats_left(s.id),
         0
    from public.sessions s
   where s.session_date between p_from and p_to
   order by s.session_date, s.starts_at;
$$;

revoke execute on function public.get_sessions_with_seats(date, date) from public, anon;
grant execute on function public.get_sessions_with_seats(date, date) to authenticated, service_role;


-- -----------------------------------------------------------------------------
-- 5. get_open_sessions(p_from, p_to) — the ONLY public read path for sessions.
--    Service role only (called by getOpenSessions). Returns open sessions from
--    max(p_from, today in Bangkok) to min(p_to, today + 70 days). Never capacity, never names.
--    NULL p_from / p_to are allowed (GREATEST/LEAST ignore NULLs).
-- -----------------------------------------------------------------------------

create or replace function public.get_open_sessions(p_from date, p_to date)
returns table (
  session_id      uuid,
  session_date    date,
  starts_at       time,
  ends_at         time,
  seats_left      integer,
  public_note_th  text,
  public_note_en  text
)
language sql
stable
security definer
set search_path = ''
as $$
  select s.id,
         s.session_date,
         s.starts_at,
         s.ends_at,
         public.session_seats_left(s.id),
         s.public_note_th,
         s.public_note_en
  from public.sessions s
  where s.status = 'open'::public.session_status
    and s.session_date >= greatest(p_from, (now() at time zone 'Asia/Bangkok')::date)
    and s.session_date <= least(p_to, (now() at time zone 'Asia/Bangkok')::date + 70)
  order by s.session_date, s.starts_at;
$$;

revoke execute on function public.get_open_sessions(date, date) from public, anon, authenticated;
grant execute on function public.get_open_sessions(date, date) to service_role;


-- -----------------------------------------------------------------------------
-- 6. generate_weekend_sessions(p_from, p_weeks, p_capacity) — staff only
--    Creates a Saturday and a Sunday session (09:00–15:00, status 'open') for p_weeks weeks,
--    starting with the first Saturday ON or AFTER p_from. Existing dates are skipped.
--    p_capacity NULL → studio_settings.default_session_capacity (may also be NULL).
--    Returns the number of sessions created. SECURITY INVOKER: RLS applies as the staff user.
-- -----------------------------------------------------------------------------

create or replace function public.generate_weekend_sessions(p_from date, p_weeks integer, p_capacity integer)
returns integer
language plpgsql
volatile
security invoker
set search_path = ''
as $$
declare
  v_first_saturday date;
  v_capacity       integer;
  v_created        integer := 0;
  v_rows           integer;
  v_day            date;
  v_week           integer;
begin
  if not public.is_staff() then
    raise exception 'Not allowed: staff only' using errcode = '42501';
  end if;
  if p_from is null or p_weeks is null or p_weeks < 1 or p_weeks > 26 then
    raise exception 'p_from is required and p_weeks must be between 1 and 26' using errcode = '22023';
  end if;
  if p_capacity is not null and p_capacity < 1 then
    raise exception 'p_capacity must be NULL or greater than 0' using errcode = '22023';
  end if;

  v_capacity := coalesce(
    p_capacity,
    (select st.default_session_capacity from public.studio_settings st where st.id)
  );

  -- isodow: Monday = 1 … Saturday = 6, Sunday = 7
  v_first_saturday := p_from + ((6 - extract(isodow from p_from)::integer + 7) % 7);

  for v_week in 0 .. p_weeks - 1 loop
    foreach v_day in array array[v_first_saturday + v_week * 7, v_first_saturday + v_week * 7 + 1] loop
      insert into public.sessions (session_date, capacity, status, created_by)
      values (v_day, v_capacity, 'open'::public.session_status, auth.uid())
      on conflict (session_date, starts_at) do nothing;
      get diagnostics v_rows = row_count;
      v_created := v_created + v_rows;
    end loop;
  end loop;

  return v_created;
end;
$$;

revoke execute on function public.generate_weekend_sessions(date, integer, integer) from public, anon;
grant execute on function public.generate_weekend_sessions(date, integer, integer) to authenticated;

-- End of 0003_sessions.sql
