-- Database tests T-DB1 to T-DB6 (TRD 20). Everything runs in one transaction and is rolled back,
-- so the dev database keeps no test data. Run (from the repo root):
--   npx supabase@2.119.0 db query --linked -f supabase/tests/database_test.sql
-- The last result lists one line per check: PASS or FAIL.
-- Reference numbers from PRD section 8: EMI ₹7,996.39 × 11 + ₹7,996.40 (₹90,000, 12%, 12 months).

begin;

create schema cftest;
grant usage on schema cftest to authenticated, anon;

create function cftest.check(p_name text, p_ok boolean, p_detail text default null) returns void
language plpgsql as $$
begin
  perform set_config('cftest.out',
    coalesce(current_setting('cftest.out', true), '')
      || case when coalesce(p_ok, false) then 'PASS ' else 'FAIL ' end || p_name
      || coalesce(' (' || p_detail || ')', '') || E'\n', true);
end;
$$;

-- Acts as a signed-in user on one login session (the JWT claims Supabase sets).
create function cftest.login(p_user uuid, p_session text) returns void
language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_user, 'role', 'authenticated', 'session_id', p_session)::text, true);
  perform set_config('role', 'authenticated', true);
end;
$$;

grant execute on all functions in schema cftest to authenticated, anon;

-- ---------- Setup (as the database owner) ----------

insert into auth.users (id, email, aud, role) values
  ('a0000000-0000-4000-8000-000000000001', 'a@test.local', 'authenticated', 'authenticated'),
  ('b0000000-0000-4000-8000-000000000002', 'b@test.local', 'authenticated', 'authenticated');

-- User A: approved phone (sa), pending phone (sp), removed phone (sr). User B: approved phone (sb).
insert into public.devices (user_id, name, status, session_id) values
  ('a0000000-0000-4000-8000-000000000001', 'A phone', 'approved', 'sa'),
  ('a0000000-0000-4000-8000-000000000001', 'A new phone', 'pending', 'sp'),
  ('a0000000-0000-4000-8000-000000000001', 'A lost phone', 'removed', 'sr'),
  ('b0000000-0000-4000-8000-000000000002', 'B phone', 'approved', 'sb');

-- A has Premium; B is Free.
insert into public.subscriptions (user_id, product_id, base_plan, status, expires_at, purchase_token) values
  ('a0000000-0000-4000-8000-000000000001', 'premium', 'monthly', 'active', now() + interval '30 days', 'tok-a');

insert into public.people (id, user_id, name, phone_normalized) values
  ('a1000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001', 'Rahul', '+919876543210'),
  ('b1000000-0000-4000-8000-000000000002', 'b0000000-0000-4000-8000-000000000002', 'Sita', null);

insert into public.debts (id, user_id, person_id, direction, amount, occurred_at, payment_mode) values
  ('a2000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001',
   'a1000000-0000-4000-8000-000000000001', 'lent', 500000, now(), 'cash'),
  ('b2000000-0000-4000-8000-000000000002', 'b0000000-0000-4000-8000-000000000002',
   'b1000000-0000-4000-8000-000000000002', 'borrowed', 100000, now(), 'cash');

insert into public.categories (id, user_id, kind, name, name_key, icon, color, is_default) values
  ('a3000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001', 'expense', 'EMI', 'catEmi', 'calendar', 4280000000, true);

insert into public.emis (id, user_id, name, loan_amount, rate_bp, months, emi_amount, first_due_date) values
  ('a4000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001', 'Bike loan', 9000000, 1200, 12, 799639, '2026-11-05'),
  ('b4000000-0000-4000-8000-000000000002', 'b0000000-0000-4000-8000-000000000002', 'Old phone', 1200000, 0, 12, 100000, '2026-11-05');

insert into public.emi_installments (id, user_id, emi_id, seq, due_date, amount, interest_part, principal_part) values
  ('a5000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001', 'a4000000-0000-4000-8000-000000000001', 1, '2026-11-05', 799639, 90000, 709639),
  ('a5000000-0000-4000-8000-000000000002', 'a0000000-0000-4000-8000-000000000001', 'a4000000-0000-4000-8000-000000000001', 2, '2026-12-05', 799640, 7917, 791723);

