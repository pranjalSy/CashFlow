-- Row Level Security, approved-device sessions and Premium write checks (NFR-3, TRD 10.2, 13.2).
-- The server decides; the app only mirrors. Nothing is exposed to `anon`.
-- Rows are never hard-deleted by the app (soft delete), so no DELETE is granted.

-- Nothing in `public` is open to signed-out callers.
revoke all on all tables in schema public from anon;
revoke all on all sequences in schema public from anon;

-- ---------- Helpers (in `private`, not reachable through the Data API) ----------

-- The caller's login session belongs to an approved device of this user (TRD 10.2).
-- `session_id` is a required claim in Supabase user tokens ([Verify] 17 Oct 2026).
create function private.is_approved_session() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.devices d
    where d.user_id = auth.uid()
      and d.session_id = (auth.jwt() ->> 'session_id')
      and d.status = 'approved'
      and d.deleted_at is null
  );
$$;

-- The caller has Premium now (TRD 13.2). A cancelled plan stays active until it ends.
create function private.has_active_plan() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.subscriptions s
    where s.user_id = auth.uid()
      and s.status in ('active', 'grace', 'cancelled')
      and s.expires_at > now()
      and s.deleted_at is null
  );
$$;

revoke all on function private.is_approved_session() from public;
revoke all on function private.has_active_plan() from public;
grant usage on schema private to authenticated;
grant execute on function private.is_approved_session() to authenticated;
grant execute on function private.has_active_plan() to authenticated;

-- ---------- User tables: own rows, approved device; Premium tables also need a plan to write ----------

do $$
declare
  t text;
  owner text := '(select auth.uid()) = user_id and (select private.is_approved_session())';
  plan text := ' and (select private.has_active_plan())';
  premium text[] := array['emis', 'emi_installments', 'bills', 'bill_payments', 'budgets',
    'budget_category_limits', 'debt_extensions'];
begin
  foreach t in array array['profiles', 'categories', 'people', 'transactions', 'debts', 'debt_payments',
    'debt_extensions', 'emis', 'emi_installments', 'bills', 'bill_payments', 'budgets', 'budget_category_limits']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('grant select, insert, update on public.%I to authenticated', t);
    -- Reads stay allowed after a plan ends (data becomes read-only, not hidden).
    execute format('create policy own_read on public.%I for select to authenticated using (%s)', t, owner);
    if t = any (premium) then
      execute format('create policy own_insert on public.%I for insert to authenticated with check (%s%s)', t, owner, plan);
      execute format('create policy own_update on public.%I for update to authenticated using (%s) with check (%s%s)', t, owner, owner, plan);
    else
      execute format('create policy own_insert on public.%I for insert to authenticated with check (%s)', t, owner);
      execute format('create policy own_update on public.%I for update to authenticated using (%s) with check (%s)', t, owner, owner);
    end if;
  end loop;
end;
$$;

-- ---------- Server tables ----------

alter table public.devices enable row level security;
alter table public.device_requests enable row level security;
alter table public.subscriptions enable row level security;
alter table public.app_settings enable row level security;
alter table public.notification_log enable row level security;

-- A phone may read its account's devices once approved (Devices screen, T18). Writes go through
-- server functions only.
grant select on public.devices to authenticated;
create policy own_read on public.devices for select to authenticated
  using ((select auth.uid()) = user_id and (select private.is_approved_session()));

-- The plan is mirrored to the phone (PlanCache). Written only by purchase verification (T20).
grant select on public.subscriptions to authenticated;
create policy own_read on public.subscriptions for select to authenticated
  using ((select auth.uid()) = user_id);

-- Global switches such as `ads_enabled` (TRD 13.3), read-only for signed-in users.
grant select on public.app_settings to authenticated;
create policy read_all on public.app_settings for select to authenticated using (true);

-- device_requests and notification_log: no policy and no grant, so only server functions see them.

-- ---------- Udhar due date and reminders are Premium (G3) ----------

create function private.guard_debt_premium_fields() returns trigger
language plpgsql set search_path = '' as $$
begin
  if (tg_op = 'INSERT' and (new.due_date is not null or new.reminder_days is not null))
     or (tg_op = 'UPDATE' and (new.due_date is distinct from old.due_date
                               or new.reminder_days is distinct from old.reminder_days)) then
    if not private.has_active_plan() then
      raise exception 'premium_required' using errcode = '42501';
    end if;
  end if;
  return new;
end;
$$;

create trigger guard_premium_fields before insert or update on public.debts
  for each row execute function private.guard_debt_premium_fields();

-- ---------- A repayment never exceeds what is left (G8) ----------

create function private.guard_repayment_cap() returns trigger
language plpgsql set search_path = '' as $$
declare
  total bigint;
  paid bigint;
begin
  if new.deleted_at is not null then
    return new;
  end if;
  -- Lock the udhar so two repayments at once cannot both pass the check.
  select d.amount into total from public.debts d where d.id = new.debt_id for update;
  if total is null then
    raise exception 'debt_not_found' using errcode = 'P0002';
  end if;
  select coalesce(sum(p.amount), 0) into paid
  from public.debt_payments p
  where p.debt_id = new.debt_id and p.deleted_at is null and p.id <> new.id;
  if new.amount > total - paid then
    raise exception 'repayment_exceeds_remaining' using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger guard_repayment_cap before insert or update on public.debt_payments
  for each row execute function private.guard_repayment_cap();
