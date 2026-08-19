import 'dart:io';

import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/datas/app_db.dart';
import 'package:arabic_lexicons/history/history.dart';
import 'package:arabic_lexicons/reader/input.dart';
import 'package:arabic_lexicons/reader/settings_class.dart';
import 'package:arabic_lexicons/word_list/book_marks.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path;

abstract final class WordStore {
  static const int histMaxSize = 200;
  static const int _maxBookMarkWrodSize = 10;

  static Database get _db => AppDb.db;

  static final Set<String> _bookmarkedWords = <String>{};
  static final List<String> bookmarkedWords = <String>[];

  static final Set<String> _foreignWords = <String>{};
  static final List<String> foreignWords = <String>[];

  static final List<SearchHistItem> searchHist = []; //<SearchHist>{};

  /// word not okay
  static bool _wnok(String s) => s.isEmpty || s.length > _maxBookMarkWrodSize;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  static bool _inited = false;
  static Future<void> init() async {
    if (_inited) return;

    await _loadCache();

    if (bookmarkedWords.isEmpty) await BookMarks.migrateOld();
    if (foreignEmpty) await _migrateForeigns();

    _inited = true;
  }

  static Future<void> _loadCache() async {
    final bookmarks = await _db.query('bookmarked_words');
    bookmarkedWords.addAll(bookmarks.map((e) => e['word'] as String));
    _bookmarkedWords.addAll(bookmarkedWords);

    final foreigns = await _db.query(
      'foreign_words',
      orderBy: 'created_at ASC',
    );

    foreignWords.addAll(foreigns.map((e) => e['word'] as String));
    _foreignWords.addAll(foreignWords);

    final hists = await _db.query('search_history', orderBy: 'created_at ASC');

    final dicts = Dict.values;
    for (final r in hists) {
      final word = r['word'] as String;
      int dictIndex = r['dict'] as int;

      if (dictIndex < 0 || dictIndex >= dicts.length) dictIndex = 0;

      searchHist.add(SearchHistItem(word: word, dict: dicts[dictIndex]));
    }
  }

  // ---------------------------------------------------------------------------
  // Bookmark words
  // ---------------------------------------------------------------------------

  static bool isBm(String word) => _bookmarkedWords.contains(word);
  static int get bmLen => bookmarkedWords.length;
  static String bmAt(int i) => bookmarkedWords[i];
  static bool get bmEmpty => bookmarkedWords.isEmpty;
  static bool get bmNotEmpty => bookmarkedWords.isNotEmpty;

