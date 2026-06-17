import 'dart:io';

import 'package:ara_dict/datas/word_store.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

abstract final class AppDb {
  static bool _inited = false;
  static late final Database _db;

  static Database get db {
    if (!_inited) throw Exception("AppDb was not inited");
    return _db;
  }

  static Future<void> init() async {
    if (_inited) return;

    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    _db = await openDatabase(path.join(dbPath, 'app.db'), version: 1);

    await _db.transaction((Transaction txn) async {
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS bookmarked_words (
        word TEXT PRIMARY KEY
        )
        ''');

      await txn.execute('''
        CREATE TABLE IF NOT EXISTS foreign_words (
        word TEXT PRIMARY KEY,
        created_at INTEGER NOT NULL
        )
        ''');
      await txn.execute('''
        CREATE TABLE IF NOT EXISTS search_history (
        word TEXT PRIMARY KEY,
        dict INTEGER NOT NULL,
        created_at INTEGER NOT NULL
        );
        ''');
    });
    _inited = true;
    WordStore.init();
  }
}
