import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

Future<String> loadString(String path) async {
  var data = await rootBundle.load(path);
  return latin1.decode(data.buffer.asUint8List());
}

// Define Entry class (similar to the Go struct Entry)
class Entry {
  final String root;
  final String word;
  final String morph;
  final String def;
  final String fam;
  final String pos;

  Entry({
    required this.root,
    required this.word,
    required this.morph,
    required this.def,
    required this.fam,
    required this.pos,
  });

  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
      root: json['root'],
      word: json['word'],
      morph: json['morph'],
      def: json['def'],
      fam: json['family'],
      pos: json['pos'] ?? '',
    );
  }
  Map<String, dynamic> toJson() => {
        'root': root,
        'word': word,
        'morph': morph,
        'def': def,
        'family': fam,
        'pos': pos,
      };

  @override
  String toString() {
    return 'Entry(root: $root, word: $word, def: $def)';
  }

  @override
  bool operator ==(Object other) =>
      other is Entry &&
      other.root == root &&
      other.word == word &&
      other.morph == morph &&
      other.def == def &&
      other.fam == fam &&
      other.pos == pos;

  @override
  int get hashCode => Object.hash(root, word, morph, def, fam, pos);
}

class WordAndEntries {
  final String word;
  final bool isPunctuation;
  final List<Entry> entries;

  WordAndEntries(
      {required this.word, required this.isPunctuation, required this.entries});

  @override
  String toString() {
    return 'WordandEntries($word [${entries.map((e) => e.toString()).join(',')}])';
  }
}

// Dictionary class
class Dictionary {
  final Map<String, List<Entry>> _dictPref = {};
  final Map<String, List<Entry>> _dictStems = {};
  final Map<String, List<Entry>> _dictSuff = {};
  final Map<String, List<String>> _tableAB = {};
  final Map<String, List<String>> _tableAC = {};
  final Map<String, List<String>> _tableBC = {};
  var err = '';
  var loaded = false;

  Dictionary() {
    loadData();
  }

  // removes all the char other than arabic!
  String cleanWord(String w) {
    if (w.isEmpty) return '';

    var cw = '';
    for (int i = 0; i < w.length; i++) {
      if (uni2buck.containsKey(w[i])) {
        cw = '$cw${w[i]}';
      }
    }
    return cw;
  }

  // words htat has thier non arabic char removed
  List<Entry> findCleanedWord(String w) {
    List<Entry> res = [];
    w = _transliterateRmHarakats(w);
    for (int i = 0; i < w.length; i++) {
      for (int j = i + 1; j <= w.length; j++) {
        // var c = dict(rSlice(w, 0, i), rSlice(w, i, j), rSlice(w, j, w.length));
        var c = dict(
            w.substring(0, i), w.substring(i, j), w.substring(j, w.length));
        res.addAll(c);
      }
    }
    return res;
  }

  // Method to find word
  List<Entry> findWord(String word) {
    if (word.isEmpty) return [];
    var w = cleanWord(word);
    if (w.isEmpty) return [];
    return findCleanedWord(w);
  }

  // Main dictionary search function
  List<Entry> dict(String pref, String stem, String suff) {
    // print('$pref, $stem, $suff');
    var prf = _dictPref[pref] ?? [];
    var stm = _dictStems[stem] ?? [];
    var suf = _dictSuff[suff] ?? [];
    List<Entry> res = [];

    for (var p in prf) {
      for (var s in stm) {
        for (var su in suf) {
          if (!obeysGrammer(p.morph, s.morph, su.morph)) {
            continue;
          }

          var entry = Entry(
            root: _deTransliterate(s.root),
            word: _deTransliterate(p.word + s.word + su.word),
            def: formatDef(p, s, su),
            fam: s.fam,
            pos: s.pos,
            morph: '',
          );

          res.add(entry);
        }
      }
    }
    return res;
  }

