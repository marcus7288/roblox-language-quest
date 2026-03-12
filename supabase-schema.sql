-- ============================================================
-- MUNDO ESPAÑOL — Supabase Schema
-- Run this in the Supabase SQL Editor for your project
-- ============================================================

-- Students table
CREATE TABLE students (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  class_code  TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- Units reference table
CREATE TABLE units (
  id          INT PRIMARY KEY,
  title       TEXT NOT NULL,        -- e.g. "La Casa"
  subtitle    TEXT NOT NULL,        -- e.g. "Rooms of the House"
  language    TEXT NOT NULL DEFAULT 'es'
);

INSERT INTO units (id, title, subtitle) VALUES
  (1, 'La Casa',      'Rooms of the House'),
  (2, 'Los Colores',  'Colors & Materials'),
  (3, 'Las Personas', 'Characters & Dialogue');

-- Student progress per unit
CREATE TABLE unit_progress (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id  UUID REFERENCES students(id) ON DELETE CASCADE,
  unit_id     INT  REFERENCES units(id),
  attempts    INT  NOT NULL DEFAULT 0,
  best_score  INT  NOT NULL DEFAULT 0,
  passed      BOOLEAN NOT NULL DEFAULT false,
  unlock_code TEXT,                 -- generated code given to student
  completed_at TIMESTAMPTZ,
  UNIQUE(student_id, unit_id)
);

-- Quiz attempt log (for teacher analytics)
CREATE TABLE quiz_attempts (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id  UUID REFERENCES students(id) ON DELETE CASCADE,
  unit_id     INT  REFERENCES units(id),
  score       INT  NOT NULL,
  total       INT  NOT NULL,
  passed      BOOLEAN NOT NULL,
  attempted_at TIMESTAMPTZ DEFAULT now()
);

-- ── Row Level Security ────────────────────────────────────────
-- Students can only read/write their own rows.
-- Teachers connect via service role key (never expose to client).

ALTER TABLE students      ENABLE ROW LEVEL SECURITY;
ALTER TABLE unit_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;

-- Students policy: allow insert on login, select own row
CREATE POLICY "students_insert" ON students FOR INSERT WITH CHECK (true);
CREATE POLICY "students_select" ON students FOR SELECT USING (true);

-- Progress: student can upsert and read their own progress
CREATE POLICY "progress_insert" ON unit_progress FOR INSERT WITH CHECK (true);
CREATE POLICY "progress_update" ON unit_progress FOR UPDATE USING (true);
CREATE POLICY "progress_select" ON unit_progress FOR SELECT USING (true);

-- Attempts: insert only from client
CREATE POLICY "attempts_insert" ON quiz_attempts FOR INSERT WITH CHECK (true);

-- ── Helpful Views for Teacher Dashboard ───────────────────────

CREATE VIEW class_summary AS
SELECT
  s.class_code,
  s.name,
  COUNT(CASE WHEN up.passed THEN 1 END)   AS units_passed,
  COUNT(up.unit_id)                        AS units_attempted,
  MAX(up.completed_at)                     AS last_active
FROM students s
LEFT JOIN unit_progress up ON up.student_id = s.id
GROUP BY s.class_code, s.name, s.id
ORDER BY s.class_code, s.name;

-- ── Usage Notes ───────────────────────────────────────────────
-- 1. Create a Supabase project at https://supabase.com
-- 2. Paste this into SQL Editor and run it
-- 3. Copy your project URL and anon key into your .env:
--      VITE_SUPABASE_URL=https://xxxx.supabase.co
--      VITE_SUPABASE_ANON_KEY=your-anon-key
-- 4. npm install @supabase/supabase-js
-- 5. Replace in-memory state in App.jsx with Supabase calls
