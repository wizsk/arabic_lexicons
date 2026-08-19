import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:arabic_lexicons/lex/dicts/ar_en/ar_en_utils.dart';

class ArEnEntry {
  final String root;
  final String word;
  final String def;

  ArEnEntry({required this.root, required this.word, required this.def});
}

class _Entry {
  final String root;
  final String word;
  final String morph;
  final String def;
  final bool isVerb;
  final String fam;
  final String pos;

  const _Entry({
    required this.root,
    required this.word,
    required this.morph,
    required this.def,
    required this.isVerb,
    required this.fam,
    required this.pos,
  });

  @override
  String toString() {
    return '_Entry(root: $root, word: $word, def: $def)';
  }
}

// Messages
sealed class ArEnDictMessage {
  const ArEnDictMessage();
}

class InitArEnMessage extends ArEnDictMessage {
  final List<ByteData> data;
  final SendPort replyPort;
  const InitArEnMessage(this.data, this.replyPort);
}

class SearchArEnMessage extends ArEnDictMessage {
  final String query;
  final SendPort replyPort;
  const SearchArEnMessage(this.query, this.replyPort);
}

// Result
class SearchArEnResult {
  final List<ArEnEntry> results;
  const SearchArEnResult(this.results);
}

// The engine itself (runs inside the isolate)
class DictEngine {
  late final Map<String, List<_Entry>> _dictPref;
  late final Map<String, List<_Entry>> _dictStems;
  late final Map<String, List<_Entry>> _dictSuff;
  late final Map<String, List<String>> _tableAB;
  late final Map<String, List<String>> _tableAC;
  late final Map<String, List<String>> _tableBC;

  void init(List<ByteData> dataList) {
    _parseAndIndex(dataList);
  }

  void _parseAndIndex(List<ByteData> datas) {
    _dictPref = _loadDict(_decodeData(datas[0]), _DictPos.pre);
    _dictStems = _loadDict(_decodeData(datas[1]), _DictPos.def);
    _dictSuff = _loadDict(_decodeData(datas[2]), _DictPos.sfuff);

    _tableAB = _loadTable(_decodeData(datas[3]));
    _tableAC = _loadTable(_decodeData(datas[4]));
    _tableBC = _loadTable(_decodeData(datas[5]));
  }

  List<ArEnEntry> findWords(String words) {
    final List<ArEnEntry> res = [];

    for (final w in words.split("_")) {
      if (w.isEmpty) continue;
      res.addAll(findWord(w));
    }
    return res;
  }

  List<ArEnEntry> findWord(String w, {bool check = false}) {
    final List<ArEnEntry> res = [];

    for (int i = 0; i < w.length; i++) {
      for (int j = i + 1; j <= w.length; j++) {
        final pref = w.substring(0, i);
        final prf = _dictPref[pref];
        if (prf == null || prf.isEmpty) continue;

        final stem = w.substring(i, j);
        final stm = _dictStems[stem];
        if (stm == null || stm.isEmpty) continue;

        final suff = w.substring(j, w.length);
        final suf = _dictSuff[suff];
        if (suf == null || suf.isEmpty) continue;

        for (final p in prf) {
          for (final s in stm) {
            for (final su in suf) {
              if (!_obeysGrammer(p.morph, s.morph, su.morph)) continue;

              final r = ArEnEntry(
                root: s.root,
                word: p.word + s.word + su.word,
                def: _formatDef(p.def, s.def, su.def, su.isVerb),
              );

              if (check) return [r];
              res.add(r);
            }
          }
        }
      }
    }

    return res;
  }

  bool _obeysGrammer(String pref, String stem, String suff) {
    // return tableAB[pref]?.contains(stem) ??
    //     false && tableBC[stem]!.contains(suff) ??
    //     false && tableAC[pref]?.contains(suff) ??
    //     false;
    if (!(_tableAB[pref]?.contains(stem) ?? false)) {
      return false;
    }
    if (!(_tableBC[stem]?.contains(suff) ?? true)) {
      return false;
    }
    if (!(_tableAC[pref]?.contains(suff) ?? true)) {
      return false;
    }
    return true;
  }
}

enum _DictPos {
  pre, // prefix
  def, // defenition
  sfuff, // suffix
}

Map<String, List<_Entry>> _loadDict(String fileContent, _DictPos dp) {
  var lines = LineSplitter.split(fileContent);
  final Map<String, List<_Entry>> dict = {};

  String root = '';
  bool rootTranliterated = false;
  String family = '';
  for (var line in lines) {
    if (line.trim() == ';') {
      root = '';
      rootTranliterated = false;
      family = '';
    } else if (line.startsWith(';--- ')) {
      root = line.split(' ')[1];
      rootTranliterated = false;
    } else if (line.startsWith('; form')) {
      family = line.split(' ')[2];
    } else if (!line.startsWith(';') && line.isNotEmpty) {
      final parts = line.split('\t');
      final key = bukToArabic(parts[0]);
      // if (key.isEmpty) continue; // don't

      if (root.isNotEmpty && !rootTranliterated) {
        root = bukToArabic(root);
        rootTranliterated = true;
      }
      final word = bukToArabic(parts[1]);
      final (def, isVerb) = _formatDictDef(dp, parts[3]);

      final e = _Entry(
        root: root,
        word: word,
        morph: parts[2],
        def: def,
        isVerb: isVerb,
        fam: family,
        pos: '',
      );
      dict.putIfAbsent(key, () => []).add(e);
    }
  }
  return dict;
}

// Load a table file into a map
Map<String, List<String>> _loadTable(String fileContent) {
  var lines = LineSplitter.split(fileContent);
  final Map<String, List<String>> table = {};

  for (var line in lines) {
    if (line.isEmpty || line.startsWith(';')) continue;
    var parts = line.split(' ');
    if (parts.length == 2) {
      table.putIfAbsent(parts[0], () => []).add(parts[1]);
    }
  }
  return table;
}

String _decodeData(ByteData data) {
  return latin1.decode(data.buffer.asUint8List());
}

String _formatDef(String pre, String stem, String suf, bool isVerb) {
  final res = StringBuffer(pre);
  if (isVerb) {
    res.write(suf.replaceFirst('<verb>', stem));
  } else {
    res.write(stem);
    res.write(suf);
  }
  return res.toString();
}

(String, bool) _formatDictDef(_DictPos dp, String def) {
  def = def.trim();
  if (def.isEmpty) return ('', false);
  switch (dp) {
    case _DictPos.pre:
      final res = "[${def.split('<pos>')[0].trim()}] ";
      return (res, false);

    case _DictPos.def:
      final res = def.split('<pos>')[0].trim().replaceAll(';', ', ');
      return (res, false);

    case _DictPos.sfuff:
      final res = StringBuffer();
      var subDef = def.split("<pos>")[0].trim();
      if (subDef.contains("<verb>")) {
        var parts = subDef.split("<verb>");
        res.write('[${parts[0].trim()}] <verb>');
        if (parts.length > 1 && parts[1].trim().isNotEmpty) {
          res.write(' [${parts[1].trim()}]');
        }
        return (res.toString(), true);
      }
      res.write(' [$subDef]');
      return (res.toString(), false);
  }
}
