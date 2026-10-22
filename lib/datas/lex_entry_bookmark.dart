import 'package:arabic_lexicons/alphabets.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/datas/app_db.dart';
import 'package:arabic_lexicons/lex/dicts/ar_en/ar_en.dart';
import 'package:arabic_lexicons/lex/dicts/db.dart';
import 'package:arabic_lexicons/lex/res.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

extension _LexEntryBookmarkExt on Dict {
  LexEntryBookmarkKey key(int id) => (table, id);
}

typedef LexEntryBookmarkKey = (String, int);

abstract final class LexEntryBm {
  static const String t = 'lex_entries_bm';

  static Database get _db => AppDb.db;

  static final Set<LexEntryBookmarkKey> _entries = {};

  static bool contains(Dict d, DbRow r) => containsId(d, r.id);

  static bool containsId(Dict d, int id) => _entries.contains(d.key(id));

  static Future<void> init() async {
    final rows = await _db.query(t, columns: ['id', 'lex_table']);
    for (final r in rows) {
      final LexEntryBookmarkKey k = (r['lex_table'] as String, r['id'] as int);

      _entries.add(k);
    }
  }

  static Future<void> addDbRow(Dict d, DbRow r) async {
    final String meaning;
    if ((d == Dict.hanswehr || d == Dict.laneLexicon) &&
        r.meanings.contains(engDictHighClass)) {
      meaning = r.meanings.replaceAll(engDictHighClass, "");
    } else {
      meaning = r.meanings;
    }

    final word = r.word.replaceAll("_", " ");

    return add(d: d, id: r.id, word: word, meaning: meaning);
  }

  static Future<void> add({
    required Dict d,
    required int id,
    required String word,
    required String meaning,
  }) async {
    await _db.insert(t, {
      "id": id,
      "word": word,
      "lex_table": d.table,
      "meanings": meaning,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    _entries.add(d.key(id));
  }

  static Future<void> removeDbRow(Dict d, DbRow r) async {
    return remove(d.table, r.id);
  }

  static Future<void> remove(String lexTable, int id) async {
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

    final List<LexEntryBmEnty> res = [];

    loop:
    for (final r in rows) {
      final v = LexEntryBmEnty.fromMap(r);
      if (v != null) {
        res.add(v);
        continue;
      }

      try {
        final id = r['id'] as int?;
        final tbl = r['lex_table'] as String?;

        if (id == null || tbl == null) continue loop;
        LexEntryBm.remove(tbl, id);
      } catch (_) {}
    }

    return res;
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

  bool get isSaved => LexEntryBm.containsId(dict, r.id);

  Future<void> touggle() async =>
      isSaved ? LexEntryBm.removeDbRow(dict, r) : LexEntryBm.addDbRow(dict, r);

  static LexEntryBmEnty? fromMap(Map<String, Object?> map) {
    final tbl = map['lex_table'] as String;
    final dIdx = allDicts.indexWhere((d) => d.table == tbl);
    final m = map['meanings'] as String;

    final d = dIdx == -1
        ? ArabicNormalizer.englishWord.hasMatch(m)
              ? Dict.hanswehr
              : Dict.mujamulGhoni
        : allDicts[dIdx];

    final String meanings;
    if (d == Dict.arEn) {
      try {
        meanings = ArEnEntry.fromJsonString(m).fmtStr;
      } catch (_) {
        return null;
      }
    } else {
      meanings = m;
    }

    final r = DbRow(
      id: map['id'] as int,
      word: map['word'] as String,
      meanings: meanings,
    );

    return LexEntryBmEnty(r: r, lexTable: tbl, dict: d);
  }

  factory LexEntryBmEnty.fromDR(Dict d, DbRow r) {
    return LexEntryBmEnty(dict: d, lexTable: d.table, r: r);
  }

  Future<void> save() async => LexEntryBm.addDbRow(dict, r);

  Future<void> remove() async => LexEntryBm.remove(lexTable, id);

  Widget formatDef(
    BuildContext context, {
    required TextStyle ts,
    required String hlFont,
    required double hlFontSize,
    Color? hlhiColor,
    double hlFontHeight = htmlFontHeight,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return dict.isArEn
        ? Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              meanings,
              style: ts,
              textAlign: TextAlign.left,
              maxLines: maxLines,
              overflow: overflow,
            ),
          )
        : dict.isEng
        ? r.engMeaningView(
            fontSize: hlFontSize,
            fontFam: hlFont,
            maxlines: maxLines,
            textOverFlow: overflow,
            machHiColor: hlhiColor,
          )
        : r.arMeaningView(
            context,
            ts: ts,
            hasRefs: dict.hasRefs,
            maxlines: maxLines,
            textOverFlow: overflow,
          );
  }
}
