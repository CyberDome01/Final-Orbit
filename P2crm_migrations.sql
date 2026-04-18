-- ================================================================
-- CRM Deep Build — SQL Migrations
-- Run in Supabase SQL Editor
-- Project: finrdvvhmzmbnkixriwu
-- ================================================================

-- ── 1. EXTEND crm_leads ─────────────────────────────────────────
ALTER TABLE crm_leads
  ADD COLUMN IF NOT EXISTS last_contacted_at timestamptz,
  ADD COLUMN IF NOT EXISTS company_id        uuid REFERENCES crm_companies(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS converted_deal_id uuid;

-- ── 2. EXTEND crm_contacts ──────────────────────────────────────
ALTER TABLE crm_contacts
  ADD COLUMN IF NOT EXISTS company_id  uuid REFERENCES crm_companies(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS lead_id     uuid REFERENCES crm_leads(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS notes       text,
  ADD COLUMN IF NOT EXISTS updated_at  timestamptz NOT NULL DEFAULT now();

-- ── 3. EXTEND crm_companies ─────────────────────────────────────
ALTER TABLE crm_companies
  ADD COLUMN IF NOT EXISTS notes      text,
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

-- ── 4. NEW: crm_activities ──────────────────────────────────────
-- Tracks every call, email, meeting, note against a lead/contact/deal
CREATE TABLE IF NOT EXISTS crm_activities (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  type        text NOT NULL DEFAULT 'note',   -- call | email | meeting | note | task
  subject     text NOT NULL,
  notes       text,
  outcome     text,
  lead_id     uuid REFERENCES crm_leads(id)    ON DELETE CASCADE,
  deal_id     uuid REFERENCES crm_deals(id)    ON DELETE CASCADE,
  contact_id  uuid REFERENCES crm_contacts(id) ON DELETE CASCADE,
  logged_by   uuid REFERENCES user_profiles(id) ON DELETE SET NULL,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE crm_activities ENABLE ROW LEVEL SECURITY;
CREATE POLICY "activities_all" ON crm_activities
  FOR ALL
  USING  (org_id = public.get_user_org_id())
  WITH CHECK (org_id = public.get_user_org_id());

CREATE INDEX IF NOT EXISTS idx_activities_lead    ON crm_activities(lead_id);
CREATE INDEX IF NOT EXISTS idx_activities_deal    ON crm_activities(deal_id);
CREATE INDEX IF NOT EXISTS idx_activities_contact ON crm_activities(contact_id);
CREATE INDEX IF NOT EXISTS idx_activities_org     ON crm_activities(org_id);

-- ── 5. NEW: crm_proposals ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS crm_proposals (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  title       text NOT NULL,
  deal_id     uuid REFERENCES crm_deals(id)    ON DELETE SET NULL,
  contact_id  uuid REFERENCES crm_contacts(id) ON DELETE SET NULL,
  status      text NOT NULL DEFAULT 'draft',   -- draft | sent | accepted | rejected | expired
  total       numeric NOT NULL DEFAULT 0,
  valid_until date,
  notes       text,
  terms       text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE crm_proposals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "proposals_all" ON crm_proposals
  FOR ALL
  USING  (org_id = public.get_user_org_id())
  WITH CHECK (org_id = public.get_user_org_id());

CREATE INDEX IF NOT EXISTS idx_proposals_org  ON crm_proposals(org_id);
CREATE INDEX IF NOT EXISTS idx_proposals_deal ON crm_proposals(deal_id);

-- ── 6. NEW: crm_proposal_items ──────────────────────────────────
CREATE TABLE IF NOT EXISTS crm_proposal_items (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid NOT NULL REFERENCES organisations(id) ON DELETE CASCADE,
  proposal_id uuid NOT NULL REFERENCES crm_proposals(id) ON DELETE CASCADE,
  description text NOT NULL,
  quantity    numeric NOT NULL DEFAULT 1,
  unit_price  numeric NOT NULL DEFAULT 0,
  total       numeric GENERATED ALWAYS AS (quantity * unit_price) STORED,
  sort_order  int NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE crm_proposal_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "proposal_items_all" ON crm_proposal_items
  FOR ALL
  USING  (org_id = public.get_user_org_id())
  WITH CHECK (org_id = public.get_user_org_id());

CREATE INDEX IF NOT EXISTS idx_proposal_items_proposal ON crm_proposal_items(proposal_id);

-- ── 7. REALTIME on new tables ────────────────────────────────────
ALTER PUBLICATION supabase_realtime ADD TABLE crm_activities;
ALTER PUBLICATION supabase_realtime ADD TABLE crm_proposals;

-- ── 8. VERIFY — should list all CRM tables ───────────────────────
SELECT table_name
FROM   information_schema.tables
WHERE  table_schema = 'public'
  AND  table_name LIKE 'crm_%'
ORDER  BY table_name;
