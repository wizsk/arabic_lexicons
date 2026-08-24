import 'dart:async';
import 'dart:io';

import 'package:arabic_lexicons/alphabets.dart';
import 'package:arabic_lexicons/datas/app_db.dart';
import 'package:arabic_lexicons/reader/settings_class.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqlite_api.dart';

class BookEntry {
  final String sha;
  final String title;
  final String titleCl;
  final bool pinned;

  const BookEntry({
    required this.sha,
    required this.title,
    required this.titleCl,
    required this.pinned,
  });

  BookEntry copyWith({
    String? sha,
    String? title,
    String? titleCl,
    bool? pinned,
  }) {
    return BookEntry(
      sha: sha ?? this.sha,
      title: title ?? this.title,
      titleCl: titleCl ?? this.titleCl,
      pinned: pinned ?? this.pinned,
    );
  }
}

abstract final class ReaderInputPageData {
  static InitState _initState = InitState.not;

  static final Completer<void> _initCompleter = Completer<void>();

  static bool get inited => _initState.isInited;

  static List<BookEntry> bookEntries = [];
  static List<BookEntry> bookEnsUnord = [];

  static const booksIndexName = 'books.txt';

  static late final String booksDirPath;
  static String bookTextDest(String sha) =>
      '${path.join(booksDirPath, sha)}.txt';

  static late final String confDirPath;

