import 'dart:io';

import 'package:ara_dict/app_db.dart';
import 'package:ara_dict/reader/input.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqlite_api.dart';

abstract final class BookStore {
  static String? _bookDir;
  static Future<String> get bookDir async {
    if (_bookDir != null) return _bookDir!;

    final doc = await getApplicationDocumentsDirectory();
    final d = path.join(doc.path, 'books');
    _bookDir = d;
    return d;
  }

  static Future<File> bookFile(String id) async {
    return File(path.join(await bookDir, '$id.txt'));
  }

  static Database get _db => AppDb.db;
  static List<BookEntry> books = [];

  /// add or update
  static Future<void> add(BookEntry book, {String? content}) async {
    final idx = books.indexWhere((b) => b.hash == book.hash);
    if (idx > -1) {
      books[idx] = book;
    }

    if (content != null) {
      await (await bookFile(book.hash)).writeAsString(content);
    }

    await _db.insert('books', {
      'hash': book.hash,
      'title': book.name,
      'title_cl': book.nameCl,
      'total_paragraphs': book.totalParas,
      'total_words': book.totalWords,
      'current_paragraph': book.currentPara,
      'pinned': book.pinned ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> addBooks(List<BookEntry> books) async {
    final batch = _db.batch();

    for (final book in books) {
      final idx = books.indexWhere((b) => b.hash == book.hash);
      if (idx > -1) {
        continue;
      }

      batch.insert('books', {
        'hash': book.hash,
        'title': book.name,
        'title_cl': book.nameCl,
        'total_paragraphs': book.totalParas,
        'total_words': book.totalWords,
        'current_paragraph': book.currentPara,
        'pinned': book.pinned ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  // delete

  static Future<void> delete(String id) async {
    await _db.delete('books', where: 'hash = ?', whereArgs: [id]);
    books.removeWhere((b) => b.hash == id);
    try {
      (await bookFile(id)).delete();
    } catch (_) {}
  }

  static Future<void> deleteBooks(List<String> ids) async {
    if (ids.isEmpty) return;

    for (final id in ids) {
      books.removeWhere((b) => b.hash == id);
      try {
        (await bookFile(id)).delete();
      } catch (_) {}
    }

    final placeholders = List.filled(ids.length, '?').join(',');

    await _db.delete('books', where: 'hash IN ($placeholders)', whereArgs: ids);
  }

  // update

  static Future<bool> touglePin(String hash) async {
    final idx = books.indexWhere((b) => b.hash == hash);
    if (idx < 0) return false;

    final pinned = books[idx].pinned;
    books[idx].pinned = !pinned;

    await _db.update(
      'books',
      {'pinned': pinned ? 1 : 0},
      where: 'hash = ?',
      whereArgs: [hash],
    );
    return pinned;
  }

  static Future<void> setCurrentPara(String hash, int para) async {
    final idx = books.indexWhere((b) => b.hash == hash);
    if (idx < 0) return;

    books[idx].currentPara = para;

    await _db.update(
      'books',
      {'current_paragraph': para},
      where: 'hash = ?',
      whereArgs: [hash],
    );
  }

  static Future<void> updateConfig(String hash, String configJson) async {
    await _db.update(
      'books',
      {'config': configJson},
      where: 'hash = ?',
      whereArgs: [hash],
    );
  }
}

Future<void> migrateBookEntris() async {
  final data = await ReaderInputPageData.indexFile!.readAsLines();
  final books = ReaderInputPageData.parseBooks(data);
  if (books.isEmpty) return;

  await BookStore.addBooks(books);
  await ReaderInputPageData.indexFile!.delete();
}
