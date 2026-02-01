-- ============================================
-- MBWD Supabase Database Schema
-- Erstelle diese Tabellen in deinem Supabase-Projekt
-- unter SQL Editor → New Query
-- ============================================

-- 1. BENUTZER (Users)
CREATE TABLE IF NOT EXISTS users (
    kuerzel TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    pin TEXT NOT NULL,
    funktionen TEXT[] DEFAULT '{}',
    role TEXT DEFAULT 'user',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. MELDUNGEN (Notifications)
CREATE TABLE IF NOT EXISTS meldungen (
    id TEXT PRIMARY KEY,
    titel TEXT NOT NULL,
    beschreibung TEXT,
    kategorie TEXT,
    prioritaet TEXT DEFAULT 'mittel',
    zustaendig TEXT DEFAULT 'alle',
    ersteller TEXT,
    ersteller_kuerzel TEXT,
    datum TIMESTAMPTZ DEFAULT now(),
    erledigt BOOLEAN DEFAULT false,
    rueckmeldung TEXT,
    rueckmeldung_von TEXT,
    rueckmeldung_zeit TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. CHECK-ARCHIVE (Ambulanz, MPG, Wochen, Reinigung)
CREATE TABLE IF NOT EXISTS check_archive (
    id TEXT PRIMARY KEY,
    doc_id TEXT NOT NULL,
    type TEXT NOT NULL, -- 'ambulanz', 'mpg', 'wochen', 'reinigung'
    meta JSONB NOT NULL,
    checkliste JSONB,
    reinigung JSONB,
    unterschrift TEXT,
    exported BOOLEAN DEFAULT false,
    exported_at TIMESTAMPTZ,
    exported_by TEXT,
    checksum TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Index für schnelle Typ-Abfragen
CREATE INDEX IF NOT EXISTS idx_check_archive_type ON check_archive(type);
CREATE INDEX IF NOT EXISTS idx_check_archive_created ON check_archive(created_at DESC);

-- 4. AUDIT LOG
CREATE TABLE IF NOT EXISTS audit_log (
    id TEXT PRIMARY KEY,
    timestamp TIMESTAMPTZ DEFAULT now(),
    user_kuerzel TEXT,
    user_name TEXT,
    action TEXT NOT NULL,
    details TEXT
);

CREATE INDEX IF NOT EXISTS idx_audit_log_timestamp ON audit_log(timestamp DESC);

-- 5. LÖSCH-PROTOKOLL (Delete Log)
CREATE TABLE IF NOT EXISTS delete_log (
    id TEXT PRIMARY KEY,
    timestamp TIMESTAMPTZ DEFAULT now(),
    deleted_by TEXT,
    deleted_by_name TEXT,
    document_id TEXT,
    document_type TEXT,
    document_meta JSONB
);

-- 6. EINSATZ-LOG (Deployment Statistics)
CREATE TABLE IF NOT EXISTS einsatz_log (
    id TEXT PRIMARY KEY,
    typ TEXT NOT NULL, -- 'rtw' oder 'ambulanz'
    datum TIMESTAMPTZ DEFAULT now(),
    notizen TEXT,
    erfasst_von TEXT,
    erfasst_von_name TEXT
);

CREATE INDEX IF NOT EXISTS idx_einsatz_log_datum ON einsatz_log(datum DESC);

-- 7. VERFALLSDATEN-TRACKER (Expiry Tracker)
CREATE TABLE IF NOT EXISTS expiry_tracker (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    date TEXT NOT NULL,
    added_by TEXT,
    added_at TIMESTAMPTZ DEFAULT now()
);

-- 8. DOC COUNTERS
CREATE TABLE IF NOT EXISTS doc_counters (
    key TEXT PRIMARY KEY, -- z.B. 'ambulanz_2025'
    counter INTEGER DEFAULT 0
);

-- 9. APP SETTINGS (Theme etc. pro User)
CREATE TABLE IF NOT EXISTS app_settings (
    user_kuerzel TEXT PRIMARY KEY,
    theme TEXT DEFAULT 'dark',
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- Alle Benutzer dürfen alles lesen/schreiben
-- (Abteilungs-App, kein feingranularer Zugriff nötig)
-- ============================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE meldungen ENABLE ROW LEVEL SECURITY;
ALTER TABLE check_archive ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE delete_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE einsatz_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE expiry_tracker ENABLE ROW LEVEL SECURITY;
ALTER TABLE doc_counters ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

-- Öffentlicher Zugriff für alle (anon key reicht)
CREATE POLICY "Allow all for anon" ON users FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for anon" ON meldungen FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for anon" ON check_archive FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for anon" ON audit_log FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for anon" ON delete_log FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for anon" ON einsatz_log FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for anon" ON expiry_tracker FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for anon" ON doc_counters FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Allow all for anon" ON app_settings FOR ALL USING (true) WITH CHECK (true);

-- ============================================
-- REALTIME aktivieren für Meldungen
-- (damit alle Geräte sofort neue Meldungen sehen)
-- ============================================
ALTER PUBLICATION supabase_realtime ADD TABLE meldungen;
ALTER PUBLICATION supabase_realtime ADD TABLE check_archive;
ALTER PUBLICATION supabase_realtime ADD TABLE einsatz_log;
ALTER PUBLICATION supabase_realtime ADD TABLE expiry_tracker;
ALTER PUBLICATION supabase_realtime ADD TABLE users;
