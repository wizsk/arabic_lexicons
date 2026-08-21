import 'dart:io';
import 'package:arabic_lexicons/alphabets.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// db is saved in cache directory
const String dbFileName = 'db_v3.sqlite';

class DbRow {
  final String word;
  final String meanings;
  final bool isRoot;
  final bool isHi;

  DbRow({
    required this.word,
    required this.meanings,
    this.isRoot = false,
    this.isHi = false,
  });
}

class DbService {
  static const _assetDbPath = 'assets/data/db/db.sqlite';
  static const _oldDbFileNames = ['db.sqlite', 'db_v2.sqlite'];

  static Database? _db;

  static Future<Database> _openDb({String? parent}) async {
    final dbPath = await _copyDbFromAssetsIfNeeded(parent: parent);
    return openDatabase(dbPath, readOnly: true);
  }

  static Future<String> _copyDbFromAssetsIfNeeded({String? parent}) async {
    final dbDir = parent ?? (await getApplicationCacheDirectory()).path;
    final dbPath = join(dbDir, dbFileName);

    if (await File(dbPath).exists()) {
      return dbPath;
    }

    // delete old files
    for (final n in _oldDbFileNames) {
      final f = File(join(dbDir, n));
      f.exists().then((ok) {
        if (ok) f.delete();
      });

      if (kDebugMode) {
        debugPrint('Deleted: ${f.path}');
      }
    }

    if (kDebugMode) {
      debugPrint('Copying db $_assetDbPath -> $dbPath');
    }

    final data = await rootBundle.load(_assetDbPath);
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );

    await File(dbPath).create(recursive: true);
    await File(dbPath).writeAsBytes(bytes, flush: true);

