-- ============================================================
-- UNRAVEL BOARD — Supabase Schema
-- Run this in Supabase SQL Editor (https://app.supabase.com)
-- ============================================================

-- ENABLE UUID EXTENSION
create extension if not exists "pgcrypto";

-- ============================================================
-- TABLES
-- ============================================================

-- Projects (boards)
create table if not exists projects (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  slug        text unique not null,
  description text,
  owner_id    uuid references auth.users(id) on delete set null,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- Columns (lists inside a project)
create table if not exists columns (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid references projects(id) on delete cascade not null,
  title       text not null,
  color       text default '#4f6ef7',
  position    int default 0,
  created_at  timestamptz default now()
);

-- Cards (tasks)
create table if not exists cards (
  id          uuid primary key default gen_random_uuid(),
  column_id   uuid references columns(id) on delete cascade not null,
  project_id  uuid references projects(id) on delete cascade not null,
  title       text not null,
  description text,
  priority    text check (priority in ('low','med','high')) default 'low',
  labels      text[] default '{}',
  assignee    text,               -- user initials or user_id
  due_date    date,
  position    int default 0,
  is_archived boolean default false,
  created_by  uuid references auth.users(id) on delete set null,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- Activity log (audit trail)
create table if not exists activity (
  id          uuid primary key default gen_random_uuid(),
  card_id     uuid references cards(id) on delete cascade,
  project_id  uuid references projects(id) on delete cascade,
  user_id     uuid references auth.users(id) on delete set null,
  action      text not null,  -- e.g. 'created', 'moved', 'updated', 'archived'
  meta        jsonb,          -- { from_col, to_col, field_changed, ... }
  created_at  timestamptz default now()
);

-- Team members per project
create table if not exists project_members (
  id          uuid primary key default gen_random_uuid(),
  project_id  uuid references projects(id) on delete cascade not null,
  user_id     uuid references auth.users(id) on delete cascade not null,
  role        text check (role in ('admin','editor','viewer')) default 'editor',
  joined_at   timestamptz default now(),
  unique (project_id, user_id)
);

-- ============================================================
-- INDEXES (performance for 10+ users)
-- ============================================================
create index if not exists idx_cards_project    on cards(project_id);
create index if not exists idx_cards_column     on cards(column_id);
create index if not exists idx_cards_assignee   on cards(assignee);
create index if not exists idx_cards_due        on cards(due_date);
create index if not exists idx_activity_card    on activity(card_id);
create index if not exists idx_activity_project on activity(project_id);
create index if not exists idx_columns_project  on columns(project_id);

-- ============================================================
-- UPDATED_AT TRIGGER
-- ============================================================
create or replace function update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger trg_cards_updated
  before update on cards
  for each row execute function update_updated_at();

create trigger trg_projects_updated
  before update on projects
  for each row execute function update_updated_at();

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================
alter table projects         enable row level security;
alter table columns          enable row level security;
alter table cards            enable row level security;
alter table activity         enable row level security;
alter table project_members  enable row level security;

-- Projects: members can read; admins can write
create policy "project_member_read" on projects
  for select using (
    auth.uid() in (
      select user_id from project_members where project_id = projects.id
    )
  );

create policy "project_admin_write" on projects
  for all using (
    auth.uid() in (
      select user_id from project_members
      where project_id = projects.id and role = 'admin'
    )
  );

-- Cards: project members can read; editors/admins can write
create policy "card_member_read" on cards
  for select using (
    auth.uid() in (
      select user_id from project_members where project_id = cards.project_id
    )
  );

create policy "card_editor_write" on cards
  for all using (
    auth.uid() in (
      select user_id from project_members
      where project_id = cards.project_id and role in ('editor','admin')
    )
  );

-- Columns: same as cards
create policy "column_member_read" on columns
  for select using (
    auth.uid() in (
      select user_id from project_members where project_id = columns.project_id
    )
  );

create policy "column_editor_write" on columns
  for all using (
    auth.uid() in (
      select user_id from project_members
      where project_id = columns.project_id and role in ('editor','admin')
    )
  );

-- Activity: read only for members
create policy "activity_member_read" on activity
  for select using (
    auth.uid() in (
      select user_id from project_members where project_id = activity.project_id
    )
  );

-- ============================================================
-- SEED: Default project for Unravel Digital
-- (Run after first user signs up — replace USER_UUID)
-- ============================================================

/*
insert into projects (name, slug, description) values
  ('Campaign Q2',      'campaign-q2',      'Q2 paid & organic campaigns'),
  ('Asset Production', 'asset-production',  'Creative asset pipeline'),
  ('General Tasks',    'general-tasks',     'Cross-team to-dos');

-- Then add columns per project and invite team members.
*/
