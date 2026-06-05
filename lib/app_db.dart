import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

abstract final class AppDb {
  static bool _inited = false;
  static late final Database _db;

  static Database get db {
    if (!_inited) {
      throw Exception("AppDb not initialized. Call AppDb.init() first.");
    }
    return _db;
  }

  Future<void> init() async {
    if (_inited) return;

    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();

    _db = await openDatabase(
      path.join(dbPath, 'app.db'),
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
                title_cl  TEXT,
                author    TEXT,

                total_para  INTEGER NOT NULL,
                total_words INTEGER NOT NULL,

                pinned        INTEGER NOT NULL DEFAULT 0,   -- 0=false, 1=true
                config        TEXT,                         -- JSON string
                current_para  INTEGER NOT NULL DEFAULT 0
            );
            ''');
      },
    );

    _inited = true;
  }
}