    return dbPath;
  }

  /// Must be called once (Linux requirement)
  static Future<void> init({String? path}) async {
    if (Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _db = await _openDb(parent: path);
  }

  static Database get database {
    if (_db == null) {
      throw "no db open";
    }
    return _db!;
  }

  /// Fetch by exact word
  static Future<List<DbRow>> _getByWordWith3Rows(Dict d, String? word) async {
    if (word == null || word.isEmpty) {
      return const [];
    }

    final db = database;
    var res = await db.query(d.table, where: 'word = ?', whereArgs: [word]);

    // if (res.isEmpty && word.length > 2) {
    //   res = await db.query(d.table, where: 'word = ?', whereArgs: ['ال$word']);
    // }

    if (res.isEmpty) return const [];

    final entries = <DbRow>[];

    for (final row in res) {
      final meaningsRaw = row['meanings'] as String? ?? '';
      String m = meaningsRaw.replaceAll('|', '\n').replaceAll('<br>', '\n');
      if (d.hasRefs) m = ReferenceProcessor.process(m);
      entries.add(DbRow(word: row['word'] as String? ?? '', meanings: m));
    }

    return entries;
  }

  static Future<List<DbRow>> _getByWordGoni(String? word) async {
    if (word == null || word.isEmpty) {
      return const [];
    }
    final db = database;
    const q =
        'SELECT word, root, meanings FROM mujamul_ghoni WHERE root = ? OR no_harakat = ?';
    final res = await db.rawQuery(q, [word, word]);

    final entries = <DbRow>[];

    for (final row in res) {
      final meaningsRaw = row['meanings'] as String? ?? '';

      entries.add(
        DbRow(
          word: row['word'] as String? ?? '',
          meanings: meaningsRaw.replaceAll('|', '\n').replaceAll('<br>', '\n'),
          isRoot: (row['root'] as String?) != "",
        ),
      );
    }

    return entries;
  }

  static Future<List<DbRow>> _getByWordHans(String? wordArg) async {
    wordArg = wordArg?.trim();
    if (wordArg == null || wordArg.isEmpty) {
      return const [];
    }

    final secondary = wordArg.replaceAll(ArabicNormalizer.hamzaAlifs, "ا");

    final words = [wordArg, if (wordArg != secondary) secondary];

    final db = database;
    final results = <DbRow>[];

    for (var query in words) {
      var res = await db.rawQuery(
        '''
      SELECT word, meanings, is_root
      FROM hanswehr
      WHERE parent_id IN (
        SELECT parent_id FROM hanswehr WHERE is_root AND word = ?
      )
      ORDER BY id
    ''',
        [query],
      );

      if (res.isNotEmpty) {
        for (final r in res) {
          results.add(
            DbRow(
              word: r['word'] as String? ?? "",
              meanings: r['meanings'] as String? ?? "",
              isRoot: (r['is_root'] as int? ?? 0) == 1,
            ),
          );
        }
        return results;
      }

      if (res.isEmpty) {
        res = await db.rawQuery(
          '''
      SELECT word, meanings, is_root
      FROM hanswehr
      WHERE parent_id IN (
        SELECT parent_id FROM hanswehr WHERE word = ?
      )
      ORDER BY id
    ''',
          [query],
        );
      }

      if (res.isNotEmpty) {
        for (final r in res) {
          final w = r['word'] as String? ?? "";
          results.add(
            DbRow(
              word: w,
              meanings: r['meanings'] as String? ?? "",
              isRoot: (r['is_root'] as int? ?? 0) == 1,
              isHi: query == w,
            ),
          );
        }
        return results;
      }

      if (query.length >= 3) {
        query = query.replaceAll("_", " ");
        res = await db.rawQuery(
          '''
        SELECT word, meanings, is_root
        FROM hanswehr
        WHERE meanings LIKE ?
        LIMIT 40
      ''',
          ['%$query%'],
        );

        if (res.isEmpty) continue;

        for (final row in res) {
          final w = row['word'] as String? ?? '';
          var m = row['meanings'] as String? ?? '';

          // Highlight query inside meanings
          final highlighted = m.replaceAll(
            query,
            '<span class="high">$query</span>',
          );

          results.add(
            DbRow(
              word: w,
              meanings: highlighted,
              isRoot: (row['is_root'] as int? ?? 0) == 1,
            ),
          );
        }
        return results;
      }
    }

    return results;
  }

  static Future<List<DbRow>> _getByWordLane(String? wordArg) async {
    wordArg = wordArg?.trim();
    if (wordArg == null || wordArg.isEmpty) {
      return const [];
    }

    final db = database;
    final results = <DbRow>[];

    final secondary = wordArg.replaceAll(ArabicNormalizer.hamzaAlifs, "ا");

    final words = [wordArg, if (wordArg != secondary) secondary];

    for (final word in words) {
      var q = '''SELECT word, meanings, is_root FROM lanelexcon
	WHERE parent_id IN (SELECT parent_id FROM lanelexcon WHERE is_root AND WORD = ?)
	ORDER BY id''';
      var res = await db.rawQuery(q, [word]);

      if (res.isNotEmpty) {
        for (final r in res) {
          results.add(
            DbRow(
              word: r['word'] as String? ?? "",
              meanings: r['meanings'] as String? ?? "",
              isRoot: (r['is_root'] as int? ?? 0) == 1,
            ),
          );
        }
        return results;
      }

      q = '''SELECT word, meanings, is_root FROM lanelexcon
       WHERE parent_id IN (SELECT parent_id FROM lanelexcon WHERE WORD = ?)
       ORDER BY id''';
      res = await db.rawQuery(q, [word]);

      if (res.isEmpty) continue;

      for (final r in res) {
        final w = r['word'] as String? ?? "";
        results.add(
          DbRow(
            word: w,
            meanings: r['meanings'] as String? ?? "",
            isRoot: (r['is_root'] as int? ?? 0) == 1,
            isHi: word == w,
          ),
        );
      }
      return results;
    }
    return results;
  }

  static Future<void> close() async {
    await _db?.close();
  }

  static Future<List<(String, bool)>> getSearchSuggestionList(
    Dict selectedDict,
  ) async {
    final res = <(String, bool)>[];
    switch (selectedDict) {
      case Dict.arEn:
        return res;

      case Dict.mujamulGhoni:
        final db = database;

        var dbRes = await db.rawQuery(
          'SELECT root, no_harakat FROM ${selectedDict.table}',
        );

        for (final r in dbRes) {
          final root = r['root'] as String;
          if (root.isNotEmpty) res.add((root, root.length < 5));
          final nh = r['no_harakat'] as String;
          if (nh.isNotEmpty && nh != root) {
            res.add((nh, false));
          }
        }

        return res;

      case Dict.hanswehr:
      case Dict.laneLexicon:
        final db = database;
        final dbRes = await db.rawQuery(
          'SELECT word, is_root FROM ${selectedDict.table}',
        );

        for (final r in dbRes) {
          final word = r['word'] as String;
          final isRoot = r['is_root'] as int == 1;
          if (word.isNotEmpty) res.add((word, isRoot && word.length < 5));
        }
        return res;

      case Dict.mujamulShihah:
      case Dict.lisanAlArab:
      case Dict.mujamulMuashiroh:
      case Dict.mujamulWasith:
      case Dict.mujamulMuhith:
      case Dict.mufradatAlfajulQuran:
      case Dict.maqayeesulLuga:
        final db = database;
        final dbRes = await db.rawQuery(
          'SELECT word FROM ${selectedDict.table}',
        );
        for (final r in dbRes) {
          final word = r['word'] as String;
          if (word.isNotEmpty) res.add((word, false));
        }
        return res;
    }
  }

  static final _cache = LruCache<String, List<DbRow>>(150);

  static Future<List<DbRow>> search(Dict d, String word) async {
    final key = '${d.table}_$word';
    final c = _cache.get(key);
    if (c != null) return c;

    List<DbRow> dbRes;

    switch (d) {
      case Dict.hanswehr:
        dbRes = await _getByWordHans(word);

      case Dict.laneLexicon:
        dbRes = await _getByWordLane(word);

      case Dict.mujamulGhoni:
        dbRes = await _getByWordGoni(word);

      case Dict.mujamulShihah:
      case Dict.lisanAlArab:
      case Dict.mujamulMuashiroh:
      case Dict.mujamulWasith:
      case Dict.mujamulMuhith:
      case Dict.mufradatAlfajulQuran:
      case Dict.maqayeesulLuga:
        dbRes = await _getByWordWith3Rows(d, word);

      default:
        throw "NO no table for ${d.name}";
    }

    _cache.put(key, dbRes);
    return dbRes;
  }
}

