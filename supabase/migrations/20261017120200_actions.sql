-- Atomic actions (TRD 6.3): each runs in one transaction, so a linked expense is never left alone.
-- They run as the caller (security invoker): RLS, the approved-device check, the Premium checks and
-- the repayment cap all still apply. Rows are passed as JSON made on the phone (same ids), and a
-- retry of the same upload is harmless (it returns without doing anything twice).

-- ---------- EMI: mark paid / unpaid (FR-E7, FR-E11) ----------

create function public.mark_installment_paid(p_installment_id uuid, p_txn jsonb) returns void
language plpgsql security invoker set search_path = '' as $$
declare
  inst public.emi_installments;
  r public.transactions;
begin
  select * into inst from public.emi_installments
  where id = p_installment_id and deleted_at is null for update;
  if not found then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  r := jsonb_populate_record(null::public.transactions, p_txn);
  if inst.status = 'paid' then
    if inst.transaction_id = r.id then
      return;
    end if;
    raise exception 'already_paid' using errcode = '23514';
  end if;
  if exists (select 1 from public.emi_installments e
             where e.emi_id = inst.emi_id and e.seq < inst.seq and e.status = 'due' and e.deleted_at is null) then
    raise exception 'not_next_due' using errcode = '23514';
  end if;

  insert into public.transactions (id, user_id, created_at, kind, amount, title, category_id, occurred_at,
    payment_mode, online_method, note, source, source_id)
  values (r.id, auth.uid(), coalesce(r.created_at, now()), 'expense', inst.amount, r.title, r.category_id,
    r.occurred_at, r.payment_mode, r.online_method, r.note, 'emi', inst.id);

  update public.emi_installments
  set status = 'paid', paid_at = r.occurred_at, transaction_id = r.id
  where id = inst.id;

  if not exists (select 1 from public.emi_installments e
                 where e.emi_id = inst.emi_id and e.status = 'due' and e.deleted_at is null) then
    update public.emis set status = 'closed' where id = inst.emi_id;
  end if;
end;
$$;

create function public.unmark_installment_paid(p_installment_id uuid) returns void
language plpgsql security invoker set search_path = '' as $$
declare
  inst public.emi_installments;
begin
  select * into inst from public.emi_installments
  where id = p_installment_id and deleted_at is null for update;
  if not found then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if inst.status <> 'paid' then
    return;
  end if;
  if inst.transaction_id is not null then
    update public.transactions set deleted_at = now() where id = inst.transaction_id and deleted_at is null;
  end if;
  update public.emi_installments set status = 'due', paid_at = null, transaction_id = null where id = inst.id;
  update public.emis set status = 'active' where id = inst.emi_id and status <> 'active';
end;
$$;

-- ---------- Bills: pay (FR-B4) ----------

create function public.pay_bill(p_bill_id uuid, p_due_date date, p_txn jsonb, p_payment jsonb) returns void
language plpgsql security invoker set search_path = '' as $$
declare
  b public.bills;
  r public.transactions;
  pay public.bill_payments;
begin
  select * into b from public.bills where id = p_bill_id and deleted_at is null for update;
  if not found then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  r := jsonb_populate_record(null::public.transactions, p_txn);
  pay := jsonb_populate_record(null::public.bill_payments, p_payment);
  if exists (select 1 from public.bill_payments where id = pay.id) then
    return;
  end if;
  if b.next_due_date <> p_due_date then
    raise exception 'due_date_moved' using errcode = '23514';
  end if;

  insert into public.transactions (id, user_id, created_at, kind, amount, title, category_id, occurred_at,
    payment_mode, online_method, note, source, source_id)
  values (r.id, auth.uid(), coalesce(r.created_at, now()), 'expense', pay.amount, r.title, r.category_id,
    r.occurred_at, r.payment_mode, r.online_method, r.note, 'bill', pay.id);

  insert into public.bill_payments (id, user_id, created_at, bill_id, due_date, amount, paid_at, transaction_id)
  values (pay.id, auth.uid(), coalesce(pay.created_at, now()), b.id, p_due_date, pay.amount, r.occurred_at, r.id);

  -- Same rule as the phone: 31 Jan + 1 month = 28 Feb (last day of a shorter month).
  update public.bills set next_due_date = (p_due_date + make_interval(months => b.every_months))::date
  where id = b.id;
end;
$$;

