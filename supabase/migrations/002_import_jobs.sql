create table import_jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  account_id uuid not null references accounts on delete cascade,
  source text not null,
  file_path text not null,
  status text not null default 'processing' check (status in ('processing','done','failed')),
  rows_total int default 0, rows_imported int default 0, rows_duplicate int default 0,
  errors jsonb default '[]',
  created_at timestamptz default now()
);
alter table import_jobs enable row level security;
create policy own_import_jobs on import_jobs for select using (user_id = auth.uid());
