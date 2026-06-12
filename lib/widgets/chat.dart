import 'package:ara_dict/conf.dart';
import 'package:ara_dict/llm/llm_prover.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:ara_dict/widgets/selectable_text_screen.dart';
import 'package:flutter/material.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  static Future<void> screen(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Chat')),
          body: const SafeArea(child: ChatView()),
        ),
      ),
    );
  }

  // static Future<void> bottomSheet(BuildContext context) async {
  //   await showModalBottomSheet(
  //     constraints: BoxConstraints(maxWidth: 600),
  //     useSafeArea: true,
  //     isScrollControlled: true,
  //     showDragHandle: true,
  //     context: context,
  //     builder: (context) {
  //       return Padding(
  //         padding: EdgeInsets.only(
  //           bottom: scrollPaddingBottmSheet(context).bottom,
  //         ),
  //         child: ChatView(),
  //       );
  //     },
  //   );
  // }

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  TextDirection _chatDirection = L.dir;
  LlmModels _provider = LlmModels.gemini;

  bool _requesting = false;

  final _sc = ScrollController();
  final _tc = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _sc.dispose();
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_focusNode.hasFocus) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
      child: Column(
        children: [
          // MaterialBanner(
          //   content: const Text('Previous messages are not sent to the model.'),
          //   actions: [TextButton(onPressed: () {}, child: const Text('OK'))],
          // ),
          Expanded(
            child: ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: AppChatsDb.chats.length,
              // separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                index = (AppChatsDb.chats.length - 1) - index;
                final c = AppChatsDb.chats[index];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // const SizedBox(height: 8),
                    ChatTimestamp(time: c.time),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ChatBubble(
                        c: c,
                        isUser: true,
                        afterChange: () => setState(() {}),
                        onReply: () {},
                      ),
                    ),

                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: ChatBubble(
                        c: c,
                        isUser: false,
                        onReply: () {},
                        afterChange: () => setState(() {}),
                      ),
                    ),
                    // const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),

          const Divider(height: 0),
          Padding(
            padding: const EdgeInsets.all(8.0),
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
              horizontal: 8.0,
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
                  onLongPress: () async {
                    final res = await showConfirmDialog(context, 'Clear chat?');

                    if (res != true) return;

                    AppChatsDb.clearChats();

                    if (context.mounted) {
                      setState(() {});
                    }
                  },
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
    );
  }
}

class ChatTimestamp extends StatelessWidget {
  const ChatTimestamp({super.key, this.time});

  final DateTime? time;

  static String _format(DateTime? time) {
    if (time == null) {
      return '--:-- -- • --/--/----';
    }

    final hour24 = time.hour;
    final minute = time.minute;

    final isPm = hour24 >= 12;
    final period = isPm ? 'PM' : 'AM';

    final hour12 = switch (hour24) {
      0 => 12,
      > 12 => hour24 - 12,
      _ => hour24,
    };

    final hh = hour12.toString();
    final mm = minute.toString().padLeft(2, '0');

    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    final year = time.year.toString();

    return '$hh:$mm $period • $day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          _format(time),
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}
