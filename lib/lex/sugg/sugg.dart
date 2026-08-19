import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/lex/dicts/db.dart';
import 'package:arabic_lexicons/lex/sugg/data.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const int searchSuggestionsLimit = 10;
const String suggDataSep = '#';

// Messages
sealed class SuggMessage {
  const SuggMessage();
}

class InitSuggMessage extends SuggMessage {
  final String cacheDir;
  final SendPort replyPort;
  const InitSuggMessage(this.cacheDir, this.replyPort);
}

class SuggSearch extends SuggMessage {
  final String query;
  final SendPort replyPort;
  const SuggSearch(this.query, this.replyPort);
}

// Result
class SuggResult {
  final SuggestionEntries results;
  const SuggResult(this.results);
}

// engine
class SearchSuggestions {
  var _datas = SuggDatas.empty();

  bool _initialized = false;

  //  bool get shouldShow {
  //   return _initialized && appSettingsNotifier.showSearchSugg;
  // }

  Future<void> init(String cacheDirPath) async {
    if (_initialized) return;

    _initialized = await _loadCache(cacheDirPath);
    if (_initialized) return;

    try {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await DbService.init(path: cacheDirPath);
    } catch (e) {
      if (kDebugMode) debugPrint('err: $e');
      return;
    }
    _datas = await initSuggetions();
    DbService.close();

    if (_datas.isEmpty) return;
    _initialized = true;

    _saveCache(cacheDirPath, _datas);
  }

  /// Results must be cleaned
  SuggestionEntries getSuggestions(String query, {final int limit = 10}) {
    return getSuggestionsV2(query, limit: limit);
    // final arEnRes =

    // var st = Stopwatch()..start();
    // final res = getSuggestionsV2(query, limit: limit);
    // st.stop();
    // print('\n----------');
    // print('v2 took -> ${st.elapsedMilliseconds}');

    // st.reset();
    // st.start();
    // getSuggestionsV1(query);
    // st.stop();
    // print('v1 took -> ${st.elapsedMilliseconds}');
    // print('----------\n');
    // print('-------main -- start-------');
    // for (final e in res.entries) {
    //   for (final s in e.value) {
    //     if (s.isRoot) print('${e.key.en} -- ${s.word}');
    //   }
    // }
    // print('-------end-------');
    // return res;
  }

  SuggestionEntries getSuggestionsV2(String query, {final int limit = 10}) {
    if (query.isEmpty) return {};
    final SuggestionEntries res = {
      for (final d in allDicts) d: <SuggestionEntry>{},
    };
    final Set<String> matches = {};

    int filledDict = 0;
    final filledDictLen = allDicts.length - 1;
    bool add(String mq) {
      var found = _datas.suggMap[mq];
      if (found != null) {
        for (final r in found.dicts) {
          if (res[r]!.length > limit) {
            filledDict++;
            if (filledDict == filledDictLen) return true;
            continue;
          }
          res[r]!.add(SuggestionEntry(found.isRoot, mq));
        }
        matches.add(mq);
      }
      return false;
    }

    // add
    if (add(query)) return res;

    // when two it might be like حب where حبب
    if (query.length == 2) {
      final q = '$query${query.substring(1)}';
      if (add(q)) return res;
    }

    // TODO: add more replacements

    // Prefix match
    final prefixList = _datas.prefixIndex[query];
    if (prefixList != null) {
      for (final w in prefixList) {
        if (add(w)) return res;
      }
    }

    // Contains match
    for (final word in _datas.allRootKeys) {
      if (word.contains(query)) {
        if (add(word)) return res;
      }
    }

    for (final word in _datas.allWordKeys) {
      if (word.contains(query)) {
        if (add(word)) return res;
      }
    }

    return res;
  }

