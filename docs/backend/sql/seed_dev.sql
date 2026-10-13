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
-- Output: NOTICE lines "PASS …". The first failing check raises "FAIL …" and aborts.
-- The final SELECT prints one row when everything passed.
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

  -- cancelling returns the credit and the seat
  update public.bookings set status = 'cancelled' where id = 'b1000000-0000-4000-8000-000000000003';
  select pb.sessions_left into v_left from public.package_balances pb
   where pb.package_purchase_id = 'd0000000-0000-4000-8000-000000000001';
  v_seats := public.session_seats_left('b0000000-0000-4000-8000-000000000003');
  if v_left is distinct from 1 or v_seats is distinct from 1 then
    raise exception 'FAIL cancel should give 1 credit and 1 seat back, got % and %', v_left, v_seats;
  end if;
  raise notice 'PASS cancel returns credit and seat';

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
  perform * from public.get_child_health('c0000000-0000-4000-8000-000000000001');
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
  v_export := public.export_family_data('f0000000-0000-4000-8000-000000000001');
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
  if not exists (select 1 from public.bookings b
                  where b.id = 'b1000000-0000-4000-8000-000000000002'
                    and b.status = 'cancelled' and b.child_id is null and b.family_id is null) then
    raise exception 'FAIL future booking should be cancelled and anonymised';
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