insert into public.bills (id, user_id, bill_type, name, every_months, next_due_date) values
  ('a6000000-0000-4000-8000-000000000001', 'a0000000-0000-4000-8000-000000000001', 'electricity', 'Torrent Power', 1, '2027-01-31');

-- ---------- Signed out: nothing ----------

set local role anon;
do $$
begin
  perform count(*) from public.people;
  perform cftest.check('anon cannot read people', false);
exception when insufficient_privilege then
  perform cftest.check('anon cannot read people', true);
end;
$$;
do $$
begin
  perform public.record_repayment('{}'::jsonb);
  perform cftest.check('anon cannot call actions', false);
exception when insufficient_privilege then
  perform cftest.check('anon cannot call actions', true);
end;
$$;
reset role;

-- ---------- T-DB1: another user's rows are invisible and untouchable ----------

select cftest.login('b0000000-0000-4000-8000-000000000002', 'sb');
do $$
declare n int;
begin
  select count(*) into n from public.people;
  perform cftest.check('T-DB1 B sees only own people', n = 1, n || ' rows');
  select count(*) into n from public.debts where user_id = 'a0000000-0000-4000-8000-000000000001';
  perform cftest.check('T-DB1 B cannot read A debts', n = 0);
  update public.debts set note = 'hacked' where id = 'a2000000-0000-4000-8000-000000000001';
  get diagnostics n = row_count;
  perform cftest.check('T-DB1 B cannot update A debt', n = 0);
  begin
    insert into public.people (id, user_id, name) values (gen_random_uuid(), 'a0000000-0000-4000-8000-000000000001', 'X');
    perform cftest.check('T-DB1 B cannot write rows as A', false);
  exception when insufficient_privilege then
    perform cftest.check('T-DB1 B cannot write rows as A', true);
  end;
  begin
    perform public.mark_installment_paid('a5000000-0000-4000-8000-000000000001',
      jsonb_build_object('id', gen_random_uuid(), 'occurred_at', now(), 'payment_mode', 'cash'));
    perform cftest.check('T-DB1 B cannot pay A installment', false);
  exception when no_data_found then
    perform cftest.check('T-DB1 B cannot pay A installment', true);
  end;
  begin
    delete from public.people;
    perform cftest.check('hard delete is not allowed', false);
  exception when insufficient_privilege then
    perform cftest.check('hard delete is not allowed', true);
  end;
end;
$$;
reset role;

-- ---------- T-DB2: pending, removed or unknown phone sees nothing ----------

do $$
declare
  s text;
  n int;
begin
  foreach s in array array['sp', 'sr', 'unknown'] loop
    perform cftest.login('a0000000-0000-4000-8000-000000000001', s);
    select count(*) into n from public.people;
    perform cftest.check('T-DB2 session ' || s || ' sees no people', n = 0, n || ' rows');
    begin
      insert into public.people (id, user_id, name) values (gen_random_uuid(), 'a0000000-0000-4000-8000-000000000001', 'Y');
      perform cftest.check('T-DB2 session ' || s || ' cannot write', false);
    exception when insufficient_privilege then
      perform cftest.check('T-DB2 session ' || s || ' cannot write', true);
    end;
    reset role;
  end loop;
end;
$$;

select cftest.login('a0000000-0000-4000-8000-000000000001', 'sa');
do $$
declare n int;
begin
  select count(*) into n from public.people;
  perform cftest.check('T-DB2 approved phone sees its people', n = 1, n || ' rows');
end;
$$;
reset role;

-- ---------- T-DB3: Premium writes need a plan; data stays readable ----------