  Map<Dict, Set<String>> getSuggestionsV1(String query) {
    if (query.isEmpty) return {};
    final Map<Dict, Set<String>> results = {};
    final Set<String> addedWords = {};
    int count = 0;

    const limit = searchSuggestionsLimit;
    void tryAdd(String word) {
      if (count >= limit) return;
      if (!addedWords.add(word)) return;

      final sm = _datas.suggMap[word];
      if (sm == null) return;

      for (final d in sm.dicts) {
        results.putIfAbsent(d, () => <String>{}).add(word);
      }

      count++;
    }

    // Exact match
    if (_datas.suggMap.containsKey(query)) {
      tryAdd(query);
    }

    if (count >= limit) return results;

    // Prefix match
    final prefixList = _datas.prefixIndex[query];
    if (prefixList != null) {
      for (final word in prefixList) {
        tryAdd(word);
        if (count >= limit) break;
      }
    }

    if (count >= limit) return results;

    // Contains match
    for (final word in _datas.allRootKeys) {
      if (word.contains(query)) {
        tryAdd(word);
        if (count >= limit) break;
      }
    }

    if (count >= limit) return results;

    for (final word in _datas.allWordKeys) {
      if (word.contains(query)) {
        tryAdd(word);
        if (count >= limit) break;
      }
    }

    return results;
  }

  final String _suggSaveFileName = 'sugg_data.txt';
  final String _suggPrefixSaveFileName = 'sugg_prefix.txt';

  Future<void> _saveCache(String cacheDir, SuggDatas currDatas) async {
    if (!_initialized) return;

    Stopwatch? sw;
    if (kDebugMode) sw = Stopwatch()..start();

    final data = currDatas.suggMap.entries
        .map(
          (v) =>
              '${v.value.isRoot ? "1" : "0"}'
              '$suggDataSep${encode(v.value.dicts)}$suggDataSep${v.key}',
        )
        .join('\n');

    File(join(cacheDir, _suggSaveFileName)).writeAsString(data);

    final prefixData = currDatas.prefixIndex.entries
        .map((v) => '${v.key}$suggDataSep${jsonEncode(v.value)}')
        .join('\n');

    File(join(cacheDir, _suggPrefixSaveFileName)).writeAsString(prefixData);

    if (kDebugMode) {
      debugPrint('sugg_db saved in ${sw?.elapsedMilliseconds}ms');
    }
  }

  Future<bool> _loadCache(String cacheDir) async {
    try {
      final suggData = await File(
        join(cacheDir, _suggSaveFileName),
      ).readAsLines();

      final prefixData = await File(
        join(cacheDir, _suggPrefixSaveFileName),
      ).readAsLines();

      // Parse in background isolate
      final parsed = parseCacheDatas(suggData, prefixData);

      if (parsed.suggMap.isEmpty || parsed.prefixIndex.isEmpty) return false;

      _datas = parsed;
      if (kDebugMode) debugPrint('loaded sugg form cache: $cacheDir');

      return true;
    } catch (e) {
      return false;
    }
  }
}

class SuggestionMeta {
  final bool isRoot;
  final Set<Dict> dicts;

  SuggestionMeta(this.isRoot, this.dicts);
}

Future<void> _isolateSugg(SendPort mainSendPort) async {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort); // handshake

  final engine = SearchSuggestions();

  receivePort.listen((message) async {
    if (message is InitSuggMessage) {
      await engine.init(message.cacheDir);
      message.replyPort.send(true); // ack
    } else if (message is SuggSearch) {
      final results = engine.getSuggestions(message.query);
      message.replyPort.send(SuggResult(results));
    }
  });
}

// Public-facing handle (used from main isolate)
class SuggIsolate {
  late final Isolate _isolate;
  late final SendPort _sendPort;

  Future<void> spwan() async {
    final ready = ReceivePort();
    _isolate = await Isolate.spawn(_isolateSugg, ready.sendPort);
    _sendPort = await ready.first;
  }

  Future<void> init(String cacheDir) async {
    final reply = ReceivePort();
    _sendPort.send(InitSuggMessage(cacheDir, reply.sendPort));
    await reply.first; // wait for ack
    reply.close();
  }

  Future<SuggResult> search(String query) async {
    final reply = ReceivePort();
    _sendPort.send(SuggSearch(query, reply.sendPort));
    final result = await reply.first as SuggResult;
    reply.close();
    return result;
  }

  void dispose() {
    _isolate.kill(priority: Isolate.immediate);
  }
}
