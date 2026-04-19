-- ================================================================
-- HRM Deep Build — SQL Migrations
-- Run in Supabase SQL Editor (new tab)
-- Project: finrdvvhmzmbnkixriwu
-- ================================================================

-- ── 1. EXTEND organisations (country/tax settings) ───────────────
ALTER TABLE organisations
  ADD COLUMN IF NOT EXISTS country        text NOT NULL DEFAULT 'UAE',
  ADD COLUMN IF NOT EXISTS currency       text NOT NULL DEFAULT 'AED',
  ADD COLUMN IF NOT EXISTS timezone       text NOT NULL DEFAULT 'Asia/Dubai',
  ADD COLUMN IF NOT EXISTS tax_region     text NOT NULL DEFAULT 'gulf',
  ADD COLUMN IF NOT EXISTS work_start_time time NOT NULL DEFAULT '09:00',
  ADD COLUMN IF NOT EXISTS fiscal_month   int  NOT NULL DEFAULT 1;

-- ── 2. EXTEND hrm_employees ─────────────────────────────────────
ALTER TABLE hrm_employees
  ADD COLUMN IF NOT EXISTS national_id        text,
  ADD COLUMN IF NOT EXISTS date_of_birth      date,
  ADD COLUMN IF NOT EXISTS gender             text,
  ADD COLUMN IF NOT EXISTS address            text,
  ADD COLUMN IF NOT EXISTS emergency_contact  text,
  ADD COLUMN IF NOT EXISTS emergency_phone    text,
  ADD COLUMN IF NOT EXISTS bank_account       text,
  ADD COLUMN IF NOT EXISTS tax_id             text,
  ADD COLUMN IF NOT EXISTS tax_country        text,
  ADD COLUMN IF NOT EXISTS probation_end_date date,
  ADD COLUMN IF NOT EXISTS contract_end_date  date,
  ADD COLUMN IF NOT EXISTS avatar_url         text;

-- ── 3. EXTEND hrm_leave_requests ────────────────────────────────
ALTER TABLE hrm_leave_requests
  ADD COLUMN IF NOT EXISTS rejection_reason text,
  ADD COLUMN IF NOT EXISTS approved_by      uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS business_days    int,
  ADD COLUMN IF NOT EXISTS updated_at       timestamptz NOT NULL DEFAULT now();

-- ── 4. NEW: hrm_leave_balances ──────────────────────────────────
-- Tracks annual entitlement and used days per employee per year
CREATE TABLE IF NOT EXISTS hrm_leave_balances (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id          uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  employee_id     uuid NOT NULL REFERENCES hrm_employees(id) ON DELETE CASCADE,
  leave_type      text NOT NULL DEFAULT 'annual',
  year            int  NOT NULL DEFAULT EXTRACT(YEAR FROM now())::int,
  entitlement     numeric NOT NULL DEFAULT 21,
  used            numeric NOT NULL DEFAULT 0,
  pending         numeric NOT NULL DEFAULT 0,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE(employee_id, leave_type, year)
);

ALTER TABLE hrm_leave_balances ENABLE ROW LEVEL SECURITY;
CREATE POLICY "leave_balances_all" ON hrm_leave_balances
  FOR ALL USING  (org_id = public.get_user_org_id())
  WITH CHECK (org_id = public.get_user_org_id());

-- ── 5. EXTEND hrm_attendance ────────────────────────────────────
ALTER TABLE hrm_attendance
  ADD COLUMN IF NOT EXISTS notes       text,
  ADD COLUMN IF NOT EXISTS updated_at  timestamptz NOT NULL DEFAULT now();

-- ── 6. NEW: hrm_payroll_runs ────────────────────────────────────
-- One row per monthly payroll run
CREATE TABLE IF NOT EXISTS hrm_payroll_runs (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id          uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  period_month    int  NOT NULL,   -- 1–12
  period_year     int  NOT NULL,
  status          text NOT NULL DEFAULT 'draft',  -- draft | processing | paid
  tax_region      text NOT NULL DEFAULT 'gulf',
  total_gross     numeric NOT NULL DEFAULT 0,
  total_tax       numeric NOT NULL DEFAULT 0,
  total_deductions numeric NOT NULL DEFAULT 0,
  total_net       numeric NOT NULL DEFAULT 0,
  employee_count  int  NOT NULL DEFAULT 0,
  notes           text,
  paid_at         timestamptz,
  created_by      uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  UNIQUE(org_id, period_month, period_year)
);

ALTER TABLE hrm_payroll_runs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "payroll_runs_all" ON hrm_payroll_runs
  FOR ALL USING  (org_id = public.get_user_org_id())
  WITH CHECK (org_id = public.get_user_org_id());