class ReferenceProcessor {
  // Compiled once. Never recreated.
  static final RegExp _refExp = RegExp(r'\[\[(.*?)\]\]', dotAll: true);

  static String process(String text) {
    if (text.isEmpty) return text;

    final StringBuffer mainBuffer = StringBuffer();
    final List<String> refs = [];

    int lastIndex = 0;
    int counter = 1;

    for (final match in _refExp.allMatches(text)) {
      // Write text before match
      mainBuffer.write(text.substring(lastIndex, match.start));

      final refContent = match.group(1);
      if (refContent != null) {
        refs.add(refContent.trim());

        final arabicNumber = enToArNum(counter.toString());
        mainBuffer.write('($arabicNumber)');
        counter++;
      }

      lastIndex = match.end;
    }

    // Write remaining text
    mainBuffer.write(text.substring(lastIndex));

    if (refs.isEmpty) {
      return mainBuffer.toString();
    }

    mainBuffer.write('\n\n');
    // Append references section

    for (int i = 0; i < refs.length; i++) {
      final arabicNumber = enToArNum((i + 1).toString());
      final r = refs[i].trim().replaceFirst('. ', '');
      mainBuffer
        ..write('($arabicNumber) ')
        ..writeln(r);
    }

    return mainBuffer.toString().trimRight();
  }
}
