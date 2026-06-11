-- ================================================================
-- Life OS — Supabase Schema
-- Run in: Supabase Dashboard → SQL Editor
-- ================================================================

-- ── 1. Businesses ────────────────────────────────────────────────
create table if not exists businesses (
  id           text        primary key,           -- e.g. 'reck-it'
  name         text        not null,
  type         text,                              -- e.g. 'Vakantie Parken'
  emoji        text        default '🏢',
  color        text        default '#3B82F6',     -- hex for dashboard
  notion_url   text,
  dashboard_url text,
  active       boolean     default true,
  sort_order   int         default 0,
  created_at   timestamptz default now()
);

-- ── 2. Marketing metrics (from Meta + PipeDrive via n8n) ──────────
create table if not exists marketing_metrics (
  id              bigserial   primary key,
  business_id     text        references businesses(id),
  week_start      date        not null,          -- Monday of the week
  spend           numeric(10,2) default 0,
  clicks          integer     default 0,
  leads           integer     default 0,
  appointments    integer     default 0,
  sales           integer     default 0,
  -- Computed
  cpl             numeric(10,2) generated always as
                    (case when leads > 0 then spend / leads else null end) stored,
  cpa_appt        numeric(10,2) generated always as
                    (case when appointments > 0 then spend / appointments else null end) stored,
  cpa_sale        numeric(10,2) generated always as
                    (case when sales > 0 then spend / sales else null end) stored,
  created_at      timestamptz default now(),
  updated_at      timestamptz default now(),
  unique(business_id, week_start)
);

-- ── 3. Monthly finance snapshot ───────────────────────────────────
create table if not exists finance_monthly (
  id              bigserial   primary key,
  month           date        not null unique,   -- first day of month
  revenue         numeric(12,2) default 0,
  expenses        numeric(12,2) default 0,
  profit          numeric(12,2) generated always as (revenue - expenses) stored,
  net_worth       numeric(12,2),
  runway_months   int,
  notes           text,
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);

-- ── 4. Daily life check-ins (from Obsidian via n8n) ───────────────
create table if not exists life_checkins (
  id          bigserial   primary key,
  date        date        not null unique,
  energy      smallint    check (energy between 1 and 10),
  focus       smallint    check (focus between 1 and 10),
  mood        smallint    check (mood between 1 and 10),
  wins        text[]      default '{}',
  blockers    text[]      default '{}',
  notes       text,
  created_at  timestamptz default now()
);

-- ── 5. Weekly Claude briefings ────────────────────────────────────
create table if not exists weekly_briefings (
  id          bigserial   primary key,
  week_start  date        not null unique,
  content     text        not null,
  model       text        default 'claude-opus-4-8',
  created_at  timestamptz default now()
);

-- ── Indexes ────────────────────────────────────────────────────────
create index if not exists idx_marketing_biz_week on marketing_metrics(business_id, week_start);
create index if not exists idx_checkins_date      on life_checkins(date desc);
create index if not exists idx_briefings_week     on weekly_briefings(week_start desc);
create index if not exists idx_finance_month      on finance_monthly(month desc);

-- ── Dashboard view (used by the HTML dashboard directly) ──────────
-- Returns: latest briefing, current week marketing per business,
--          latest finance month, last 7 days life averages.
-- Called as: GET /rest/v1/v_dashboard_businesses (for business pipeline data)
-- and individual table queries for briefing/finance/life.

create or replace view v_dashboard_businesses as
select
  b.id,
  b.name,
  b.emoji,
  b.color,
  b.type,
  b.dashboard_url,
  b.sort_order,
  -- This week marketing
  m.spend,
  m.clicks,
  m.leads,
  m.appointments,
  m.sales,
  m.cpl,
  m.cpa_sale,
  m.week_start,
  -- Status: simple heuristic — override manually as needed
  case
    when m.leads > 40  then 'growing'
    when m.leads > 0   then 'stable'
    when m.leads = 0   then 'attention'
    else 'stable'
  end as status
from businesses b
left join marketing_metrics m
  on b.id = m.business_id
  and m.week_start = date_trunc('week', current_date)::date
where b.active = true
order by b.sort_order, b.name;

-- ── RLS (Row Level Security) ──────────────────────────────────────
-- Allow anon read access (safe — these are your personal business metrics,
-- not user data. The anon key is read-only by design.)
alter table businesses         enable row level security;
alter table marketing_metrics  enable row level security;
alter table finance_monthly    enable row level security;
alter table life_checkins      enable row level security;
alter table weekly_briefings   enable row level security;

-- Read-only for anon (the dashboard uses the anon key)
create policy "anon_read_businesses"        on businesses         for select using (true);
create policy "anon_read_marketing"         on marketing_metrics  for select using (true);
create policy "anon_read_finance"           on finance_monthly    for select using (true);
create policy "anon_read_checkins"          on life_checkins      for select using (true);
create policy "anon_read_briefings"         on weekly_briefings   for select using (true);

-- Service role (n8n) can write everything — no extra policy needed,
-- service role bypasses RLS by default.

-- ── Seed: businesses ─────────────────────────────────────────────
insert into businesses (id, name, type, emoji, color, sort_order, active) values
  ('reck-it',   'Reck-It',            'Vakantie Parken',   '🏕️', '#E3A04A', 1, true),
  ('bolshippers','Bolshippers',        'Logistics',         '🚢', '#3B82F6', 2, true),
  ('kr-makler', 'KR Makler',          'Vakantie Vastgoed', '🏡', '#10B981', 3, true),
  ('trading',   'Trading',            'Financial Markets', '📈', '#8B5CF6', 4, true),
  ('va',        'Virtual Assistance', 'Diensten',          '💻', '#06B6D4', 5, true)
on conflict (id) do update set
  name     = excluded.name,
  type     = excluded.type,
  emoji    = excluded.emoji,
  color    = excluded.color,
  sort_order = excluded.sort_order;

-- ── How data flows IN ──────────────────────────────────────────────
-- marketing_metrics: existing n8n Meta flow + PipeDrive flow
--   → add an extra step at the end of each flow:
--     POST https://PROJECT.supabase.co/rest/v1/marketing_metrics
--     with apikey header (service role key from n8n env)
--     body: { business_id, week_start, spend, clicks, leads, appointments, sales }
--     prefer: resolution=merge-duplicates (upsert)
--
-- finance_monthly: manual entry via Supabase Studio or a Notion → n8n flow
--
-- life_checkins: n8n webhook receives Obsidian note content,
--   parses energy/focus/mood/wins/blockers, inserts row
--
-- weekly_briefings: life-os-briefing-flow.json writes to Notion
--   → add a final step: POST /rest/v1/weekly_briefings (upsert by week_start)
