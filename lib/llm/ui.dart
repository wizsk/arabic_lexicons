import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/llm/input_area.dart';
import 'package:ara_dict/llm/llm_prover.dart';
import 'package:ara_dict/llm/utils.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:ara_dict/widgets/expandable_text/expandable_text.dart';
import 'package:ara_dict/widgets/no_res.dart';
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

// final List<Chat> __chats = [
//   Chat(
//     id: 1,
//     user: 'What is the difference between Flutter and React Native?',
//     bot:
//         'Flutter uses Dart and renders everything via its own Skia/Impeller engine, giving pixel-perfect UI on all platforms. React Native bridges JavaScript to native components, which can feel more "native" but introduces a JS bridge overhead. Flutter generally wins on performance consistency; React Native wins if your team already knows JavaScript.',
//     prompt: 'You are a mobile development expert.',
//     provider: LlmModels.gemini,
//     model: 'gemini-1.5-pro',
//     time: DateTime.now().subtract(const Duration(hours: 3, minutes: 14)),
//   ),
//   Chat(
//     id: 2,
//     user: 'ما هي أفضل طريقة لتعلم البرمجة من الصفر؟',
//     bot:
//         'أفضل طريقة هي البدء بلغة بسيطة مثل Python، ثم التركيز على حل المشكلات الصغيرة يومياً. استخدم منصات مثل freeCodeCamp أو Codecademy للبداية، وانتقل بعدها إلى مشاريع حقيقية. الثبات والممارسة اليومية أهم من أي دورة أو كتاب.',
//     prompt: 'أنت مساعد تعليمي متخصص في البرمجة.',
//     provider: LlmModels.chatGpt,
//     model: 'gpt-4o',
//     time: DateTime.now().subtract(const Duration(hours: 1, minutes: 5)),
//   ),
//   Chat(
//     id: 3,
//     user: 'Summarize the key principles of clean architecture.',
//     bot:
//         'Clean Architecture (Uncle Bob) centres on the Dependency Rule: source code dependencies must point inward only. The layers are: Entities (business rules), Use Cases (app logic), Interface Adapters (controllers/presenters), and Frameworks/Drivers (UI, DB). The goal is to keep the core independent of frameworks, databases, and delivery mechanisms so the system is testable and change-resilient.',
//     prompt: 'You are a senior software architect.',
//     provider: LlmModels.gemini,
//     model: 'gemini-1.5-flash',
//     time: DateTime.now().subtract(const Duration(minutes: 22)),
//   ),
//   Chat(
//     id: 4,
//     user: 'كيف أتعامل مع القلق والتوتر اليومي؟',
//     bot:
//         'تقنيات فعّالة: تنفس عميق (٤ ثوانٍ شهيق، ٤ حبس، ٦ زفير)، ممارسة الرياضة 30 دقيقة يومياً، وتحديد أوقات ثابتة للنوم. من الناحية المعرفية، دوّن أفكارك القلقة وتحقق من واقعيتها. إذا استمر القلق، استشر متخصصاً.',
//     prompt: 'أنت معالج نفسي متعاطف.',
//     provider: LlmModels.chatGpt,
//     model: 'gpt-4o-mini',
//     time: DateTime.now().subtract(const Duration(minutes: 7)),
//   ),
// ];

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  List<Chat> get _chats => AppChatsDb.chats;

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) showSnack(context, 'Copied to clipboard');
  }

  final _sc = ScrollController();

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

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
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Column(
            children: [
              Expanded(
                child: _chats.isEmpty
                    ? const Center(
                        child: NoResults(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'No chats yet',
                          subtitle: 'Your conversations will appear here',
                        ),
                      )
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
                padding: EdgeInsets.symmetric(horizontal: padd.right),
                child: LlmInput(
                  sc: _sc,
                  onGettingSuccessfulReply: () {
                    if (!context.mounted) return;
                    setState(() {});
                  },
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
            onCopyBot: () => onCopy(chat.reply),
          ),

          const Divider(height: 4),

          _MessageBubble(
            text: chat.user,
            maxCollapsedLines: 2,
            isRtl: chat.questionRtl,
          ),

          const Divider(height: 4),

          _MessageBubble(
            text: chat.reply,
            maxCollapsedLines: 2,
            isRtl: chat.replyRtl,
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
                value: 'cp_u',
                child: Row(
                  children: [
                    const Icon(Icons.person_outline_rounded),
                    const SizedBox(width: 10),
                    Text('Copy Prompt'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'cp_b',
                child: Row(
                  children: [
                    const Icon(Icons.smart_toy_outlined),
                    const SizedBox(width: 10),
                    Text('Copy Response'),
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
  final bool isRtl;

  const _MessageBubble({
    required this.text,
    required this.maxCollapsedLines,
    required this.isRtl,
  });

  @override
  Widget build(BuildContext context) {
    final dir = isRtl ? TextDirection.rtl : TextDirection.ltr;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Align(
        alignment: isRtl
            ? AlignmentGeometry.topRight
            : AlignmentGeometry.topLeft,
        child: Directionality(
          textDirection: dir,
          child: ExpandableText(
            text,
            expandText: isRtl ? 'أظهر المزيد' : 'Show more',
            collapseText: isRtl ? 'أظهر أقل' : 'Show less',
            maxLines: maxCollapsedLines,
            textAlign: isRtl ? TextAlign.right : TextAlign.left,
            style: TextStyle(height: 1.6, fontFamily: L.arFont),
            linkColor: cs.secondary,
          ),
        ),
      ),
    );
  }
}