  static Future<void> init() async {
    if (_initState.isIniting) {
      await _initCompleter.future;
      return;
    }

    if (inited) {
      setBookUnord();
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final booksDir = Directory(path.join(dir.path, 'books'));

    booksDirPath = booksDir.path;
    confDirPath = path.join(booksDirPath, 'conf');

    booksDir.create();
    Directory(confDirPath).create();

    // TODO: Remove in the future version: added at v3.4.0
    final indexFile = File(path.join(booksDir.path, booksIndexName));
    if (await indexFile.exists()) {
      final l = await indexFile.readAsLines();
      bookEntries = parseBooks(l);
      _insertAllBookEntriesToDB(bookEntries).then((_) {
        indexFile.delete();
      });

      final oldConfDir = Directory(path.join(dir.path, readerConfDirNameOld));
      try {
        if (await oldConfDir.exists()) {
          await oldConfDir.rename(confDirPath);
          oldConfDir.delete(recursive: true);
        }
      } catch (_) {}

      if (kDebugMode) debugPrint('Books data migrated!');
    } else {
      await _loadBooks();
      booksDir.create();
    }

    setBookUnord();
    _initState = InitState.done;
    _initCompleter.complete();
  }

  static List<BookEntry> parseBooks(Iterable<String> lines) {
    return lines
        .map((line) {
          final parts = line.split(':');
          if (parts.length == 3) {
            final pinned = parts[0] == '1';
            final hash = parts[1];
            final name = parts.sublist(2).join(':');
            return BookEntry(
              sha: hash,
              title: name,
              titleCl: ArabicNormalizer.cleanLineForSearch(name),
              pinned: pinned,
            );
          }

          // legacy
          if (parts.length == 2) {
            final hash = parts[0];
            final name = parts.sublist(1).join(':');
            return BookEntry(
              sha: hash,
              title: name,
              titleCl: ArabicNormalizer.cleanLineForSearch(name),
              pinned: false,
            );
          }

          return null;
        })
        .whereType<BookEntry>()
        .toList();
  }

  static void setBookUnord({String match = "", bool newToOld = true}) {
    final source = newToOld ? bookEntries.reversed : bookEntries;

    final List<({int idx, BookEntry book})> indexed = [];

    for (final (idx, bk) in source.indexed) {
      indexed.add((idx: idx, book: bk));
    }

    // source.asMap().entries.map((e) {
    //   return (idx: e.key, book: e.value);
    // }).toList();

    indexed.sort((a, b) {
      final pinA = a.book.pinned ? 0 : 1;
      final pinB = b.book.pinned ? 0 : 1;
      if (pinA != pinB) return pinA.compareTo(pinB);
      return a.idx.compareTo(b.idx);
    });

    if (match.isEmpty) {
      bookEnsUnord = indexed.map((e) => e.book).toList();
      return;
    }

    final List<({int idx, int matchIdx})> matchIndexs = [];

    for (int i = 0; i < indexed.length; i++) {
      final idx = indexed[i].book.titleCl.indexOf(match);
      if (idx > -1) matchIndexs.add((idx: i, matchIdx: idx));
    }

    matchIndexs.sort((a, b) => a.matchIdx.compareTo(b.matchIdx));

    final List<BookEntry> matches = [];

    for (final idx in matchIndexs) {
      matches.add(indexed[idx.idx].book);
    }
    bookEnsUnord = matches;
  }

  static Database get db => AppDb.db;

  static Future<bool> add(
    BookEntry book,
    String data, {
    final replace = true,
  }) async {
    await db.insert(
      'book_entries',
      {
        'sha': book.sha,
        'title': book.title,
        'pinned': book.pinned ? 1 : 0,
        'author': '',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: replace
          ? ConflictAlgorithm.replace
          : ConflictAlgorithm.ignore,
    );

    await File(bookTextDest(book.sha)).writeAsString(data);

    final sha = book.sha;
    if (replace) {
      bookEntries.removeWhere((e) => e.sha == sha);
      bookEntries.add(book);
      return true;
    }

    final idx = bookEntries.indexWhere((e) => e.sha == sha);
    if (idx != 1) bookEntries.add(book);

    return idx != 1;
  }

  static Future<bool?> togglePinned(String hash) async {
    await db.rawUpdate(
      '''
      UPDATE book_entries
      SET pinned = CASE pinned
        WHEN 0 THEN 1
        ELSE 0
      END
      WHERE sha = ?
    ''',
      [hash],
    );

    final index = bookEntries.indexWhere((book) => book.sha == hash);

    if (index != -1) {
      final book = bookEntries[index];
      bookEntries[index].copyWith(pinned: !book.pinned);
      return !book.pinned;
    }
    return null;
  }

  static Future<void> delete(String sha) async {
    await db.delete('book_entries', where: 'sha = ?', whereArgs: [sha]);
    bookEntries.removeWhere((e) => e.sha == sha);
    try {
      await File(bookTextDest(sha)).delete();
      ReaderPageSettings.delete(sha);
    } catch (_) {}
  }

  /// this should only be used for migration
  static Future<void> _insertAllBookEntriesToDB(List<BookEntry> books) async {
    var now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final book in books) {
        batch.rawInsert(
          '''
          INSERT INTO book_entries (sha, title, pinned, author, created_at)
          VALUES (?, ?, ?, ?, ?)
          ON CONFLICT(sha) DO UPDATE SET
            created_at = excluded.created_at
        ''',
          [book.sha, book.title, book.pinned ? 1 : 0, '', now],
        );
        now += 1;
      }

      await batch.commit(noResult: true);
    });
  }

  static Future<void> deleteAll() async {
    await db.delete('book_entries');

    final bd = Directory(booksDirPath);
    try {
      if (await bd.exists()) await bd.delete(recursive: true);
      await bd.create();
      await Directory(confDirPath).create();
    } catch (_) {}

    bookEntries.clear();
    bookEnsUnord.clear();
  }

  static Future<void> _loadBooks() async {
    final rows = await db.query('book_entries', orderBy: 'created_at ASC');

    bookEntries = rows.map((row) {
      final title = row['title'] as String;
      final titleClean = ArabicNormalizer.cleanLineForSearch(title);

      return BookEntry(
        sha: row['sha'] as String,
        title: row['title'] as String,
        titleCl: titleClean,
        pinned: (row['pinned'] as int) != 0,
      );
    }).toList();
  }

  static Future<String> saveBookEntriesToTmpFile() async {
    if (bookEntries.isEmpty) throw Exception('No book entries!!');
    if (!inited) throw Exception('ReaderInputPageData not inited!');

    final destDir = await getTemporaryDirectory();

    final txt = ReaderInputPageData.bookEntries
        .map((be) => '${be.pinned ? "1" : "0"}:${be.sha}:${be.title}')
        .join("\n");

    final dst = path.join(destDir.path, booksIndexName);
    final tmp = File('$dst.tmp');
    await tmp.writeAsString(txt, flush: true);

    await tmp.rename(dst);
    return dst;
  }
}
