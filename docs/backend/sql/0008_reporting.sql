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
-- Round two (14 Oct 2026, brief item 1): 'cancelled_late' uses one credit and keeps its seat. 'cancelled' = notice on
-- time (no credit). (Superseded in round three: 'cancelled_late' is NOT counted as absent; see below.)
-- New columns are appended at the end, so the existing column order is unchanged and create or replace view still works.
-- Round three (14 Oct 2026, briefs 2, 6): cancellation counts come from booking_cancellation_log (outcomes
-- family_on_time = cancelled, family_late = cancelled_late, studio = cancelled_studio), not from the bookings table.
-- attendance_rate_pct leaves cancelled_late OUT of both the numerator and the denominator: a late cancellation is not
-- an absence. PROVISIONAL (verifier fix): whether cancelled_late sits in the denominator is open owner question g
-- (00 § 13B). Seats and credits use booking_is_live (0004).
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
  (count(b.id) filter (where public.booking_is_live(b.status)))::integer            as seats_booked,
  (count(b.id) filter (where b.status = 'attended'::public.booking_status))::integer as attended,
  (count(b.id) filter (where b.status = 'absent'::public.booking_status))::integer   as absent,
  -- Round three: the cancellation columns count the log (one row per cancellation event), not the bookings.
  (select count(*)::integer from public.booking_cancellation_log l
    where l.session_id = s.id and l.outcome = 'family_on_time')                     as cancelled,
  public.session_seats_left(s.id)                                                   as seats_left,
  (select count(*)::integer from public.booking_cancellation_log l
    where l.session_id = s.id and l.outcome = 'family_late')                        as cancelled_late,
  (select count(*)::integer from public.booking_cancellation_log l
    where l.session_id = s.id and l.outcome = 'studio')                             as cancelled_studio
from public.sessions s
left join public.bookings b on b.session_id = s.id
group by s.id;

comment on view public.report_session_fill is 'Seats booked / left per session (staff only). seats_booked includes cancelled_late (the seat stays taken). cancelled = family cancellation on time (credit kept; from booking_cancellation_log); cancelled_late = late notice (one credit used; from the log; no notice is an absence, not a cancellation); cancelled_studio = the studio cancelled (credit returned; from the log).';


-- Attendance per calendar month (non-cancelled sessions).
create or replace view public.report_attendance_monthly
with (security_invoker = true)
as
-- Round three: two parts joined by month. Bookings and attendance come from the sessions that are not cancelled (as
-- before). Cancellation counts come from booking_cancellation_log for every session (a studio cancellation is on a
-- cancelled session, so it must be counted there too). A month can appear with cancellations only.
with bookings_by_month as (
  select
    (date_trunc('month', s.session_date::timestamp))::date                               as month,
    (count(distinct s.id))::integer                                                      as sessions,
    (count(b.id) filter (where public.booking_is_live(b.status)))::integer               as bookings,
    (count(b.id) filter (where b.status = 'attended'::public.booking_status))::integer    as attended,
    (count(b.id) filter (where b.status = 'absent'::public.booking_status))::integer      as absent,
    (count(b.id) filter (where b.consumes_credit and public.booking_is_live(b.status)))::integer as credit_bookings
  from public.sessions s
  left join public.bookings b on b.session_id = s.id
  where s.status <> 'cancelled'::public.session_status
  group by 1
),
cancels_by_month as (
  select
    (date_trunc('month', s.session_date::timestamp))::date                                as month,
    (count(*) filter (where l.outcome = 'family_on_time'))::integer                       as cancelled,
    (count(*) filter (where l.outcome = 'family_late'))::integer                          as cancelled_late,
    (count(*) filter (where l.outcome = 'studio'))::integer                               as cancelled_studio
  from public.booking_cancellation_log l
  join public.sessions s on s.id = l.session_id
  group by 1
)
select
  coalesce(bm.month, cm.month)                                                           as month,
  coalesce(bm.sessions, 0)                                                               as sessions,
  coalesce(bm.bookings, 0)                                                               as bookings,
  coalesce(bm.attended, 0)                                                               as attended,
  coalesce(bm.absent, 0)                                                                 as absent,
  coalesce(cm.cancelled, 0)                                                              as cancelled,
  round(
    100.0 * coalesce(bm.attended, 0)
    / nullif(coalesce(bm.attended, 0) + coalesce(bm.absent, 0), 0),
    1)                                                                                   as attendance_rate_pct,
  coalesce(cm.cancelled_late, 0)                                                         as cancelled_late,
  coalesce(bm.credit_bookings, 0)                                                        as credit_bookings,
  coalesce(cm.cancelled_studio, 0)                                                       as cancelled_studio
from bookings_by_month bm
full join cancels_by_month cm on cm.month = bm.month;

comment on view public.report_attendance_monthly is
  'Attendance per month (round three). attendance_rate_pct = attended / (attended + absent) × 100, NULL when nothing was marked. cancelled_late (late notice; one credit used; seat kept) is NOT an absence and is left out of the rate (provisional: owner question g, 00 § 13B). cancelled = family cancellation on time (credit kept). cancelled_studio = the studio cancelled (credit returned). The three cancellation columns come from booking_cancellation_log. credit_bookings = consumes_credit and live (booking_is_live), the same rule as package_balances.';


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
