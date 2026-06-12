import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/llm/helper.dart';
import 'package:ara_dict/llm/llm_prover.dart';
import 'package:ara_dict/llm/utils.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/play_rate.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

extension LlmVisuals on LlmModels {
  IconData get icon => switch (this) {
    LlmModels.gemini => Icons.auto_awesome_rounded,
    LlmModels.chatGpt => Icons.psychology_rounded,
  };
}

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  List<Chat> get _chats => AppChatsDb.chats;

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    showSnack(context, 'Copied to clipboard');
  }

  TextDirection _chatDirection = L.dir;
  LlmModels _provider = LlmModels.gemini;

  bool _requesting = false;

  final _sc = ScrollController();
  final _tc = TextEditingController();
  final _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final padd = appConf.readerPadd(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Chats ${_chats.length}'),
        actions: [
          IconButton(
            tooltip: 'Clear Chat history',
            icon: Icon(Icons.delete_sweep_outlined),
            onPressed: () async {
              final res = await showConfirmDialog(context, 'Clear chat?');

              if (res != true) return;

              AppChatsDb.clearChats();

              if (context.mounted) {
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_focusNode.hasFocus) {
              FocusManager.instance.primaryFocus?.unfocus();
            }
          },
          child: Column(
            children: [
              Expanded(
                child: _chats.isEmpty
                    ? const Center(child: _EmptyState())
                    : ListView.separated(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        reverse: true,
                        padding: EdgeInsets.only(
                          right: padd.right,
                          left: padd.left,
                          bottom: 12,
                          top: scrollPadding.bottom,
                        ),
                        itemCount: _chats.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, indexFr) {
                          final index = _chats.length - indexFr - 1;
                          final chat = _chats[index];
                          return ChatCard(
                            key: ValueKey(_chats[index].id),
                            chat: chat,
                            onDelete: () => confirmDeleteChatEntry(
                              context,
                              chat.id!,
                              () => setState(() {}),
                            ),
                            onCopy: _copyText,
                            onInfo: () => showChatInfoSheet(context, chat),
                          );
                        },
                      ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: padd.right),
                child: const Divider(height: 0),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: padd.right,
                  vertical: 8.0,
                ),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  runAlignment: WrapAlignment.center,
                  alignment: WrapAlignment.center,
                  children: [
                    ActionChip(
                      visualDensity: VisualDensity.compact,
                      avatar: Icon(switch (_chatDirection) {
                        TextDirection.ltr => Icons.language,
                        TextDirection.rtl => Icons.translate,
                      }, size: 18),
                      label: Text(switch (_chatDirection) {
                        TextDirection.ltr => 'English',
                        TextDirection.rtl => 'Arabic',
                      }),
                      onPressed: () {
                        setState(() {
                          _chatDirection = _chatDirection == TextDirection.ltr
                              ? TextDirection.rtl
                              : TextDirection.ltr;
                        });
                      },
                    ),
                    ActionChip(
                      visualDensity: VisualDensity.compact,
                      avatar: Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text(_provider.name),
                      onPressed: () {
                        setState(() {
                          _provider = switch (_provider) {
                            LlmModels.gemini => LlmModels.chatGpt,
                            LlmModels.chatGpt => LlmModels.gemini,
                          };
                        });
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: padd.right,
                ).copyWith(bottom: 10.0),
                child: Row(
                  children: [
                    Flexible(
                      child: Directionality(
                        textDirection: _chatDirection,
                        child: TextField(
                          focusNode: _focusNode,
                          controller: _tc,
                          magnifierConfiguration:
                              TextMagnifierConfiguration.disabled,
                          contextMenuBuilder: (context, selectableRegionState) {
                            return AdaptiveTextSelectionToolbar.buttonItems(
                              anchors: selectableRegionState.contextMenuAnchors,
                              buttonItems:
                                  selectableRegionState.contextMenuButtonItems,
                            );
                          },
                          minLines: 1,
                          maxLines: 2,
                          textDirection: _chatDirection,
                          style: L.arStyle,
                          decoration: InputDecoration(
                            hintText: switch (_chatDirection) {
                              TextDirection.ltr => 'Ask...',
                              TextDirection.rtl => 'اسأل...',
                            },
                            hintTextDirection: _chatDirection,
                            // prefixIcon: IconButton(
                            //   icon: Icon(Icons.arrow_forward_rounded),
                            //   onPressed: () {},
                            // ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filled(
                      icon: Icon(Icons.arrow_forward),
                      onPressed: _requesting
                          ? null
                          : () async {
                              // setState(() {
                              //   _requesting = true;
                              // });
                              // await Future.delayed(Duration(seconds: 2));
                              // if (context.mounted) {
                              //   setState(() {
                              //     _requesting = false;
                              //   });
                              // }
                              // return;

                              final question = _tc.text.trim();
                              if (question.isEmpty) return;
                              FocusManager.instance.primaryFocus?.unfocus();
                              setState(() {
                                _requesting = true;
                              });

                              final (msg, prompt) = (
                                question,
                                'Question: $question\n\n'
                                    '(Reply in ${_chatDirection == TextDirection.ltr ? 'English' : 'Arabic'})',
                              );

                              final success = await ChatHelper.getRes(
                                context,
                                _provider,
                                prompt,
                                msg,
                              );

                              if (!context.mounted) return;
                              setState(() {
                                if (success) _tc.clear();
                                _requesting = false;
                              });

                              if (success) {
                                showSnack(
                                  context,
                                  'Got response',
                                  duration: const Duration(seconds: 2),
                                );
                              }

                              if (success && _sc.hasClients) {
                                _sc.jumpTo(0);
                              }
                            },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// class _ChatCardState extends State<ChatCard> {
class ChatCard extends StatelessWidget {
  final Chat chat;
  final VoidCallback onDelete;
  final ValueChanged<String> onCopy;
  final VoidCallback onInfo;

  const ChatCard({
    super.key,
    required this.chat,
    required this.onDelete,
    required this.onCopy,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(width: 1, color: cs.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Header row ──
          _CardHeader(chat: chat, onDelete: onDelete, onInfo: onInfo),

          // ── Divider ──
          const Divider(height: 1),

          // ── User bubble ──
          _MessageBubble(
            role: 'You',
            icon: Icons.person_rounded,
            text: chat.user,
            maxCollapsedLines: 2,
            onCopy: () => onCopy(chat.user),
          ),

          // ── Divider ──
          const Divider(height: 1),

          // ── Bot bubble ──
          _MessageBubble(
            role: chat.provider.name,
            icon: chat.provider.icon,
            text: chat.bot,
            maxCollapsedLines: 3,
            onCopy: () => onCopy(chat.bot),
          ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final Chat chat;
  final VoidCallback onDelete;
  final VoidCallback onInfo;

  const _CardHeader({
    required this.chat,
    required this.onDelete,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        spacing: 0,
        children: [
          ProviderBadge(provider: chat.provider),
          const Spacer(),
          // Time
          Text(
            _timeAgo(chat.time),
            style: theme.textTheme.bodySmall?.copyWith(color: cs.secondary),
          ),
          const SizedBox(width: 6),
          // Info button
          _HeaderIconBtn(
            icon: Icons.info_outline_rounded,
            color: cs.secondary,
            onTap: onInfo,
          ),
          const SizedBox(width: 6),
          // Delete button
          _HeaderIconBtn(
            icon: Icons.delete_outline_rounded,
            color: cs.error,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HeaderIconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      iconSize: 20,
      color: color,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
    );
  }
}

class ProviderBadge extends StatelessWidget {
  final LlmModels provider;
  const ProviderBadge({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(provider.icon, size: 16, color: cs.onPrimary),
          const SizedBox(width: 4),
          Text(
            provider.name,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatefulWidget {
  final String role;
  final IconData icon;
  final String text;
  final int maxCollapsedLines;
  final VoidCallback onCopy;

  const _MessageBubble({
    required this.role,
    required this.icon,
    required this.text,
    required this.maxCollapsedLines,
    required this.onCopy,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final arabic = isArabic(widget.text);
    final dir = arabic ? TextDirection.rtl : TextDirection.ltr;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Column(
        // crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role row
          Row(
            children: [
              Icon(widget.icon, size: 14, color: cs.onPrimaryContainer),
              const SizedBox(width: 5),
              Text(
                widget.role,
                style: TextStyle(
                  color: cs.onPrimaryContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),

              _HeaderIconBtn(
                icon: Icons.copy_rounded,
                color: cs.secondary,
                onTap: widget.onCopy,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Message text with RTL support
          Align(
            alignment: arabic
                ? AlignmentGeometry.topRight
                : AlignmentGeometry.topLeft,
            child: Directionality(
              textDirection: dir,
              child: Text(
                widget.text,
                textAlign: arabic ? TextAlign.right : TextAlign.left,
                maxLines: _showAll ? null : widget.maxCollapsedLines,
                overflow: _showAll
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: TextStyle(height: 1.6, fontFamily: L.arFont),
              ),
            ),
          ),

          // Show more/less
          if (widget.text.length > 100) ...[
            const SizedBox(height: 6),
            TextButton(
              child: Text(
                _showAll ? 'Show less' : 'Show more',
                style: L.arStyle,
              ),
              onPressed: () => setState(() => _showAll = !_showAll),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final th = theme.textTheme;
    final cs = theme.colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        elevatedIcon(cs, Icons.chat_bubble_outline_rounded),
        const SizedBox(height: 16),
        Text(
          'No chats yet',
          style: th.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your conversations will appear here',
          style: th.bodySmall?.copyWith(color: cs.secondary, fontSize: 13),
        ),
      ],
    );
  }
}