-- ---------- Udhar: repayment, extra as new udhar, extend due date (FR-D3, FR-D4, G7, G8, G10) ----------

-- Saves a repayment capped at what is left and returns {applied, extra, settled}.
create function public.record_repayment(p_payment jsonb) returns jsonb
language plpgsql security invoker set search_path = '' as $$
declare
  p public.debt_payments;
  d public.debts;
  paid bigint;
  left_amount bigint;
  applied bigint;
  extra bigint;
begin
  p := jsonb_populate_record(null::public.debt_payments, p_payment);
  select * into d from public.debts where id = p.debt_id and deleted_at is null for update;
  if not found then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if exists (select 1 from public.debt_payments where id = p.id) then
    select amount into applied from public.debt_payments where id = p.id;
    return jsonb_build_object('applied', applied, 'extra', coalesce(d.extra_not_added, 0), 'settled', d.status = 'settled');
  end if;

  select coalesce(sum(amount), 0) into paid from public.debt_payments where debt_id = d.id and deleted_at is null;
  left_amount := d.amount - paid;
  if left_amount <= 0 then
    return jsonb_build_object('applied', 0, 'extra', 0, 'settled', true);
  end if;
  applied := least(p.amount, left_amount);
  extra := p.amount - applied;

  insert into public.debt_payments (id, user_id, created_at, debt_id, amount, occurred_at, payment_mode, online_method, note)
  values (p.id, auth.uid(), coalesce(p.created_at, now()), d.id, applied, p.occurred_at, p.payment_mode, p.online_method, p.note);

  update public.debts
  set status = case when applied = left_amount then 'settled' else 'partial' end,
      extra_not_added = case when extra > 0 then extra end
  where id = d.id;

  return jsonb_build_object('applied', applied, 'extra', extra, 'settled', applied = left_amount);
end;
$$;

-- "Yes" on the extra: it becomes udhar in the other direction, linked to the first one (G7).
create function public.add_extra_as_debt(p_from_debt_id uuid, p_debt jsonb) returns void
language plpgsql security invoker set search_path = '' as $$
declare
  f public.debts;
  n public.debts;
begin
  n := jsonb_populate_record(null::public.debts, p_debt);
  select * into f from public.debts where id = p_from_debt_id and deleted_at is null for update;
  if not found then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if exists (select 1 from public.debts where id = n.id) then
    return;
  end if;
  if f.extra_not_added is null then
    raise exception 'no_extra' using errcode = '23514';
  end if;

  insert into public.debts (id, user_id, created_at, person_id, direction, amount, occurred_at, payment_mode,
    online_method, note, due_date, reminder_days, extra_from_debt_id)
  values (n.id, auth.uid(), coalesce(n.created_at, now()), f.person_id,
    case f.direction when 'lent' then 'borrowed' else 'lent' end, f.extra_not_added,
    coalesce(n.occurred_at, now()), f.payment_mode, f.online_method, n.note, n.due_date, n.reminder_days, f.id);

  update public.debts set extra_not_added = null where id = f.id;
end;
$$;

-- New due date with history (Premium: the RLS and the due-date guard check the plan).
create function public.extend_due_date(p_debt_id uuid, p_ext jsonb) returns void
language plpgsql security invoker set search_path = '' as $$
declare
  d public.debts;
  e public.debt_extensions;
begin
  e := jsonb_populate_record(null::public.debt_extensions, p_ext);
  select * into d from public.debts where id = p_debt_id and deleted_at is null for update;
  if not found then
    raise exception 'not_found' using errcode = 'P0002';
  end if;
  if exists (select 1 from public.debt_extensions where id = e.id) then
    return;
  end if;
  insert into public.debt_extensions (id, user_id, created_at, debt_id, old_due_date, new_due_date)
  values (e.id, auth.uid(), coalesce(e.created_at, now()), d.id, d.due_date, e.new_due_date);
  update public.debts set due_date = e.new_due_date where id = d.id;
end;
$$;

-- Only signed-in users may call these; RLS inside decides what they may touch.
do $$
declare f text;
begin
  foreach f in array array[
    'mark_installment_paid(uuid, jsonb)', 'unmark_installment_paid(uuid)', 'pay_bill(uuid, date, jsonb, jsonb)',
    'record_repayment(jsonb)', 'add_extra_as_debt(uuid, jsonb)', 'extend_due_date(uuid, jsonb)']
  loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end;
$$;
