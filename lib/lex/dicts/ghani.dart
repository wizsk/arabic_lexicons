import 'package:arabic_lexicons/lex/dicts/db.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:sqflite/sqflite.dart';

Future<List<DbRow>> getGoniRes(Database db, String word) async {
  final q = word.trim();
  if (q.isEmpty) return [];

  final acc = <int, DbRow>{}; // keyed by id, keeps insertion order, dedupes

  void add(
    List<Map<String, Object?>> rows,
    // bool hi = false,
    // bool root = false,
  ) {
    for (final r in rows) {
      acc.putIfAbsent(
        r['id'] as int,
        () => DbRow(
          word: r['word'] as String,
          meanings: r['meanings'] as String,
        ),
      );
    }
  }

  // all entries sharing a primary or secondary root with the given ids
  Future<void> addRootsOf(Iterable<int> ids) async {
    if (ids.isEmpty) return;
    final ph = List.filled(ids.length, '?').join(',');
    final r = await db.rawQuery(
      'SELECT root_id, root_secondary_id FROM ghani WHERE id IN ($ph)',
      ids.toList(),
    );

    final roots = <String?>[
      for (final x in r) ...[
        x['root'] as String?,
        x['root_secondary'] as String?,
      ],
    ].whereType<String>().toSet();

    if (roots.isEmpty) return;

    final rp = List.filled(roots.length, '?').join(',');
    add(
      await db.rawQuery(
        'SELECT id, word, meanings FROM ghani '
        'WHERE root IN ($rp) OR root_secondary IN ($rp) ORDER BY id',
        [...roots, ...roots],
      ),
    );
  }

  final idx = await db.rawQuery(
    'SELECT DISTINCT g.id, g.word, g.meanings, w.is_root '
    'FROM ghani_words w JOIN ghani g ON g.id = w.word_id '
    'WHERE w.word = ?',
    [q],
  );

  if (idx.isEmpty) return [];

  add(idx);
  dp(acc.length);

  // why skip?
  // casue: if it's the root, then it already contains
  // all the word ids so, we don't need to add them again
  final needToGet = idx
      .where((r) => r['is_root'] as int == 0)
      .map((r) => r['id'] as int);

  dp("need to get:", needToGet.length);
  if (needToGet.isNotEmpty) await addRootsOf(needToGet);
  dp(acc.length);
  dp();

  return acc.values.toList();
}
