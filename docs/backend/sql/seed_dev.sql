-- =============================================================================
-- seed_dev.sql · CherryLee & Co. backend · FAKE DEV DATA + BEHAVIOUR CHECKS
-- -----------------------------------------------------------------------------
-- NOT A MIGRATION. Never paste this into Lovable chat as "apply this migration".
-- FAKE DATA ONLY (ผู้ปกครองทดสอบ / Test Parent / น้องทดสอบ / 0800000001 / test.line.id).
--
-- Needs: 0001–0005, 0007 and 0008 applied (0006 not needed: this file creates its own
--        TEST consent texts, version 999).
-- Where to run (in this order of preference):
--   1. A LOCAL Supabase (supabase start), after applying the migrations in order. Best option.
--   2. The Lovable Cloud database, ONLY by the builder with the owner's OK, pasted into
--      Lovable → More → Cloud → SQL editor (review R-19; never through Lovable chat, which may save it as
--      a migration). It is safe there ONLY because the last line is ROLLBACK.
-- NEVER remove or change the final ROLLBACK: drafts and the live site may share one database
-- (00-overview § 13), and the live database must never contain test rows.
-- Runs as the database owner (SQL editor / psql): RLS is bypassed and auth.uid() is NULL, so
-- audit rows show actor_kind = 'system'. Staff-permission behaviour is checked by
-- tests/rls_smoke.sql instead.
-- Output: NOTICE lines "PASS …" (and "SKIP …" where a check can't run on this database). The first failing
-- check raises "FAIL …" and aborts. The final SELECT prints one row when everything passed.
-- Coverage of the review fixes (00-overview § 15): § 6 starts with R-35; § 7b checks create_family_from_request
-- (R-15, R-38), the consent-change alert queue (D29/R-05), the allergy marker (R-07), the legacy/YouTube media rule
-- (R-11), set_media_asset_children and publish_consent_text (R-15), set_primary_guardian (R-39), submit_enrolment
-- (scope, R-21, R-22, R-33, R-34, link_used, health withdrawal) and the restriction guard (D28/R-09/R-36/R-37).
-- § 7c checks the 14 Oct 2026 decisions: marketing_line (guardian scope, guardian_consent_records, follow-up list),
-- media_print (same rules as media_social) and cancel_notice_hours (decisions 2, 3, 10; check_make_up_notice was removed in round three).
-- § 7d checks the round-two decisions of 14 Oct 2026: the credit rule by notice (cancelled vs cancelled_late, absent),
-- the allergen key flour, get_child_health with includeHealth, and the follow-up label and two-row rule.
-- § 7e checks the round-three decisions of 14 Oct 2026: cancel_booking() and booking_cancellation_log (on time, late,
-- studio; the notice channels line / phone / teacher / in_person), the rebooking rule (no make-up notice check), the
-- follow-up label for one, two and three children, the print status line (granted / refused / not_asked), the
-- 6-month clock (cancelled_late counts) and the reports read from the log. § 7c's make-up checks are gone.
-- Not checkable here: the row LOCK in submit_enrolment (needs two concurrent sessions; the reviewer reads the
-- FOR UPDATE at card P3-17).
-- =============================================================================

begin;

-- -----------------------------------------------------------------------------
-- 0. Fixed fake ids (readable on purpose) and dates relative to "today in Bangkok"
--    P  = last Saturday (past, closed)   N1 = next Saturday   N2 = the Sunday after N1
--    Test sessions start at 07:00 so they never collide with real 09:00 sessions.
-- -----------------------------------------------------------------------------

do $$
declare
  v_today date := (now() at time zone 'Asia/Bangkok')::date;
  v_n1    date;
begin
  v_n1 := v_today + ((6 - extract(isodow from v_today)::integer + 7) % 7);

  insert into public.sessions (id, session_date, starts_at, ends_at, capacity, status, public_note_en, staff_note)
  values
    ('b0000000-0000-4000-8000-000000000001', v_n1 - 7, '07:00', '08:00', 10, 'closed', 'TEST', 'TEST session P'),
    ('b0000000-0000-4000-8000-000000000002', v_n1,     '07:00', '08:00', 10, 'open',   'TEST', 'TEST session N1'),
    ('b0000000-0000-4000-8000-000000000003', v_n1 + 1, '07:00', '08:00', 2,  'open',   'TEST', 'TEST session N2');
  raise notice 'PASS sessions inserted (P %, N1 %, N2 %)', v_n1 - 7, v_n1, v_n1 + 1;
end
$$;


-- -----------------------------------------------------------------------------
-- 1. Booking request (P1)
-- -----------------------------------------------------------------------------

insert into public.booking_requests
  (id, ref_code, guardian_name, contact_phone, contact_line_id, preferred_contact, children,
   package_code, preferred_day, session_id, message, lang, privacy_notice_version)
values
  ('90000000-0000-4000-8000-000000000001', 'CL-TEST2', 'ผู้ปกครองทดสอบ', '0800000001', 'test.line.id', 'line',
   '[{"nickname": "น้องทดสอบ", "age_years": 8}, {"age_years": 11}]'::jsonb,
   'four', 'either', 'b0000000-0000-4000-8000-000000000002', 'TEST message', 'th', 'test-v0');

do $$
declare
  v_count smallint;
begin
  select br.children_count into v_count from public.booking_requests br
   where br.id = '90000000-0000-4000-8000-000000000001';
  if v_count is distinct from 2 then
    raise exception 'FAIL children_count should be 2, got %', v_count;
  end if;
  raise notice 'PASS children_count = 2';

  -- age 13 must be rejected
  begin
    insert into public.booking_requests (ref_code, guardian_name, contact_phone, preferred_contact, children, privacy_notice_version)
    values ('CL-TEST3', 'Test Parent', '0800000001', 'phone', '[{"age_years": 13}]'::jsonb, 'test-v0');
    raise exception 'FAIL a child aged 13 was accepted';
  exception when check_violation then
    raise notice 'PASS child aged 13 rejected';
  end;

  -- unknown key in a child object must be rejected
  begin
    insert into public.booking_requests (ref_code, guardian_name, contact_phone, preferred_contact, children, privacy_notice_version)
    values ('CL-TEST4', 'Test Parent', '0800000001', 'phone', '[{"age_years": 8, "school": "x"}]'::jsonb, 'test-v0');
    raise exception 'FAIL an extra child field was accepted';
  exception when check_violation then
    raise notice 'PASS extra child field rejected';
  end;

  -- D26 / R-03: a phone call-back needs a phone number; "line" needs nothing (the parent messages the OA)
  begin
    insert into public.booking_requests (ref_code, guardian_name, contact_line_id, preferred_contact, children, privacy_notice_version)
    values ('CL-TEST5', 'Test Parent', 'test.line.id', 'phone', '[{"age_years": 8}]'::jsonb, 'test-v0');
    raise exception 'FAIL preferred_contact phone without a phone number was accepted';
  exception when check_violation then
    raise notice 'PASS phone call-back needs a phone number';
  end;
  insert into public.booking_requests (ref_code, guardian_name, preferred_contact, children, privacy_notice_version)
  values ('CL-TEST6', 'Test Parent', 'line', '[{"age_years": 8}]'::jsonb, 'test-v0');
  raise notice 'PASS preferred_contact line with no phone and no LINE ID is accepted';

  -- bad ref code must be rejected
  begin
    insert into public.booking_requests (ref_code, guardian_name, contact_phone, preferred_contact, children, privacy_notice_version)
    values ('CL-TEST0', 'Test Parent', '0800000001', 'phone', '[{"age_years": 8}]'::jsonb, 'test-v0');
    raise exception 'FAIL ref code with 0 was accepted';
  exception when check_violation then
    raise notice 'PASS ref code pattern enforced';
  end;
end
$$;


-- -----------------------------------------------------------------------------
-- 2. Rate limit (P1): 5 per hour
-- -----------------------------------------------------------------------------

do $$
declare
  v_hash text := repeat('ab', 32);
  v_ok   boolean;
  i      integer;
begin
  for i in 1 .. 5 loop
    v_ok := public.check_rate_limit('seed_dev_test', v_hash, 5, 20);
    if not v_ok then
      raise exception 'FAIL rate limit blocked call % of 5', i;
    end if;
  end loop;
  v_ok := public.check_rate_limit('seed_dev_test', v_hash, 5, 20);
  if v_ok then
    raise exception 'FAIL 6th call in an hour was allowed';
  end if;
  raise notice 'PASS rate limit: 5 allowed, 6th refused';
end
$$;


-- -----------------------------------------------------------------------------
-- 3. Public open sessions (P2): seats left only, closed/past sessions hidden
-- -----------------------------------------------------------------------------

do $$
declare
  v_n1_left integer;
  v_n2_left integer;
  v_p_seen  boolean;
begin
  select os.seats_left into v_n1_left from public.get_open_sessions(null, null) os
   where os.session_id = 'b0000000-0000-4000-8000-000000000002';
  select os.seats_left into v_n2_left from public.get_open_sessions(null, null) os
   where os.session_id = 'b0000000-0000-4000-8000-000000000003';
  select exists (select 1 from public.get_open_sessions(null, null) os
                  where os.session_id = 'b0000000-0000-4000-8000-000000000001') into v_p_seen;
  if v_n1_left is distinct from 10 or v_n2_left is distinct from 2 then
    raise exception 'FAIL seats left should be 10 and 2, got % and %', v_n1_left, v_n2_left;
  end if;
  if v_p_seen then
    raise exception 'FAIL a closed past session is listed publicly';
  end if;
  raise notice 'PASS get_open_sessions shows seats left only for open future sessions';
end
$$;


-- -----------------------------------------------------------------------------
-- 4. Family, guardian, children, contacts, package, payment (P3)
-- -----------------------------------------------------------------------------

insert into public.families (id, display_name, source_request_id)
values ('f0000000-0000-4000-8000-000000000001', 'ครอบครัวทดสอบ (TEST)', '90000000-0000-4000-8000-000000000001'),
       ('f0000000-0000-4000-8000-000000000002', 'ครอบครัวทดสอบสอง (TEST)', null);

insert into public.guardians
  (id, family_id, full_name, phone, line_id, is_primary, has_parental_responsibility, responsibility_attested_at,
   identity_check_method, identity_checked_at)
values
  ('a0000000-0000-4000-8000-000000000001', 'f0000000-0000-4000-8000-000000000001', 'ผู้ปกครองทดสอบ',
   '0800000001', 'test.line.id', true, true, now(), 'line_account', now()),
  ('a0000000-0000-4000-8000-000000000002', 'f0000000-0000-4000-8000-000000000002', 'ผู้ปกครองทดสอบสอง',
   '0800000003', null, true, true, now(), null, null);

insert into public.children (id, family_id, nickname, birth_month)
values
  ('c0000000-0000-4000-8000-000000000001', 'f0000000-0000-4000-8000-000000000001', 'น้องทดสอบ',
   (date_trunc('month', now() at time zone 'Asia/Bangkok') - interval '8 years 2 months')::date),
  ('c0000000-0000-4000-8000-000000000002', 'f0000000-0000-4000-8000-000000000001', 'น้องทดสอบสอง',
   (date_trunc('month', now() at time zone 'Asia/Bangkok') - interval '11 years 2 months')::date);

insert into public.family_contacts
  (id, family_id, name, phone, relationship, is_emergency_contact, is_authorised_pickup, guardian_attests_informed_at)
values
  ('e0000000-0000-4000-8000-000000000001', 'f0000000-0000-4000-8000-000000000001', 'ผู้รับทดสอบ', '0800000002',
   'TEST relative', true, true, now()),
  ('e0000000-0000-4000-8000-000000000002', 'f0000000-0000-4000-8000-000000000001', 'ผู้ติดต่อฉุกเฉินทดสอบ', '0800000004',
   'TEST neighbour', true, false, now());

update public.booking_requests
   set status = 'converted', converted_family_id = 'f0000000-0000-4000-8000-000000000001'
 where id = '90000000-0000-4000-8000-000000000001';

insert into public.package_purchases (id, family_id, package_code, sessions_total, price_thb)
values ('d0000000-0000-4000-8000-000000000001', 'f0000000-0000-4000-8000-000000000001', 'four', 4, 14400);

insert into public.payments
  (id, family_id, package_purchase_id, amount_thb, method, status, paid_at, receipt_no, note)
values
  ('d1000000-0000-4000-8000-000000000001', 'f0000000-0000-4000-8000-000000000001',
   'd0000000-0000-4000-8000-000000000001', 14400, 'promptpay', 'paid', now(), 'TEST-0001', 'TEST payment');

do $$
declare
  v_retain timestamptz;
begin
  -- sessions_total must match package_code
  begin
    insert into public.package_purchases (family_id, package_code, sessions_total, price_thb)
    values ('f0000000-0000-4000-8000-000000000001', 'four', 5, 14400);
    raise exception 'FAIL package four with 5 sessions was accepted';
  exception when check_violation then
    raise notice 'PASS sessions_total must match package_code';
  end;

  select p.retain_until into v_retain from public.payments p where p.id = 'd1000000-0000-4000-8000-000000000001';
  if v_retain < now() + interval '5 years' or v_retain > now() + interval '6 years 1 day' then
    raise exception 'FAIL payment retain_until looks wrong: %', v_retain;
  end if;
  raise notice 'PASS payment retain_until = end of (year + 5): %', v_retain;
end
$$;


-- -----------------------------------------------------------------------------
-- 5. Bookings, credits, seats, attendance, pickup rules (P3)
-- -----------------------------------------------------------------------------

insert into public.bookings (id, session_id, child_id, package_purchase_id, status, checked_in_at, checked_out_at,
                             picked_up_by_contact_id)
values ('b1000000-0000-4000-8000-000000000001', 'b0000000-0000-4000-8000-000000000001',
        'c0000000-0000-4000-8000-000000000001', 'd0000000-0000-4000-8000-000000000001', 'attended',
        now() - interval '7 days', now() - interval '7 days' + interval '1 hour',
        'e0000000-0000-4000-8000-000000000001');

insert into public.bookings (id, session_id, child_id, package_purchase_id, status)
values ('b1000000-0000-4000-8000-000000000002', 'b0000000-0000-4000-8000-000000000002',
        'c0000000-0000-4000-8000-000000000001', 'd0000000-0000-4000-8000-000000000001', 'confirmed'),
       ('b1000000-0000-4000-8000-000000000003', 'b0000000-0000-4000-8000-000000000003',
        'c0000000-0000-4000-8000-000000000001', 'd0000000-0000-4000-8000-000000000001', 'confirmed'),
       ('b1000000-0000-4000-8000-000000000004', 'b0000000-0000-4000-8000-000000000003',
        'c0000000-0000-4000-8000-000000000002', 'd0000000-0000-4000-8000-000000000001', 'confirmed');

do $$
declare
  v_left       integer;
  v_seats      integer;
  v_family     uuid;
  v_last       date;
  v_p_date     date;
begin
  select pb.sessions_left into v_left from public.package_balances pb
   where pb.package_purchase_id = 'd0000000-0000-4000-8000-000000000001';
  if v_left is distinct from 0 then
    raise exception 'FAIL 4 bookings on a four-pack should leave 0, got %', v_left;
  end if;
  raise notice 'PASS package balance 0 after 4 bookings';

  select b.family_id into v_family from public.bookings b where b.id = 'b1000000-0000-4000-8000-000000000002';
  if v_family is distinct from 'f0000000-0000-4000-8000-000000000001'::uuid then
    raise exception 'FAIL bookings.family_id was not filled from the child';
  end if;
  raise notice 'PASS bookings.family_id filled from the child';

  select c.last_session_on into v_last from public.children c where c.id = 'c0000000-0000-4000-8000-000000000001';
  select s.session_date into v_p_date from public.sessions s where s.id = 'b0000000-0000-4000-8000-000000000001';
  if v_last is distinct from v_p_date then
    raise exception 'FAIL last_session_on should be %, got %', v_p_date, v_last;
  end if;
  raise notice 'PASS children.last_session_on follows attended bookings';

  v_seats := public.session_seats_left('b0000000-0000-4000-8000-000000000003');
  if v_seats is distinct from 0 then
    raise exception 'FAIL N2 (capacity 2, 2 bookings) should have 0 seats left, got %', v_seats;
  end if;
  raise notice 'PASS seats left counts bookings';

  -- no credit left → a 5th credit booking is refused
  begin
    insert into public.bookings (session_id, child_id, package_purchase_id, status)
    values ('b0000000-0000-4000-8000-000000000002', 'c0000000-0000-4000-8000-000000000002',
            'd0000000-0000-4000-8000-000000000001', 'confirmed');
    raise exception 'FAIL a booking beyond the package was accepted';
  exception when check_violation then
    raise notice 'PASS no booking beyond the package credits';
  end;

  -- round two: cancelled with notice on time (4 hours before N2 starts) returns the credit and the seat.
  -- Round three: cancellations go through cancel_booking() (the only path that writes booking_cancellation_log).
  perform public.cancel_booking('b1000000-0000-4000-8000-000000000003', 'line',
         (select (s.session_date + s.starts_at) at time zone 'Asia/Bangkok' - interval '4 hours'
            from public.sessions s where s.id = 'b0000000-0000-4000-8000-000000000003'),
         false);
  select pb.sessions_left into v_left from public.package_balances pb
   where pb.package_purchase_id = 'd0000000-0000-4000-8000-000000000001';
  v_seats := public.session_seats_left('b0000000-0000-4000-8000-000000000003');
  if v_left is distinct from 1 or v_seats is distinct from 1 then
    raise exception 'FAIL cancel should give 1 credit and 1 seat back, got % and %', v_left, v_seats;
  end if;
  raise notice 'PASS cancel with notice on time returns credit and seat (round two)';

  -- an emergency-only contact cannot be recorded as the pickup person
  begin
    update public.bookings set picked_up_by_contact_id = 'e0000000-0000-4000-8000-000000000002'
     where id = 'b1000000-0000-4000-8000-000000000001';
    raise exception 'FAIL a non-authorised pickup contact was accepted';
  exception when check_violation then
    raise notice 'PASS only authorised pickup contacts';
  end;

  -- a booking cannot be moved to another child
  begin
    update public.bookings set child_id = 'c0000000-0000-4000-8000-000000000002'
     where id = 'b1000000-0000-4000-8000-000000000002';
    raise exception 'FAIL a booking moved to another child';
  exception when check_violation then
    raise notice 'PASS booking cannot move to another child';
  end;

  -- family_contacts need a role
  begin
    insert into public.family_contacts (family_id, name, phone, relationship, guardian_attests_informed_at)
    values ('f0000000-0000-4000-8000-000000000001', 'TEST', '0800000005', 'TEST', now());
    raise exception 'FAIL a contact with no role was accepted';
  exception when check_violation then
    raise notice 'PASS contacts must be emergency and/or pickup';
  end;
end
$$;


-- -----------------------------------------------------------------------------
-- 6. Consent texts (TEST version 999), health consent, audited reads (P4)
-- -----------------------------------------------------------------------------

-- R-35: publish_consent_text() never creates the FIRST health_allergy text (G-HEALTH = paper must hold).
-- Runs before the TEST health text below exists; skipped when 0006 with health rows is already applied.
do $$
begin
  if exists (select 1 from public.consent_texts ct where ct.purpose = 'health_allergy') then
    raise notice 'SKIP R-35 first-health-text check: a health_allergy text already exists (G-HEALTH = system)';
  else
    begin
      perform public.publish_consent_text('health_allergy', 'TEST', 'TEST body — not real wording', 'TEST',
                                          'TEST body — not real wording', true, 10::smallint);
      raise exception 'FAIL publish_consent_text created the first health_allergy text';
    exception when check_violation then
      raise notice 'PASS publish_consent_text refuses the first health_allergy text (R-35)';
    end;
  end if;
end
$$;

insert into public.consent_texts (id, purpose, version, lang, title, body_md, is_explicit, requires_child_consent_from_age)
values
  ('60000000-0000-4000-8000-000000000001', 'health_allergy', 999, 'en', 'TEST health text', 'TEST body — not real wording', true, 10),
  ('60000000-0000-4000-8000-000000000002', 'media_website', 999, 'en', 'TEST media text', 'TEST body — not real wording', false, 10),
  ('60000000-0000-4000-8000-000000000003', 'media_youtube', 999, 'en', 'TEST media text (to retire)', 'TEST body — not real wording', false, 10);

do $$
declare
  v_sha        text;
  v_audit_0    bigint;
  v_audit_1    bigint;
  v_has        boolean;
  v_rows       integer;
begin
  select ct.sha256 into v_sha from public.consent_texts ct where ct.id = '60000000-0000-4000-8000-000000000001';
  if v_sha is null or v_sha !~ '^[0-9a-f]{64}$' then
    raise exception 'FAIL consent text sha256 not computed: %', v_sha;
  end if;
  raise notice 'PASS consent text sha256 computed';

  -- consent texts are immutable (only retired_at may change)
  begin
    update public.consent_texts set body_md = body_md || ' edited' where id = '60000000-0000-4000-8000-000000000001';
    raise exception 'FAIL a consent text body was edited';
  exception when insufficient_privilege then
    raise notice 'PASS consent text body cannot be edited';
  end;
  update public.consent_texts set retired_at = now() where id = '60000000-0000-4000-8000-000000000003';
  raise notice 'PASS consent text can be retired';

  -- a retired text cannot be used for a new grant
  begin
    insert into public.consent_records (family_id, guardian_id, child_id, purpose, consent_text_id, decision,
                                        given_by, media_level, channel, method)
    values ('f0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001',
            'c0000000-0000-4000-8000-000000000001', 'media_youtube', '60000000-0000-4000-8000-000000000003',
            'granted', 'guardian', 'face_visible', 'web', 'checkbox');
    raise exception 'FAIL a retired text was used for a grant';
  exception when check_violation then
    raise notice 'PASS retired text cannot be granted';
  end;

  -- health data without consent is refused by the database
  begin
    perform public.upsert_child_health('c0000000-0000-4000-8000-000000000001', array['peanut'], null, null, null);
    raise exception 'FAIL health data stored without consent';
  exception when insufficient_privilege then
    raise notice 'PASS health data needs explicit consent first';
  end;

  -- guardian gives explicit health consent through the private link
  insert into public.consent_records (family_id, guardian_id, child_id, purpose, consent_text_id, decision,
                                      given_by, channel, method)
  values ('f0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001',
          'c0000000-0000-4000-8000-000000000001', 'health_allergy', '60000000-0000-4000-8000-000000000001',
          'granted', 'guardian', 'web', 'checkbox');

  perform public.upsert_child_health('c0000000-0000-4000-8000-000000000001',
                                     array['peanut', 'egg', 'peanut'], 'TEST kiwi', '', 'TEST care note');
  select h.has_allergy into v_has from public.child_health h where h.child_id = 'c0000000-0000-4000-8000-000000000001';
  if v_has is distinct from true then
    raise exception 'FAIL health row missing or has_allergy false';
  end if;
  raise notice 'PASS health stored after consent';

  -- unknown allergen key refused
  begin
    perform public.upsert_child_health('c0000000-0000-4000-8000-000000000001', array['chocolate'], null, null, null);
    raise exception 'FAIL unknown allergen accepted';
  exception when check_violation then
    raise notice 'PASS allergen list enforced';
  end;

  -- each health read writes exactly one audit row
  select count(*) into v_audit_0 from public.audit_log a where a.action = 'read_health';
  perform * from public.get_child_health('c0000000-0000-4000-8000-000000000001', true);
  select count(*) into v_audit_1 from public.audit_log a where a.action = 'read_health';
  if v_audit_1 - v_audit_0 <> 1 then
    raise exception 'FAIL get_child_health wrote % audit rows', v_audit_1 - v_audit_0;
  end if;
  raise notice 'PASS get_child_health is audited';

  select count(*) into v_rows from public.list_session_health_flags('b0000000-0000-4000-8000-000000000002') f
   where f.child_id = 'c0000000-0000-4000-8000-000000000001' and 'peanut' = any (f.allergens);
  if v_rows <> 1 then
    raise exception 'FAIL roster health flags missing for the test child';
  end if;
  raise notice 'PASS list_session_health_flags returns allergen chips';

  -- consent_records are append-only
  begin
    update public.consent_records set decision = 'refused' where child_id = 'c0000000-0000-4000-8000-000000000001';
    raise exception 'FAIL a consent record was updated';
  exception when insufficient_privilege then
    raise notice 'PASS consent records are append-only';
  end;

  -- withdrawal deletes the health row immediately
  insert into public.consent_records (family_id, guardian_id, child_id, purpose, consent_text_id, decision,
                                      given_by, channel, method)
  values ('f0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001',
          'c0000000-0000-4000-8000-000000000001', 'health_allergy', '60000000-0000-4000-8000-000000000001',
          'withdrawn', 'guardian', 'web', 'checkbox');
  if exists (select 1 from public.child_health h where h.child_id = 'c0000000-0000-4000-8000-000000000001') then
    raise exception 'FAIL health row still exists after withdrawal';
  end if;
  if public.has_active_consent('c0000000-0000-4000-8000-000000000001', 'health_allergy') then
    raise exception 'FAIL has_active_consent still true after withdrawal';
  end if;
  raise notice 'PASS withdrawal deletes health data';
end
$$;


-- -----------------------------------------------------------------------------
-- 7. Media consent, children 10+ (D11), face level (P4)
-- -----------------------------------------------------------------------------

insert into public.media_assets (id, kind, title, shows_children, shows_faces, on_website)
values ('70000000-0000-4000-8000-000000000001', 'photo', 'TEST photo', true, true, true);
insert into public.media_asset_children (asset_id, child_id)
values ('70000000-0000-4000-8000-000000000001', 'c0000000-0000-4000-8000-000000000002');

do $$
declare
  v_status text;
begin
  -- guardian grants website use with face visible for the 11-year-old
  insert into public.consent_records (family_id, guardian_id, child_id, purpose, consent_text_id, decision,
                                      given_by, media_level, channel, method)
  values ('f0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001',
          'c0000000-0000-4000-8000-000000000002', 'media_website', '60000000-0000-4000-8000-000000000002',
          'granted', 'guardian', 'face_visible', 'web', 'checkbox');
  v_status := public.consent_status('c0000000-0000-4000-8000-000000000002', 'media_website');
  if v_status <> 'needs_child' then
    raise exception 'FAIL 11-year-old without own consent should be needs_child, got %', v_status;
  end if;
  if public.can_publish_media('70000000-0000-4000-8000-000000000001', 'media_website') then
    raise exception 'FAIL asset publishable without the child''s own consent';
  end if;
  raise notice 'PASS child 10+ needs own consent before publication';

  -- the child says yes in person (recorded by a fake staff id)
  insert into public.consent_records (family_id, child_id, purpose, consent_text_id, decision,
                                      given_by, channel, method, recorded_by)
  values ('f0000000-0000-4000-8000-000000000001', 'c0000000-0000-4000-8000-000000000002', 'media_website',
          '60000000-0000-4000-8000-000000000002', 'granted', 'child', 'in_person', 'staff_recorded_verbal',
          '50000000-0000-4000-8000-000000000001');
  if not public.can_publish_media('70000000-0000-4000-8000-000000000001', 'media_website') then
    raise exception 'FAIL asset not publishable after guardian + child consent';
  end if;
  if public.can_publish_media('70000000-0000-4000-8000-000000000001', 'media_youtube') then
    raise exception 'FAIL consent for website leaked to youtube';
  end if;
  raise notice 'PASS publishable on the consented channel only';

  -- guardian changes to face hidden → an asset that shows faces is no longer publishable
  insert into public.consent_records (family_id, guardian_id, child_id, purpose, consent_text_id, decision,
                                      given_by, media_level, channel, method)
  values ('f0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001',
          'c0000000-0000-4000-8000-000000000002', 'media_website', '60000000-0000-4000-8000-000000000002',
          'granted', 'guardian', 'face_hidden', 'web', 'checkbox');
  if public.can_publish_media('70000000-0000-4000-8000-000000000001', 'media_website') then
    raise exception 'FAIL face_hidden consent still allows an asset showing faces';
  end if;
  raise notice 'PASS face_hidden respected';

  -- a media grant without a face level is refused
  begin
    insert into public.consent_records (family_id, guardian_id, child_id, purpose, consent_text_id, decision,
                                        given_by, channel, method)
    values ('f0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001',
            'c0000000-0000-4000-8000-000000000001', 'media_website', '60000000-0000-4000-8000-000000000002',
            'granted', 'guardian', 'web', 'checkbox');
    raise exception 'FAIL media grant without media_level accepted';
  exception when check_violation then
    raise notice 'PASS media grant needs a face level';
  end;
end
$$;


-- -----------------------------------------------------------------------------
-- 7b. Review safety SQL (00-overview § 15). Uses the SECOND test family (f…0002) and a third one made from a
--     request, so section 8's export/erase counts for f…0001 stay the same.
--     c…0003 (7 y), c…0004 (11 y), c…0005 (7 y) are new children of f…0002.
-- -----------------------------------------------------------------------------

insert into public.children (id, family_id, nickname, birth_month)
values
  ('c0000000-0000-4000-8000-000000000003', 'f0000000-0000-4000-8000-000000000002', 'น้องทดสอบสาม',
   (date_trunc('month', now() at time zone 'Asia/Bangkok') - interval '7 years 2 months')::date),
  ('c0000000-0000-4000-8000-000000000004', 'f0000000-0000-4000-8000-000000000002', 'น้องทดสอบสี่',
   (date_trunc('month', now() at time zone 'Asia/Bangkok') - interval '11 years 2 months')::date),
  ('c0000000-0000-4000-8000-000000000005', 'f0000000-0000-4000-8000-000000000002', 'น้องทดสอบห้า',
   (date_trunc('month', now() at time zone 'Asia/Bangkok') - interval '7 years 2 months')::date);

insert into public.family_contacts
  (id, family_id, name, phone, relationship, is_emergency_contact, is_authorised_pickup, guardian_attests_informed_at)
values
  ('e0000000-0000-4000-8000-000000000003', 'f0000000-0000-4000-8000-000000000002', 'ผู้รับทดสอบสาม', '0800000008',
   'TEST relative', false, true, now());

insert into public.consent_texts (id, purpose, version, lang, title, body_md, is_explicit, requires_child_consent_from_age)
values ('60000000-0000-4000-8000-000000000004', 'media_youtube', 1000, 'en', 'TEST youtube text',
        'TEST body — not real wording', false, 10);

insert into public.booking_requests
  (id, ref_code, guardian_name, contact_phone, preferred_contact, children, privacy_notice_version)
values
  ('90000000-0000-4000-8000-000000000002', 'CL-TEST7', 'ผู้ปกครองทดสอบสาม', '0800000007', 'phone',
   '[{"nickname": "น้องทดสอบหก", "age_years": 9}]'::jsonb, 'test-v0'),
  ('90000000-0000-4000-8000-000000000003', 'CL-TEST8', 'Test Parent', null, 'line',
   '[{"age_years": 8}]'::jsonb, 'test-v0');

-- 7b.1 create_family_from_request (R-15) and the LINE path without any contact detail (D26, R-38)
do $$
declare
  v_fam uuid;
  v_n   integer;
begin
  v_fam := public.create_family_from_request(
    '90000000-0000-4000-8000-000000000002', 'ครอบครัวทดสอบสาม (TEST)',
    '{"full_name": "ผู้ปกครองทดสอบสาม", "phone": "0800000007", "line_id": null}'::jsonb,
    '[{"nickname": "น้องทดสอบหก", "age_years": 9}]'::jsonb);
  select count(*) into v_n from public.guardians g where g.family_id = v_fam and g.is_primary;
  if v_n <> 1 then
    raise exception 'FAIL create_family_from_request: expected 1 primary guardian, got %', v_n;
  end if;
  if not exists (select 1 from public.children c
                  where c.family_id = v_fam and c.reported_age_years = 9 and c.reported_age_on is not null) then
    raise exception 'FAIL create_family_from_request: the child''s age was not copied';
  end if;
  if not exists (select 1 from public.booking_requests br
                  where br.id = '90000000-0000-4000-8000-000000000002'
                    and br.status = 'converted' and br.converted_family_id = v_fam) then
    raise exception 'FAIL create_family_from_request: the request is not marked converted';
  end if;
  raise notice 'PASS create_family_from_request writes family, guardian, child and request status in one call';

  begin
    perform public.create_family_from_request('90000000-0000-4000-8000-000000000002', 'TEST again',
      '{"full_name": "Test Parent", "phone": "0800000007", "line_id": null}'::jsonb,
      '[{"nickname": "TEST", "age_years": 9}]'::jsonb);
    raise exception 'FAIL a request was converted twice';
  exception when check_violation then
    raise notice 'PASS a request converts only once';
  end;

  begin
    perform public.create_family_from_request('90000000-0000-4000-8000-000000000003', 'ครอบครัวทดสอบสี่ (TEST)',
      '{"full_name": "Test Parent", "phone": null, "line_id": null}'::jsonb,
      '[{"nickname": "TEST", "age_years": 8}]'::jsonb);
    raise exception 'FAIL a guardian with no phone, LINE ID or email was accepted';
  exception when check_violation then
    null;
  end;
  if exists (select 1 from public.families f where f.source_request_id = '90000000-0000-4000-8000-000000000003')
     or (select br.status::text from public.booking_requests br
          where br.id = '90000000-0000-4000-8000-000000000003') <> 'new' then
    raise exception 'FAIL a failed conversion left a half-written family behind';
  end if;
  raise notice 'PASS a conversion without any contact detail is refused and leaves nothing behind (R-38)';
end
$$;

-- 7b.2 set_primary_guardian (R-39): one primary at a time, swapped in one call
insert into public.guardians (id, family_id, full_name, phone, is_primary)
values ('a0000000-0000-4000-8000-000000000003', 'f0000000-0000-4000-8000-000000000002', 'ผู้ปกครองทดสอบสี่',
        '0800000010', false);

do $$
declare
  v_primary uuid;
  v_n       integer;
begin
  perform public.set_primary_guardian('a0000000-0000-4000-8000-000000000003');
  select g.id into v_primary from public.guardians g
   where g.family_id = 'f0000000-0000-4000-8000-000000000002' and g.is_primary;
  select count(*) into v_n from public.guardians g
   where g.family_id = 'f0000000-0000-4000-8000-000000000002' and g.is_primary;
  if v_n <> 1 or v_primary is distinct from 'a0000000-0000-4000-8000-000000000003'::uuid then
    raise exception 'FAIL set_primary_guardian: % primary guardians, primary = %', v_n, v_primary;
  end if;
  perform public.set_primary_guardian('a0000000-0000-4000-8000-000000000002');   -- back, for the checks below
  if not exists (select 1 from public.guardians g
                  where g.id = 'a0000000-0000-4000-8000-000000000002' and g.is_primary) then
    raise exception 'FAIL set_primary_guardian did not swap back';
  end if;
  raise notice 'PASS set_primary_guardian swaps the primary guardian in one call (R-39)';
end
$$;

-- 7b.3 consent-change alert queue (D29, R-05)
do $$
declare
  v_rec uuid;
  v_n   integer;
begin
  insert into public.consent_records (family_id, guardian_id, child_id, purpose, consent_text_id, decision,
                                      given_by, media_level, channel, method)
  values ('f0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000002',
          'c0000000-0000-4000-8000-000000000003', 'media_website', '60000000-0000-4000-8000-000000000002',
          'granted', 'guardian', 'face_visible', 'web', 'checkbox');
  insert into public.consent_records (family_id, guardian_id, child_id, purpose, consent_text_id, decision,
                                      given_by, channel, method)
  values ('f0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000002',
          'c0000000-0000-4000-8000-000000000003', 'media_youtube', '60000000-0000-4000-8000-000000000004',
          'refused', 'guardian', 'web', 'checkbox');
  select count(*) into v_n
    from public.staff_notifications sn
    join public.consent_records cr on cr.id = sn.ref_id
   where sn.kind = 'consent_withdrawn' and cr.child_id = 'c0000000-0000-4000-8000-000000000003';
  if v_n <> 0 then
    raise exception 'FAIL a first grant or a first refusal queued % alerts', v_n;
  end if;
  raise notice 'PASS a first grant or refusal queues no alert';

  insert into public.consent_records (family_id, guardian_id, child_id, purpose, consent_text_id, decision,
                                      given_by, channel, method)
  values ('f0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000002',
          'c0000000-0000-4000-8000-000000000003', 'media_website', '60000000-0000-4000-8000-000000000002',
          'withdrawn', 'guardian', 'web', 'checkbox')
  returning id into v_rec;
  select count(*) into v_n from public.staff_notifications sn
   where sn.kind = 'consent_withdrawn' and sn.ref_id = v_rec and sn.status = 'pending';
  if v_n <> 1 then
    raise exception 'FAIL a guardian withdrawal queued % pending alerts (expected 1)', v_n;
  end if;
  raise notice 'PASS a guardian withdrawal queues one pending alert (D29)';

  -- a 10+ child's own "no" while the guardian's grant stands
  insert into public.consent_records (family_id, guardian_id, child_id, purpose, consent_text_id, decision,
                                      given_by, media_level, channel, method)
  values ('f0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000002',
          'c0000000-0000-4000-8000-000000000004', 'media_website', '60000000-0000-4000-8000-000000000002',
          'granted', 'guardian', 'face_visible', 'web', 'checkbox');
  insert into public.consent_records (family_id, child_id, purpose, consent_text_id, decision,
                                      given_by, channel, method, recorded_by)
  values ('f0000000-0000-4000-8000-000000000002', 'c0000000-0000-4000-8000-000000000004', 'media_website',
          '60000000-0000-4000-8000-000000000002', 'refused', 'child', 'in_person', 'staff_recorded_verbal',
          '50000000-0000-4000-8000-000000000001')
  returning id into v_rec;
  select count(*) into v_n from public.staff_notifications sn
   where sn.kind = 'consent_withdrawn' and sn.ref_id = v_rec;
  if v_n <> 1 then
    raise exception 'FAIL a 10+ child''s refusal queued % alerts (expected 1)', v_n;
  end if;
  raise notice 'PASS a child''s own "no" queues an alert while the guardian''s grant stands';
end
$$;

-- 7b.4 allergy marker (R-07)
do $$
declare
  v_marker timestamptz;
begin
  insert into public.consent_records (family_id, guardian_id, child_id, purpose, consent_text_id, decision,
                                      given_by, channel, method)
  values ('f0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000002',
          'c0000000-0000-4000-8000-000000000003', 'health_allergy', '60000000-0000-4000-8000-000000000001',
          'granted', 'guardian', 'web', 'checkbox');
  perform public.upsert_child_health('c0000000-0000-4000-8000-000000000003', array['milk'], null, null, null);
  insert into public.consent_records (family_id, guardian_id, child_id, purpose, consent_text_id, decision,
                                      given_by, channel, method)
  values ('f0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000002',
          'c0000000-0000-4000-8000-000000000003', 'health_allergy', '60000000-0000-4000-8000-000000000001',
          'withdrawn', 'guardian', 'web', 'checkbox');
  select c.allergy_check_needed_at into v_marker from public.children c
   where c.id = 'c0000000-0000-4000-8000-000000000003';
  if v_marker is null
     or exists (select 1 from public.child_health h where h.child_id = 'c0000000-0000-4000-8000-000000000003') then
    raise exception 'FAIL withdrawal should delete the health row and set allergy_check_needed_at';
  end if;
  raise notice 'PASS a health withdrawal deletes the row and sets allergy_check_needed_at (R-07)';

  insert into public.consent_records (family_id, guardian_id, child_id, purpose, consent_text_id, decision,
                                      given_by, channel, method)
  values ('f0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000002',
          'c0000000-0000-4000-8000-000000000003', 'health_allergy', '60000000-0000-4000-8000-000000000001',
          'granted', 'guardian', 'web', 'checkbox');
  perform public.upsert_child_health('c0000000-0000-4000-8000-000000000003', array['egg'], null, null, null);
  if (select c.allergy_check_needed_at from public.children c
       where c.id = 'c0000000-0000-4000-8000-000000000003') is not null then
    raise exception 'FAIL new allergy info did not clear allergy_check_needed_at';
  end if;
  raise notice 'PASS new allergy info clears the marker';
end
$$;

-- 7b.5 media: legacy-only clip and the YouTube-on-website rule (R-11); set_media_asset_children (R-15)
insert into public.media_assets (id, kind, youtube_id, title, shows_children, shows_faces, legacy_consent_note,
                                 legacy_consent_purposes, on_website, on_youtube)
values
  ('70000000-0000-4000-8000-000000000002', 'youtube', 'TESTclip001', 'TEST legacy clip', true, true,
   'TEST pre-system note', array['media_website']::public.consent_purpose[], true, true),
  ('70000000-0000-4000-8000-000000000003', 'youtube', 'TESTclip002', 'TEST clip with a linked child', true, false,
   null, '{}'::public.consent_purpose[], true, true);

do $$
begin
  if not public.can_publish_media('70000000-0000-4000-8000-000000000002', 'media_website')
     or public.can_publish_media('70000000-0000-4000-8000-000000000002', 'media_youtube')
     or public.can_publish_media('70000000-0000-4000-8000-000000000002', 'media_social') then
    raise exception 'FAIL a legacy-only clip must be publishable only on the channels its note covers';
  end if;
  raise notice 'PASS legacy-only clip: publishable only where the legacy note applies (R-11)';

  perform public.set_media_asset_children('70000000-0000-4000-8000-000000000003',
                                          array['c0000000-0000-4000-8000-000000000005']::uuid[]);
  if (select count(*) from public.media_asset_children mac
       where mac.asset_id = '70000000-0000-4000-8000-000000000003') <> 1 then
    raise exception 'FAIL set_media_asset_children did not link the child';
  end if;
  insert into public.consent_records (family_id, guardian_id, child_id, purpose, consent_text_id, decision,
                                      given_by, media_level, channel, method)
  values ('f0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000002',
          'c0000000-0000-4000-8000-000000000005', 'media_website', '60000000-0000-4000-8000-000000000002',
          'granted', 'guardian', 'face_visible', 'web', 'checkbox');
  if public.can_publish_media('70000000-0000-4000-8000-000000000003', 'media_website') then
    raise exception 'FAIL a YouTube clip passed the website check without media_youtube consent';
  end if;
  insert into public.consent_records (family_id, guardian_id, child_id, purpose, consent_text_id, decision,
                                      given_by, media_level, channel, method)
  values ('f0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000002',
          'c0000000-0000-4000-8000-000000000005', 'media_youtube', '60000000-0000-4000-8000-000000000004',
          'granted', 'guardian', 'face_visible', 'web', 'checkbox');
  if not public.can_publish_media('70000000-0000-4000-8000-000000000003', 'media_website') then
    raise exception 'FAIL a YouTube clip with website + YouTube consent is still not publishable on the website';
  end if;
  raise notice 'PASS a YouTube clip on the website also needs media_youtube consent (R-11)';
end
$$;

-- 7b.6 publish_consent_text (R-15): TH + EN of version N+1 together, older versions retired
do $$
declare
  v_version integer;
begin
  v_version := public.publish_consent_text('media_social', 'TEST title TH', 'TEST body TH — not real wording',
                                           'TEST title EN', 'TEST body EN — not real wording', false, 10::smallint);
  if (select count(*) from public.consent_texts ct
       where ct.purpose = 'media_social' and ct.version = v_version and ct.retired_at is null) <> 2 then
    raise exception 'FAIL publish_consent_text did not add TH + EN of version %', v_version;
  end if;
  if exists (select 1 from public.consent_texts ct
              where ct.purpose = 'media_social' and ct.version < v_version and ct.retired_at is null) then
    raise exception 'FAIL publish_consent_text left an older media_social version current';
  end if;
  raise notice 'PASS publish_consent_text adds TH + EN together and retires older versions';
end
$$;

-- 7b.7 submit_enrolment (R-15 scope, R-21, R-22, R-33, R-34, link_used, health withdrawal)
insert into public.family_links (id, family_id, purpose, token_hash, expires_at)
values ('62000000-0000-4000-8000-000000000001', 'f0000000-0000-4000-8000-000000000002', 'enrol',
        repeat('c1', 32), now() + interval '14 days'),
       ('62000000-0000-4000-8000-000000000002', 'f0000000-0000-4000-8000-000000000002', 'enrol',
        repeat('c2', 32), now() + interval '14 days');

do $$
declare
  v_out     jsonb;
  v_g       record;
  v_n0      integer;
  v_n1      integer;
  v_m3      text;
  v_m4      text;
  v_guard   jsonb := jsonb_build_object('full_name', 'ผู้ปกครองทดสอบสอง', 'phone', '0800000003',
                                        'line_id', null, 'email', null);
begin
  select to_char(c.birth_month, 'YYYY-MM') into v_m3 from public.children c
   where c.id = 'c0000000-0000-4000-8000-000000000003';
  select to_char(c.birth_month, 'YYYY-MM') into v_m4 from public.children c
   where c.id = 'c0000000-0000-4000-8000-000000000004';

  -- scope: a child of ANOTHER family is refused (22023) and nothing is written
  begin
    perform public.submit_enrolment('62000000-0000-4000-8000-000000000001', jsonb_build_object(
      'guardian', v_guard,
      'children', jsonb_build_array(jsonb_build_object(
        'child_id', 'c0000000-0000-4000-8000-000000000001', 'birth_month', v_m3,
        'health', jsonb_build_object('decision', 'skipped'), 'media', '[]'::jsonb, 'media_level', null)),
      'contacts', '[]'::jsonb));
    raise exception 'FAIL submit_enrolment accepted a child from another family';
  exception when invalid_parameter_value then
    raise notice 'PASS submit_enrolment refuses a child outside the link''s family';
  end;

  -- R-34: the 11-year-old said no to health info → a guardian "granted" fails with 23514, not 42501
  insert into public.consent_records (family_id, child_id, purpose, consent_text_id, decision,
                                      given_by, channel, method, recorded_by)
  values ('f0000000-0000-4000-8000-000000000002', 'c0000000-0000-4000-8000-000000000004', 'health_allergy',
          '60000000-0000-4000-8000-000000000001', 'refused', 'child', 'in_person', 'staff_recorded_verbal',
          '50000000-0000-4000-8000-000000000001');
  begin
    perform public.submit_enrolment('62000000-0000-4000-8000-000000000001', jsonb_build_object(
      'guardian', v_guard,
      'children', jsonb_build_array(jsonb_build_object(
        'child_id', 'c0000000-0000-4000-8000-000000000004', 'birth_month', v_m4,
        'health', jsonb_build_object('decision', 'granted',
                                     'consent_text_id', '60000000-0000-4000-8000-000000000001',
                                     'allergens', jsonb_build_array('milk'), 'other_allergens', '',
                                     'foods_to_avoid', '', 'care_notes', ''),
        'media', '[]'::jsonb, 'media_level', null)),
      'contacts', '[]'::jsonb));
    raise exception 'FAIL health was accepted although the child said no';
  exception when check_violation then
    raise notice 'PASS a child''s own health "no" blocks a guardian grant with 23514 (R-34)';
  end;

  -- the full statement: phone changed, c…0003 YouTube ticked, c…0004 website left unticked (it was granted)
  select count(*) into v_n0 from public.consent_records cr
   where cr.child_id = 'c0000000-0000-4000-8000-000000000004' and cr.purpose = 'media_website'
     and cr.given_by = 'guardian';
  v_out := public.submit_enrolment('62000000-0000-4000-8000-000000000001', jsonb_build_object(
    'guardian', v_guard || jsonb_build_object('phone', '0800000006'),
    'children', jsonb_build_array(
      jsonb_build_object(
        'child_id', 'c0000000-0000-4000-8000-000000000003', 'birth_month', v_m3,
        'health', jsonb_build_object('decision', 'skipped'),
        'media', jsonb_build_array(jsonb_build_object('purpose', 'media_youtube', 'on', true,
                                   'consent_text_id', '60000000-0000-4000-8000-000000000004')),
        'media_level', 'face_hidden'),
      jsonb_build_object(
        'child_id', 'c0000000-0000-4000-8000-000000000004', 'birth_month', v_m4,
        'health', jsonb_build_object('decision', 'skipped'),
        'media', jsonb_build_array(jsonb_build_object('purpose', 'media_website', 'on', false,
                                   'consent_text_id', '60000000-0000-4000-8000-000000000002')),
        'media_level', null)),
    'contacts', jsonb_build_array(jsonb_build_object(
      'id', null, 'name', 'ผู้ติดต่อทดสอบสี่', 'phone', '0800000009', 'relationship', 'TEST aunt',
      'is_emergency_contact', true, 'is_authorised_pickup', false))));
  if (v_out ->> 'ok') is distinct from 'true'
     or (v_out ->> 'family_id') is distinct from 'f0000000-0000-4000-8000-000000000002' then
    raise exception 'FAIL submit_enrolment did not succeed: %', v_out;
  end if;
  if (select fl.used_at from public.family_links fl where fl.id = '62000000-0000-4000-8000-000000000001') is null then
    raise exception 'FAIL the enrol link was not spent';
  end if;
  select g.phone, g.identity_checked_at, g.pending_link_changes into v_g
    from public.guardians g where g.id = 'a0000000-0000-4000-8000-000000000002';
  if v_g.phone is distinct from '0800000006' or v_g.identity_checked_at is not null
     or (v_g.pending_link_changes -> 'before' ->> 'phone') is distinct from '0800000003' then
    raise exception 'FAIL R-21: phone %, identity_checked_at %, pending %', v_g.phone, v_g.identity_checked_at,
                    v_g.pending_link_changes;
  end if;
  raise notice 'PASS submit_enrolment spends the link, keeps the old phone for staff and never marks identity (R-21)';

  select count(*) into v_n1 from public.consent_records cr
   where cr.child_id = 'c0000000-0000-4000-8000-000000000004' and cr.purpose = 'media_website'
     and cr.given_by = 'guardian';
  if v_n1 <> v_n0 then
    raise exception 'FAIL an unticked box on a re-sent link changed an earlier media decision (R-33)';
  end if;
  if (select cc.decision::text from public.current_consents cc
       where cc.child_id = 'c0000000-0000-4000-8000-000000000003' and cc.purpose = 'media_youtube'
         and cc.given_by = 'guardian') is distinct from 'granted' then
    raise exception 'FAIL a ticked box did not record granted';
  end if;
  raise notice 'PASS ticked = granted; unticked keeps an earlier decision (R-33)';

  if not exists (select 1 from public.family_contacts fc
                  where fc.id = 'e0000000-0000-4000-8000-000000000003' and not fc.is_active)
     or not exists (select 1 from public.family_contacts fc
                     where fc.family_id = 'f0000000-0000-4000-8000-000000000002' and fc.is_active
                       and fc.phone = '0800000009') then
    raise exception 'FAIL contacts: the left-out one must be soft-deleted, the new one added (R-22)';
  end if;
  raise notice 'PASS contacts left out are soft-deleted and new ones added (R-22)';

  v_out := public.submit_enrolment('62000000-0000-4000-8000-000000000001', jsonb_build_object(
    'guardian', v_guard, 'children', '[]'::jsonb, 'contacts', '[]'::jsonb));
  if (v_out ->> 'code') is distinct from 'link_used' then
    raise exception 'FAIL a used enrol link returned %', v_out;
  end if;
  raise notice 'PASS a used enrol link returns link_used';

  -- explicit health "no" after a grant (c…0003 has a health row from 7b.4) → withdrawn, row gone, alert id back
  v_out := public.submit_enrolment('62000000-0000-4000-8000-000000000002', jsonb_build_object(
    'guardian', v_guard || jsonb_build_object('phone', '0800000006'),
    'children', jsonb_build_array(jsonb_build_object(
      'child_id', 'c0000000-0000-4000-8000-000000000003', 'birth_month', v_m3,
      'health', jsonb_build_object('decision', 'refused',
                                   'consent_text_id', '60000000-0000-4000-8000-000000000001'),
      'media', '[]'::jsonb, 'media_level', null)),
    'contacts', '[]'::jsonb));
  if (v_out ->> 'ok') is distinct from 'true' or jsonb_array_length(v_out -> 'alert_ids') <> 1 then
    raise exception 'FAIL a health withdrawal through /enrol should return one alert id: %', v_out;
  end if;
  if (select cc.decision::text from public.current_consents cc
       where cc.child_id = 'c0000000-0000-4000-8000-000000000003' and cc.purpose = 'health_allergy'
         and cc.given_by = 'guardian') is distinct from 'withdrawn'
     or exists (select 1 from public.child_health h where h.child_id = 'c0000000-0000-4000-8000-000000000003') then
    raise exception 'FAIL "I don''t want to share this" after a grant must record withdrawn and delete the row';
  end if;
  raise notice 'PASS health "I don''t want to share this" after a grant = withdrawn, row deleted, alert id returned';
end
$$;

-- 7b.8 restriction (D28, R-09, R-36, R-37)
insert into public.family_links (id, family_id, purpose, token_hash, expires_at)
values ('62000000-0000-4000-8000-000000000003', 'f0000000-0000-4000-8000-000000000002', 'enrol',
        repeat('c3', 32), now() + interval '14 days');

do $$
declare
  v_audit0 integer;
  v_audit1 integer;
begin
  begin
    update public.families set processing_restricted_at = now()
     where id = 'f0000000-0000-4000-8000-000000000002';
    raise exception 'FAIL the restriction columns changed without set_family_restriction()';
  exception when insufficient_privilege then
    raise notice 'PASS the restriction columns are guarded';
  end;

  perform public.set_family_restriction('f0000000-0000-4000-8000-000000000002', true, 'TEST restriction');
  if (select fl.revoked_at from public.family_links fl
       where fl.id = '62000000-0000-4000-8000-000000000003') is null then
    raise exception 'FAIL restricting did not revoke the unused enrol link';
  end if;
  raise notice 'PASS restricting revokes unused enrol links';

  begin
    update public.guardians set full_name = 'ผู้ปกครองทดสอบสอง (แก้)' where id = 'a0000000-0000-4000-8000-000000000002';
    raise exception 'FAIL a restricted family''s guardian was edited';
  exception when check_violation then null;
  end;
  begin
    update public.children set nickname = 'TEST edit' where id = 'c0000000-0000-4000-8000-000000000003';
    raise exception 'FAIL a restricted family''s child was edited';
  exception when check_violation then null;
  end;
  begin
    update public.families set display_name = 'TEST edit' where id = 'f0000000-0000-4000-8000-000000000002';
    raise exception 'FAIL a restricted family''s display name was edited (R-36)';
  exception when check_violation then null;
  end;
  begin
    update public.families set staff_note = 'TEST' where id = 'f0000000-0000-4000-8000-000000000002';
    raise exception 'FAIL a restricted family''s staff note was edited (R-36)';
  exception when check_violation then null;
  end;
  begin
    update public.family_contacts set relationship = 'TEST edit' where id = 'e0000000-0000-4000-8000-000000000003';
    raise exception 'FAIL an inactive contact of a restricted family was edited (R-36)';
  exception when check_violation then null;
  end;
  begin
    insert into public.family_links (family_id, purpose, token_hash, expires_at)
    values ('f0000000-0000-4000-8000-000000000002', 'enrol', repeat('c4', 32), now() + interval '14 days');
    raise exception 'FAIL a restricted family got a new enrol link';
  exception when check_violation then null;
  end;
  begin
    insert into public.consent_records (family_id, guardian_id, child_id, purpose, consent_text_id, decision,
                                        given_by, media_level, channel, method)
    values ('f0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000002',
            'c0000000-0000-4000-8000-000000000003', 'media_website', '60000000-0000-4000-8000-000000000002',
            'granted', 'guardian', 'face_visible', 'web', 'checkbox');
    raise exception 'FAIL a restricted family recorded a new grant';
  exception when check_violation then null;
  end;
  -- withdrawals still work
  insert into public.consent_records (family_id, guardian_id, child_id, purpose, consent_text_id, decision,
                                      given_by, channel, method)
  values ('f0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000002',
          'c0000000-0000-4000-8000-000000000005', 'media_youtube', '60000000-0000-4000-8000-000000000004',
          'withdrawn', 'guardian', 'web', 'checkbox');
  raise notice 'PASS restricted: edits (incl. the family row), new links and new grants refused; withdrawal allowed (D28, R-36)';

  -- R-37: correcting disputed data = lift → correct → restrict again; the audit log shows each step
  select count(*) into v_audit0 from public.audit_log a
   where a.table_name = 'families' and a.row_id = 'f0000000-0000-4000-8000-000000000002' and a.action = 'update';
  perform public.set_family_restriction('f0000000-0000-4000-8000-000000000002', false, null);
  update public.guardians set full_name = 'ผู้ปกครองทดสอบสอง (แก้ไข)' where id = 'a0000000-0000-4000-8000-000000000002';
  perform public.set_family_restriction('f0000000-0000-4000-8000-000000000002', true, 'TEST restriction (after correction)');
  select count(*) into v_audit1 from public.audit_log a
   where a.table_name = 'families' and a.row_id = 'f0000000-0000-4000-8000-000000000002' and a.action = 'update';
  if v_audit1 - v_audit0 < 2
     or (select f.processing_restricted_at from public.families f
          where f.id = 'f0000000-0000-4000-8000-000000000002') is null
     or not exists (select 1 from public.audit_log a
                     where a.table_name = 'guardians' and a.row_id = 'a0000000-0000-4000-8000-000000000002'
                       and a.action = 'update') then
    raise exception 'FAIL lift → correct → restrict again did not work or was not audited';
  end if;
  raise notice 'PASS lift → correct → restrict again works and each step is audited (R-37)';
end
$$;


-- -----------------------------------------------------------------------------
-- 7c. Marketing choice (decision 2), print (decision 3), cancel notice (decision 10), 14 Oct 2026
-- -----------------------------------------------------------------------------
-- Two TEST consent texts (version 999; not real wording). The real texts are in 0006 / 0006a.
insert into public.consent_texts (id, purpose, version, lang, title, body_md, is_explicit, requires_child_consent_from_age)
values
  ('60000000-0000-4000-8000-000000000005', 'marketing_line', 999, 'en', 'TEST marketing text',
   'TEST body — not real wording', false, null),
  ('60000000-0000-4000-8000-000000000006', 'media_print', 999, 'en', 'TEST print text',
   'TEST body — not real wording', false, 10);

do $$
declare
  v_n     integer;
  v_start timestamptz;
begin
  -- nothing is granted by default: marketing_line (guardian) and media_print (child) start as "not granted"
  if exists (select 1 from public.current_marketing_consents cm
              where cm.guardian_id = 'a0000000-0000-4000-8000-000000000001') then
    raise exception 'FAIL marketing_line is granted by default';
  end if;
  if public.consent_status('c0000000-0000-4000-8000-000000000001', 'media_print') <> 'not_granted' then
    raise exception 'FAIL media_print is granted by default';
  end if;
  select count(*) into v_n from public.consent_matrix(array['c0000000-0000-4000-8000-000000000001']::uuid[]);
  if v_n <> 6 then
    raise exception 'FAIL consent_matrix should list 6 child purposes, got %', v_n;
  end if;
  raise notice 'PASS marketing_line and media_print are not granted by default; consent_matrix lists 6 child purposes';

  -- marketing_line is a guardian purpose: a child-level record is refused
  begin
    insert into public.consent_records (family_id, guardian_id, child_id, purpose, consent_text_id, decision,
                                        given_by, channel, method)
    values ('f0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001',
            'c0000000-0000-4000-8000-000000000001', 'marketing_line', '60000000-0000-4000-8000-000000000005',
            'withdrawn', 'guardian', 'web', 'checkbox');
    raise exception 'FAIL a child-level record carried the marketing purpose';
  exception when check_violation then
    raise notice 'PASS marketing_line cannot be recorded against a child';
  end;

  -- a granted choice is on the follow-up list; a later withdrawal takes it off (the latest row wins)
  insert into public.guardian_consent_records
    (id, family_id, guardian_id, purpose, consent_text_id, decision, channel, method)
  values ('6f000000-0000-4000-8000-000000000001', 'f0000000-0000-4000-8000-000000000001',
          'a0000000-0000-4000-8000-000000000001', 'marketing_line', '60000000-0000-4000-8000-000000000005',
          'granted', 'web', 'checkbox');
  select count(*) into v_n from public.marketing_follow_up_list fl
   where fl.guardian_id = 'a0000000-0000-4000-8000-000000000001';
  if v_n <> 1 then
    raise exception 'FAIL a granted guardian is missing from the follow-up list (%)', v_n;
  end if;

  insert into public.guardian_consent_records
    (id, family_id, guardian_id, purpose, consent_text_id, decision, channel, method)
  values ('6f000000-0000-4000-8000-000000000002', 'f0000000-0000-4000-8000-000000000001',
          'a0000000-0000-4000-8000-000000000001', 'marketing_line', '60000000-0000-4000-8000-000000000005',
          'withdrawn', 'web', 'checkbox');
  if (select cm.decision from public.current_marketing_consents cm
       where cm.guardian_id = 'a0000000-0000-4000-8000-000000000001') <> 'withdrawn' then
    raise exception 'FAIL the latest marketing choice is not the withdrawal';
  end if;
  select count(*) into v_n from public.marketing_follow_up_list fl
   where fl.guardian_id = 'a0000000-0000-4000-8000-000000000001';
  if v_n <> 0 then
    raise exception 'FAIL a withdrawn guardian is still on the follow-up list';
  end if;
  raise notice 'PASS marketing_line: granted → on the follow-up list; withdrawn → off it (decision 2)';

  -- a guardian choice can be withdrawn, but never deleted or edited (append-only)
  begin
    delete from public.guardian_consent_records where id = '6f000000-0000-4000-8000-000000000001';
    raise exception 'FAIL a guardian consent record was deleted';
  exception when insufficient_privilege then
    raise notice 'PASS a guardian consent record can be withdrawn but never deleted';
  end;
  begin
    update public.guardian_consent_records set decision = 'withdrawn'
     where id = '6f000000-0000-4000-8000-000000000001';
    raise exception 'FAIL a guardian consent record was edited';
  exception when insufficient_privilege then
    raise notice 'PASS a guardian consent record cannot be edited';
  end;

  -- family 2 is still restricted (section 7b.8): no new marketing grant, but a withdrawal is allowed
  begin
    insert into public.guardian_consent_records
      (family_id, guardian_id, purpose, consent_text_id, decision, channel, method)
    values ('f0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000002', 'marketing_line',
            '60000000-0000-4000-8000-000000000005', 'granted', 'web', 'checkbox');
    raise exception 'FAIL a restricted family recorded a marketing grant';
  exception when check_violation then null;
  end;
  insert into public.guardian_consent_records
    (family_id, guardian_id, purpose, consent_text_id, decision, channel, method)
  values ('f0000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000002', 'marketing_line',
          '60000000-0000-4000-8000-000000000005', 'withdrawn', 'web', 'checkbox');
  raise notice 'PASS restricted family: marketing grant refused, withdrawal allowed (PDPA s.34)';

  -- decision 3: media_print follows the media_social rules (child level, face level, one channel at a time)
  insert into public.media_assets (id, kind, title, shows_children, shows_faces, on_print)
  values ('70000000-0000-4000-8000-000000000002', 'photo', 'TEST print asset', true, true, true);
  insert into public.media_asset_children (asset_id, child_id)
  values ('70000000-0000-4000-8000-000000000002', 'c0000000-0000-4000-8000-000000000001');
  if public.can_publish_media('70000000-0000-4000-8000-000000000002', 'media_print') then
    raise exception 'FAIL print use allowed without consent';
  end if;
  insert into public.consent_records (family_id, guardian_id, child_id, purpose, consent_text_id, decision,
                                      given_by, media_level, channel, method)
  values ('f0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001',
          'c0000000-0000-4000-8000-000000000001', 'media_print', '60000000-0000-4000-8000-000000000006',
          'granted', 'guardian', 'face_hidden', 'web', 'checkbox');
  if public.can_publish_media('70000000-0000-4000-8000-000000000002', 'media_print') then
    raise exception 'FAIL face_hidden print consent still allows an asset that shows faces';
  end if;
  insert into public.consent_records (family_id, guardian_id, child_id, purpose, consent_text_id, decision,
                                      given_by, media_level, channel, method)
  values ('f0000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001',
          'c0000000-0000-4000-8000-000000000001', 'media_print', '60000000-0000-4000-8000-000000000006',
          'granted', 'guardian', 'face_visible', 'web', 'checkbox');
  if not public.can_publish_media('70000000-0000-4000-8000-000000000002', 'media_print') then
    raise exception 'FAIL print asset not publishable after a face_visible print consent';
  end if;
  if public.can_publish_media('70000000-0000-4000-8000-000000000002', 'media_social') then
    raise exception 'FAIL print consent leaked to social';
  end if;
  raise notice 'PASS media_print follows the media_social rules (child level, face level, one channel at a time)';

  -- decision 10: cancel_notice_hours defaults to 3, must be 0–72, and the cancellation notice rule uses it (round three)
  if (select st.cancel_notice_hours from public.studio_settings st where st.id) <> 3 then
    raise exception 'FAIL cancel_notice_hours should default to 3';
  end if;
  begin
    update public.studio_settings set cancel_notice_hours = 73 where id;
    raise exception 'FAIL cancel_notice_hours accepted 73';
  exception when check_violation then null;
  end;
  begin
    update public.studio_settings set cancel_notice_hours = -1 where id;
    raise exception 'FAIL cancel_notice_hours accepted -1';
  exception when check_violation then null;
  end;
  -- Round three (brief 7): check_make_up_notice is removed. The make-up notice checks that stood here are replaced by
  -- the rebooking checks in § 7e (a rebooking uses the kept or returned credit; no notice check).
  if to_regprocedure('public.check_make_up_notice(uuid, timestamptz)') is not null then
    raise exception 'FAIL check_make_up_notice still exists (round three removes it)';
  end if;
  raise notice 'PASS check_make_up_notice is removed (round three, brief 7)';
end
$$;


-- -----------------------------------------------------------------------------
-- 7d. Round two (14 Oct 2026): credit rule by notice (brief item 1), allergen 'flour' (item 7), get_child_health with
--     includeHealth (item 3), follow-up label and the two-row rule (items 4 and 5). FAKE data only.
--     Family f…0003 is a new test family: one four-pack and two consenting guardians.
-- -----------------------------------------------------------------------------

do $$
declare
  v_today    date := (now() at time zone 'Asia/Bangkok')::date;
  v_n1       date;
  v_start    timestamptz;
  v_left     integer;
  v_used     integer;
  v_seats0   integer;
  v_seats1   integer;
  v_status   public.booking_status;
  v_n        integer;
  v_label    text;
  v_label_en text;
begin
  v_n1 := v_today + ((6 - extract(isodow from v_today)::integer + 7) % 7);

  insert into public.sessions (id, session_date, starts_at, ends_at, capacity, status, public_note_en, staff_note)
  values
    ('b0000000-0000-4000-8000-000000000004', v_n1 + 7,  '07:00', '08:00', 10, 'open', 'TEST', 'TEST round two N3'),
    ('b0000000-0000-4000-8000-000000000005', v_n1 + 14, '07:00', '08:00', 10, 'open', 'TEST', 'TEST round two N4'),
    ('b0000000-0000-4000-8000-000000000006', v_n1 + 21, '07:00', '08:00', 10, 'open', 'TEST', 'TEST round two N5'),
    ('b0000000-0000-4000-8000-000000000007', v_n1 + 28, '07:00', '08:00', 10, 'open', 'TEST', 'TEST round two N6');

  insert into public.families (id, display_name, source_request_id)
  values ('f0000000-0000-4000-8000-000000000003', 'ครอบครัวทดสอบสาม (TEST)', null);

  insert into public.guardians
    (id, family_id, full_name, phone, is_primary, has_parental_responsibility, responsibility_attested_at,
     identity_check_method, identity_checked_at)
  values
    ('a0000000-0000-4000-8000-0000000000a1', 'f0000000-0000-4000-8000-000000000003', 'ผู้ปกครองทดสอบห้า',
     '0800000011', true, true, now(), 'line_account', now()),
    ('a0000000-0000-4000-8000-0000000000a2', 'f0000000-0000-4000-8000-000000000003', 'ผู้ปกครองทดสอบหก',
     '0800000012', false, true, now(), 'line_account', now());

  -- one child with a booking (the label names this nickname) and one child with no booking (not named: the label
  -- counts non-cancelled bookings, not is_active; verifier fix, 14 Oct 2026)
  insert into public.children (id, family_id, nickname, is_active)
  values ('c0000000-0000-4000-8000-0000000000a1', 'f0000000-0000-4000-8000-000000000003', 'ทดสอบ', true),
         ('c0000000-0000-4000-8000-0000000000a2', 'f0000000-0000-4000-8000-000000000003', 'ทดสอบเก่า', false);

  insert into public.package_purchases (id, family_id, package_code, sessions_total, price_thb)
  values ('d0000000-0000-4000-8000-0000000000a1', 'f0000000-0000-4000-8000-000000000003', 'four', 4, 14400);

  -- (1) cancelled with notice EXACTLY cancel_notice_hours (3) before the start: on time, the credit is kept
  insert into public.bookings (id, session_id, child_id, package_purchase_id, status)
  values ('b1000000-0000-4000-8000-0000000000a1', 'b0000000-0000-4000-8000-000000000002',
          'c0000000-0000-4000-8000-0000000000a1', 'd0000000-0000-4000-8000-0000000000a1', 'confirmed');
  select (s.session_date + s.starts_at) at time zone 'Asia/Bangkok' into v_start
    from public.sessions s where s.id = 'b0000000-0000-4000-8000-000000000002';
  perform public.cancel_booking('b1000000-0000-4000-8000-0000000000a1', 'line', v_start - interval '3 hours', false);
  select b.status into v_status from public.bookings b where b.id = 'b1000000-0000-4000-8000-0000000000a1';
  select pb.sessions_left into v_left from public.package_balances pb
   where pb.package_purchase_id = 'd0000000-0000-4000-8000-0000000000a1';
  if v_status is distinct from 'cancelled' or v_left is distinct from 4 then
    raise exception 'FAIL notice exactly 3 hours before should keep the credit (status %, left %)', v_status, v_left;
  end if;
  raise notice 'PASS notice exactly cancel_notice_hours before the session: status cancelled, credit kept';

  -- (2) one second later than the cutoff: cancelled_late, one credit used, the seat stays taken
  insert into public.bookings (id, session_id, child_id, package_purchase_id, status)
  values ('b1000000-0000-4000-8000-0000000000a2', 'b0000000-0000-4000-8000-000000000004',
          'c0000000-0000-4000-8000-0000000000a1', 'd0000000-0000-4000-8000-0000000000a1', 'confirmed');
  select (s.session_date + s.starts_at) at time zone 'Asia/Bangkok' into v_start
    from public.sessions s where s.id = 'b0000000-0000-4000-8000-000000000004';
  v_seats0 := public.session_seats_left('b0000000-0000-4000-8000-000000000004');
  perform public.cancel_booking('b1000000-0000-4000-8000-0000000000a2', 'in_person',
                                v_start - interval '3 hours' + interval '1 second', false);
  select b.status into v_status from public.bookings b where b.id = 'b1000000-0000-4000-8000-0000000000a2';
  v_seats1 := public.session_seats_left('b0000000-0000-4000-8000-000000000004');
  select pb.sessions_left into v_left from public.package_balances pb
   where pb.package_purchase_id = 'd0000000-0000-4000-8000-0000000000a1';
  if v_status is distinct from 'cancelled_late' then
    raise exception 'FAIL one second after the cutoff should be cancelled_late, got %', v_status;
  end if;
  if v_seats1 is distinct from v_seats0 then
    raise exception 'FAIL cancelled_late should keep the seat (% -> %)', v_seats0, v_seats1;
  end if;
  if v_left is distinct from 3 then
    raise exception 'FAIL cancelled_late should use one credit, left %', v_left;
  end if;
  raise notice 'PASS notice one second after the cutoff: cancelled_late, one credit used, seat kept';

  -- (3) absent uses one credit (no notice is involved)
  insert into public.bookings (id, session_id, child_id, package_purchase_id, status)
  values ('b1000000-0000-4000-8000-0000000000a3', 'b0000000-0000-4000-8000-000000000005',
          'c0000000-0000-4000-8000-0000000000a1', 'd0000000-0000-4000-8000-0000000000a1', 'absent');
  select pb.sessions_left into v_left from public.package_balances pb
   where pb.package_purchase_id = 'd0000000-0000-4000-8000-0000000000a1';
  if v_left is distinct from 2 then
    raise exception 'FAIL absent should use one credit, left %', v_left;
  end if;
  raise notice 'PASS absent uses one credit';

  -- (4) verifier fix (14 Oct 2026): a family cancellation with NO notice is refused (22023). Staff record it as
  -- 'absent' instead: one credit used, no cancellation log row.
  insert into public.bookings (id, session_id, child_id, package_purchase_id, status)
  values ('b1000000-0000-4000-8000-0000000000a4', 'b0000000-0000-4000-8000-000000000006',
          'c0000000-0000-4000-8000-0000000000a1', 'd0000000-0000-4000-8000-0000000000a1', 'confirmed');
  begin
    perform public.cancel_booking('b1000000-0000-4000-8000-0000000000a4', null, null, false);
    raise exception 'FAIL a family cancellation without notice was accepted';
  exception when sqlstate '22023' then
    raise notice 'PASS a family cancellation without notice is refused (record it as absent)';
  end;
  update public.bookings set status = 'absent' where id = 'b1000000-0000-4000-8000-0000000000a4';
  select b.status into v_status from public.bookings b where b.id = 'b1000000-0000-4000-8000-0000000000a4';
  select pb.sessions_left into v_left from public.package_balances pb
   where pb.package_purchase_id = 'd0000000-0000-4000-8000-0000000000a1';
  if v_status is distinct from 'absent' or v_left is distinct from 1 then
    raise exception 'FAIL a missed class recorded as absent should use one credit (status %, left %)', v_status, v_left;
  end if;
  raise notice 'PASS a missed class recorded as absent uses one credit';
  -- verifier fix: an attended or absent booking cannot be cancelled (23514)
  begin
    perform public.cancel_booking('b1000000-0000-4000-8000-0000000000a3', 'phone', now(), false);
    raise exception 'FAIL an absent booking was cancelled';
  exception when sqlstate '23514' then
    raise notice 'PASS an absent booking cannot be cancelled';
  end;

  -- (5) a studio cancellation of the whole session gives the credit back (no notice rule)
  insert into public.bookings (id, session_id, child_id, package_purchase_id, status)
  values ('b1000000-0000-4000-8000-0000000000a5', 'b0000000-0000-4000-8000-000000000007',
          'c0000000-0000-4000-8000-0000000000a1', 'd0000000-0000-4000-8000-0000000000a1', 'confirmed');
  update public.sessions set status = 'cancelled' where id = 'b0000000-0000-4000-8000-000000000007';
  select b.status into v_status from public.bookings b where b.id = 'b1000000-0000-4000-8000-0000000000a5';
  select pb.sessions_left into v_left from public.package_balances pb
   where pb.package_purchase_id = 'd0000000-0000-4000-8000-0000000000a1';
  if v_status is distinct from 'cancelled_studio' or v_left is distinct from 1 then
    raise exception 'FAIL a studio cancellation should give cancelled_studio and return the credit (status %, left %)', v_status, v_left;
  end if;
  raise notice 'PASS studio cancellation of a session gives cancelled_studio and returns the credit (round three)';

  -- (6) totals: cancelled_late x2 + absent = 3 used, 1 left
  select pb.sessions_used, pb.sessions_left into v_used, v_left from public.package_balances pb
   where pb.package_purchase_id = 'd0000000-0000-4000-8000-0000000000a1';
  if v_used is distinct from 3 or v_left is distinct from 1 then
    raise exception 'FAIL totals should be 3 used and 1 left, got % and %', v_used, v_left;
  end if;
  raise notice 'PASS package totals agree with the credit rule (3 used, 1 left)';

  -- (7) a notice time without a channel is refused (the notice pair). Uses a live booking (absent), because a
  -- studio-cancelled booking is now refused by the log guard before the pair check.
  begin
    update public.bookings set cancel_notice_at = now() where id = 'b1000000-0000-4000-8000-0000000000a3';
    raise exception 'FAIL a notice time without a channel was accepted';
  exception when check_violation then
    raise notice 'PASS notice channel and notice time are stored together';
  end;

  -- (8) the reports count cancelled_late the same way
  select rf.cancelled_late into v_n from public.report_session_fill rf
   where rf.session_id = 'b0000000-0000-4000-8000-000000000004';
  if v_n is distinct from 1 then
    raise exception 'FAIL report_session_fill should show 1 cancelled_late on N3, got %', v_n;
  end if;
  raise notice 'PASS report_session_fill counts cancelled_late';

  -- (9) two consenting guardians = two follow-up rows, labelled from the nicknames of every attending child (one here)
  insert into public.guardian_consent_records
    (id, family_id, guardian_id, purpose, consent_text_id, decision, channel, method)
  values ('6f000000-0000-4000-8000-0000000000a1', 'f0000000-0000-4000-8000-000000000003',
          'a0000000-0000-4000-8000-0000000000a1', 'marketing_line', '60000000-0000-4000-8000-000000000005',
          'granted', 'web', 'checkbox'),
         ('6f000000-0000-4000-8000-0000000000a2', 'f0000000-0000-4000-8000-000000000003',
          'a0000000-0000-4000-8000-0000000000a2', 'marketing_line', '60000000-0000-4000-8000-000000000005',
          'granted', 'web', 'checkbox');
  select count(*) into v_n from public.marketing_follow_up_list fl
   where fl.family_id = 'f0000000-0000-4000-8000-000000000003';
  if v_n <> 2 then
    raise exception 'FAIL two consenting guardians should give two follow-up rows, got %', v_n;
  end if;
  select min(fl.family_label_th), min(fl.family_label_en) into v_label, v_label_en
    from public.marketing_follow_up_list fl where fl.family_id = 'f0000000-0000-4000-8000-000000000003';
  if v_label is distinct from 'ครอบครัวน้องทดสอบ' or v_label_en is distinct from 'Family of ทดสอบ' then
    raise exception 'FAIL follow-up label should name every attending child (one child here), got % / %', v_label, v_label_en;
  end if;
  if exists (select 1 from information_schema.columns c
              where c.table_schema = 'public' and c.table_name = 'marketing_follow_up_list'
                and c.column_name in ('family_display_name', 'nickname', 'child_nickname', 'birth_month',
                                      'age_years', 'allergens', 'phone', 'line_id')) then
    raise exception 'FAIL marketing_follow_up_list has a child, health or contact column';
  end if;
  raise notice 'PASS follow-up list: one row per consenting guardian, nickname-only label (TH and EN), minimal columns';

  -- (10) a withdrawn guardian drops out; the other guardian keeps one row
  insert into public.guardian_consent_records
    (id, family_id, guardian_id, purpose, consent_text_id, decision, channel, method)
  values ('6f000000-0000-4000-8000-0000000000a3', 'f0000000-0000-4000-8000-000000000003',
          'a0000000-0000-4000-8000-0000000000a2', 'marketing_line', '60000000-0000-4000-8000-000000000005',
          'withdrawn', 'web', 'checkbox');
  select count(*) into v_n from public.marketing_follow_up_list fl
   where fl.family_id = 'f0000000-0000-4000-8000-000000000003';
  if v_n <> 1 then
    raise exception 'FAIL after one withdrawal one row should remain, got %', v_n;
  end if;
  raise notice 'PASS a withdrawn guardian drops out of the follow-up list';
end
$$;

do $$
declare
  v_arr  text[];
  v_food text;
  v_care text;
begin
  -- Allergy keys: flour is a new key, wheat stays its own key (brief item 7). Rolled back at the end of the block.
  begin
    update public.child_health
       set allergens = array['flour', 'wheat', 'peanut'], foods_to_avoid = 'TEST food', care_notes = 'TEST note'
     where child_id = 'c0000000-0000-4000-8000-000000000001';
    select g.allergens into v_arr
      from public.get_child_health('c0000000-0000-4000-8000-000000000001', false) g;
    if not ('flour' = any (v_arr) and 'wheat' = any (v_arr)) then
      raise exception 'FAIL flour and wheat should both be stored and returned';
    end if;
    -- includeHealth = false: allergens come back, the notes do not
    select g.foods_to_avoid, g.care_notes into v_food, v_care
      from public.get_child_health('c0000000-0000-4000-8000-000000000001', false) g;
    if v_food is not null or v_care is not null then
      raise exception 'FAIL includeHealth = false must hide foods_to_avoid and care_notes';
    end if;
    -- includeHealth = true: the notes come back
    select g.foods_to_avoid, g.care_notes into v_food, v_care
      from public.get_child_health('c0000000-0000-4000-8000-000000000001', true) g;
    if v_food is distinct from 'TEST food' or v_care is distinct from 'TEST note' then
      raise exception 'FAIL includeHealth = true must return the notes';
    end if;
    raise notice 'PASS get_child_health: allergens always, notes only with includeHealth = true (brief item 3)';
    raise exception 'TEST_ROLLBACK';
  exception when raise_exception then
    if sqlerrm <> 'TEST_ROLLBACK' then
      raise;
    end if;
  end;

  begin
    perform public.get_child_health('c0000000-0000-4000-8000-000000000001', null);
    raise exception 'FAIL get_child_health accepted a missing includeHealth';
  exception when sqlstate '22004' then
    raise notice 'PASS includeHealth is required (null is refused)';
  end;

  begin
    update public.child_health set allergens = array['gluten']
     where child_id = 'c0000000-0000-4000-8000-000000000001';
    raise exception 'FAIL an unknown allergen key was accepted';
  exception when check_violation then
    raise notice 'PASS allergen keys are a closed list (gluten refused; flour accepted)';
  end;
end
$$;


-- -----------------------------------------------------------------------------
-- 7e. Round three (14 Oct 2026): cancellations and the cancellation log (briefs 1, 2, 6), the rebooking rule (brief 7),
--     the follow-up label for one, two and three children (brief 5), the print status line (brief 4), the 6-month
--     clock (brief 3). Family f…0004 is NEW: four children and one eight-pack, all on session N7 (…0008). FAKE data only.
--     Cancellations go through cancel_booking(). Cancelling 'cancelled_studio' by session is in § 7d (5).
-- -----------------------------------------------------------------------------

do $$
declare
  v_today    date := (now() at time zone 'Asia/Bangkok')::date;
  v_n1       date;
  v_start    timestamptz;
  v_n        integer;
  v_status   public.booking_status;
  v_left     integer;
  v_outcome  public.cancellation_outcome;
  v_label_th text;
  v_label_en text;
  v_rows     integer;
  v_status_c text;
  v_flag     boolean;
  v_food     text;
  v_rec      public.booking_cancellation_log%rowtype;
  v_expect   numeric;
  v_r        public.report_attendance_monthly%rowtype;
  v_sess3    date;
  v_start_n1 timestamptz;
begin
  v_n1 := v_today + ((6 - extract(isodow from v_today)::integer + 7) % 7);

  insert into public.sessions (id, session_date, starts_at, ends_at, capacity, status, public_note_en, staff_note)
  values ('b0000000-0000-4000-8000-000000000008', v_n1 + 35, '07:00', '08:00', 10, 'open', 'TEST', 'TEST round three N7');
  select (s.session_date + s.starts_at) at time zone 'Asia/Bangkok' into v_start
    from public.sessions s where s.id = 'b0000000-0000-4000-8000-000000000008';

  insert into public.families (id, display_name)
  values ('f0000000-0000-4000-8000-000000000004', 'ครอบครัวทดสอบสี่ (TEST)');

  insert into public.guardians
    (id, family_id, full_name, phone, is_primary, has_parental_responsibility, responsibility_attested_at,
     identity_check_method, identity_checked_at)
  values ('a0000000-0000-4000-8000-0000000000b1', 'f0000000-0000-4000-8000-000000000004', 'ผู้ปกครองทดสอบเจ็ด',
          '0800000013', true, true, now(), 'line_account', now());

  insert into public.children (id, family_id, nickname)
  values ('c0000000-0000-4000-8000-0000000000b1', 'f0000000-0000-4000-8000-000000000004', 'ทดสอบหนึ่ง'),
         ('c0000000-0000-4000-8000-0000000000b2', 'f0000000-0000-4000-8000-000000000004', 'ทดสอบสอง'),
         ('c0000000-0000-4000-8000-0000000000b3', 'f0000000-0000-4000-8000-000000000004', 'ทดสอบสาม'),
         ('c0000000-0000-4000-8000-0000000000b4', 'f0000000-0000-4000-8000-000000000004', 'ทดสอบสี่');

  insert into public.package_purchases (id, family_id, package_code, sessions_total, price_thb)
  values ('d0000000-0000-4000-8000-0000000000b1', 'f0000000-0000-4000-8000-000000000004', 'eight', 8, 28800);

  -- (L1) one child with a live booking: the label names one child
  insert into public.bookings (id, session_id, child_id, package_purchase_id, status)
  values ('b1000000-0000-4000-8000-0000000000b1', 'b0000000-0000-4000-8000-000000000008',
          'c0000000-0000-4000-8000-0000000000b1', 'd0000000-0000-4000-8000-0000000000b1', 'confirmed');
  select count(*), min(l.label_th), min(l.label_en) into v_rows, v_label_th, v_label_en
    from public.family_label('f0000000-0000-4000-8000-000000000004') l;
  if v_rows <> 1 or v_label_th is distinct from 'ครอบครัวน้องทดสอบหนึ่ง' or v_label_en is distinct from 'Family of ทดสอบหนึ่ง' then
    raise exception 'FAIL one-child label should be ครอบครัวน้องทดสอบหนึ่ง / Family of ทดสอบหนึ่ง, got % rows: % / %', v_rows, v_label_th, v_label_en;
  end if;
  raise notice 'PASS follow-up label for one child (TH: ครอบครัว + น้อง + nickname; EN: Family of nickname)';

  -- (L2) verifier fix (14 Oct 2026): a LATE cancellation (notice after the cutoff) is cancelled_late, keeps the seat and
  -- uses one credit, but the child is NOT named on the label (the label counts non-cancelled bookings only). The
  -- 6-month health clock still counts the child (D50).
  insert into public.bookings (id, session_id, child_id, package_purchase_id, status)
  values ('b1000000-0000-4000-8000-0000000000b2', 'b0000000-0000-4000-8000-000000000008',
          'c0000000-0000-4000-8000-0000000000b2', 'd0000000-0000-4000-8000-0000000000b1', 'confirmed');
  v_outcome := public.cancel_booking('b1000000-0000-4000-8000-0000000000b2', 'line', v_start - interval '2 hours', false);
  if v_outcome is distinct from 'family_late' then
    raise exception 'FAIL a late notice should log family_late, got %', v_outcome;
  end if;
  select b.status into v_status from public.bookings b where b.id = 'b1000000-0000-4000-8000-0000000000b2';
  if v_status is distinct from 'cancelled_late' or not public.child_has_recent_booking('c0000000-0000-4000-8000-0000000000b2') then
    raise exception 'FAIL a cancelled_late child should keep the 6-month clock (status %)', v_status;
  end if;
  select count(*), min(l.label_th), min(l.label_en) into v_rows, v_label_th, v_label_en
    from public.family_label('f0000000-0000-4000-8000-000000000004') l;
  if v_rows <> 1 or v_label_th is distinct from 'ครอบครัวน้องทดสอบหนึ่ง'
     or v_label_en is distinct from 'Family of ทดสอบหนึ่ง' then
    raise exception 'FAIL a late-cancelled child must not be named on the label (one child only), got % / %', v_label_th, v_label_en;
  end if;
  raise notice 'PASS a late cancellation is not named on the label, but keeps the 6-month clock (round three, verifier fix)';

  -- (L3) b2 books another session (N4, session 0005) and b3 books N8: three attending children now. The label uses a
  -- comma for the middle names and "และ" before the last one. b2 is named because of the non-cancelled N4 booking.
  insert into public.bookings (id, session_id, child_id, package_purchase_id, status)
  values ('b1000000-0000-4000-8000-0000000000b5', 'b0000000-0000-4000-8000-000000000005',
          'c0000000-0000-4000-8000-0000000000b2', 'd0000000-0000-4000-8000-0000000000b1', 'confirmed');
  insert into public.bookings (id, session_id, child_id, package_purchase_id, status)
  values ('b1000000-0000-4000-8000-0000000000b3', 'b0000000-0000-4000-8000-000000000008',
          'c0000000-0000-4000-8000-0000000000b3', 'd0000000-0000-4000-8000-0000000000b1', 'confirmed');
  select count(*), min(l.label_th), min(l.label_en) into v_rows, v_label_th, v_label_en
    from public.family_label('f0000000-0000-4000-8000-000000000004') l;
  if v_rows <> 1 or v_label_th is distinct from 'ครอบครัวน้องทดสอบหนึ่ง, น้องทดสอบสอง และ น้องทดสอบสาม'
     or v_label_en is distinct from 'Family of ทดสอบหนึ่ง, ทดสอบสอง and ทดสอบสาม' then
    raise exception 'FAIL three-child label, got % / %', v_label_th, v_label_en;
  end if;
  raise notice 'PASS follow-up label for three children: comma between the first two, และ / and before the last';

  -- (L4) a child whose only booking on N8 is cancelled ON TIME (notice 'phone', exactly at the cutoff) is not counted.
  -- The label still names the three children who have a non-cancelled booking (b2 via N4).
  insert into public.bookings (id, session_id, child_id, package_purchase_id, status)
  values ('b1000000-0000-4000-8000-0000000000b4', 'b0000000-0000-4000-8000-000000000008',
          'c0000000-0000-4000-8000-0000000000b4', 'd0000000-0000-4000-8000-0000000000b1', 'confirmed');
  v_outcome := public.cancel_booking('b1000000-0000-4000-8000-0000000000b4', 'phone', v_start - interval '3 hours', false);
  if v_outcome is distinct from 'family_on_time' then
    raise exception 'FAIL a phone notice exactly cancel_notice_hours before should be family_on_time, got %', v_outcome;
  end if;
  if public.child_has_recent_booking('c0000000-0000-4000-8000-0000000000b4') then
    raise exception 'FAIL a child cancelled on time should not keep the 6-month clock';
  end if;
  select count(*) into v_rows from public.family_label('f0000000-0000-4000-8000-000000000004');
  if v_rows <> 1 or (select l.label_en from public.family_label('f0000000-0000-4000-8000-000000000004') l)
                    is distinct from 'Family of ทดสอบหนึ่ง, ทดสอบสอง and ทดสอบสาม' then
    raise exception 'FAIL a child cancelled on time should drop off the label';
  end if;
  raise notice 'PASS a phone notice exactly at the cutoff is on time (credit kept); the child drops off the clock';

  -- (L5) the third child cancels with a teacher as the notice: back to two children
  v_outcome := public.cancel_booking('b1000000-0000-4000-8000-0000000000b3', 'teacher', v_start - interval '5 hours', false);
  if v_outcome is distinct from 'family_on_time' then
    raise exception 'FAIL a teacher notice 5 hours before should be family_on_time, got %', v_outcome;
  end if;
  select count(*), min(l.label_th), min(l.label_en) into v_rows, v_label_th, v_label_en
    from public.family_label('f0000000-0000-4000-8000-000000000004') l;
  if v_rows <> 1 or v_label_th is distinct from 'ครอบครัวน้องทดสอบหนึ่ง และ น้องทดสอบสอง'
     or v_label_en is distinct from 'Family of ทดสอบหนึ่ง and ทดสอบสอง' then
    raise exception 'FAIL after the third child cancels, the label should name two children, got % / %', v_label_th, v_label_en;
  end if;
  raise notice 'PASS a teacher notice counts as notice (any channel); the label drops that child';

  -- (L6) no attending child (a family id with no children): no row
  select count(*) into v_rows from public.family_label('f0000000-0000-4000-8000-0000000000ff');
  if v_rows <> 0 then
    raise exception 'FAIL a family with no attending child should give no label row';
  end if;
  raise notice 'PASS a family with no attending child has no label row';

  -- (C) the cancellation log: one row per cancellation event, with outcome, channel and notice time
  -- a1 was booked on N1 (…0002) in § 7d; its notice was exactly cancel_notice_hours before N1 starts
  select (s.session_date + s.starts_at) at time zone 'Asia/Bangkok' - interval '3 hours' into v_start_n1
    from public.sessions s where s.id = 'b0000000-0000-4000-8000-000000000002';
  select * into v_rec from public.booking_cancellation_log l where l.booking_id = 'b1000000-0000-4000-8000-0000000000a1';
  if v_rec.outcome is distinct from 'family_on_time' or v_rec.notice_channel is distinct from 'line'
     or v_rec.notice_at is distinct from v_start_n1 then
    raise exception 'FAIL log row for the on-time cancel (section 7d) is wrong: % / % / %', v_rec.outcome, v_rec.notice_channel, v_rec.notice_at;
  end if;
  select * into v_rec from public.booking_cancellation_log l where l.booking_id = 'b1000000-0000-4000-8000-0000000000a2';
  if v_rec.outcome is distinct from 'family_late' or v_rec.notice_channel is distinct from 'in_person' then
    raise exception 'FAIL log row for the late cancel with a notice is wrong: % / %', v_rec.outcome, v_rec.notice_channel;
  end if;
  select * into v_rec from public.booking_cancellation_log l where l.booking_id = 'b1000000-0000-4000-8000-0000000000b2';
  if v_rec.outcome is distinct from 'family_late' or v_rec.notice_channel is distinct from 'line' then
    raise exception 'FAIL log row for the late cancel on N8 (line) is wrong: % / %', v_rec.outcome, v_rec.notice_channel;
  end if;
  -- verifier fix: a missed class recorded as absent (§ 7d (4)) writes no cancellation row
  select count(*) into v_n from public.booking_cancellation_log l where l.booking_id = 'b1000000-0000-4000-8000-0000000000a4';
  if v_n <> 0 then
    raise exception 'FAIL a missed class recorded as absent must not write a cancellation log row';
  end if;
  select * into v_rec from public.booking_cancellation_log l where l.booking_id = 'b1000000-0000-4000-8000-0000000000a5';
  -- recorded_by = auth.uid(); the SQL editor has no signed-in user, so it is NULL in this seed (verifier fix: comment only)
  if v_rec.outcome is distinct from 'studio' or v_rec.recorded_by is not null then
    raise exception 'FAIL log row for the studio cancellation is wrong: % / %', v_rec.outcome, v_rec.recorded_by;
  end if;
  select count(*) into v_n from public.booking_cancellation_log l where l.booking_id = 'b1000000-0000-4000-8000-0000000000a3';
  if v_n <> 0 then
    raise exception 'FAIL an absence must not write a cancellation log row';
  end if;
  select l.notice_channel::text into v_status_c from public.booking_cancellation_log l
   where l.booking_id = 'b1000000-0000-4000-8000-0000000000b4';
  if v_status_c is distinct from 'phone' then
    raise exception 'FAIL the phone notice should be stored as phone, got %', v_status_c;
  end if;
  select l.notice_channel::text into v_status_c from public.booking_cancellation_log l
   where l.booking_id = 'b1000000-0000-4000-8000-0000000000b3';
  if v_status_c is distinct from 'teacher' then
    raise exception 'FAIL the teacher notice should be stored as teacher, got %', v_status_c;
  end if;
  raise notice 'PASS cancellation log: family_on_time / family_late / studio rows with channel and notice time; absences write none';

  -- (G) guards: a direct edit cannot cancel, a second cancel is refused, studio cannot carry a notice, the log is append-only
  begin
    update public.bookings set status = 'cancelled' where id = 'b1000000-0000-4000-8000-0000000000a3';
    raise exception 'FAIL a direct cancel of a booking was accepted';
  exception when insufficient_privilege then
    raise notice 'PASS a direct status edit cannot cancel a booking (only cancel_booking() writes the log)';
  end;
  begin
    perform public.cancel_booking('b1000000-0000-4000-8000-0000000000a1', 'line', v_start - interval '3 hours', false);
    raise exception 'FAIL a booking was cancelled twice';
  exception when check_violation then
    raise notice 'PASS a cancelled booking cannot be cancelled again';
  end;
  begin
    perform public.cancel_booking('b1000000-0000-4000-8000-0000000000b1', 'line', now(), true);
    raise exception 'FAIL a studio cancellation with a notice was accepted';
  exception when invalid_parameter_value then
    raise notice 'PASS a studio cancellation carries no notice';
  end;
  begin
    update public.booking_cancellation_log set outcome = 'studio' where booking_id = 'b1000000-0000-4000-8000-0000000000a1';
    raise exception 'FAIL the cancellation log accepted an update';
  exception when insufficient_privilege then
    raise notice 'PASS booking_cancellation_log cannot be updated';
  end;
  begin
    delete from public.booking_cancellation_log where booking_id = 'b1000000-0000-4000-8000-0000000000a1';
    raise exception 'FAIL the cancellation log accepted a delete';
  exception when insufficient_privilege then
    raise notice 'PASS booking_cancellation_log cannot be deleted';
  end;

  -- (R) brief 7: a rebooking uses the returned credit (child of § 7d, family 3, studio-cancelled on N6), no notice check
  insert into public.bookings (id, session_id, child_id, package_purchase_id, status, makeup_of_booking_id)
  values ('b1000000-0000-4000-8000-0000000000c1', 'b0000000-0000-4000-8000-000000000008',
          'c0000000-0000-4000-8000-0000000000a1', 'd0000000-0000-4000-8000-0000000000a1', 'confirmed',
          'b1000000-0000-4000-8000-0000000000a5');
  select pb.sessions_left into v_left from public.package_balances pb
   where pb.package_purchase_id = 'd0000000-0000-4000-8000-0000000000a1';
  if v_left is distinct from 0 then
    raise exception 'FAIL the rebooking should use the returned credit, left %', v_left;
  end if;
  raise notice 'PASS a rebooking uses the returned credit (no make-up notice check)';
  begin
    insert into public.bookings (session_id, child_id, package_purchase_id, status)
    values ('b0000000-0000-4000-8000-000000000002', 'c0000000-0000-4000-8000-0000000000a1',
            'd0000000-0000-4000-8000-0000000000a1', 'confirmed');
    raise exception 'FAIL a booking with no sessions left was accepted';
  exception when check_violation then
    raise notice 'PASS no booking beyond the package credits, after the rebooking';
  end;
  begin
    insert into public.bookings (session_id, child_id, package_purchase_id, status, makeup_of_booking_id)
    values ('b0000000-0000-4000-8000-000000000002', 'c0000000-0000-4000-8000-0000000000b1',
            'd0000000-0000-4000-8000-0000000000b1', 'confirmed', 'b1000000-0000-4000-8000-0000000000a5');
    raise exception 'FAIL a rebooking linked to another child was accepted';
  exception when check_violation then
    raise notice 'PASS a rebooking must replace a booking of the same child';
  end;

  -- (H) brief 3: the 6-month clock counts cancelled_late, not cancelled or cancelled_studio.
  -- PROVISIONAL (verifier fix): the cancelled_studio rule is the drafter's reading; the owner has not ruled (00 § 13B c).
  if not public.child_has_recent_booking('c0000000-0000-4000-8000-0000000000b1')
     or not public.child_has_recent_booking('c0000000-0000-4000-8000-0000000000b2') then
    raise exception 'FAIL a live or cancelled_late child should keep the 6-month clock';
  end if;
  if public.child_has_recent_booking('c0000000-0000-4000-8000-0000000000b3')
     or public.child_has_recent_booking('c0000000-0000-4000-8000-0000000000b4') then
    raise exception 'FAIL a child cancelled on time should not keep the 6-month clock';
  end if;
  if public.booking_is_live('cancelled_late'::public.booking_status) is not true
     or public.booking_is_live('cancelled'::public.booking_status) is not false
     or public.booking_is_live('cancelled_studio'::public.booking_status) is not false
     or public.booking_is_live('absent'::public.booking_status) is not true then
    raise exception 'FAIL booking_is_live truth table is wrong';
  end if;
  raise notice 'PASS the 6-month clock counts cancelled_late; cancelled and cancelled_studio do not (brief 3)';

  -- (P) brief 4: the print read model always carries the health consent STATUS; content only with includeHealth
  -- P1 granted: the guardian grants health for b1, staff stores an allergen and notes
  insert into public.consent_records (family_id, guardian_id, child_id, purpose, consent_text_id, decision,
                                      given_by, channel, method)
  values ('f0000000-0000-4000-8000-000000000004', 'a0000000-0000-4000-8000-0000000000b1',
          'c0000000-0000-4000-8000-0000000000b1', 'health_allergy', '60000000-0000-4000-8000-000000000001',
          'granted', 'guardian', 'web', 'checkbox');
  perform public.upsert_child_health('c0000000-0000-4000-8000-0000000000b1', array['flour'], null, 'TEST food', 'TEST note');
  select g.health_consent_status into v_status_c
    from public.get_child_health('c0000000-0000-4000-8000-0000000000b1', false) g;
  if v_status_c is distinct from 'granted' then
    raise exception 'FAIL print status should be granted, got %', v_status_c;
  end if;
  -- P2 not asked: no consent row at all (b2 has none)
  select g.health_consent_status, g.has_health_record into v_status_c, v_flag
    from public.get_child_health('c0000000-0000-4000-8000-0000000000b2', false) g;
  if v_status_c is distinct from 'not_asked' or v_flag then
    raise exception 'FAIL print status should be not_asked with no health record, got % / %', v_status_c, v_flag;
  end if;
  -- P3 refused: a guardian refusal for b4 (no health row)
  insert into public.consent_records (family_id, guardian_id, child_id, purpose, consent_text_id, decision,
                                      given_by, channel, method)
  values ('f0000000-0000-4000-8000-000000000004', 'a0000000-0000-4000-8000-0000000000b1',
          'c0000000-0000-4000-8000-0000000000b4', 'health_allergy', '60000000-0000-4000-8000-000000000001',
          'refused', 'guardian', 'web', 'checkbox');
  select g.health_consent_status into v_status_c
    from public.get_child_health('c0000000-0000-4000-8000-0000000000b4', false) g;
  if v_status_c is distinct from 'refused' then
    raise exception 'FAIL print status should be refused, got %', v_status_c;
  end if;
  -- P4 the status is shown with includeHealth false; the content is not; with true the content comes back
  select g.foods_to_avoid into v_food
    from public.get_child_health('c0000000-0000-4000-8000-0000000000b1', false) g;
  if v_food is not null then
    raise exception 'FAIL includeHealth = false must not return the food notes';
  end if;
  select g.foods_to_avoid into v_food
    from public.get_child_health('c0000000-0000-4000-8000-0000000000b1', true) g;
  if v_food is distinct from 'TEST food' then
    raise exception 'FAIL includeHealth = true must return the food notes';
  end if;
  perform public.record_family_print('f0000000-0000-4000-8000-000000000004', false);
  perform public.record_family_print('f0000000-0000-4000-8000-000000000004', true);
  raise notice 'PASS print read model: health consent status on every sheet (granted, not_asked, refused); content only with includeHealth';

  -- (RP) brief 2: the reports count cancellations from the log
  if (select rf.cancelled from public.report_session_fill rf where rf.session_id = 'b0000000-0000-4000-8000-000000000008') is distinct from 2
     or (select rf.cancelled_late from public.report_session_fill rf where rf.session_id = 'b0000000-0000-4000-8000-000000000008') is distinct from 1
     or (select rf.seats_booked from public.report_session_fill rf where rf.session_id = 'b0000000-0000-4000-8000-000000000008') is distinct from 3 then
    raise exception 'FAIL N7 fill should be cancelled 2, cancelled_late 1, seats_booked 3 (live: b1, b2, rebook)';
  end if;
  if (select rf.cancelled from public.report_session_fill rf where rf.session_id = 'b0000000-0000-4000-8000-000000000002') is distinct from 1
     or (select rf.cancelled_studio from public.report_session_fill rf where rf.session_id = 'b0000000-0000-4000-8000-000000000007') is distinct from 1 then
    raise exception 'FAIL report_session_fill should count one on-time cancel on N1 and one studio cancel on N6 from the log';
  end if;
  raise notice 'PASS report_session_fill counts cancellations from booking_cancellation_log (on time, late, studio)';

  -- attendance rate: a late cancellation is not an absence (left out of numerator and denominator)
  select (s.session_date) into v_sess3 from public.sessions s where s.id = 'b0000000-0000-4000-8000-000000000004';
  select r.* into v_r from public.report_attendance_monthly r
   where r.month = (date_trunc('month', v_sess3::timestamp))::date;
  if v_r.cancelled_late < 1 then
    raise exception 'FAIL the month of N3 should show the late cancellation';
  end if;
  v_expect := round(100.0 * v_r.attended / nullif(v_r.attended + v_r.absent, 0), 1);
  if v_r.attendance_rate_pct is distinct from v_expect then
    raise exception 'FAIL attendance rate should be attended / (attended + absent), got % expected %', v_r.attendance_rate_pct, v_expect;
  end if;
  raise notice 'PASS attendance rate leaves cancelled_late out (not an absence)';
end
$$;

-- -----------------------------------------------------------------------------
-- 8. Privacy operations (P5): deadlines, export, erase, purge
-- -----------------------------------------------------------------------------

insert into public.dsr_requests (id, family_id, requester_name, requested_right, channel, received_at)
values ('80000000-0000-4000-8000-000000000001', 'f0000000-0000-4000-8000-000000000001', 'ผู้ปกครองทดสอบ',
        'erasure', 'line', now()),
       ('80000000-0000-4000-8000-000000000002', 'f0000000-0000-4000-8000-000000000001', 'ผู้ปกครองทดสอบ',
        'access', 'in_person', now());

insert into public.breach_incidents (id, title, aware_at, risk_level, data_categories)
values ('81000000-0000-4000-8000-000000000001', 'TEST incident', now(), 'unlikely', array['TEST']);

do $$
declare
  v_due_erasure  timestamptz;
  v_due_access   timestamptz;
  v_review       timestamptz;
  v_pdpc         timestamptz;
  v_export       jsonb;
  v_counts       jsonb;
  v_purge        jsonb;
begin
  select d.due_at, d.review_due_at into v_due_erasure, v_review from public.dsr_requests d
   where d.id = '80000000-0000-4000-8000-000000000001';
  select d.due_at into v_due_access from public.dsr_requests d where d.id = '80000000-0000-4000-8000-000000000002';
  select b.pdpc_deadline into v_pdpc from public.breach_incidents b where b.id = '81000000-0000-4000-8000-000000000001';
  if v_due_erasure <> now() + interval '90 days' or v_due_access <> now() + interval '30 days'
     or v_review <> now() + interval '15 days' or v_pdpc <> now() + interval '72 hours' then
    raise exception 'FAIL deadlines wrong: erasure %, access %, review %, pdpc %', v_due_erasure, v_due_access, v_review, v_pdpc;
  end if;
  raise notice 'PASS DSR and breach deadlines';

  -- export returns this family only
  v_export := public.export_family_data('f0000000-0000-4000-8000-000000000001', true);
  if jsonb_array_length(v_export -> 'guardians') <> 1 or jsonb_array_length(v_export -> 'children') <> 2 then
    raise exception 'FAIL export counts wrong';
  end if;
  if v_export::text like '%ผู้ปกครองทดสอบสอง%' then
    raise exception 'FAIL export contains another family''s data';
  end if;
  if v_export::text like '%token_hash%' then
    raise exception 'FAIL export contains token hashes';
  end if;
  raise notice 'PASS export_family_data returns one family only';

  -- Round two (brief item 3, decision 3): includeHealth false = no health in the file; the choice is required
  v_export := public.export_family_data('f0000000-0000-4000-8000-000000000001', false);
  if jsonb_array_length(v_export -> 'child_health') <> 0 then
    raise exception 'FAIL export with includeHealth false still carries health';
  end if;
  raise notice 'PASS export without includeHealth carries no health data';
  begin
    perform public.export_family_data('f0000000-0000-4000-8000-000000000001', null);
    raise exception 'FAIL export_family_data accepted a missing includeHealth';
  exception when sqlstate '22004' then
    raise notice 'PASS export_family_data refuses a missing includeHealth';
  end;

  -- erase
  v_counts := public.erase_family('f0000000-0000-4000-8000-000000000001');
  if exists (select 1 from public.families f where f.id = 'f0000000-0000-4000-8000-000000000001')
     or exists (select 1 from public.guardians g where g.family_id = 'f0000000-0000-4000-8000-000000000001')
     or exists (select 1 from public.children c where c.id = 'c0000000-0000-4000-8000-000000000001') then
    raise exception 'FAIL family data still present after erase';
  end if;
  if not exists (select 1 from public.payments p
                  where p.id = 'd1000000-0000-4000-8000-000000000001' and p.family_id is null
                    and p.note is null and p.amount_thb = 14400) then
    raise exception 'FAIL payment should stay, anonymised';
  end if;
  if not exists (select 1 from public.consent_records cr
                  where cr.family_id is null and cr.child_nickname_snapshot = 'น้องทดสอบ'
                    and cr.retain_until > now() + interval '1000 days') then
    raise exception 'FAIL consent evidence should be detached and kept ~3 years';
  end if;
  if not exists (select 1 from public.guardian_consent_records gcr
                  where gcr.id = '6f000000-0000-4000-8000-000000000001' and gcr.family_id is null
                    and gcr.guardian_id is null and gcr.retain_until > now() + interval '1000 days') then
    raise exception 'FAIL marketing choices should be detached and kept ~3 years';
  end if;
  -- verifier fix (14 Oct 2026): erase keeps the round-two behaviour. The future booking keeps its status (confirmed)
  -- and its credit, is anonymised, and erase writes NO cancellation row. Only the family id is detached from log rows.
  if not exists (select 1 from public.bookings b
                  where b.id = 'b1000000-0000-4000-8000-000000000002'
                    and b.status = 'confirmed'::public.booking_status and b.child_id is null and b.family_id is null) then
    raise exception 'FAIL erase should keep the future booking confirmed (no studio cancellation) and anonymise it';
  end if;
  if exists (select 1 from public.booking_cancellation_log l
              where l.booking_id = 'b1000000-0000-4000-8000-000000000002') then
    raise exception 'FAIL erase must not write a cancellation log row for a future booking';
  end if;
  if exists (select 1 from public.booking_cancellation_log l where l.family_id = 'f0000000-0000-4000-8000-000000000001') then
    raise exception 'FAIL the cancellation log should drop the family id on erase';
  end if;
  if exists (select 1 from public.booking_requests br where br.id = '90000000-0000-4000-8000-000000000001') then
    raise exception 'FAIL the family''s booking request should be deleted';
  end if;
  if not exists (select 1 from public.audit_log a
                  where a.action = 'erase' and a.row_id = 'f0000000-0000-4000-8000-000000000001') then
    raise exception 'FAIL erase not audited';
  end if;
  raise notice 'PASS erase_family: personal data gone, money and consent evidence kept anonymised (%)', v_counts;

  -- the other family is untouched
  if not exists (select 1 from public.guardians g where g.id = 'a0000000-0000-4000-8000-000000000002') then
    raise exception 'FAIL erase touched another family';
  end if;
  raise notice 'PASS other families untouched';

  -- purge runs end to end
  v_purge := public.purge_expired_records();
  if (v_purge ->> 'version') is distinct from '4' then
    raise exception 'FAIL purge_expired_records did not report version 4: %', v_purge;
  end if;
  raise notice 'PASS purge_expired_records v4 ran: %', v_purge;
end
$$;


-- -----------------------------------------------------------------------------
-- 9. Report views (P6) return rows without errors
-- -----------------------------------------------------------------------------

do $$
declare
  v_n bigint;
begin
  select count(*) into v_n from public.report_session_fill where session_id = 'b0000000-0000-4000-8000-000000000003';
  if v_n <> 1 then
    raise exception 'FAIL report_session_fill missing the test session';
  end if;
  perform * from public.report_requests_weekly;
  perform * from public.report_attendance_monthly;
  perform * from public.report_revenue_monthly;   -- 0 rows here: the SQL editor user is not an owner
  raise notice 'PASS report views';
end
$$;

select 'seed_dev.sql: all behaviour checks passed — rolling back, nothing is kept' as result;

rollback;
