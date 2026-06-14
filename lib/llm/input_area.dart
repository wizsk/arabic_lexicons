import 'dart:math';

import 'package:ara_dict/conf.dart';
import 'package:ara_dict/llm/helper.dart';
import 'package:ara_dict/llm/llm_prover.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:flutter/material.dart';

class LlmInput extends StatefulWidget {
  final ScrollController sc;
  final List<Widget>? pre;

  final (String, String) Function(String question, String lang)? msgAndPrompt;

  final void Function(void Function()) parentState;

  const LlmInput({
    super.key,
    required this.sc,
    required this.parentState,
    this.pre,
    this.msgAndPrompt,
  });

  static Widget bottomPadd(BuildContext context) =>
      SizedBox(height: max(MediaQuery.of(context).padding.bottom, 12));

  @override
  State<LlmInput> createState() => _LlmInputState();
}

enum _LlmReplyL { en, ar, auto }

class _LlmInputState extends State<LlmInput> {
  TextDirection get _chatDirection => switch (_replyL) {
    _LlmReplyL.ar => TextDirection.rtl,
    _ => TextDirection.ltr,
  };

  _LlmReplyL _replyL = L.isAr ? _LlmReplyL.ar : _LlmReplyL.en;

  LlmModels _provider = LlmModels.gemini;
  final _tc = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Stack(
      children: [
        Column(
          children: [
            if (widget.pre != null) ...widget.pre!,

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                runAlignment: WrapAlignment.center,
                alignment: WrapAlignment.center,
                children: [
                  ActionChip(
                    tooltip: 'Llm reply language',
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(switch (_replyL) {
                      _LlmReplyL.en => Icons.language,
                      _LlmReplyL.ar => Icons.translate,
                      _LlmReplyL.auto => Icons.auto_awesome,
                    }, size: 18),
                    label: Text(switch (_replyL) {
                      _LlmReplyL.en => 'English',
                      _LlmReplyL.ar => 'Arabic',
                      _LlmReplyL.auto => 'Auto',
                    }),
                    onPressed: () {
                      setState(() {
                        _replyL = switch (_replyL) {
                          _LlmReplyL.en => _LlmReplyL.ar,
                          _LlmReplyL.ar => _LlmReplyL.auto,
                          _LlmReplyL.auto => _LlmReplyL.en,
                        };
                      });
                    },
                  ),
                  ActionChip(
                    tooltip: 'Llm model provider',
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
            Row(
              children: [
                Flexible(
                  child: Directionality(
                    textDirection: _chatDirection,
                    child: TextField(
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
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: ChatHelper.requesting
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
                            ChatHelper.requesting = true;
                          });

                          final replyLang = switch (_replyL) {
                            _LlmReplyL.en => 'English',
                            _LlmReplyL.ar => 'Arabic',
                            _LlmReplyL.auto => 'same language as the questoin',
                          };

                          final (msg, prompt) =
                              widget.msgAndPrompt?.call(question, replyLang) ??
                              (
                                question,
                                'Question: $question\n\n'
                                    '(Reply in $replyLang)',
                              );

                          final success = await ChatHelper.getRes(
                            context,
                            _provider,
                            prompt,
                            msg,
                          );

                          if (!context.mounted) return;
                          if (!success) {
                            setState(() {});
                          } else {
                            if (success) _tc.clear();
                            widget.parentState(() {});
                            showSnack(
                              context,
                              'Got response',
                              duration: const Duration(seconds: 2),
                            );

                            if (widget.sc.hasClients) {
                              widget.sc.jumpTo(0);
                            }
                          }
                        },
                ),
              ],
            ),
            LlmInput.bottomPadd(context),
          ],
        ),

        if (ChatHelper.requesting) ...[
          Positioned(
            top: 0,
            right: 0,
            left: 0,
            bottom: 0,
            child: ColoredBox(color: cs.surface),
          ),

          Positioned(
            top: 0,
            right: 0,
            left: 0,
            bottom: 0,
            child: Align(
              alignment: AlignmentGeometry.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // CircularProgressIndicator(),
                  // SizedBox(height: 6),
                  Text(
                    'Requesting...',
                    style: theme.textTheme.titleMedium?.copyWith(
                      // color: cs.onPrimaryContainer,
                    ),
                  ),
                  SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    label: Text('Cancel'),
                    icon: Icon(Icons.cancel_outlined),
                    onPressed: () {
                      ChatHelper.tryCancelReq(() {
                        if (context.mounted) setState(() {});
                      });
                      if (context.mounted) {
                        showSnack(
                          context,
                          'Trying to cancel request, please wait',
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
