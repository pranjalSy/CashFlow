-- CashFlow cloud schema (TRD 5, 6.1, 6.2). Same tables and columns as the phone (Drift).
-- Money: bigint paise. Rates: basis points. Due dates: date. Instants: timestamptz (UTC).
-- Every synced table: id (made on the phone), user_id, created_at, updated_at (server-set), deleted_at.
-- Soft delete only. Parent links are deferrable so one upload batch may arrive in any order.

create schema if not exists private;

-- ---------- Synced user tables ----------

create table public.profiles (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  name text,
  language text not null default 'en' check (language in ('en', 'hi', 'gu')),
  opening_cash bigint not null default 0,
  opening_online bigint not null default 0,
  default_reminder_days int not null default 3 check (default_reminder_days in (0, 3, 7)),
  hide_amounts boolean not null default false,
  analytics_opt_in boolean not null default true,
  onboarding_done boolean not null default false
);
create unique index profiles_one_per_user on public.profiles (user_id) where deleted_at is null;

create table public.categories (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  kind text not null check (kind in ('income', 'expense')),
  name text not null check (length(name) between 1 and 60),
  name_key text,
  icon text not null,
  color bigint not null,
  is_default boolean not null default false,
  last_used_at timestamptz,
  sort_order int not null default 0
);

create table public.people (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  name text not null check (length(name) between 1 and 100),
  phone_normalized text check (phone_normalized ~ '^\+[0-9]{0,15}$'),
  -- Phone contact id: a cache on one phone only; kept so a restore does not lose the link.
  contact_cache_id text
);

create table public.transactions (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  kind text not null check (kind in ('income', 'expense')),
  amount bigint not null check (amount > 0),
  title text,
  category_id uuid references public.categories (id) deferrable initially deferred,
  occurred_at timestamptz not null,
  payment_mode text not null check (payment_mode in ('cash', 'online')),
  online_method text check (online_method in ('upi', 'card', 'bank')),
  note text,
  source text not null default 'manual' check (source in ('manual', 'emi', 'bill')),
  source_id uuid,
  constraint transactions_method_matches check ((payment_mode = 'cash') = (online_method is null))
);

create table public.debts (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  person_id uuid not null references public.people (id) deferrable initially deferred,
  direction text not null check (direction in ('lent', 'borrowed')),
  amount bigint not null check (amount > 0),
  occurred_at timestamptz not null,
  payment_mode text not null check (payment_mode in ('cash', 'online')),
  online_method text check (online_method in ('upi', 'card', 'bank')),
  note text,
  due_date date,
  -- Comma list of lead days, for example '0,3' (same as the phone).
  reminder_days text check (reminder_days ~ '^[0-9]+(,[0-9]+)*$'),
  status text not null default 'open' check (status in ('open', 'partial', 'settled')),
  extra_from_debt_id uuid references public.debts (id) deferrable initially deferred,
  extra_not_added bigint check (extra_not_added > 0),
  constraint debts_method_matches check ((payment_mode = 'cash') = (online_method is null))
);

create table public.debt_payments (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  debt_id uuid not null references public.debts (id) deferrable initially deferred,
  amount bigint not null check (amount > 0),
  occurred_at timestamptz not null,
  payment_mode text not null check (payment_mode in ('cash', 'online')),
  online_method text check (online_method in ('upi', 'card', 'bank')),
  note text,
  constraint debt_payments_method_matches check ((payment_mode = 'cash') = (online_method is null))
);

create table public.debt_extensions (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  debt_id uuid not null references public.debts (id) deferrable initially deferred,
  old_due_date date,
  new_due_date date not null
);

create table public.emis (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  name text not null check (length(name) between 1 and 60),
  icon text not null default 'bike',
  lender text,
  item_price bigint check (item_price >= 0),
  down_payment bigint check (down_payment >= 0),
  loan_amount bigint not null check (loan_amount > 0),
  rate_bp int not null check (rate_bp between 0 and 10000),
  months int not null check (months between 1 and 600),
  emi_amount bigint not null check (emi_amount > 0),
  first_due_date date not null,
  status text not null default 'active' check (status in ('active', 'closed'))
);

create table public.emi_installments (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  emi_id uuid not null references public.emis (id) deferrable initially deferred,
  seq int not null check (seq >= 1),
  due_date date not null,
  amount bigint not null check (amount > 0),
  interest_part bigint not null check (interest_part >= 0),
  principal_part bigint not null check (principal_part >= 0),
  status text not null default 'due' check (status in ('due', 'paid')),
  paid_at timestamptz,
  transaction_id uuid references public.transactions (id) deferrable initially deferred,
  constraint installments_paid_has_time check ((status = 'paid') = (paid_at is not null))
);

