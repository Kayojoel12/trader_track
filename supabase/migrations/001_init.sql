-- TRADE Track : schéma MVP (profils, comptes, trades, tags) + RLS.
create extension if not exists "pgcrypto";

create table profiles (
  id uuid primary key references auth.users on delete cascade,
  pseudo text, locale text default 'fr', theme text default 'dark',
  base_currency text default 'USD', trader_level text,
  risk_target_pct numeric(5,2), onboarding_done boolean default false,
  created_at timestamptz default now()
);

create table accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  name text not null,
  type text not null check (type in ('live','demo','prop','savings','personal')),
  broker text,
  platform text not null default 'manual' check (platform in ('mt5','binance','bybit','okx','manual')),
  currency text not null default 'USD',
  initial_balance numeric(18,2) default 0,
  sync_status text, last_sync_at timestamptz,
  archived boolean default false,
  created_at timestamptz default now()
);

create table trades (
  id uuid primary key,
  user_id uuid not null references auth.users on delete cascade,
  account_id uuid not null references accounts on delete cascade,
  strategy_id uuid,
  external_id text,
  source text not null default 'manual' check (source in ('manual','mt5_file','mt5_sync','csv','exchange')),
  symbol text not null,
  direction text not null check (direction in ('buy','sell')),
  volume numeric(18,4) not null,
  entry_price numeric(18,6) not null, exit_price numeric(18,6),
  sl numeric(18,6), tp numeric(18,6),
  opened_at timestamptz not null, closed_at timestamptz,
  gross_pnl numeric(18,2) default 0,
  commission numeric(18,2) default 0, swap numeric(18,2) default 0, fees numeric(18,2) default 0,
  risk_amount numeric(18,2),
  mae numeric(18,6), mfe numeric(18,6),
  confidence smallint check (confidence between 1 and 5),
  notes_md text,
  deleted_at timestamptz,
  updated_at timestamptz default now(),
  unique (account_id, external_id)  -- anti-doublons à l'import
);
create index trades_user_opened on trades (user_id, opened_at desc);

create table tags (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  name text not null,
  kind text not null check (kind in ('setup','session','timeframe','error','emotion','market'))
);
create table trade_tags (
  trade_id uuid references trades on delete cascade,
  tag_id uuid references tags on delete cascade,
  primary key (trade_id, tag_id)
);

-- Row Level Security : chaque utilisateur ne voit que ses données.
alter table profiles enable row level security;
alter table accounts enable row level security;
alter table trades enable row level security;
alter table tags enable row level security;
alter table trade_tags enable row level security;

create policy own_profile on profiles for all using (id = auth.uid()) with check (id = auth.uid());
create policy own_accounts on accounts for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_trades on trades for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_tags on tags for all using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy own_trade_tags on trade_tags for all
  using (exists (select 1 from trades t where t.id = trade_id and t.user_id = auth.uid()))
  with check (exists (select 1 from trades t where t.id = trade_id and t.user_id = auth.uid()));
