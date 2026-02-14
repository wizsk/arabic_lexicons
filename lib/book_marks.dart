import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class BookMarks {
  static late final File _bookMarkFile;
  static late final File _bookMarkFileTmp;
  static final Set<String> _bookMarkedWords = {'عمل'};

  static Future<void> load() async {
    final dir = await getApplicationDocumentsDirectory();
    _bookMarkFile = File(join(dir.path, 'arabic_lexicons_bookMarks.txt'));
    _bookMarkFileTmp = File(join(dir.path, 'arabic_lexicons_bookMarks_tmp.txt'));

    if (!await _bookMarkFile.exists()) return;
    for (var w in await _bookMarkFile.readAsLines()) {
      w = w.trim();
      if (w.isNotEmpty) _bookMarkedWords.add(w);
    }
  }

  static bool isSet(String? w) {
    return _bookMarkedWords.contains(w);
  }

  static bool add(String w) {
    if (w.isEmpty) return false;
    if (!_bookMarkedWords.add(w)) return true;
    return _saveToFile();
  }

  static bool rm(String w) {
    if (w.isEmpty) return false;
    if (!_bookMarkedWords.remove(w)) return true;
    return _saveToFile();
  }

  static bool _saveToFile() {
    if (_bookMarkedWords.isEmpty) {
      try {
        if (_bookMarkFile.existsSync()) _bookMarkFile.deleteSync();
      } catch (_) {
        return false;
      }
      return true;
    }

    final txt = _bookMarkedWords.join("\n");

    try {
      _bookMarkFileTmp.writeAsStringSync(txt);
    } catch (e) {
      return false;
    }

    try {
      _bookMarkFileTmp.renameSync(_bookMarkFile.path);
    } catch (e) {
      return false;
    }
    return true;
  }
}