create table public.bills (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  bill_type text not null check (bill_type in ('electricity', 'gas', 'mobile', 'internet', 'dth', 'water', 'insurance', 'other')),
  name text not null check (length(name) between 1 and 60),
  -- For the user's own reference only; never sent to any provider (I3).
  customer_id text,
  every_months int not null check (every_months in (1, 2, 3, 6, 12)),
  next_due_date date not null,
  usual_amount bigint check (usual_amount >= 0),
  reminder_days text check (reminder_days ~ '^[0-9]+(,[0-9]+)*$'),
  paused boolean not null default false
);

create table public.bill_payments (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  bill_id uuid not null references public.bills (id) deferrable initially deferred,
  due_date date not null,
  amount bigint not null check (amount > 0),
  paid_at timestamptz not null,
  transaction_id uuid references public.transactions (id) deferrable initially deferred
);

create table public.budgets (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  monthly_limit bigint not null check (monthly_limit > 0),
  alert_enabled boolean not null default true
);
create unique index budgets_one_per_user on public.budgets (user_id) where deleted_at is null;

create table public.budget_category_limits (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  category_id uuid not null references public.categories (id) deferrable initially deferred,
  limit_amount bigint not null check (limit_amount > 0),
  alert_enabled boolean not null default true
);

-- ---------- Server tables (written only by server functions) ----------

create table public.devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  name text not null,
  os_version text,
  fcm_token text,
  status text not null default 'pending' check (status in ('pending', 'approved', 'removed', 'blocked')),
  -- The `session_id` claim of the device's login token (TRD 10.2).
  session_id text,
  approved_at timestamptz,
  last_seen timestamptz
);

create table public.device_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  device_id uuid not null references public.devices (id) on delete cascade,
  purpose text not null check (purpose in ('approve_login', 'remove_device')),
  target_device_id uuid references public.devices (id) on delete cascade,
  -- Only the hash of an email code is stored (NFR, TRD 10.1).
  code_hash text,
  code_expires_at timestamptz,
  attempts int not null default 0 check (attempts between 0 and 5),
  expires_at timestamptz not null,
  method text check (method in ('device', 'email')),
  result text check (result in ('approved', 'blocked', 'expired', 'removed'))
);

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  product_id text not null,
  base_plan text not null check (base_plan in ('monthly', 'yearly')),
  status text not null check (status in ('active', 'grace', 'cancelled', 'on_hold', 'expired')),
  intro_used boolean not null default false,
  expires_at timestamptz not null,
  purchase_token text not null unique
);

create table public.app_settings (
  key text primary key,
  value text not null,
  updated_at timestamptz not null default now()
);

create table public.notification_log (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  item_kind text not null check (item_kind in ('debt', 'emi', 'bill', 'plan')),
  item_id uuid not null,
  due_date date not null,
  lead_days int not null,
  sent_at timestamptz not null default now(),
  unique (user_id, item_kind, item_id, due_date, lead_days)
);

-- ---------- Indexes (TRD 6.2) ----------

create index profiles_sync on public.profiles (user_id, updated_at, id);
create index categories_sync on public.categories (user_id, updated_at, id);
create index people_sync on public.people (user_id, updated_at, id);
create index transactions_sync on public.transactions (user_id, updated_at, id);
create index debts_sync on public.debts (user_id, updated_at, id);
create index debt_payments_sync on public.debt_payments (user_id, updated_at, id);
create index debt_extensions_sync on public.debt_extensions (user_id, updated_at, id);
create index emis_sync on public.emis (user_id, updated_at, id);
create index emi_installments_sync on public.emi_installments (user_id, updated_at, id);
create index bills_sync on public.bills (user_id, updated_at, id);
create index bill_payments_sync on public.bill_payments (user_id, updated_at, id);
create index budgets_sync on public.budgets (user_id, updated_at, id);
create index budget_category_limits_sync on public.budget_category_limits (user_id, updated_at, id);

create index transactions_time on public.transactions (user_id, occurred_at);
create index debts_time on public.debts (user_id, occurred_at);
create index debts_due on public.debts (user_id, due_date);
create index emi_installments_due on public.emi_installments (user_id, due_date);
create index bills_due on public.bills (user_id, next_due_date);
create index devices_status on public.devices (user_id, status);
create index devices_session on public.devices (session_id);
create index debt_payments_debt on public.debt_payments (debt_id);
create index emi_installments_emi on public.emi_installments (emi_id, seq);
create index bill_payments_bill on public.bill_payments (bill_id, due_date);

-- ---------- updated_at is always the server's clock (TRD 8, FR-S6) ----------

create function private.set_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

do $$
declare t text;
begin
  foreach t in array array['profiles', 'categories', 'people', 'transactions', 'debts', 'debt_payments',
    'debt_extensions', 'emis', 'emi_installments', 'bills', 'bill_payments', 'budgets',
    'budget_category_limits', 'devices', 'device_requests', 'subscriptions', 'app_settings']
  loop
    execute format('create trigger set_updated_at before insert or update on public.%I
      for each row execute function private.set_updated_at()', t);
  end loop;
end;
$$;
