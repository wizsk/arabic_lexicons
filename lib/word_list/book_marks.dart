import 'dart:io';

import 'package:ara_dict/datas/word_store.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

abstract final class BookMarks {
  static const bookMarkFileName = 'arabic_lexicons_bookMarks.txt';

  static Future<void> migrateOld() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final bmF = File(join(dir.path, bookMarkFileName));

      if (!await bmF.exists()) return;

      final r = await bmF.readAsLines();
      await WordStore.addBMs(r);

      await bmF.delete();
    } catch (_) {}
  }
}
