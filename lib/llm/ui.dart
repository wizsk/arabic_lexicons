import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/llm/helper.dart';
import 'package:ara_dict/llm/llm_prover.dart';
import 'package:ara_dict/llm/utils.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/play_rate.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:ara_dict/widgets/expandable_text/expandable_text.dart';
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

final List<Chat> __chats = [
  Chat(
    id: 1,
    user: 'What is the difference between Flutter and React Native?',
    bot:
        'Flutter uses Dart and renders everything via its own Skia/Impeller engine, giving pixel-perfect UI on all platforms. React Native bridges JavaScript to native components, which can feel more "native" but introduces a JS bridge overhead. Flutter generally wins on performance consistency; React Native wins if your team already knows JavaScript.',
    prompt: 'You are a mobile development expert.',
    provider: LlmModels.gemini,
    model: 'gemini-1.5-pro',
    time: DateTime.now().subtract(const Duration(hours: 3, minutes: 14)),
  ),
  Chat(
    id: 2,
    user: 'ما هي أفضل طريقة لتعلم البرمجة من الصفر؟',
    bot:
        'أفضل طريقة هي البدء بلغة بسيطة مثل Python، ثم التركيز على حل المشكلات الصغيرة يومياً. استخدم منصات مثل freeCodeCamp أو Codecademy للبداية، وانتقل بعدها إلى مشاريع حقيقية. الثبات والممارسة اليومية أهم من أي دورة أو كتاب.',
    prompt: 'أنت مساعد تعليمي متخصص في البرمجة.',
    provider: LlmModels.chatGpt,
    model: 'gpt-4o',
    time: DateTime.now().subtract(const Duration(hours: 1, minutes: 5)),
  ),
  Chat(
    id: 3,
    user: 'Summarize the key principles of clean architecture.',
    bot:
        'Clean Architecture (Uncle Bob) centres on the Dependency Rule: source code dependencies must point inward only. The layers are: Entities (business rules), Use Cases (app logic), Interface Adapters (controllers/presenters), and Frameworks/Drivers (UI, DB). The goal is to keep the core independent of frameworks, databases, and delivery mechanisms so the system is testable and change-resilient.',
    prompt: 'You are a senior software architect.',
    provider: LlmModels.gemini,
    model: 'gemini-1.5-flash',
    time: DateTime.now().subtract(const Duration(minutes: 22)),
  ),
  Chat(
    id: 4,
    user: 'كيف أتعامل مع القلق والتوتر اليومي؟',
    bot:
        'تقنيات فعّالة: تنفس عميق (٤ ثوانٍ شهيق، ٤ حبس، ٦ زفير)، ممارسة الرياضة 30 دقيقة يومياً، وتحديد أوقات ثابتة للنوم. من الناحية المعرفية، دوّن أفكارك القلقة وتحقق من واقعيتها. إذا استمر القلق، استشر متخصصاً.',
    prompt: 'أنت معالج نفسي متعاطف.',
    provider: LlmModels.chatGpt,
    model: 'gpt-4o-mini',
    time: DateTime.now().subtract(const Duration(minutes: 7)),
  ),
];

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  List<Chat> get _chats => true ? __chats : AppChatsDb.chats;

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
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(width: 1, color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _CardHeader(
            chat: chat,
            onDelete: onDelete,
            onInfo: onInfo,
            onCopyUser: () => onCopy(chat.user),
            onCopyBot: () => onCopy(chat.bot),
          ),

          const Divider(height: 4),

          _MessageBubble(text: chat.user, maxCollapsedLines: 2),

          const Divider(height: 4),

          _MessageBubble(text: chat.bot, maxCollapsedLines: 2),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final Chat chat;
  final VoidCallback onDelete;
  final VoidCallback onInfo;
  final VoidCallback onCopyUser;
  final VoidCallback onCopyBot;

  const _CardHeader({
    required this.chat,
    required this.onDelete,
    required this.onInfo,
    required this.onCopyUser,
    required this.onCopyBot,
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
          Text(
            chat.provider.name,
            style: theme.textTheme.titleSmall?.copyWith(color: cs.primary),
          ),
          const Spacer(),
          // Time
          Text(
            _timeAgo(chat.time),
            style: theme.textTheme.bodySmall?.copyWith(color: cs.secondary),
          ),
          const SizedBox(width: 6),
          PopupMenuButton<String>(
            child: const SizedBox(
              width: 26,
              height: 26,
              child: Icon(Icons.more_vert, size: 20),
            ),
            onSelected: (value) async {
              switch (value) {
                case 'info':
                  onInfo();
                  break;
                case 'delete':
                  onDelete();
                  break;
                case 'cp_u':
                  onCopyUser();
                  break;
                case 'cp_b':
                  onCopyBot();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded),
                    const SizedBox(width: 10),
                    Text('Copy User'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    const Icon(Icons.smart_toy_outlined),
                    const SizedBox(width: 10),
                    Text('Copy Bot'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline_rounded),
                    const SizedBox(width: 10),
                    Text('Delete'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded),
                    const SizedBox(width: 10),
                    Text('Info'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final int maxCollapsedLines;
  final String text;

  const _MessageBubble({required this.text, required this.maxCollapsedLines});

  @override
  Widget build(BuildContext context) {
    final arabic = isArabic(text);
    final dir = arabic ? TextDirection.rtl : TextDirection.ltr;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Align(
        alignment: arabic
            ? AlignmentGeometry.topRight
            : AlignmentGeometry.topLeft,
        child: Directionality(
          textDirection: dir,
          child: ExpandableText(
            text,
            expandText: arabic ? 'أظهر المزيد' : 'Show more',
            collapseText: arabic ? 'أظهر أقل' : 'Show less',
            maxLines: maxCollapsedLines,
            textAlign: arabic ? TextAlign.right : TextAlign.left,
            style: TextStyle(height: 1.6, fontFamily: L.arFont),
          ),
        ),
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