-- ── 7. NEW: hrm_payroll_items ────────────────────────────────────
-- One row per employee per payroll run
CREATE TABLE IF NOT EXISTS hrm_payroll_items (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id            uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  run_id            uuid NOT NULL REFERENCES hrm_payroll_runs(id) ON DELETE CASCADE,
  employee_id       uuid NOT NULL REFERENCES hrm_employees(id) ON DELETE CASCADE,
  -- Gross
  base_salary       numeric NOT NULL DEFAULT 0,
  allowances        numeric NOT NULL DEFAULT 0,
  overtime          numeric NOT NULL DEFAULT 0,
  gross             numeric NOT NULL DEFAULT 0,
  -- Tax (stored so we have an audit trail)
  tax_region        text    NOT NULL DEFAULT 'gulf',
  income_tax        numeric NOT NULL DEFAULT 0,
  social_security   numeric NOT NULL DEFAULT 0,
  medicare          numeric NOT NULL DEFAULT 0,
  national_insurance numeric NOT NULL DEFAULT 0,
  pension           numeric NOT NULL DEFAULT 0,
  provincial_tax    numeric NOT NULL DEFAULT 0,
  other_deductions  numeric NOT NULL DEFAULT 0,
  total_deductions  numeric NOT NULL DEFAULT 0,
  -- Net
  net               numeric NOT NULL DEFAULT 0,
  -- Meta
  currency          text NOT NULL DEFAULT 'AED',
  notes             text,
  created_at        timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE hrm_payroll_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "payroll_items_all" ON hrm_payroll_items
  FOR ALL USING  (org_id = public.get_user_org_id())
  WITH CHECK (org_id = public.get_user_org_id());

CREATE INDEX IF NOT EXISTS idx_payroll_items_run      ON hrm_payroll_items(run_id);
CREATE INDEX IF NOT EXISTS idx_payroll_items_employee ON hrm_payroll_items(employee_id);

-- ── 8. NEW: hrm_job_openings ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS hrm_job_openings (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id          uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  title           text NOT NULL,
  department      text,
  location        text,
  type            text NOT NULL DEFAULT 'full_time', -- full_time|part_time|contract|remote
  status          text NOT NULL DEFAULT 'open',      -- open|closed|draft|on_hold
  description     text,
  requirements    text,
  salary_min      numeric,
  salary_max      numeric,
  currency        text NOT NULL DEFAULT 'AED',
  posted_at       date DEFAULT CURRENT_DATE,
  closes_at       date,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE hrm_job_openings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "job_openings_all" ON hrm_job_openings
  FOR ALL USING  (org_id = public.get_user_org_id())
  WITH CHECK (org_id = public.get_user_org_id());

-- ── 9. NEW: hrm_applicants ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS hrm_applicants (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id          uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  job_id          uuid NOT NULL REFERENCES hrm_job_openings(id) ON DELETE CASCADE,
  name            text NOT NULL,
  email           text,
  phone           text,
  stage           text NOT NULL DEFAULT 'applied',
  -- applied | screening | interview | assessment | offer | hired | rejected
  rating          int  DEFAULT 0,  -- 1-5 stars
  source          text,            -- linkedin|referral|website|agency|other
  cv_url          text,
  cover_letter    text,
  interview_notes text,
  offer_amount    numeric,
  offer_currency  text DEFAULT 'AED',
  rejection_reason text,
  hired_as_employee_id uuid REFERENCES hrm_employees(id) ON DELETE SET NULL,
  applied_at      timestamptz NOT NULL DEFAULT now(),
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE hrm_applicants ENABLE ROW LEVEL SECURITY;
CREATE POLICY "applicants_all" ON hrm_applicants
  FOR ALL USING  (org_id = public.get_user_org_id())
  WITH CHECK (org_id = public.get_user_org_id());

CREATE INDEX IF NOT EXISTS idx_applicants_job ON hrm_applicants(job_id);
CREATE INDEX IF NOT EXISTS idx_applicants_org ON hrm_applicants(org_id);

-- ── 10. REALTIME ──────────────────────────────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE hrm_payroll_runs;
ALTER PUBLICATION supabase_realtime ADD TABLE hrm_applicants;

-- ── 11. INDEXES ───────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_leave_balances_emp  ON hrm_leave_balances(employee_id);
CREATE INDEX IF NOT EXISTS idx_payroll_runs_org    ON hrm_payroll_runs(org_id);
CREATE INDEX IF NOT EXISTS idx_job_openings_org    ON hrm_job_openings(org_id);

-- ── 12. VERIFY ────────────────────────────────────────────────────
SELECT table_name
FROM   information_schema.tables
WHERE  table_schema = 'public'
  AND  table_name LIKE 'hrm_%'
ORDER  BY table_name;
