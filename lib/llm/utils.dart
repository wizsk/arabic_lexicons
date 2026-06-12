import 'package:ara_dict/data.dart';
import 'package:ara_dict/llm/llm_prover.dart';
import 'package:ara_dict/llm/ui.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:ara_dict/utils.dart';
import 'package:flutter/material.dart';

Future<void> confirmDeleteChatEntry(
  BuildContext context,
  int id,
  VoidCallback afterChange,
) async {
  final res = await showConfirmDialog(
    context,
    'Delete entry?',
    message: 'This chat entry will be permanently removed.',
    confirmText: 'Delete',
    destructive: true,
  );
  if (res != true) return;

  AppChatsDb.deleteChat(id);

  if (!context.mounted) return;
  afterChange();
  showSnack(context, 'Entry deleted');
}

void showChatInfoSheet(BuildContext context, Chat chat) {
  showModalBottomSheet(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 400),
    builder: (_) => _InfoSheet(chat: chat),
  );
}

class _InfoSheet extends StatelessWidget {
  final Chat chat;
  const _InfoSheet({required this.chat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final th = theme.textTheme;
    return SingleChildScrollView(
      padding: scrollPaddingBottmSheet(context, sides: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ProviderBadge(provider: chat.provider),
              const SizedBox(width: 10),
              Text('Chat Info', style: th.titleMedium),
            ],
          ),
          const SizedBox(height: 12),

          ...separatedList(
            separatorBuilder: (_) => Divider(height: 6),
            items: [
              _infoTile(theme, Icons.tag_rounded, 'ID', '#${chat.id ?? '—'}'),
              _infoTile(theme, Icons.memory_rounded, 'Model', chat.model),
              _infoTile(
                theme,
                Icons.access_time_rounded,
                'Time',
                formatDateTime(context, dt: chat.time),
              ),
              _infoTile(
                theme,
                Icons.format_size_rounded,
                'User length',
                '${chat.user.length} chars',
              ),
              _infoTile(
                theme,
                Icons.smart_toy_rounded,
                'Bot length',
                '${chat.bot.length} chars',
              ),
              _infoTile(
                theme,
                Icons.language_rounded,
                'Language',
                isArabic(chat.user) ? 'Arabic (RTL)' : 'English (LTR)',
              ),
            ],
          ),
          // Info rows
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _infoTile(ThemeData theme, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 15, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Text(label, style: theme.textTheme.titleSmall),
          const Spacer(),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}

bool isArabic(String text) {
  final firstLetter = RegExp(r'\p{L}', unicode: true).firstMatch(text);

  if (firstLetter == null) {
    return false;
  }

  final char = firstLetter.group(0)!;

  return RegExp(r'[\u0600-\u06FF]').hasMatch(char);
}
