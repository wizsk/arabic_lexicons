import 'dart:math';

import 'package:arabic_lexicons/datas/app_db.dart';
import 'package:arabic_lexicons/datas/word_store.dart';
import 'package:sqflite/sqflite.dart';

enum RevOrder { old, newest, rand }

const repeatDurMin = 10;

class ReviewRepo {
  static const _t = 'review';

  final Set<String> _words;
  final Database _db;
  final _rnd = Random();

  ReviewRepo(this._words, this._db);

  static Future<ReviewRepo> init() async {
    final db = AppDb.db;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_t (
        word TEXT PRIMARY KEY,
        due INTEGER NOT NULL,
        last_interval INTEGER NOT NULL DEFAULT 0,
        hidden INTEGER NOT NULL DEFAULT 0
      )''');

    final rows = await db.query('review', columns: ['word']);
    final words = rows.map((r) => r['word'] as String).toSet();

    return ReviewRepo(words, db);
  }

  static int get _now => DateTime.now().millisecondsSinceEpoch;

  /// Adds a word as due now (no-op if it already exists).
  Future<bool> add(String word) async {
    final n = await _db.insert(_t, {
      'word': word,
      'due': _now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    _words.add(word);

    return n > 0; // false if it already existed
  }

  Future<void> rmAll(Iterable<String> words) async {
    if (words.isEmpty) return;
    _words.removeAll(words);

    final list = words.toList();
    final placeholders = List.filled(list.length, '?').join(' ,');

    await _db.delete(_t, where: 'word IN ($placeholders)', whereArgs: list);
  }

  // ReviewRepo: return the last interval for a word
  // Future<int> lastInterval(String word) async {
  //   final rows = await _db.query(
  //     'review',
  //     columns: ['last_interval'],
  //     where: 'word = ?',
  //     whereArgs: [word],
  //     limit: 1,
  //   );
  //   return rows.isEmpty ? 0 : rows.first['last_interval'] as int;
  // }

  static const List<int> defIntervals = [1, 3, 5];

  // Anki-like: returns [hard, good, easy] in days, strictly increasing
  static List<int> calcIntervals(int? prev) {
    if (prev == null || prev <= 0) return defIntervals;
    final hard = (prev * 1.2).round().clamp(1, 100000);
    final good = (prev * 2.5).round().clamp(hard + 1, 100000);
    final easy = (prev * 3.5).round().clamp(good + 1, 100000);
    return [hard, good, easy];
  }

  /// Next due, non-hidden word, or null.
  Future<({String word, List<int> intervals})?> next(
    RevOrder ord,
    bool onlyNew,
  ) async {
    if (!onlyNew) {
      final orderBy = switch (ord) {
        RevOrder.old => 'due ASC',
        RevOrder.newest => 'due DESC',
        RevOrder.rand => 'RANDOM()',
      };

      final rows = await _db.query(
        _t,
        columns: ['word'],
        where: 'hidden = 0 AND due <= ?',
        whereArgs: [_now],
        orderBy: orderBy,
        limit: 1,
      );

      if (rows.isNotEmpty) {
        final r = rows.first;
        final intervals = calcIntervals(r['last_interval'] as int?);
        return (word: r['word'] as String, intervals: intervals);
      }
    }

    switch (ord) {
      case RevOrder.old:
      case RevOrder.newest:
        for (final l in [WordStore.bookmarkedWords, WordStore.foreignWords]) {
          Iterable<String> x = l;
          if (ord == RevOrder.newest) x = l.reversed;
          for (final w in x) {
            if (_words.contains(w)) continue;
            add(w);
            return (word: w, intervals: defIntervals);
          }
        }
        return null;

      case RevOrder.rand:
        final Set<(int, int)> s = {};

        final len =
            WordStore.bookmarkedWords.length + WordStore.foreignWords.length;

        while (s.length < len) {
          final listNo = _rnd.nextInt(1);

          final l = listNo == 0
              ? WordStore.bookmarkedWords
              : WordStore.foreignWords;

          final wordNo = _rnd.nextInt(l.length - 1);
          final key = (listNo, wordNo);
          if (s.contains(key)) continue;
          s.add(key);

          final w = l[wordNo];

          if (_words.contains(w)) continue;
          add(w);
          return (word: w, intervals: defIntervals);
        }

        return null;
    }
  }

  // Future<bool> exists(String word) async {
  //   final rows = await _db.query(
  //     'review',
  //     columns: ['word'],
  //     where: 'word = ?',
  //     whereArgs: [word],
  //     limit: 1,
  //   );
  //   return rows.isNotEmpty;
  // }

  /// days < 0 means "repeat": show again in 10 minutes.
  Future<void> showAfter(String word, int days) async {
    final due = days < 0
        ? _now + const Duration(minutes: repeatDurMin).inMilliseconds
        : _now + Duration(days: days).inMilliseconds;

    await _db.update(
      _t,
      {'due': due, if (days >= 0) 'last_interval': days},
      where: 'word = ?',
      whereArgs: [word],
    );
  }

  Future<void> hide(String word, {bool hide = true}) async {
    await _db.update(
      _t,
      {'hidden': hide ? 1 : 0},
      where: 'word = ?',
      whereArgs: [word],
    );
  }

  Future<List<RevItem>> list({String q = '', bool hidden = false}) async {
    final esc = q
        .replaceAll('\\', '\\\\')
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_');

    final where = StringBuffer('hidden = ?');
    final args = <Object?>[hidden ? 1 : 0];
    if (q.isNotEmpty) {
      where.write(" AND word LIKE ? ESCAPE '\\'");
      args.add('%$esc%');
    }

    final rows = await _db.query(
      _t,
      where: where.toString(),
      whereArgs: args,
      orderBy: 'due ASC',
    );
    return rows.map(RevItem.fromMap).toList();
  }

  Future<void> setDays(String word, int days) async {
    await _db.update(
      _t,
      {
        'due': DateTime.now().add(Duration(days: days)).millisecondsSinceEpoch,
        'last_interval': days,
      },
      where: 'word = ?',
      whereArgs: [word],
    );
  }

  Future<void> setHidden(String word, bool hidden) async {
    return hide(word, hide: hidden);
  }

  Future<void> delete(String word) async {
    await _db.delete(_t, where: 'word = ?', whereArgs: [word]);
    _words.remove(word);
  }

  /// Insert (or restore) a full row.
  Future<void> put(RevItem i) async {
    await _db.insert(
      _t,
      i.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _words.add(i.word);
  }
}

class RevItem {
  final String word;
  final int due; // epoch ms
  final int lastInterval; // days
  final bool hidden;

  RevItem(this.word, this.due, this.lastInterval, this.hidden);

  factory RevItem.fromMap(Map<String, Object?> m) => RevItem(
    m['word'] as String,
    m['due'] as int,
    m['last_interval'] as int,
    (m['hidden'] as int) == 1,
  );

  Map<String, Object?> toMap() => {
    'word': word,
    'due': due,
    'last_interval': lastInterval,
    'hidden': hidden ? 1 : 0,
  };
}