select cftest.login('b0000000-0000-4000-8000-000000000002', 'sb');
do $$
declare n int;
begin
  begin
    insert into public.emis (id, user_id, name, loan_amount, rate_bp, months, emi_amount, first_due_date)
    values (gen_random_uuid(), 'b0000000-0000-4000-8000-000000000002', 'TV', 3000000, 1400, 10, 320000, '2026-12-01');
    perform cftest.check('T-DB3 Free cannot add an EMI', false);
  exception when insufficient_privilege then
    perform cftest.check('T-DB3 Free cannot add an EMI', true);
  end;
  select count(*) into n from public.emis;
  perform cftest.check('T-DB3 Free still reads an old EMI', n = 1, n || ' rows');
  begin
    update public.emis set name = 'Renamed' where id = 'b4000000-0000-4000-8000-000000000002';
    perform cftest.check('T-DB3 old EMI is read-only on Free', false);
  exception when insufficient_privilege then
    perform cftest.check('T-DB3 old EMI is read-only on Free', true);
  end;
end;
$$;
do $$
declare n int;
begin
  insert into public.debts (id, user_id, person_id, direction, amount, occurred_at, payment_mode)
  values (gen_random_uuid(), 'b0000000-0000-4000-8000-000000000002', 'b1000000-0000-4000-8000-000000000002', 'lent', 20000, now(), 'cash');
  perform cftest.check('T-DB3 Free can add udhar without a due date', true);
  begin
    insert into public.debts (id, user_id, person_id, direction, amount, occurred_at, payment_mode, due_date)
    values (gen_random_uuid(), 'b0000000-0000-4000-8000-000000000002', 'b1000000-0000-4000-8000-000000000002', 'lent', 20000, now(), 'cash', '2026-11-01');
    perform cftest.check('T-DB3 Free cannot set a due date', false);
  exception when insufficient_privilege then
    perform cftest.check('T-DB3 Free cannot set a due date', true);
  end;
  begin
    update public.debts set reminder_days = '0,3' where id = 'b2000000-0000-4000-8000-000000000002';
    perform cftest.check('T-DB3 Free cannot set reminders', false);
  exception when insufficient_privilege then
    perform cftest.check('T-DB3 Free cannot set reminders', true);
  end;
  update public.debts set note = 'fine' where id = 'b2000000-0000-4000-8000-000000000002';
  get diagnostics n = row_count;
  perform cftest.check('T-DB3 Free can edit a note', n = 1);
  begin
    perform public.extend_due_date('b2000000-0000-4000-8000-000000000002',
      jsonb_build_object('id', gen_random_uuid(), 'new_due_date', '2026-12-01'));
    perform cftest.check('T-DB3 Free cannot extend a due date', false);
  exception when insufficient_privilege then
    perform cftest.check('T-DB3 Free cannot extend a due date', true);
  end;
end;
$$;
reset role;

-- ---------- T-DB5: updated_at is the server's clock ----------

select cftest.login('a0000000-0000-4000-8000-000000000001', 'sa');
do $$
declare t timestamptz;
begin
  insert into public.people (id, user_id, name, updated_at)
  values ('a1000000-0000-4000-8000-000000000009', 'a0000000-0000-4000-8000-000000000001', 'Clock', '2000-01-01');
  select updated_at into t from public.people where id = 'a1000000-0000-4000-8000-000000000009';
  perform cftest.check('T-DB5 insert sets updated_at', t = now(), t::text);
  update public.people set updated_at = '2000-01-01', name = 'Clock 2' where id = 'a1000000-0000-4000-8000-000000000009';
  select updated_at into t from public.people where id = 'a1000000-0000-4000-8000-000000000009';
  perform cftest.check('T-DB5 update sets updated_at', t = now(), t::text);
end;
$$;

-- ---------- T-DB4: repayment never exceeds what is left; the extra becomes new udhar ----------

do $$
declare
  res jsonb;
  d public.debts;
  extra_debt public.debts;
