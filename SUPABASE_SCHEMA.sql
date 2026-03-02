-- ============================================
-- HealthHome v2 — Schema Supabase PostgreSQL
-- Execute no SQL Editor do Supabase
-- ============================================

-- Habilitar extensão UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Marcadores de saúde
CREATE TABLE IF NOT EXISTS health_markers (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id      TEXT NOT NULL,
  marker_key   TEXT NOT NULL,
  value        NUMERIC NOT NULL,
  recorded_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Eventos da linha do tempo
CREATE TABLE IF NOT EXISTS timeline_events (
  id       BIGINT PRIMARY KEY,
  user_id  TEXT NOT NULL,
  type     TEXT NOT NULL CHECK (type IN ('exam','consultation','prescription','alert','wearable')),
  title    TEXT NOT NULL,
  date     DATE NOT NULL,
  desc     TEXT,
  tags     TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Pacientes (acesso médico)
CREATE TABLE IF NOT EXISTS patients (
  id          BIGINT PRIMARY KEY,
  doctor_id   TEXT NOT NULL,
  name        TEXT NOT NULL,
  dob         DATE,
  sex         CHAR(1),
  conditions  TEXT,
  emergency   TEXT,
  notes       TEXT,
  avatar      TEXT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Documentos (metadados — arquivo no Storage)
CREATE TABLE IF NOT EXISTS documents (
  id           TEXT PRIMARY KEY,
  user_id      TEXT NOT NULL,
  name         TEXT NOT NULL,
  category     TEXT,
  storage_path TEXT,
  file_size    TEXT,
  file_type    TEXT,
  uploaded_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================
ALTER TABLE health_markers ENABLE ROW LEVEL SECURITY;
ALTER TABLE timeline_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Políticas: usuário acessa apenas seus dados
CREATE POLICY "user_own_markers" ON health_markers FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY "user_own_events"  ON timeline_events FOR ALL USING (user_id = auth.uid()::text);
CREATE POLICY "doctor_own_patients" ON patients FOR ALL USING (doctor_id = auth.uid()::text);
CREATE POLICY "user_own_docs"   ON documents FOR ALL USING (user_id = auth.uid()::text);

-- ============================================
-- STORAGE BUCKET
-- ============================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'healthhome-records',
  'healthhome-records',
  false,
  52428800,  -- 50MB
  ARRAY['application/pdf','image/jpeg','image/png','image/webp']
) ON CONFLICT (id) DO NOTHING;

-- Storage RLS
CREATE POLICY "user_own_files" ON storage.objects FOR ALL
USING (bucket_id = 'healthhome-records' AND (storage.foldername(name))[1] = auth.uid()::text);

-- ============================================
-- ÍNDICES PARA PERFORMANCE
-- ============================================
CREATE INDEX IF NOT EXISTS idx_markers_user ON health_markers (user_id, marker_key, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_events_user  ON timeline_events (user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_patients_doc ON patients (doctor_id);
CREATE INDEX IF NOT EXISTS idx_docs_user    ON documents (user_id);
