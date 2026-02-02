-- From CHATGPT
-- ===========================================
-- 🔧  SQLite Optimization for Dictionary DBs
--  (Safe for read-only, retrieval-only usage)
-- ===========================================

PRAGMA journal_mode = OFF;
PRAGMA synchronous = OFF;
PRAGMA temp_store = MEMORY;
PRAGMA cache_size = -2000;  -- ~20MB page cache in RAM
-- PRAGMA mmap_size = 3000000000; -- allow OS memory-mapped I/O (~3GB max)
PRAGMA mmap_size = 500000; -- 500mb
PRAGMA locking_mode = EXCLUSIVE;

-- ---------------------------
-- 🧩  Indexes for fast lookup
-- ---------------------------

-- mujamul_ghoni
CREATE INDEX IF NOT EXISTS idx_mujamul_ghoni_root       ON mujamul_ghoni(root);
CREATE INDEX IF NOT EXISTS idx_mujamul_ghoni_word       ON mujamul_ghoni(word);
CREATE INDEX IF NOT EXISTS idx_mujamul_ghoni_no_harakat ON mujamul_ghoni(no_harakat);

-- mujamul_muashiroh
CREATE INDEX IF NOT EXISTS idx_mujamul_muashiroh_word   ON mujamul_muashiroh(word);

-- mujamul_wasith
CREATE INDEX IF NOT EXISTS idx_mujamul_wasith_word      ON mujamul_wasith(word);

-- mujamul_muhith
CREATE INDEX IF NOT EXISTS idx_mujamul_muhith_word      ON mujamul_muhith(word);

-- mujamul_shihah
CREATE INDEX IF NOT EXISTS idx_mujamul_shihah_word      ON mujamul_shihah(word);

-- lisanularab
CREATE INDEX IF NOT EXISTS idx_lisanularab_word         ON lisanularab(word);

-- hanswehr
CREATE INDEX IF NOT EXISTS idx_hanswehr_isroot_word     ON hanswehr(is_root, word);
CREATE INDEX IF NOT EXISTS idx_hanswehr_word            ON hanswehr(word);

-- lanelexcon
CREATE INDEX IF NOT EXISTS idx_lanelexcon_isroot_word   ON lanelexcon(is_root, word);
CREATE INDEX IF NOT EXISTS idx_lanelexcon_word          ON lanelexcon(word);

-- ---------------------------
-- 🧠  Update optimizer stats
-- ---------------------------
ANALYZE;

-- ---------------------------
-- 🧩  Ask SQLite to self-tune
-- ---------------------------
PRAGMA optimize;

-- ---------------------------
-- ✅  Confirm DB read-only
-- ---------------------------
-- (When opening from Go or other app, use)
--   file:data.db?mode=ro&_query_only=1&cache=shared