begin
  begin
    insert into public.debt_payments (id, user_id, debt_id, amount, occurred_at, payment_mode)
    values (gen_random_uuid(), 'a0000000-0000-4000-8000-000000000001', 'a2000000-0000-4000-8000-000000000001', 500001, now(), 'cash');
    perform cftest.check('T-DB4 direct overpayment is rejected', false);
  exception when check_violation then
    perform cftest.check('T-DB4 direct overpayment is rejected', true);
  end;

  res := public.record_repayment(jsonb_build_object('id', 'a7000000-0000-4000-8000-000000000001',
    'debt_id', 'a2000000-0000-4000-8000-000000000001', 'amount', 200000, 'occurred_at', now(), 'payment_mode', 'cash'));
  perform cftest.check('T-DB4 ₹2,000 of ₹5,000 applied', res = '{"applied": 200000, "extra": 0, "settled": false}'::jsonb, res::text);

  res := public.record_repayment(jsonb_build_object('id', 'a7000000-0000-4000-8000-000000000001',
    'debt_id', 'a2000000-0000-4000-8000-000000000001', 'amount', 200000, 'occurred_at', now(), 'payment_mode', 'cash'));
  perform cftest.check('T-DB4 retry does not pay twice',
    (select count(*) from public.debt_payments where debt_id = 'a2000000-0000-4000-8000-000000000001') = 1);

  res := public.record_repayment(jsonb_build_object('id', 'a7000000-0000-4000-8000-000000000002',
    'debt_id', 'a2000000-0000-4000-8000-000000000001', 'amount', 400000, 'occurred_at', now(), 'payment_mode', 'online', 'online_method', 'upi'));
  perform cftest.check('T-DB4 ₹4,000 on ₹3,000 left: ₹3,000 applied, ₹1,000 extra',
    res = '{"applied": 300000, "extra": 100000, "settled": true}'::jsonb, res::text);
  select * into d from public.debts where id = 'a2000000-0000-4000-8000-000000000001';
  perform cftest.check('T-DB4 udhar is settled with the extra remembered', d.status = 'settled' and d.extra_not_added = 100000);

  perform public.add_extra_as_debt('a2000000-0000-4000-8000-000000000001',
    jsonb_build_object('id', 'a2000000-0000-4000-8000-000000000009', 'occurred_at', now()));
  select * into extra_debt from public.debts where id = 'a2000000-0000-4000-8000-000000000009';
  perform cftest.check('T-DB4 extra becomes borrowed ₹1,000 linked to the first',
    extra_debt.direction = 'borrowed' and extra_debt.amount = 100000
      and extra_debt.extra_from_debt_id = 'a2000000-0000-4000-8000-000000000001');
  perform cftest.check('T-DB4 extra is cleared on the first udhar',
    (select extra_not_added from public.debts where id = 'a2000000-0000-4000-8000-000000000001') is null);
end;
$$;

-- ---------- T-DB6: EMI and bill actions ----------

do $$
declare
  t public.transactions;
  i public.emi_installments;
  b public.bills;
