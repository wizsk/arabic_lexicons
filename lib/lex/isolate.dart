import 'dart:async';
import 'dart:isolate';

import 'package:arabic_lexicons/lex/dicts/ar_en/ar_en.dart';
import 'package:arabic_lexicons/lex/dicts/ar_en/ar_en_utils.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/lex/sugg/data.dart';
import 'package:arabic_lexicons/lex/sugg/sugg.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:path_provider/path_provider.dart';

class Isolates {
  static late final Isolate _isolate;
  static late final SendPort _sendPort;

  static Future<void> spawn() async {
    final ready = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEngines, ready.sendPort);
    _sendPort = await ready.first;
  }

  static bool _arEnIniting = false;
  static bool _arEnInited = false;
  // static bool get arEnInited => _arEnInited;
  static final Completer<void> _arEnInitCompleter = Completer<void>();

  static Future<void> initArEn() async {
    if (_arEnInited || _arEnIniting) return;
    _arEnIniting = true;

    final datas = await Future.wait([
      loadData('assets/data/ar_en/dictprefixes'),
      loadData('assets/data/ar_en/dictstems'),
      loadData('assets/data/ar_en/dictsuffixes'),
      loadData('assets/data/ar_en/tableab'),
      loadData('assets/data/ar_en/tableac'),
      loadData('assets/data/ar_en/tablebc'),
    ]);

    final reply = ReceivePort();
    _sendPort.send(InitArEnMessage(datas, reply.sendPort));
    await reply.first; // wait for ack
    reply.close();
    _arEnIniting = false;
    _arEnInited = true;

    _arEnInitCompleter.complete();
  }

  static bool _suggIniting = false;
  static bool _suggInited = false;
  static final Completer<void> suggInitCompleter = Completer<void>();
  static bool get suggInited => _suggInited;

  static Future<void> initSugg() async {
    if (_suggInited || _suggIniting || !appConf.showSearchSugg) return;
    _suggIniting = true;

    final dataDir = (await getApplicationDocumentsDirectory()).path;
    final reply = ReceivePort();
    _sendPort.send(InitSuggMessage(dataDir, reply.sendPort));
    await reply.first; // wait for ack
    reply.close();

    _suggInited = true;
    _suggIniting = false;
    suggInitCompleter.complete();
  }

  static final _arEnCache = LruCache<String, List<ArEnEntry>>(200);

  static Future<List<ArEnEntry>> arEnSearch(String? query) async {
    if (!_arEnInited) {
      await _arEnInitCompleter.future;
    }

    if (query == null || query.isEmpty) return [];
    final c = _arEnCache.get(query);
    if (c != null) return c;

    final reply = ReceivePort();
    _sendPort.send(SearchArEnMessage(query, reply.sendPort));
    final result = await reply.first as SearchArEnResult;
    reply.close();

    _arEnCache.put(query, result.results);
    return result.results;
  }

  static final _suggCache = LruCache<String, SuggestionEntries>(100);

  // static bool get suggCanBeShown => _suggInited && appConf.showSearchSugg;

  static Future<SuggestionEntries> getSugg(String query) async {
    // await Future.delayed(Duration(seconds: 4));
    if (!_suggInited) {
      await suggInitCompleter.future;
    }

    final c = _suggCache.get(query);
    if (c != null) return c;

    final reply = ReceivePort();
    _sendPort.send(SuggSearch(query, reply.sendPort));
    final result = await reply.first as SuggResult;
    reply.close();

    _suggCache.put(query, result.results);
    return result.results;
  }

  static void dispose() {
    _isolate.kill(priority: Isolate.immediate);
  }
}

void _isolateEngines(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort); // handshake

  final dictEngine = DictEngine();
  final suggEngine = SearchSuggestions();

  receivePort.listen((message) async {
    if (message is InitArEnMessage) {
      dictEngine.init(message.data);
      message.replyPort.send(true); // ack
    } else if (message is SearchArEnMessage) {
      final results = dictEngine.findWords(message.query);
      message.replyPort.send(SearchArEnResult(results));

      // sugg
    } else if (message is InitSuggMessage) {
      await suggEngine.init(message.dataDir);
      message.replyPort.send(true); // ack
    } else if (message is SuggSearch) {
      var res = suggEngine.getSuggestions(message.query);

      final arEnRes = dictEngine.findWord(message.query, check: true);
      if (arEnRes.isNotEmpty) {
        res[Dict.arEn]!.add(SuggestionEntry(false, message.query));
      }

      final filteredRes = Map.fromEntries(
        res.entries.where((e) => e.value.isNotEmpty),
      );

      message.replyPort.send(SuggResult(filteredRes));
    }
  });
}
