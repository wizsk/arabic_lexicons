import 'package:arabic_lexicons/alphabets.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/datas/app_db.dart';
import 'package:arabic_lexicons/lex/dicts/db.dart';
import 'package:sqflite/sqflite.dart';

extension _LexEntryBookmarkExt on Dict {
  LexEntryBookmarkKey key(int id) => (table, id);
}

typedef LexEntryBookmarkKey = (String, int);

abstract final class LexEntryBm {
  static const String t = 'lex_entries_bm';

  static Database get _db => AppDb.db;

  static final Set<LexEntryBookmarkKey> _entries = {};

  static bool contains(Dict d, DbRow r) => _entries.contains(d.key(r.id));

  static Future<void> init() async {
    final rows = await _db.query(t, columns: ['id', 'lex_table']);
    for (final r in rows) {
      final LexEntryBookmarkKey k = (r['lex_table'] as String, r['id'] as int);

      _entries.add(k);
    }
  }

  static Future<void> add(Dict d, DbRow r) async {
    final String meaning;
    if ((d == Dict.hanswehr || d == Dict.laneLexicon) &&
        r.meanings.contains(engDictHighClass)) {
      meaning = r.meanings.replaceAll(engDictHighClass, "");
    } else {
      meaning = r.meanings;
    }

    final word = r.word.replaceAll("_", " ");

    await _db.insert(t, {
      "id": r.id,
      "word": word,
      "lex_table": d.table,
      "meanings": meaning,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    _entries.add(d.key(r.id));
  }

  static Future<void> remove(Dict d, DbRow r) async {
    return removeRaw(d.table, r.id);
  }

  static Future<void> removeRaw(String lexTable, int id) async {
    final LexEntryBookmarkKey k = (lexTable, id);

    await _db.delete(
      t,
      where: "lex_table = ? AND id = ?",
      whereArgs: [lexTable, id],
    );

    _entries.remove(k);
  }

  static Future<List<LexEntryBmEnty>> getAll() async {
    final rows = await _db.query(t, orderBy: 'created_at ASC');

    return rows.map(LexEntryBmEnty.fromMap).toList();
  }
}

class LexEntryBmEnty {
  final DbRow r;
  final String lexTable;
  final Dict dict;

  const LexEntryBmEnty({
    required this.r,
    required this.lexTable,
    required this.dict,
  });

  int get id => r.id;
  String get word => r.word;
  String get meanings => r.meanings;

  factory LexEntryBmEnty.fromMap(Map<String, Object?> map) {
    final meanings = map['meanings'] as String;
    final tbl = map['lex_table'] as String;
    final dIdx = allDicts.indexWhere((d) => d.table == tbl);
    final d = dIdx == -1
        ? ArabicNormalizer.englishWord.hasMatch(meanings)
              ? Dict.hanswehr
              : Dict.mujamulGhoni
        : allDicts[dIdx];

    final r = DbRow(
      id: map['id'] as int,
      word: map['word'] as String,
      meanings: meanings,
    );

    return LexEntryBmEnty(r: r, lexTable: tbl, dict: d);
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'word': word,
    'lex_table': lexTable,
    'meanings': meanings,
  };

  Future<void> remove() async => LexEntryBm.removeRaw(lexTable, id);
}
