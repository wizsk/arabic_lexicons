import 'dart:convert';

import 'package:ara_dict/llm/llm_prover.dart';
import 'package:ara_dict/llm/utils.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

String _promt(String? context, String question, String lang) {
  final rl = '(Reply in $lang)';

  if (context == null || context.isEmpty) {
    return '$question\n\n$rl';
  }

  return '<context>\n'
      '$context\n'
      '</context>\n\n'
      'Question: $question\n\n'
      '$rl';
}

class _LlmRes {
  final String res;
  final String model;

  const _LlmRes({required this.res, required this.model});
}

abstract final class ChatHelper {
  static bool requesting = false;
  static bool _cancelled = false;
  static VoidCallback? _onCancelSuccess;

  static void tryCancelReq(VoidCallback onSuccess) {
    _cancelled = true;
    _onCancelSuccess = onSuccess;
  }

  static Future<bool> getRes(
    BuildContext context,
    LlmModels provider,
    String? qContext,
    String question,
    String lang,
  ) async {
    requesting = true;
    _cancelled = false;
    final prompt = _promt(qContext, question, lang);

    try {
      _LlmRes? res;

      // AppChatsDb.chats.add(
      //   Chat(
      //     provider: LlmModels.gemini,
      //     reply: 'nice',
      //     replyRtl: false,
      //     question: question,
      //     context: qContext,
      //     questionRtl: RtlLangs.test(question),
      //     model: 'me---me',
      //     time: DateTime.now(),
      //   ),
      // );
      // return true;
      // while (true) {
      //   if (_cancelled) {
      //     _onCancelSuccess?.call();
      //     return false;
      //   }
      //   await Future.delayed(Duration(seconds: 4));
      // }

      switch (provider) {
        case LlmModels.gemini:
          res = await _getGeminiReply(prompt, ctx: context);
          break;
        case LlmModels.chatGpt:
          res = await _getOpenAIReply(context, prompt);
          break;
      }

      if (res == null) return false;

      final c = Chat(
        context: qContext,
        question: question,
        questionRtl: RtlLangs.test(question),
        reply: res.res,
        replyRtl: RtlLangs.test(res.res),
        provider: LlmModels.gemini,
        model: res.model,
        time: DateTime.now(),
      );

      AppChatsDb.addChat(c);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('While getting ai res: $e');

      if (!context.mounted) return false;
      showInfoDialog(
        context,
        'Error',
        message: 'Could not get results, please try again later :D',
      );
      return false;
    } finally {
      requesting = false;
    }
  }

  static Future<_LlmRes?> _getGeminiReply(
    String message, {
    required BuildContext ctx,
  }) async {
    // Native endpoint string using the stable free-tier flash model
    final gemini = AppChatsDb.models[LlmModels.gemini];

    if (gemini == null || gemini.models.isEmpty || gemini.apiKeys.isEmpty) {
      if (ctx.mounted) {
        await showInfoDialog(
          ctx,
          'No models or api key found',
          message: 'Please add some from the settings page.',
        );
      }
      return null;
    }

    for (final m in gemini.models) {
      for (final k in gemini.apiKeys) {
        if (_cancelled) {
          _onCancelSuccess?.call();
          return null;
        }
        if (kDebugMode) debugPrint('trying: $m');
        try {
          final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$m:generateContent',
          );

          final res = await http.post(
            url,
            headers: {
              'x-goog-api-key': k, // Google's official API key header
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              "contents": [
                {
                  "role": "user",
                  "parts": [
                    {
                      "text":
                          "System Instruction: You are a helpful assistant for an Arabic reader app. "
                          "Answer questions about the book or text the user is reading. "
                          "Keep replies concise, clear, and comprehensive. "
                          "Use plain text only—no emojis and no markdown styling like bolding or headers. "
                          "You may use text-based bullet points (using '•') to organize information if needed. "
                          "There may be a context section followed by the user question. Reply in the language specified.\n\n"
                          "User Message: $message",
                    },
                  ],
                },
              ],
              "generationConfig": {"temperature": 0.3},
            }),
          );

          if (res.statusCode != 200) {
            throw Exception('Gemini API Error: ${res.body}');
          }

          final data = jsonDecode(res.body);

          // Safe navigation down Google's native JSON tree response
          final parts = data["candidates"]?[0]["content"]["parts"] as List?;
          if (parts != null && parts.isNotEmpty) {
            final r = parts[0]["text"].toString().trim();
            return _LlmRes(res: r, model: m);
          }
        } catch (e) {
          if (kDebugMode) debugPrint('while getting res: $e');
        }
      }
    }
    throw Exception('No response fround from all the models');
  }

  static Future<_LlmRes?> _getOpenAIReply(
    BuildContext ctx,
    String message,
  ) async {
    final gpt = AppChatsDb.models[LlmModels.chatGpt];

    if (gpt == null || gpt.models.isEmpty || gpt.apiKeys.isEmpty) {
      if (ctx.mounted) {
        await showInfoDialog(
          ctx,
          'No models or api key found',
          message: 'Please add some from the settings page.',
        );
      }
      return null;
    }

    for (final m in gpt.models) {
      for (final k in gpt.apiKeys) {
        if (_cancelled) {
          _onCancelSuccess?.call();
          return null;
        }

        if (kDebugMode) debugPrint('trying: $m');

        try {
          final res = await http.post(
            Uri.parse('https://api.openai.com/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $k',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              "model": m,
              "messages": [
                {
                  "role": "system",
                  "content":
                      "System Instruction: You are a helpful assistant for an Arabic reader app. "
                      "Answer questions about the book or text the user is reading. "
                      "Keep replies concise, clear, and comprehensive. "
                      "Use plain text only—no emojis and no markdown styling like bolding or headers. "
                      "You may use text-based bullet points (using '•') to organize information if needed. "
                      "There may be a context section followed by the user question. Reply in the language specified.",
                },
                {"role": "user", "content": message},
              ],
              "temperature": 0.3,
            }),
          );

          final data = jsonDecode(res.body);
          final r = data["choices"][0]["message"]["content"].trim() as String;

          return _LlmRes(model: m, res: r);
        } catch (e) {
          if (kDebugMode) debugPrint('while getting res: $e');
        }
      }
    }
    throw Exception('No response fround from all the models');
  }
}
