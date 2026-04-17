-- ================================================================
-- Final Orbit — Phase 1 Schema
-- Run this ONCE in your Supabase SQL Editor
-- Project: finrdvvhmzmbnkixriwu
-- ================================================================

-- ── 1. ORGANISATIONS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS organisations (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL,
  slug        text UNIQUE,
  plan        text NOT NULL DEFAULT 'professional',
  logo_url    text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

-- ── 2. USER PROFILES ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_profiles (
  id          uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  org_id      uuid REFERENCES organisations(id) ON DELETE CASCADE,
  full_name   text,
  job_title   text,
  department  text,
  phone       text,
  avatar_url  text,
  role        text NOT NULL DEFAULT 'member',  -- owner | admin | member
  plan        text NOT NULL DEFAULT 'professional',
  trial_ends_at timestamptz DEFAULT (now() + interval '7 days'),
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

-- ── 3. CRM ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS crm_leads (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  name        text NOT NULL,
  company     text,
  email       text,
  phone       text,
  status      text NOT NULL DEFAULT 'new',
  source      text,
  score       int DEFAULT 0,
  value       numeric DEFAULT 0,
  notes       text,
  assigned_to uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS crm_deals (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  name        text NOT NULL,
  company     text,
  value       numeric DEFAULT 0,
  probability int DEFAULT 0,
  stage       text NOT NULL DEFAULT 'prospecting',
  close_date  date,
  notes       text,
  lead_id     uuid REFERENCES crm_leads(id) ON DELETE SET NULL,
  assigned_to uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS crm_contacts (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  name        text NOT NULL,
  job_title   text,
  company     text,
  email       text,
  phone       text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS crm_companies (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  name        text NOT NULL,
  industry    text,
  website     text,
  phone       text,
  size        text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- ── 4. HRM ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS hrm_employees (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id          uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  name            text NOT NULL,
  job_title       text,
  email           text,
  phone           text,
  department      text,
  employment_type text NOT NULL DEFAULT 'full_time',
  status          text NOT NULL DEFAULT 'active',
  hire_date       date,
  salary          numeric,
  currency        text DEFAULT 'USD',
  manager_id      uuid REFERENCES hrm_employees(id) ON DELETE SET NULL,
  notes           text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS hrm_leave_requests (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  employee_id uuid NOT NULL REFERENCES hrm_employees(id) ON DELETE CASCADE,
  type        text NOT NULL DEFAULT 'annual',
  status      text NOT NULL DEFAULT 'pending',
  start_date  date NOT NULL,
  end_date    date NOT NULL,
  reason      text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS hrm_attendance (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  employee_id uuid NOT NULL REFERENCES hrm_employees(id) ON DELETE CASCADE,
  date        date NOT NULL,
  status      text NOT NULL DEFAULT 'present',
  check_in    time,
  check_out   time,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- ── 5. PMS ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS projects (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  name        text NOT NULL,
  description text,
  status      text NOT NULL DEFAULT 'planning',
  priority    text NOT NULL DEFAULT 'medium',
  budget      numeric DEFAULT 0,
  completion  int DEFAULT 0,
  start_date  date,
  end_date    date,
  owner_id    uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS project_tasks (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  project_id  uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  name        text NOT NULL,
  description text,
  status      text NOT NULL DEFAULT 'todo',
  priority    text NOT NULL DEFAULT 'medium',
  due_date    date,
  assigned_to uuid REFERENCES hrm_employees(id) ON DELETE SET NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS project_milestones (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  project_id  uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  name        text NOT NULL,
  due_date    date,
  status      text NOT NULL DEFAULT 'pending',
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- ── 6. FMS ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fms_expenses (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  category    text NOT NULL,
  amount      numeric NOT NULL DEFAULT 0,
  description text,
  status      text NOT NULL DEFAULT 'pending',
  date        date DEFAULT CURRENT_DATE,
  project_id  uuid REFERENCES projects(id) ON DELETE SET NULL,
  employee_id uuid REFERENCES hrm_employees(id) ON DELETE SET NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS invoices (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id         uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  invoice_number text NOT NULL,
  status         text NOT NULL DEFAULT 'draft',
  amount         numeric DEFAULT 0,
  due_date       date,
  notes          text,
  project_id     uuid REFERENCES projects(id) ON DELETE SET NULL,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS purchase_orders (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  po_number   text NOT NULL,
  vendor      text,
  amount      numeric DEFAULT 0,
  status      text NOT NULL DEFAULT 'draft',
  order_date  date DEFAULT CURRENT_DATE,
  notes       text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- ── 7. FAS ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fas_requests (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  title       text NOT NULL,
  type        text NOT NULL DEFAULT 'other',
  priority    text NOT NULL DEFAULT 'normal',
  status      text NOT NULL DEFAULT 'submitted',
  description text,
  requested_by uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS fas_assets (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id       uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  name         text NOT NULL,
  category     text,
  status       text NOT NULL DEFAULT 'available',
  assigned_to  uuid REFERENCES hrm_employees(id) ON DELETE SET NULL,
  purchase_date date,
  value        numeric DEFAULT 0,
  created_at   timestamptz NOT NULL DEFAULT now()
);

-- ── 8. AI AGENTS ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ai_agents (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  name        text NOT NULL,
  description text,
  type        text NOT NULL DEFAULT 'analysis',
  status      text NOT NULL DEFAULT 'active',
  schedule    text,
  last_run_at timestamptz,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS ai_agent_logs (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  agent_id    uuid NOT NULL REFERENCES ai_agents(id) ON DELETE CASCADE,
  status      text NOT NULL DEFAULT 'running',
  output      text,
  error       text,
  started_at  timestamptz NOT NULL DEFAULT now(),
  finished_at timestamptz
);

-- ── 9. NOTIFICATIONS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  user_id     uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  title       text NOT NULL,
  body        text,
  type        text DEFAULT 'info',
  read        boolean DEFAULT false,
  created_at  timestamptz NOT NULL DEFAULT now()
);

-- ════════════════════════════════════════════════════════════════
-- ENABLE RLS
-- ════════════════════════════════════════════════════════════════
ALTER TABLE organisations        ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles        ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_leads            ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_deals            ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_contacts         ENABLE ROW LEVEL SECURITY;
ALTER TABLE crm_companies        ENABLE ROW LEVEL SECURITY;
ALTER TABLE hrm_employees        ENABLE ROW LEVEL SECURITY;
ALTER TABLE hrm_leave_requests   ENABLE ROW LEVEL SECURITY;
ALTER TABLE hrm_attendance       ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects             ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_tasks        ENABLE ROW LEVEL SECURITY;
ALTER TABLE project_milestones   ENABLE ROW LEVEL SECURITY;
ALTER TABLE fms_expenses         ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices             ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_orders      ENABLE ROW LEVEL SECURITY;
ALTER TABLE fas_requests         ENABLE ROW LEVEL SECURITY;
ALTER TABLE fas_assets           ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_agents            ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_agent_logs        ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications        ENABLE ROW LEVEL SECURITY;

-- ════════════════════════════════════════════════════════════════
-- HELPER FUNCTION (the one that must never return NULL)
-- ════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.get_user_org_id()
RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER
AS $$
  SELECT org_id FROM public.user_profiles WHERE id = auth.uid()
$$;

-- ════════════════════════════════════════════════════════════════
-- RLS POLICIES
-- ════════════════════════════════════════════════════════════════

-- user_profiles: own row only
CREATE POLICY "profiles_select" ON user_profiles FOR SELECT USING (id = auth.uid());
CREATE POLICY "profiles_update" ON user_profiles FOR UPDATE USING (id = auth.uid());
CREATE POLICY "profiles_insert" ON user_profiles FOR INSERT WITH CHECK (id = auth.uid());

-- organisations: own org only
CREATE POLICY "orgs_select" ON organisations FOR SELECT USING (id = public.get_user_org_id());
CREATE POLICY "orgs_update" ON organisations FOR UPDATE USING (id = public.get_user_org_id());

-- all other tables: same pattern, org_id = user's org
DO $$ 
DECLARE
  tbl text;
BEGIN
  FOR tbl IN SELECT unnest(ARRAY[
    'crm_leads','crm_deals','crm_contacts','crm_companies',
    'hrm_employees','hrm_leave_requests','hrm_attendance',
    'projects','project_tasks','project_milestones',
    'fms_expenses','invoices','purchase_orders',
    'fas_requests','fas_assets',
    'ai_agents','ai_agent_logs','notifications'
  ]) LOOP
    EXECUTE format('
      CREATE POLICY "%s_all" ON %s
      FOR ALL
      USING (org_id = public.get_user_org_id())
      WITH CHECK (org_id = public.get_user_org_id());
    ', tbl, tbl);
  END LOOP;
END $$;

-- ════════════════════════════════════════════════════════════════
-- AUTO-PROFILE TRIGGER (critical: runs on every new signup)
-- Creates org + links profile automatically so org_id is NEVER null
-- ════════════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_org_id  uuid;
  v_name    text;
BEGIN
  -- Use display name from metadata, fallback to email prefix
  v_name := COALESCE(
    NEW.raw_user_meta_data->>'full_name',
    split_part(NEW.email, '@', 1)
  );

  -- Create org named after user
  INSERT INTO organisations (name)
  VALUES (v_name || '''s Workspace')
  RETURNING id INTO v_org_id;

  -- Create profile linked to org
  INSERT INTO user_profiles (id, org_id, full_name, role, plan)
  VALUES (NEW.id, v_org_id, v_name, 'owner', 'professional');

  RETURN NEW;
END;
$$;

-- Attach trigger to auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ════════════════════════════════════════════════════════════════
-- REALTIME
-- ════════════════════════════════════════════════════════════════
ALTER PUBLICATION supabase_realtime ADD TABLE crm_leads;
ALTER PUBLICATION supabase_realtime ADD TABLE hrm_employees;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE ai_agent_logs;

-- ════════════════════════════════════════════════════════════════
-- INDEXES (performance)
-- ════════════════════════════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_profiles_org    ON user_profiles(org_id);
CREATE INDEX IF NOT EXISTS idx_leads_org       ON crm_leads(org_id);
CREATE INDEX IF NOT EXISTS idx_leads_status    ON crm_leads(status);
CREATE INDEX IF NOT EXISTS idx_deals_org       ON crm_deals(org_id);
CREATE INDEX IF NOT EXISTS idx_employees_org   ON hrm_employees(org_id);
CREATE INDEX IF NOT EXISTS idx_projects_org    ON projects(org_id);
CREATE INDEX IF NOT EXISTS idx_tasks_project   ON project_tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_invoices_org    ON invoices(org_id);
CREATE INDEX IF NOT EXISTS idx_expenses_org    ON fms_expenses(org_id);
CREATE INDEX IF NOT EXISTS idx_fas_org         ON fas_requests(org_id);
CREATE INDEX IF NOT EXISTS idx_agents_org      ON ai_agents(org_id);
CREATE INDEX IF NOT EXISTS idx_logs_agent      ON ai_agent_logs(agent_id);
CREATE INDEX IF NOT EXISTS idx_notifs_user     ON notifications(user_id);

-- ════════════════════════════════════════════════════════════════
-- VERIFY (run this at the end to confirm everything worked)
-- ════════════════════════════════════════════════════════════════
SELECT 
  table_name,
  (SELECT COUNT(*) FROM information_schema.columns c 
   WHERE c.table_name = t.table_name AND c.table_schema = 'public') AS col_count
FROM information_schema.tables t
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;
