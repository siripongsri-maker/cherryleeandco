-- =============================================================================
-- 0008_reporting.sql · CherryLee & Co. backend · DRAFT MIGRATION
-- -----------------------------------------------------------------------------
-- Phase:      P6 (feature F6-01)
-- Gate:       G4 — a HUMAN applies this file through Lovable chat. Implementers never run it.
-- Purpose:    aggregate-only report views for /admin/reports (no names, no contacts, no health).
--             All views use security_invoker = true, so the caller's RLS applies (staff only).
--             report_revenue_monthly additionally returns rows only to the OWNER.
-- Depends on: 0001–0005, 0007 (uses session_seats_left v2 from 0004)
-- Apply via Lovable chat:
--   "Apply this SQL migration exactly as written. Do not change it."
-- After applying: git pull --ff-only; types.ts must contain "report_requests_weekly".
-- Rules: additive only. Safe to run twice (create or replace view).
-- Note: booking requests are deleted after 6 months, so request reports cover at most ~6 months;
--       bookings after 24 months; payments after ~5 years.
-- =============================================================================


-- Requests per ISO week (Monday start, Bangkok time) and status.
create or replace view public.report_requests_weekly
with (security_invoker = true)
as
select
  (date_trunc('week', br.created_at at time zone 'Asia/Bangkok'))::date  as week_start,
  br.status,
  count(*)::integer                                                      as requests,
  coalesce(sum(br.children_count), 0)::integer                           as children
from public.booking_requests br
group by 1, 2;

comment on view public.report_requests_weekly is
  'Booking requests per week (Monday, Bangkok) and status. Conversion = converted / all, computed in the UI.';


-- Seats per session. capacity is fine here: staff-only (sessions RLS); never exposed publicly.
create or replace view public.report_session_fill
with (security_invoker = true)
as
select
  s.id                                                                              as session_id,
  s.session_date,
  s.status,
  s.capacity,
  s.seats_held_offline,
  (count(b.id) filter (where b.status in ('held'::public.booking_status, 'confirmed'::public.booking_status,
                                          'attended'::public.booking_status, 'absent'::public.booking_status)))::integer
                                                                                    as seats_booked,
  (count(b.id) filter (where b.status = 'attended'::public.booking_status))::integer as attended,
  (count(b.id) filter (where b.status = 'absent'::public.booking_status))::integer   as absent,
  (count(b.id) filter (where b.status = 'cancelled'::public.booking_status))::integer as cancelled,
  public.session_seats_left(s.id)                                                   as seats_left
from public.sessions s
left join public.bookings b on b.session_id = s.id
group by s.id;

comment on view public.report_session_fill is 'Seats booked / left per session (staff only).';


-- Attendance per calendar month (non-cancelled sessions).
create or replace view public.report_attendance_monthly
with (security_invoker = true)
as
select
  (date_trunc('month', s.session_date::timestamp))::date                             as month,
  (count(distinct s.id))::integer                                                    as sessions,
  (count(b.id) filter (where b.status <> 'cancelled'::public.booking_status))::integer as bookings,
  (count(b.id) filter (where b.status = 'attended'::public.booking_status))::integer   as attended,
  (count(b.id) filter (where b.status = 'absent'::public.booking_status))::integer     as absent,
  (count(b.id) filter (where b.status = 'cancelled'::public.booking_status))::integer  as cancelled,
  round(
    100.0 * count(b.id) filter (where b.status = 'attended'::public.booking_status)
    / nullif(count(b.id) filter (where b.status in ('attended'::public.booking_status,
                                                   'absent'::public.booking_status)), 0),
    1)                                                                               as attendance_rate_pct
from public.sessions s
left join public.bookings b on b.session_id = s.id
where s.status <> 'cancelled'::public.session_status
group by 1;

comment on view public.report_attendance_monthly is
  'Attendance per month. attendance_rate_pct = attended / (attended + absent) × 100, NULL when nothing was marked.';


-- Revenue per month (Bangkok) and method. OWNER ONLY: other callers get zero rows.
create or replace view public.report_revenue_monthly
with (security_invoker = true)
as
select
  (date_trunc('month', p.paid_at at time zone 'Asia/Bangkok'))::date                      as month,
  p.method,
  (count(*) filter (where p.status = 'paid'::public.payment_status))::integer             as payments_paid,
  (coalesce(sum(p.amount_thb) filter (where p.status = 'paid'::public.payment_status), 0))::integer
                                                                                         as paid_thb,
  (count(*) filter (where p.status = 'refunded'::public.payment_status))::integer         as payments_refunded,
  (coalesce(sum(p.amount_thb) filter (where p.status = 'refunded'::public.payment_status), 0))::integer
                                                                                         as refunded_thb
from public.payments p
where p.paid_at is not null
  and (select public.is_owner())
group by 1, 2;

comment on view public.report_revenue_monthly is
  'Paid and refunded amounts (integer baht) per month and method. Returns rows to the owner only.';


revoke all on table public.report_requests_weekly, public.report_session_fill,
                    public.report_attendance_monthly, public.report_revenue_monthly
  from anon, authenticated;
grant select on table public.report_requests_weekly, public.report_session_fill,
                      public.report_attendance_monthly, public.report_revenue_monthly
  to authenticated, service_role;

-- End of 0008_reporting.sql
