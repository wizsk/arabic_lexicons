CREATE TABLE IF NOT EXISTS "mujamul_ghoni" (
	"id"	INTEGER PRIMARY KEY AUTOINCREMENT,
	"root"	TEXT,
	"word"	TEXT,
	"meanings"	TEXT,
	"no_harakat"	TEXT
);


CREATE TABLE IF NOT EXISTS "mujamul_muashiroh" (
	"id"	INTEGER PRIMARY KEY AUTOINCREMENT,
	"word"	TEXT,
	"meanings"	TEXT
);

CREATE TABLE IF NOT EXISTS "mujamul_wasith" (
	"id"	INTEGER PRIMARY KEY AUTOINCREMENT,
	"word"	TEXT,
	"meanings"	TEXT
);

CREATE TABLE IF NOT EXISTS "mujamul_muhith" (
	"id"	INTEGER PRIMARY KEY AUTOINCREMENT,
	"word"	TEXT,
	"meanings"	TEXT
);
CREATE TABLE IF NOT EXISTS "mujamul_shihah" (
	"id"	INTEGER PRIMARY KEY AUTOINCREMENT,
	"word"	TEXT,
	"meanings"	TEXT
);

CREATE TABLE IF NOT EXISTS "lisanularab" (
	"id"	INTEGER PRIMARY KEY AUTOINCREMENT,
	"word"	TEXT, -- this is most likely root; with no harakat
	"meanings"	TEXT
);

CREATE TABLE IF NOT EXISTS "hanswehr" (
	"id"	INTEGER PRIMARY KEY,
	"is_root"	BOOL,
	"parent_id"	INTEGER,
	"word"	TEXT, -- when is_root = true; word is root
	"meanings"	TEXT
);

CREATE TABLE IF NOT EXISTS "lanelexcon" (
	"id"	INTEGER PRIMARY KEY,
	"is_root"	BOOL,
	"parent_id"	INTEGER,
	"word"	TEXT, -- when is_root = true; word is root
	"meanings"	TEXT
);


CREATE TABLE IF NOT EXISTS "quran" (
	"id"	INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	"surat"	INTEGER NOT NULL,
	"ayat"	INTEGER NOT NULL,
	"arab"	TEXT CHARACTER NOT NULL,
	"arabic_noharokah"	TEXT CHARACTER NOT NULL,
	"nama_surat"	TEXT CHARACTER,
	"tafsir"	TEXT CHARACTER
);

CREATE TABLE IF NOT EXISTS "ghoribulquran" (
	"id"	INTEGER PRIMARY KEY AUTOINCREMENT,
	"ayah"	TEXT,
	"meanings"	TEXT,
	"arabic_noharokah"	TEXT,
	"surah_name"	TEXT,
	"id_surah"	INTEGER,
	"id_ayah"	TEXT
);
