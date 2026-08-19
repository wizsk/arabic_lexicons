import 'package:arabic_lexicons/data.dart';

class SearchHistItem {
  final String word;
  final Dict dict;

  const SearchHistItem({required this.word, required this.dict});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SearchHistItem && other.word == word;
  }

  @override
  int get hashCode => word.hashCode;

  static SearchHistItem? fromString(String str, List<Dict> dicts) {
    final parts = str.split(":");
    if (parts.length != 2) return null;

    if (parts[1].isEmpty) return null;

    final dictIdx = int.tryParse(parts[0]);
    if (dictIdx == null || dictIdx < 0 || dictIdx >= dicts.length) return null;

    return SearchHistItem(word: parts[1], dict: dicts[dictIdx]);
  }
}

// abstract final class SearchHist {
//   // no more than 200 cause who will scroll that much!?
//   static const int maxSize = 200;

//   static late final List<SearchHistItem> _items;

//   static SearchHistItem item(int index) => _items[index];
//   static int get length => _items.length;
//   static bool get isEmpty => _items.isEmpty;
//   static bool get isNotEmpty => _items.isNotEmpty;

//   // static List<SearchHistItem> get items => _items;

//   static late final File _file;
//   static late final File _tmpFile;

//   static bool _inited = false;
//   static Future<void> init() async {
//     if (_inited) return;
//     _inited = true;

//     try {
//       await _setFiles();
//       _items = await _parse();
//     } catch (_) {
//       _inited = false;
//     }
//   }

//   static Future<void> _setFiles() async {
//     final dataDir = await getApplicationDocumentsDirectory();
//     _file = File(pp.join(dataDir.path, 'dict_search_hist.txt'));
//     _tmpFile = File(pp.join(dataDir.path, 'dict_search_hist_tmp.txt'));
//   }

//   static Future<bool> _save() async {
//     if (!_inited) return false;

//     final data = _items.join("\n");
//     try {
//       await _tmpFile.writeAsString(data);
//       await _tmpFile.rename(_file.path);

//       if (kDebugMode) debugPrint("searchHist saved: ${_file.path}");

//       return true;
//     } catch (e) {
//       if (kDebugMode) {
//         debugPrint("while saving searchHist: $e");
//       }
//       return false;
//     }
//   }

//   static Future<List<SearchHistItem>> _parse() async {
//     if (!await _file.exists()) return [];

//     final data = await _file.readAsLines();

//     final List<SearchHistItem> res = [];
//     final dicts = Dict.values;
//     for (final l in data) {
//       final lc = l.trim();
//       if (lc.isEmpty) continue;

//       final itm = SearchHistItem.fromString(lc, dicts);
//       if (itm == null) continue;
//       res.add(itm);
//     }

//     return res;
//   }

//   static Future<bool> add(Dict d, String w) async {
//     if (w.isEmpty) return false;

//     _items.removeWhere((itm) => w == itm.word);
//     _items.add(SearchHistItem(dict: d, word: w));

//     if (_items.length > maxSize) {
//       _items.removeRange(0, length - maxSize);
//     }

//     return _save();
//   }

//   static Future<bool> rmAll() async {
//     _items.clear();
//     try {
//       if (await _file.exists()) await _file.delete();
//       return true;
//     } catch (_) {
//       return false;
//     }
//   }

//   static Future<bool> rm(String w) async {
//     final preLen = _items.length;
//     _items.removeWhere((itm) => w == itm.word);
//     if (_items.length != preLen) {
//       return _save();
//     }
//     return false;
//   }
// }