  // Grammar check
  bool obeysGrammer(String pref, String stem, String suff) {
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

  // Format the definition
  String formatDef(Entry pre, Entry stem, Entry suf) {
    String res = '';
    if (pre.def.isNotEmpty) {
      var seg = pre.def.split('<pos>');
      res += "[${seg[0].trim()}] ";
    }

    var def = '';
    if (stem.def.isNotEmpty) {
      var parts = stem.def.split('<pos>');
      def = parts[0].trim().replaceAll(';', ', ');
    }

    if (suf.def.isNotEmpty) {
      var subDef = suf.def.split("<pos>")[0].trim();

      if (subDef.contains("<verb>")) {
        var parts = subDef.split("<verb>");
        res += '[${parts[0].trim()}] $def';
        if (parts.length > 1 && parts[1].trim().isNotEmpty) {
          res += ' [${parts[1].trim()}]';
        }
      } else {
        res += '$def [$subDef]';
      }
    } else {
      res += def;
    }
    return res;
  }

  // Load the tables from files
  Future<void> loadData() async {
    await Future.wait([
      _loadDict('assets/data/dictprefixes', _dictPref),
      _loadDict('assets/data/dictstems', _dictStems),
      _loadDict('assets/data/dictsuffixes', _dictSuff),
      _loadTable('assets/data/tableab', _tableAB),
      _loadTable('assets/data/tableac', _tableAC),
      _loadTable('assets/data/tablebc', _tableBC),
    ]);
    loaded = true;
  }

  // Load a dictionary file into a map
  Future<void> _loadDict(String file, Map<String, List<Entry>> dict) async {
    String fileContent = "";
    try {
      fileContent = await loadString(file);
    } catch (e) {
      err = '$e';
      return;
    }
    var lines = LineSplitter.split(fileContent);

    String root = '';
    String family = '';
    for (var line in lines) {
      if (line.trim() == ';') {
        root = '';
        family = '';
      } else if (line.startsWith(';--- ')) {
        root = line.split(' ')[1];
      } else if (line.startsWith('; form')) {
        family = line.split(' ')[2];
      } else if (!line.startsWith(';') && line.isNotEmpty) {
        var parts = line.split('\t');
        var entry = Entry(
          root: root,
          word: parts[1],
          morph: parts[2],
          def: parts[3],
          fam: family,
          pos: '',
        );
        dict[parts[0]] ??= [];
        dict[parts[0]]?.add(entry);
      }
    }
  }

  // Load a table file into a map
  Future<void> _loadTable(String file, Map<String, List<String>> table) async {
    var fileContent = await loadString(file);
    var lines = LineSplitter.split(fileContent);

    for (var line in lines) {
      var parts = line.split(' ');
      if (parts.length == 2) {
        table.putIfAbsent(parts[0], () => []).add(parts[1]);
      }
    }
  }
}

// Transliterate function
// String _transliterate(String s) {
//   return s.split('').map((c) => buck2Uni[c] ?? c).join();
// }

// Remove Harakats and transliterate
String _transliterateRmHarakats(String s) {
  return s.split('').map((c) {
    var cr = uni2buck[c] ?? c;
    return harakaats.contains(cr) ? '' : cr;
  }).join();
}

// Function to convert from Buckwheat to Unicode
String _deTransliterate(String s) {
  return s.split('').map((c) => buck2uni[c] ?? c).join();
}

// Harakats (vowel markers in Arabic)
Set<String> harakaats = {'a', 'u', 'i', 'F', 'N', 'K', '~', 'o'};

Map<String, String> buck2uni = {
  '\'': String.fromCharCode(0x0621), // hamza-on-the-line
  '|': String.fromCharCode(0x0622), // madda
  '>': String.fromCharCode(0x0623), // hamza-on-'alif
  '&': String.fromCharCode(0x0624), // hamza-on-waaw
  '<': String.fromCharCode(0x0625), // hamza-under-'alif
  '}': String.fromCharCode(0x0626), // hamza-on-yaa'
  'A': String.fromCharCode(0x0627), // bare 'alif
  'b': String.fromCharCode(0x0628), // baa'
  'p': String.fromCharCode(0x0629), // taa' marbuuTa
  't': String.fromCharCode(0x062A), // taa'
  'v': String.fromCharCode(0x062B), // thaa'
  'j': String.fromCharCode(0x062C), // jiim
  'H': String.fromCharCode(0x062D), // Haa'
  'x': String.fromCharCode(0x062E), // khaa'
  'd': String.fromCharCode(0x062F), // daal
  '*': String.fromCharCode(0x0630), // dhaal
  'r': String.fromCharCode(0x0631), // raa'
  'z': String.fromCharCode(0x0632), // zaay
  's': String.fromCharCode(0x0633), // siin
  '\$': String.fromCharCode(0x0634), // shiin
  'S': String.fromCharCode(0x0635), // Saad
  'D': String.fromCharCode(0x0636), // Daad
  'T': String.fromCharCode(0x0637), // Taa'
  'Z': String.fromCharCode(0x0638), // Zaa' (DHaa')
  'E': String.fromCharCode(0x0639), // cayn
  'g': String.fromCharCode(0x063A), // ghayn
  // '_': String.fromCharCode(0x0640), // taTwiil 'ـ' we don't need this!
  'f': String.fromCharCode(0x0641), // faa'
  'q': String.fromCharCode(0x0642), // qaaf
  'k': String.fromCharCode(0x0643), // kaaf
  'l': String.fromCharCode(0x0644), // laam
  'm': String.fromCharCode(0x0645), // miim
  'n': String.fromCharCode(0x0646), // nuun
  'h': String.fromCharCode(0x0647), // haa'
  'w': String.fromCharCode(0x0648), // waaw
  'Y': String.fromCharCode(0x0649), // 'alif maqSuura
  'y': String.fromCharCode(0x064A), // yaa'
  'F': String.fromCharCode(0x064B), // fatHatayn
  'N': String.fromCharCode(0x064C), // Dammatayn
  'K': String.fromCharCode(0x064D), // kasratayn
  'a': String.fromCharCode(0x064E), // fatHa
  'u': String.fromCharCode(0x064F), // Damma
  'i': String.fromCharCode(0x0650), // kasra
  '~': String.fromCharCode(0x0651), // shaddah
  'o': String.fromCharCode(0x0652), // sukuun
  '`': String.fromCharCode(0x0670), // dagger 'alif
  '{': String.fromCharCode(0x0671), // waSla
};

Map<String, String> uni2buck = Map<String, String>.fromEntries(
  buck2uni.entries.map((e) => MapEntry(e.value, e.key)),
);