  static Future<void> addBM(String word) async {
    if (_wnok(word)) return;

    final added = _bookmarkedWords.add(word);

    if (!added) return;

    bookmarkedWords.add(word);

    await _db.insert('bookmarked_words', {
      'word': word,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<int> addBMs(Iterable<String> words) async {
    if (words.isEmpty) return 0;

    final batch = _db.batch();

    int addedCount = 0;
    for (final word in words) {
      if (_wnok(word)) continue;

      final added = _bookmarkedWords.add(word);
      if (!added) continue;
      bookmarkedWords.add(word);

      addedCount++;

      batch.insert('bookmarked_words', {
        'word': word,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    await batch.commit(noResult: true);
    return addedCount;
  }

  static Future<void> rmBM(String word) async {
    if (word.isEmpty) return;

    _bookmarkedWords.remove(word);

    bookmarkedWords.remove(word);
    await _db.delete('bookmarked_words', where: 'word = ?', whereArgs: [word]);
  }

  static Future<int> rmBMs(Iterable<String> words) async {
    if (words.isEmpty) return 0;

    _bookmarkedWords.removeAll(words);

    int rmCount = 0;
    for (final w in words) {
      if (bookmarkedWords.remove(w)) rmCount++;
    }

    final list = words.toList();
    final placeholders = List.filled(list.length, '?').join(' ,');

    await _db.delete(
      'bookmarked_words',
      where: 'word IN ($placeholders)',
      whereArgs: list,
    );

    return rmCount;
  }

  static Future<void> clearBookmarks() async {
    bookmarkedWords.clear();
    _bookmarkedWords.clear();
    await _db.delete('bookmarked_words');
  }

  // ---------------------------------------------------------------------------
  // Foreign words
  // ---------------------------------------------------------------------------

  static bool isForeign(String word) => _foreignWords.contains(word);
  static int get foreignLen => foreignWords.length;
  static String foreignIdx(int i) => foreignWords[i];
  static bool get foreignEmpty => foreignWords.isEmpty;
  static bool get foreignNotEmpty => foreignWords.isNotEmpty;

  static Future<void> addForeign(String word) async {
    if (_wnok(word)) return;

    final added = _foreignWords.add(word);

    // already exists then bump up to latest
    if (!added) {
      foreignWords.remove(word);
    }

    foreignWords.add(word);

    await _db.insert('foreign_words', {
      'word': word,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> addForeigns(Iterable<String> words) async {
    if (words.isEmpty) return 0;

    final batch = _db.batch();

    int addCount = 0;
    for (final word in words) {
      if (_wnok(word)) continue;
      addCount++;

      final added = _foreignWords.add(word);

      // if already exists then skip
      if (!added) continue;

      foreignWords.add(word);

      batch.insert('foreign_words', {
        'word': word,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
    return addCount;
  }

  static Future<void> removeForeign(String word) async {
    if (word.isEmpty) return;
    _foreignWords.remove(word);

    foreignWords.remove(word);

    await _db.delete('foreign_words', where: 'word = ?', whereArgs: [word]);
  }

  static Future<int> removeForeignMany(Iterable<String> words) async {
    if (words.isEmpty) return 0;

    final list = words.toList();
    _foreignWords.removeAll(list);

    int rmCount = 0;
    for (final w in words) {
      if (foreignWords.remove(w)) rmCount++;
    }

    final placeholders = List.filled(list.length, '?').join(' ,');

    await _db.delete(
      'foreign_words',
      where: 'word IN ($placeholders)',
      whereArgs: list,
    );

    return rmCount;
  }

  static Future<void> clearForeign() async {
    foreignWords.clear();
    _foreignWords.clear();
    await _db.delete('foreign_words');
  }

  // static List<String> getForeignWords() {
  //   return foreignWords.toList(growable: false);
  // }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  // static Future<void> reload() async {
  //   await _loadCache();
  // }

  // ---------------------------------------------------------------------------
  // Search History
  // ---------------------------------------------------------------------------
  static int get histLen => searchHist.length;
  static SearchHistItem histAt(int i) => searchHist[i];
  static bool get histEmpty => searchHist.isEmpty;
  static bool get histNotEmpty => searchHist.isNotEmpty;

  static Future<void> histAdd(Dict d, String word) async {
    if (_wnok(word)) return;

    final item = SearchHistItem(dict: d, word: word);

    // remove existing in memory (refresh order)
    final rmed = searchHist.remove(item);

    searchHist.add(item);

    await _db.insert('search_history', {
      'word': word,
      'dict': d.index,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    if (rmed) return;

    if (searchHist.length > histMaxSize + 20) {
      final removeCount = searchHist.length - histMaxSize;

      // oldest items in memory
      final toRemove = searchHist.take(removeCount).toList();

      // remove from memory
      searchHist.removeRange(0, removeCount);

      await rmHistItems(toRemove.map((e) => e.word), removeFromList: false);
    }
  }

  static Future<void> rmHistItems(
    Iterable<String> items, {
    bool removeFromList = true,
  }) async {
    final words = items.toList();

    if (removeFromList) {
      for (final w in words) {
        searchHist.removeWhere((e) => e.word == w);
      }
    }

    final placeholders = List.filled(words.length, '?').join(' ,');

    await _db.delete(
      'search_history',
      where: 'word IN ($placeholders)',
      whereArgs: words,
    );
  }

  static Future<void> rmHistItem(SearchHistItem item) async {
    // remove existing in memory (refresh order)
    searchHist.remove(item);
    await _db.delete(
      'search_history',
      where: 'word = ?',
      whereArgs: [item.word],
    );
  }

  static Future<void> clearHist() async {
    searchHist.clear();
    await _db.delete('search_history');
  }
}

Future<void> _migrateForeigns() async {
  final migratedFileInicator = File(
    path.join(
      (await getApplicationCacheDirectory()).path,
      '___foreign_migrated',
    ),
  );
  if (await migratedFileInicator.exists()) return;

  if (!ReaderInputPageData.isInited) {
    await ReaderInputPageData.init();
    if (!ReaderInputPageData.isInited) return;
  }

  for (final b in ReaderInputPageData.books) {
    final f = await ReaderPageSettings.lurFile(b.hash);
    try {
      WordStore.addForeigns(await f.readAsLines());
      if (WordStore._inited) await f.delete();
    } catch (_) {}
  }

  try {
    await migratedFileInicator.create();
  } catch (_) {}
}
