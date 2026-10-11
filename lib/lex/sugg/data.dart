import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/lex/dicts/db.dart';
import 'package:arabic_lexicons/lex/sugg/sugg.dart';

class SuggDatas {
  final Map<String, SuggestionMeta> suggMap;
  final List<String> allRootKeys;
  final List<String> allWordKeys;
  final Map<String, List<String>> prefixIndex;

  const SuggDatas({
    required this.suggMap,
    required this.allRootKeys,
    required this.allWordKeys,
    required this.prefixIndex,
  });

  void clearAll() {
    suggMap.clear();
    prefixIndex.clear();
    allRootKeys.clear();
    allWordKeys.clear();
  }

  bool get isEmpty {
    return suggMap.isEmpty || prefixIndex.isEmpty;
  }

  bool get isNotEmpty {
    return suggMap.isNotEmpty || prefixIndex.isNotEmpty;
  }

  static SuggDatas empty() {
    return SuggDatas(
      suggMap: {},
      allRootKeys: [],
      allWordKeys: [],
      prefixIndex: {},
    );
  }
}

const int _prefixMaxLen = 3;

Future<SuggDatas> initSuggetions() async {
  final currData = SuggDatas.empty();
  final Map<String, Set<String>> prefixIndexRootGen = {};
  final Map<String, Set<String>> prefixIndexWordGen = {};

  for (final d in allDicts) {
    if (d == Dict.arEn) continue;

    final list = await DbService.getSearchSuggestionList(d);
    for (final (key, isRoot) in list) {
      final existing = currData.suggMap[key];

      if (existing != null && !existing.isRoot && isRoot) {
        currData.suggMap[key] = SuggestionMeta(true, existing.dicts);
        currData.allRootKeys.add(key);
        currData.allWordKeys.remove(key);

        for (int i = 1; i <= _prefixMaxLen && i <= key.length; i++) {
          final prefix = key.substring(0, i);
          final wBucket = prefixIndexWordGen[prefix] ?? <String>{};
          if (wBucket.isNotEmpty) wBucket.remove(key);
          prefixIndexWordGen[prefix] = wBucket;

          final rBucket = prefixIndexRootGen[prefix] ?? <String>{};
          rBucket.add(key);
          prefixIndexRootGen[prefix] = rBucket;
        }
      } else if (existing == null) {
        currData.suggMap[key] = SuggestionMeta(isRoot, {d});

        if (isRoot) {
          currData.allRootKeys.add(key);
        } else {
          currData.allWordKeys.add(key);
        }

        // build prefix index
        for (int i = 1; i <= _prefixMaxLen && i <= key.length; i++) {
          final prefix = key.substring(0, i);
          if (isRoot) {
            final rBucket = prefixIndexRootGen[prefix] ?? <String>{};
            rBucket.add(key);
            prefixIndexRootGen[prefix] = rBucket;
          } else {
            final wBucket = prefixIndexWordGen[prefix] ?? <String>{};
            wBucket.add(key);
            prefixIndexWordGen[prefix] = wBucket;
          }
          // if (added) totalPrefixses++;
        }
      } else {
        existing.dicts.add(d);
      }
    }
  }

  for (final e in prefixIndexRootGen.entries) {
    final add = e.value.take(searchSuggestionsLimit).toList();
    // totalPrefixsActual += add.length;
    currData.prefixIndex[e.key] = add;
  }

  for (final e in prefixIndexWordGen.entries) {
    final willTake =
        searchSuggestionsLimit - (currData.prefixIndex[e.key]?.length ?? 0);

    if (willTake <= 0) continue;

    final add = e.value.take(willTake).toList();
    // totalPrefixsActual += add.length;
    currData.prefixIndex[e.key] = add;
  }

  // if (kDebugMode) {
  //   debugPrint('Total words indexed for searchSuggesstion');
  //   debugPrint(
  //     'Total words indexed for currData.suggMap: ${currData.suggMap.length}',
  //   );
  //   debugPrint(
  //     'Total words indexed for currData.allRootKeys: ${currData.allRootKeys.length}',
  //   );
  //   debugPrint(
  //     'Total words indexed for currData.allWordKeys: ${currData.allWordKeys.length}',
  //   );
  //   debugPrint(
  //     'Total words indexed for currData.allcurrData.currData.Keys: ${currData.allWordKeys.length + currData.allRootKeys.length}',
  //   );
  //   debugPrint(
  //     'Total words indexed for prefixIndexGen: ${currData.prefixIndex.length} -> $totalPrefixses',
  //   );
  //   debugPrint(
  //     'Total words indexed for currData.prefixIndex: ${currData.prefixIndex.length} -> $totalPrefixsActual',
  //   );
  //   debugPrint(
  //     'Total words indexed for currData.prefixIndex diff: ${totalPrefixsActual - currData.prefixIndex.length}',
  //   );

  //   sw?.stop();
  //   debugPrint('Took: ${sw?.elapsedMilliseconds}ms');

  //   final sorted = List<String>.from(currData.allRootKeys)
  //     ..sort((a, b) => b.length.compareTo(a.length));

  //   // for (int i = 0; i < 50 && i < sorted.length; i++) {
  //   //   debugPrint('$i. ${sorted[i].length} --> ${sorted[i]}');
  //   // }

  //   // File(
  //   //   '/tmp/soreted.txt',
  //   // ).writeAsString(sorted.map((i) => '${i.length} --> $i').join("\n"));
  //   debugPrint('Biggest key -> ${sorted.first.length} --> ${sorted.first}');
  // }
  return currData;
}

class SuggestionMeta {
  final bool isRoot;
  final Set<Dict> dicts;

  const SuggestionMeta(this.isRoot, this.dicts);
}

class SuggestionEntry {
  final bool isRoot;
  final String word;

  SuggestionEntry(this.isRoot, this.word);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SuggestionEntry &&
        other.isRoot == isRoot &&
        other.word == word;
  }

  @override
  int get hashCode => Object.hash(isRoot, word);
}

typedef SuggestionEntries = Map<Dict, Set<SuggestionEntry>>;
