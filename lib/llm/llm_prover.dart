import 'package:ara_dict/datas/app_db.dart';
import 'package:ara_dict/llm/utils.dart';
import 'package:sqflite/sqflite.dart';

enum LlmModels {
  gemini(name: 'Gemini', ar: 'جيميني', dbName: 'gemini'),
  chatGpt(name: 'ChatGPT', ar: 'شات جي بي تي', dbName: 'chatgpt');

  final String name;
  final String dbName;
  final String ar;

  const LlmModels({required this.name, required this.ar, required this.dbName});

  static LlmModels fromDbName(String dbName) {
    return values.firstWhere((e) => e.dbName == dbName);
  }
}

class Chat {
  final int? id;

  final bool questionRtl;
  String get user => context == null ? question : '$context\n\n$question';

  final String? context;
  final String question;

  final String reply;
  final bool replyRtl;

  final LlmModels provider;
  final String model;

  final DateTime time;

  const Chat({
    this.id,
    required this.context,
    required this.question,
    required this.questionRtl,
    required this.reply,
    required this.replyRtl,
    required this.provider,
    required this.model,
    required this.time,
  });

  Chat withId(int id) {
    return Chat(
      id: id,
      question: question,
      context: context,
      questionRtl: questionRtl,
      reply: reply,
      replyRtl: replyRtl,
      provider: provider,
      model: model,
      time: time,
    );
  }
}

class LlmModel {
  final LlmModels model;
  final List<String> models;
  final List<String> apiKeys;

  const LlmModel({
    required this.model,
    required this.models,
    required this.apiKeys,
  });
}

abstract final class AppChatsDb {
  static List<Chat> chats = [];
  static Map<LlmModels, LlmModel> models = {};

  static Database get _db => AppDb.db;

  static Future<void> init() async {
    await loadChats();
    await loadLlmModels();
  }

  // ===========================
  // Chats
  // ===========================

  static Future<void> addChat(Chat chat) async {
    final id = await _db.insert('llm_chats', {
      'question': chat.question,
      if (chat.context != null) 'context': chat.context,
      'reply': chat.reply,
      'provider': chat.provider.dbName,
      'model': chat.model,
      'time': chat.time.millisecondsSinceEpoch,
    });
    chats.add(chat.withId(id));
  }

  static Future<void> deleteChat(int id) async {
    final idx = chats.indexWhere((i) => i.id == id);
    if (idx > -1) chats.removeAt(idx);

    await _db.delete('llm_chats', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearChats() async {
    chats.clear();
    await _db.delete('llm_chats');
  }

  static Future<void> loadChats() async {
    chats.clear();
    final rows = await _db.query('llm_chats', orderBy: 'time ASC');

    for (final r in rows) {
      final question = r['question'] as String;
      final questionRtl = RtlLangs.test(question);

      final reply = r['reply'] as String;
      final replyRtl = RtlLangs.test(reply);

      chats.add(
        Chat(
          id: r['id'] as int,
          question: question,
          context: r['context'] as String?,
          questionRtl: questionRtl,
          reply: reply,
          replyRtl: replyRtl,
          provider: LlmModels.fromDbName(r['provider'] as String),
          model: r['model'] as String,
          time: DateTime.fromMillisecondsSinceEpoch(r['time'] as int),
        ),
      );
    }
  }

  // ===========================
  // API Keys
  // ===========================

  static Future<void> addApiKey(LlmModels provider, String apiKey) async {
    final m = models[provider]!;
    if (m.apiKeys.contains(apiKey)) return;
    m.apiKeys.add(apiKey);

    await _db.insert('api_keys', {
      'provider': provider.dbName,
      'api_key': apiKey,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<void> deleteApiKey(LlmModels provider, String apiKey) async {
    models[provider]?.apiKeys.remove(apiKey);

    await _db.delete(
      'api_keys',
      where: 'provider = ? AND api_key = ?',
      whereArgs: [provider.dbName, apiKey],
    );
  }

  static Future<List<String>> loadApiKeys(LlmModels provider) async {
    final rows = await _db.query(
      'api_keys',
      columns: ['api_key'],
      where: 'provider = ?',
      whereArgs: [provider.dbName],
      orderBy: 'id ASC',
    );

    return rows.map((e) => e['api_key'] as String).toList();
  }

  // ===========================
  // Models
  // ===========================

  static Future<void> addModel(LlmModels provider, String model) async {
    final m = models[provider]!;
    if (m.models.contains(model)) return;
    m.models.add(model);

    await _db.insert('llm_models', {
      'provider': provider.dbName,
      'model': model,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<void> deleteModel(LlmModels provider, String model) async {
    models[provider]?.models.remove(model);
    await _db.delete(
      'llm_models',
      where: 'provider = ? AND model = ?',
      whereArgs: [provider.dbName, model],
    );
  }

  static Future<List<String>> loadModels(LlmModels provider) async {
    final rows = await _db.query(
      'llm_models',
      columns: ['model'],
      where: 'provider = ?',
      whereArgs: [provider.dbName],
      orderBy: 'id ASC',
    );

    return rows.map((e) => e['model'] as String).toList();
  }

  // ===========================
  // All Providers
  // ===========================

  static Future<void> loadLlmModels() async {
    models.clear();

    for (final provider in LlmModels.values) {
      models[provider] = LlmModel(
        model: provider,
        models: await loadModels(provider),
        apiKeys: await loadApiKeys(provider),
      );
    }
  }
}