begin
  begin
    perform public.mark_installment_paid('a5000000-0000-4000-8000-000000000002',
      jsonb_build_object('id', gen_random_uuid(), 'occurred_at', now(), 'payment_mode', 'cash'));
    perform cftest.check('T-DB6 only the next installment can be paid', false);
  exception when check_violation then
    perform cftest.check('T-DB6 only the next installment can be paid', true);
  end;

  perform public.mark_installment_paid('a5000000-0000-4000-8000-000000000001',
    jsonb_build_object('id', 'a8000000-0000-4000-8000-000000000001', 'occurred_at', now(), 'payment_mode', 'online',
      'online_method', 'upi', 'title', 'Bike loan', 'category_id', 'a3000000-0000-4000-8000-000000000001', 'amount', 1));
  select * into t from public.transactions where id = 'a8000000-0000-4000-8000-000000000001';
  perform cftest.check('T-DB6 mark paid adds an expense of ₹7,996.39 (amount from the installment)',
    t.kind = 'expense' and t.amount = 799639 and t.source = 'emi' and t.source_id = 'a5000000-0000-4000-8000-000000000001');
  select * into i from public.emi_installments where id = 'a5000000-0000-4000-8000-000000000001';
  perform cftest.check('T-DB6 installment is paid and linked', i.status = 'paid' and i.transaction_id = t.id);

  perform public.mark_installment_paid('a5000000-0000-4000-8000-000000000001',
    jsonb_build_object('id', 'a8000000-0000-4000-8000-000000000001', 'occurred_at', now(), 'payment_mode', 'cash'));
  perform cftest.check('T-DB6 retry adds no second expense',
    (select count(*) from public.transactions where source_id = 'a5000000-0000-4000-8000-000000000001') = 1);

  perform public.mark_installment_paid('a5000000-0000-4000-8000-000000000002',
    jsonb_build_object('id', 'a8000000-0000-4000-8000-000000000002', 'occurred_at', now(), 'payment_mode', 'cash'));
  perform cftest.check('T-DB6 last installment ₹7,996.40 closes the EMI',
    (select status from public.emis where id = 'a4000000-0000-4000-8000-000000000001') = 'closed'
      and (select amount from public.transactions where id = 'a8000000-0000-4000-8000-000000000002') = 799640);

  perform public.unmark_installment_paid('a5000000-0000-4000-8000-000000000002');
  perform cftest.check('T-DB6 mark unpaid removes the expense and reopens the EMI',
    (select deleted_at from public.transactions where id = 'a8000000-0000-4000-8000-000000000002') is not null
      and (select status from public.emi_installments where id = 'a5000000-0000-4000-8000-000000000002') = 'due'
      and (select status from public.emis where id = 'a4000000-0000-4000-8000-000000000001') = 'active');

  perform public.pay_bill('a6000000-0000-4000-8000-000000000001', '2027-01-31',
    jsonb_build_object('id', 'a8000000-0000-4000-8000-000000000003', 'occurred_at', now(), 'payment_mode', 'cash', 'title', 'Torrent Power'),
    jsonb_build_object('id', 'a9000000-0000-4000-8000-000000000001', 'amount', 145000));
  select * into b from public.bills where id = 'a6000000-0000-4000-8000-000000000001';
  perform cftest.check('T-DB6 pay bill: 31 Jan + 1 month = 28 Feb', b.next_due_date = '2027-02-28', b.next_due_date::text);
  perform cftest.check('T-DB6 pay bill adds a ₹1,450 expense and a payment row',
    (select amount from public.transactions where id = 'a8000000-0000-4000-8000-000000000003') = 145000
      and (select transaction_id from public.bill_payments where id = 'a9000000-0000-4000-8000-000000000001') = 'a8000000-0000-4000-8000-000000000003');

  perform public.pay_bill('a6000000-0000-4000-8000-000000000001', '2027-01-31',
    jsonb_build_object('id', 'a8000000-0000-4000-8000-000000000003', 'occurred_at', now(), 'payment_mode', 'cash'),
    jsonb_build_object('id', 'a9000000-0000-4000-8000-000000000001', 'amount', 145000));
  perform cftest.check('T-DB6 bill retry adds nothing twice',
    (select count(*) from public.bill_payments where bill_id = 'a6000000-0000-4000-8000-000000000001') = 1
      and (select next_due_date from public.bills where id = 'a6000000-0000-4000-8000-000000000001') = '2027-02-28');

  begin
    perform public.pay_bill('a6000000-0000-4000-8000-000000000001', '2027-01-31',
      jsonb_build_object('id', gen_random_uuid(), 'occurred_at', now(), 'payment_mode', 'cash'),
      jsonb_build_object('id', gen_random_uuid(), 'amount', 145000));
    perform cftest.check('T-DB6 paying an old due date is rejected', false);
  exception when check_violation then
    perform cftest.check('T-DB6 paying an old due date is rejected', true);
  end;

  perform public.extend_due_date('a2000000-0000-4000-8000-000000000009',
    jsonb_build_object('id', 'aa000000-0000-4000-8000-000000000001', 'new_due_date', '2026-12-15'));
  perform cftest.check('T-DB6 Premium extends a due date with history',
    (select due_date from public.debts where id = 'a2000000-0000-4000-8000-000000000009') = '2026-12-15'
      and (select new_due_date from public.debt_extensions where id = 'aa000000-0000-4000-8000-000000000001') = '2026-12-15');
end;
$$;
reset role;

select line from unnest(string_to_array(trim(trailing E'\n' from current_setting('cftest.out')), E'\n')) as line;

rollback;
