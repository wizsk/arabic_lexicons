import 'dart:io';

import 'package:ara_dict/bm/book_marks.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/history/history.dart';
import 'package:ara_dict/reader/book_store.dart';
import 'package:ara_dict/reader/input.dart';
import 'package:ara_dict/reader/settings_class.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

abstract final class WordStore {
  static const int histMaxSize = 200;
  static const int _maxBookMarkWrodSize = 10;

  static bool _inited = false;
  static Database? _db;

  static final Set<String> _bookmarkedWords = <String>{};
  static final List<String> bookmarkedWords = <String>[];

  static final Set<String> _foreignWords = <String>{};
  static final List<String> foreignWords = <String>[];

  static final List<SearchHistItem> searchHist = []; //<SearchHist>{};

  static final List<BookEntry> books = [];

  /// word not okay
  static bool _wnok(String s) => s.isEmpty || s.length > _maxBookMarkWrodSize;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  static Future<void> init() async {
    if (_inited) return;

    try {
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      final dbPath = await getDatabasesPath();

      _db = await openDatabase(
        join(dbPath, 'words.db'),
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
          CREATE TABLE bookmarked_words (
            word TEXT PRIMARY KEY
          )
        ''');

          await db.execute('''
          CREATE TABLE foreign_words (
            word TEXT PRIMARY KEY,
            created_at INTEGER NOT NULL
          )
        ''');

          await db.execute('''
          CREATE TABLE search_history (
            word TEXT PRIMARY KEY,
            dict INTEGER NOT NULL,
            created_at INTEGER NOT NULL
          );
          ''');

          await db.execute('''
            CREATE TABLE books (
                id        TEXT PRIMARY KEY,          -- hash of book content
                title     TEXT NOT NULL,
                title_cl  TEXT NOT NULL,
                author    TEXT,

                total_para  INTEGER NOT NULL,
                total_words INTEGER NOT NULL,

                pinned        INTEGER NOT NULL DEFAULT 0,  -- 0=false, 1=true
                config        TEXT,                  -- JSON string
                current_para  INTEGER NOT NULL DEFAULT 0
            );
            ''');
        },
      );

      await _loadCache();

      _inited = true;
    } catch (_) {
      _inited = false;
    }

    // TODO: remove this in v5.0.0
    await BookMarks.migrateOld(_inited);
  }

  static Future<void> _loadCache() async {
    // bookmarkedWords.clear();
    // foreignWords.clear();
    // searchHist.clear();

    final bookmarks = await _db?.query('bookmarked_words');
    if (bookmarks != null) {
      bookmarkedWords.addAll(bookmarks.map((e) => e['word'] as String));
      _bookmarkedWords.addAll(bookmarkedWords);
    }

    final foreigns = await _db?.query(
      'foreign_words',
      orderBy: 'created_at ASC',
    );

    if (foreigns != null) {
      foreignWords.addAll(foreigns.map((e) => e['word'] as String));
      _foreignWords.addAll(foreignWords);
    }

    final hists = await _db?.query('search_history', orderBy: 'created_at ASC');

    if (hists != null) {
      final dicts = Dict.values;
      for (final r in hists) {
        final word = r['word'] as String;
        int dictIndex = r['dict'] as int;

        if (dictIndex < 0 || dictIndex >= dicts.length) dictIndex = 0;

        searchHist.add(SearchHistItem(word: word, dict: dicts[dictIndex]));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Books
  // ---------------------------------------------------------------------------

  Future<void> loadBooks() async {
    // nice
    // final books = await ReaderInputPageData.init();
    // if (books.isNotEmpty) {
    //   // do sutff
    // }
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

    await _db?.insert('bookmarked_words', {
      'word': word,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<int> addBMs(Iterable<String> words) async {
    if (words.isEmpty) return 0;

    final batch = _db?.batch();

    int addedCount = 0;
    for (final word in words) {
      if (_wnok(word)) continue;

      final added = _bookmarkedWords.add(word);
      if (!added) continue;
      bookmarkedWords.add(word);

      addedCount++;

      if (batch == null) continue;
      batch.insert('bookmarked_words', {
        'word': word,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    await batch?.commit(noResult: true);
    return addedCount;
  }

  static Future<void> rmBM(String word) async {
    if (word.isEmpty) return;

    _bookmarkedWords.remove(word);

    bookmarkedWords.remove(word);
    await _db?.delete('bookmarked_words', where: 'word = ?', whereArgs: [word]);
  }

  static Future<void> rmBMs(Iterable<String> words) async {
    if (words.isEmpty) return;

    _bookmarkedWords.removeAll(words);

    for (final w in words) {
      bookmarkedWords.remove(w);
    }

    if (_db == null) return;

    final list = words.toList();
    final placeholders = List.filled(list.length, '?').join(',');

    await _db?.delete(
      'bookmarked_words',
      where: 'word IN ($placeholders)',
      whereArgs: list,
    );
  }

  static Future<void> clearBookmarks() async {
    bookmarkedWords.clear();
    _bookmarkedWords.clear();
    await _db?.delete('bookmarked_words');
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

    await _db?.insert('foreign_words', {
      'word': word,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> addForeigns(Iterable<String> words) async {
    if (words.isEmpty) return;

    final batch = _db?.batch();

    for (final word in words) {
      if (_wnok(word)) continue;

      final added = _foreignWords.add(word);

      // if already exists then skip
      if (!added) continue;

      foreignWords.add(word);

      if (batch == null) continue;
      batch.insert('foreign_words', {
        'word': word,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch?.commit(noResult: true);
  }

  static Future<void> removeForeign(String word) async {
    if (word.isEmpty) return;
    _foreignWords.remove(word);

    foreignWords.remove(word);

    await _db?.delete('foreign_words', where: 'word = ?', whereArgs: [word]);
  }

  static Future<void> removeForeignMany(Iterable<String> words) async {
    if (words.isEmpty) return;

    final list = words.toList();
    _foreignWords.removeAll(list);

    for (final w in words) {
      foreignWords.remove(w);
    }

    if (_db == null) return;

    final placeholders = List.filled(list.length, '?').join(',');

    await _db?.delete(
      'foreign_words',
      where: 'word IN ($placeholders)',
      whereArgs: list,
    );
  }

  static Future<void> clearForeign() async {
    foreignWords.clear();
    _foreignWords.clear();
    await _db?.delete('foreign_words');
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

  static Future<void> close() async {
    await _db?.close();
    _db = null;

    bookmarkedWords.clear();
    _bookmarkedWords.clear();
    foreignWords.clear();
    _foreignWords.clear();
    searchHist.clear();
  }

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

    await _db?.insert('search_history', {
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

    final placeholders = List.filled(words.length, '?').join(',');

    await _db?.delete(
      'search_history',
      where: 'word IN ($placeholders)',
      whereArgs: words,
    );
  }

  static Future<void> rmHistItem(SearchHistItem item) async {
    // remove existing in memory (refresh order)
    searchHist.remove(item);
    await _db?.delete(
      'search_history',
      where: 'word = ?',
      whereArgs: [item.word],
    );
  }

  static Future<void> clearHist() async {
    searchHist.clear();
    await _db?.delete('search_history');
  }
}

Future<void> migrateForeigns() async {
  for (final b in BookStore.books) {
    final f = await ReaderPageSettings.lurFile(b.hash);
    try {
      WordStore.addForeigns(await f.readAsLines());
      await f.delete();
    } catch (_) {}
  }
}
