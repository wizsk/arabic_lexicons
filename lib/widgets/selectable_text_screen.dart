import 'dart:math';

import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/llm/helper.dart';
import 'package:ara_dict/llm/llm_prover.dart';
import 'package:ara_dict/llm/ui.dart';
import 'package:ara_dict/llm/utils.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

enum _ChatData { none, selected, all }

({String msg, String prompt}) _msgAndPrompt(
  String pre,
  String question,
  TextDirection dir,
) {
  final rl = '(Reply in ${dir == TextDirection.ltr ? 'English' : 'Arabic'})';

  if (pre.isEmpty) {
    return (msg: question, prompt: '$question\n\n$rl');
  }

  final prompt =
      '<context>\n'
      '$pre\n'
      '</context>\n\n'
      'Question: $question\n\n'
      '$rl';

  return (msg: '$pre\n\n$question', prompt: prompt);
}

typedef SelectableTextScreenFunc = String Function(int? start, int? end);

class SelectableTextScreen extends StatefulWidget {
  final SelectableTextScreenFunc fullTextFunc;
  final int? currentIdx;
  final int? start;
  // exclusive aka upuntil
  final int? end;
  final int? length;
  final TextAlign textAlign;
  final TextDirection dir;
  final TextStyle textStyleBodyMedium;

  const SelectableTextScreen({
    super.key,
    required this.fullTextFunc,
    this.currentIdx,
    this.start,
    this.end,
    this.length,
    required this.textAlign,
    required this.dir,
    required this.textStyleBodyMedium,
  });

  static Future<void> show(
    BuildContext context,
    SelectableTextScreenFunc fullTextFunc,
    TextAlign textAlign,
    TextDirection dir,
    TextStyle textStyleBodyMedium, {
    int? currentIdx,
    int? length,
    int? start,
    int? end,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectableTextScreen(
          fullTextFunc: fullTextFunc,
          textAlign: textAlign,
          dir: dir,
          textStyleBodyMedium: textStyleBodyMedium,
          currentIdx: currentIdx,
          length: length,
          start: start,
          end: end,
        ),
      ),
    );
  }

  @override
  State<SelectableTextScreen> createState() => _SelectableTextScreenState();
}

class _SelectableTextScreenState extends State<SelectableTextScreen>
    with TickerProviderStateMixin {
  late String _txt;
  late final int? _currIdx;
  late final int? _length;
  int? _start;

  final TextEditingController _tc = TextEditingController();
  final ScrollController _sc = ScrollController();
  final FocusNode _focusNode = FocusNode();

  LlmModels _provider = LlmModels.gemini;
  final List<Chat> _chats = AppChatsDb.chats;

  bool _requesting = false;
  String? _selectedTxt;
  String? _selectedTxtSaved;
  bool _chatting = false;
  TextDirection _chatDirection = L.dir;
  _ChatData _include = _ChatData.none;
  bool _chatBoxCollapsed = false;

  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  /// [_end] is exclusive
  ///
  /// but when we promt user for range we show it as is, cause user sees 1 based index
  int? _end;

  @override
  void initState() {
    super.initState();

    _tabController.addListener(() {
      if (_selectedTxtSaved != null && _tabController.index != 0) {
        return;
      }

      if (!mounted) return;
      setState(() {
        _selectedTxt = null;
        _include = _ChatData.none;
      });
    });

    for (final m in AppChatsDb.models.values) {
      if (m.apiKeys.isNotEmpty && m.models.isNotEmpty) {
        _provider = m.model;
      }
    }

    _currIdx = widget.currentIdx;
    _length = widget.length;

    assert(_currIdx == null || _length != null);

    if (_currIdx != null) {
      _start = widget.start ?? _currIdx!;

      if (widget.end != null) {
        assert(_start! < widget.end!);
      }

      _end = widget.end ?? _currIdx! + 1;
      // print('$_start, $_end frr');
    }

    _setTxt();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tc.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    showSnack(context, 'Copied to clipboard');
  }

  void _setTxt() {
    _txt = widget.fullTextFunc.call(_start, _end);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final th = theme.textTheme;
    final cs = theme.colorScheme;

    final readerPadd = appConf.readerPadd(context);

    final sidePaddNormal = readerPadd.right;
    final sidePadd = max(24.0, sidePaddNormal);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          L.p('Select Text', /* txt */ 'حدد النص'),
          style: TextStyle(fontFamily: L.arFontIf),
        ),
        actions: [
          IconButton(
            tooltip: 'Copy All',
            icon: const Icon(Icons.copy_all),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _txt));

              if (!context.mounted) return;
              showSnack(context, 'Text copied');
            },
          ),
          if (_currIdx != null)
            IconButton(
              tooltip: 'Select range',
              icon: Icon(Icons.tune),
              onPressed: () async {
                const range = 5;

                /// all start and end, minLow and maxUp inclusive and 1 indexed
                final curr = _currIdx! + 1;
                int start = _start! + 1;
                int end = _end!;

                int minLow = max(1, curr - range);
                int maxUp = min(_length!, curr + range - 1);

                final slotsLeft = (range * 2) - (maxUp - minLow);

                if (slotsLeft > 0 && !(minLow == 1 && maxUp == _length)) {
                  if (maxUp == _length) {
                    minLow = max(1, curr - (range + slotsLeft));
                  } else if (minLow == 1) {
                    maxUp = min(_length, curr + range + slotsLeft - 2);
                  }
                }

                // print('ogDiff: $slotsLeft diff: ${maxUp - minLow} -- max:$maxUp   min:$minLow curr:$curr');

                final result = await _ParaRangeDialouge.show(
                  context: context,
                  currIdx: curr,
                  minLow: minLow,
                  maxUp: maxUp,
                  lower: start,
                  upper: end,
                );

                if (result != null) {
                  _start = result.lower - 1;
                  _end = result.upper;

                  if (!context.mounted) return;
                  setState(() => _setTxt());
                  final paraShowCount = 1 + result.upper - result.lower;
                  showSnack(
                    context,
                    paraShowCount == 1
                        ? 'Showing a single para ${result.lower}'
                        : 'Showing paras from ${result.lower} to ${result.upper} '
                              '(total: $paraShowCount)',
                    duration: const Duration(seconds: 3),
                  );
                }
              },
            ),
          IconButton(
            icon: Icon(
              _chatting ? Icons.message : Icons.message_outlined,
              color: _chatting ? cs.primary : null,
            ),
            onPressed: () {
              setState(() {
                _chatting = !_chatting;
                _tabController.index = 0;
                _chatBoxCollapsed = false;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: widget.dir,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (_focusNode.hasFocus) {
                FocusManager.instance.primaryFocus?.unfocus();
              }
            },

            child: Column(
              children: [
                if (_chatting && _chats.isNotEmpty && !_chatBoxCollapsed)
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Text'),
                      Tab(text: 'Chats'),
                    ],
                  ),
                SizedBox(height: 8),
                Expanded(
                  child: TabBarView(
                    physics: _chatting && _chats.isNotEmpty
                        ? null
                        : NeverScrollableScrollPhysics(),
                    controller: _tabController,
                    children: [
                      ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsetsGeometry.only(
                          left: sidePadd,
                          right: sidePadd,
                          top: 12,
                          bottom: readerPadd.bottom,
                        ),
                        children: [
                          SelectionArea(
                            onSelectionChanged: (SelectedContent? c) {
                              String? t = c?.plainText.trim();
                              if (t == '') t = null;
                              if (_selectedTxt == null && t != null) {
                                setState(() {
                                  _selectedTxt = t;
                                });
                              } else if (_selectedTxt != null && t == null) {
                                setState(() {
                                  _selectedTxt = null;
                                });
                              }
                              _selectedTxt = t;
                            },
                            magnifierConfiguration:
                                TextMagnifierConfiguration.disabled,

                            contextMenuBuilder: (context, selectableRegionState) {
                              return AdaptiveTextSelectionToolbar.buttonItems(
                                anchors:
                                    selectableRegionState.contextMenuAnchors,
                                buttonItems: selectableRegionState
                                    .contextMenuButtonItems,
                              );
                            },
                            child: Text(
                              _txt,
                              textAlign: widget.textAlign,
                              style: widget.textStyleBodyMedium.copyWith(
                                // height: 2.0,
                                leadingDistribution:
                                    TextLeadingDistribution.even,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),

                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: ListView.builder(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          controller: _sc,
                          reverse: true,
                          padding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: sidePaddNormal,
                          ),
                          itemCount: _chats.length,
                          itemBuilder: (context, index) {
                            index = (_chats.length - 1) - index;
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
                    ],
                  ),
                ),

                if (_chatting)
                  Padding(
                    padding: EdgeInsets.only(
                      right: sidePaddNormal,
                      left: sidePaddNormal,
                      bottom: max(MediaQuery.of(context).padding.bottom, 12),
                    ),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: _chatBoxCollapsed
                          ? Column(
                              children: [
                                Divider(height: 0),
                                const SizedBox(height: 8),
                                IconButton(
                                  icon: Icon(Icons.expand_less),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => setState(() {
                                    _chatBoxCollapsed = false;
                                  }),
                                ),
                              ],
                            )
                          : Stack(
                              children: [
                                Column(
                                  children: [
                                    Divider(height: 0),
                                    const SizedBox(height: 8),
                                    IconButton(
                                      icon: Icon(Icons.expand_more),
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => setState(() {
                                        _chatBoxCollapsed = true;
                                      }),
                                    ),
                                    const SizedBox(height: 8),

                                    if (_include == _ChatData.selected &&
                                        _selectedTxtSaved != null) ...[
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxHeight: 50,
                                        ),
                                        child: SingleChildScrollView(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                          child: Text(
                                            _selectedTxtSaved!,
                                            textAlign: TextAlign.center,
                                            // maxLines: 1,
                                            // overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily:
                                                  widget.dir ==
                                                      TextDirection.rtl
                                                  ? fontNotoSansArabic
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 12),
                                    ],

                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      runAlignment: WrapAlignment.center,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        FilterChip(
                                          showCheckmark: false,
                                          visualDensity: VisualDensity.compact,
                                          label: Text('All'),
                                          selected: _ChatData.all == _include,
                                          onSelected: (_) => setState(() {
                                            _include = _ChatData.all;
                                          }),
                                        ),
                                        FilterChip(
                                          showCheckmark: false,
                                          visualDensity: VisualDensity.compact,
                                          label: Text('Selected'),
                                          selected:
                                              _ChatData.selected == _include,
                                          onSelected: _selectedTxt == null
                                              ? null
                                              : (_) => setState(() {
                                                  _selectedTxtSaved =
                                                      _selectedTxt;
                                                  _include = _ChatData.selected;
                                                }),
                                        ),
                                        FilterChip(
                                          visualDensity: VisualDensity.compact,
                                          showCheckmark: false,
                                          label: Text('None'),
                                          selected: _ChatData.none == _include,
                                          onSelected: (_) => setState(() {
                                            _include = _ChatData.none;
                                          }),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      runAlignment: WrapAlignment.center,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        ActionChip(
                                          visualDensity: VisualDensity.compact,
                                          avatar: Icon(switch (_chatDirection) {
                                            TextDirection.ltr => Icons.language,
                                            TextDirection.rtl =>
                                              Icons.translate,
                                          }, size: 18),
                                          label: Text(switch (_chatDirection) {
                                            TextDirection.ltr => 'English',
                                            TextDirection.rtl => 'Arabic',
                                          }),
                                          onPressed: () {
                                            setState(() {
                                              _chatDirection =
                                                  _chatDirection ==
                                                      TextDirection.ltr
                                                  ? TextDirection.rtl
                                                  : TextDirection.ltr;
                                            });
                                          },
                                        ),
                                        ActionChip(
                                          visualDensity: VisualDensity.compact,
                                          avatar: Icon(
                                            Icons.auto_awesome_rounded,
                                            size: 18,
                                          ),
                                          label: Text(_provider.name),
                                          onPressed: () {
                                            setState(() {
                                              _provider = switch (_provider) {
                                                LlmModels.gemini =>
                                                  LlmModels.chatGpt,
                                                LlmModels.chatGpt =>
                                                  LlmModels.gemini,
                                              };
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Directionality(
                                            textDirection: _chatDirection,
                                            child: TextField(
                                              focusNode: _focusNode,
                                              controller: _tc,
                                              magnifierConfiguration:
                                                  TextMagnifierConfiguration
                                                      .disabled,
                                              contextMenuBuilder:
                                                  (
                                                    context,
                                                    selectableRegionState,
                                                  ) {
                                                    return AdaptiveTextSelectionToolbar.buttonItems(
                                                      anchors:
                                                          selectableRegionState
                                                              .contextMenuAnchors,
                                                      buttonItems:
                                                          selectableRegionState
                                                              .contextMenuButtonItems,
                                                    );
                                                  },
                                              minLines: 1,
                                              maxLines: 2,
                                              textDirection: _chatDirection,
                                              style: L.arStyle,
                                              decoration: InputDecoration(
                                                hintText:
                                                    switch (_chatDirection) {
                                                      TextDirection.ltr =>
                                                        'Ask...',
                                                      TextDirection.rtl =>
                                                        'اسأل...',
                                                    },
                                                hintTextDirection:
                                                    _chatDirection,
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
                                            final res = await showConfirmDialog(
                                              context,
                                              'Clear chat?',
                                            );

                                            if (res != true) return;
                                            AppChatsDb.clearChats();

                                            _tabController.index = 0;
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
                                                  // await Future.delayed(
                                                  //   Duration(seconds: 2),
                                                  // );
                                                  // if (context.mounted) {
                                                  //   setState(() {
                                                  //     _requesting = false;
                                                  //   });
                                                  // }
                                                  // return;

                                                  final question = _tc.text
                                                      .trim();
                                                  if (question.isEmpty) return;
                                                  FocusManager
                                                      .instance
                                                      .primaryFocus
                                                      ?.unfocus();

                                                  setState(() {
                                                    _requesting = true;
                                                  });

                                                  final pre = switch (_include) {
                                                    _ChatData.none => '',
                                                    _ChatData.all => _txt,
                                                    _ChatData.selected =>
                                                      _selectedTxtSaved != null
                                                          ? '$_selectedTxtSaved'
                                                          : '',
                                                  };

                                                  final (
                                                    :msg,
                                                    :prompt,
                                                  ) = _msgAndPrompt(
                                                    pre,
                                                    question,
                                                    _chatDirection,
                                                  );

                                                  final success =
                                                      await ChatHelper.getRes(
                                                        context,
                                                        _provider,
                                                        prompt,
                                                        msg,
                                                      );

                                                  if (!context.mounted) return;
                                                  setState(() {
                                                    _requesting = false;
                                                    if (success) {
                                                      _selectedTxtSaved = null;
                                                      _tc.clear();
                                                      _selectedTxt = null;
                                                      _include = _ChatData.none;
                                                      _tabController.index = 1;
                                                    }
                                                  });

                                                  if (success) {
                                                    showSnack(
                                                      context,
                                                      'Got response',
                                                      duration: const Duration(
                                                        seconds: 2,
                                                      ),
                                                    );
                                                  }

                                                  if (success &&
                                                      _sc.hasClients) {
                                                    _sc.jumpTo(0);
                                                  }
                                                },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                if (_requesting) ...[
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    left: 0,
                                    bottom: 0,
                                    child: ColoredBox(
                                      color: cs.surface.withAlpha(150),
                                    ),
                                  ),

                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    left: 0,
                                    bottom: 0,
                                    child: Align(
                                      alignment: AlignmentGeometry.center,
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ParaRangeDialouge extends StatefulWidget {
  final int currIdx;
  final int minLow;
  final int maxUp;
  final int lower;
  final int upper;
  final String title;

  const _ParaRangeDialouge({
    required this.currIdx,
    required this.minLow,
    required this.maxUp,
    required this.lower,
    required this.upper,
    this.title = 'Show Paras',
  });

  static Future<Bounds?> show({
    required BuildContext context,
    required int currIdx,
    required int minLow,
    required int maxUp,
    required int lower,
    required int upper,
    String title = 'Show Paras',
  }) {
    assert(minLow <= maxUp);
    // print('min: $minLow \t max: $maxUp \t curr: $currIdx');
    return showDialog<Bounds>(
      context: context,
      builder: (context) {
        return _ParaRangeDialouge(
          currIdx: currIdx,
          minLow: minLow,
          maxUp: maxUp,
          lower: lower,
          upper: upper,
          title: title,
        );
      },
    );
  }

  @override
  State<_ParaRangeDialouge> createState() => _ParaRangeDialougeState();
}

class _ParaRangeDialougeState extends State<_ParaRangeDialouge> {
  late int _currIdx;
  late int _minLow;
  late int _maxUp;
  late int _lower;
  late int _upper;
  late final String _title;

  @override
  void initState() {
    super.initState();
    _currIdx = widget.currIdx;
    _minLow = widget.minLow;
    _maxUp = widget.maxUp;
    _lower = widget.lower;
    _upper = widget.upper;
    _title = widget.title;
  }

  void changeLower(int delta) {
    setState(() {
      _lower = (_lower + delta).clamp(_minLow, _currIdx);
    });
  }

  void changeUpper(int delta) {
    setState(() {
      _upper = (_upper + delta).clamp(_currIdx, _maxUp);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // icon: const Icon(Icons.linear_scale),
      title: Text(
        '$_title ${(1 + _upper - _lower).toString().padLeft(2, " ")}',
        textAlign: TextAlign.center,
      ),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              _ValueEditor(
                label: 'Start',
                value: _lower,
                onDecrease: _lower <= _minLow ? null : () => changeLower(-1),
                onIncrease: _currIdx == _lower ? null : () => changeLower(1),
              ),
              const Icon(Icons.arrow_right_alt_outlined, size: 28),
              _ValueEditor(
                label: 'End',
                value: _upper,
                dash: _currIdx == _upper && _currIdx == _lower,
                onDecrease: _currIdx == _upper ? null : () => changeUpper(-1),
                onIncrease: _upper >= _maxUp ? null : () => changeUpper(1),
              ),
            ],
          ),

          const SizedBox(height: 20),
          FilledButton.tonalIcon(
            label: Text('Reset'),
            icon: Icon(Icons.restore),
            onPressed: _lower == _currIdx && _upper == _currIdx
                ? null
                : () {
                    setState(() {
                      _lower = _currIdx;
                      _upper = _currIdx;
                    });
                  },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, (lower: _lower, upper: _upper));
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}

typedef Bounds = ({int lower, int upper});

class _ValueEditor extends StatelessWidget {
  final String label;
  final int value;
  final bool dash;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  const _ValueEditor({
    required this.label,
    required this.value,
    this.dash = false,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 18,
      children: [
        // Text(label, style: Theme.of(context).textTheme.titleMedium),
        IconButton.filledTonal(
          visualDensity: VisualDensity.compact,
          onPressed: onDecrease,
          icon: const Icon(Icons.remove),
        ),

        Text(
          dash ? '-' : '$value',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),

        IconButton.filledTonal(
          visualDensity: VisualDensity.compact,
          onPressed: onIncrease,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.c,
    required this.isUser,
    required this.afterChange,
    this.onReply,
  });

  final Chat c;
  final bool isUser;
  final VoidCallback? onReply; // parent wires this to its reply handler
  final VoidCallback afterChange; // parent wires this to its reply handler

  Future<void> _showBubbleMenu(
    BuildContext context,
    String text,
    Offset globalPosition,
  ) async {
    // HapticFeedback.mediumImpact(); // tactile confirmation before menu appears

    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;

    final result = await showMenu<String>(
      context: context,
      // anchor the menu exactly where the finger pressed
      position: RelativeRect.fromRect(
        Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        const PopupMenuItem(
          value: 'copy',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.copy_outlined, size: 18),
              SizedBox(width: 10),
              Text('Copy'),
            ],
          ),
        ),
        if (!isUser)
          PopupMenuItem(
            value: 'info',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outlined, size: 18),
                SizedBox(width: 10),
                Text('Info'),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'rm',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outlined, size: 18),
              SizedBox(width: 10),
              Text('Delete'),
            ],
          ),
        ),
        // PopupMenuItem(
        //   value: 'reply',
        //   child: Row(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       Icon(Icons.reply_outlined, size: 18),
        //       SizedBox(width: 10),
        //       Text('Reply'),
        //     ],
        //   ),
        // ),
      ],
    );

    if (!context.mounted) return; // guard after every async gap

    switch (result) {
      case 'copy':
        await Clipboard.setData(ClipboardData(text: text));
        if (context.mounted) {
          showSnack(
            context,
            'Copied to clipboard',
            duration: Duration(seconds: 1),
          );
        }
        break;
      case 'reply':
        onReply?.call();
        break;

      case 'rm':
        final confirm = await showConfirmDialog(
          context,
          'Delete Chat?',
          message: 'Delete current chat.',
          confirmText: 'Delete',
          destructive: true,
        );
        if (confirm != true) return;

        await AppChatsDb.deleteChat(c.id!);
        if (context.mounted) afterChange();
        break;

      case 'info':
        showSnack(
          context,
          'Model used: ${c.model.isEmpty ? "Unkown" : c.model}',
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = isUser ? c.user : c.bot;
    final dir = _direction(text);

    return GestureDetector(
      onDoubleTapDown: (details) =>
          _showBubbleMenu(context, text, details.globalPosition),
      // onTapDown: (details) => // bad cause scroll time act
      //     _showBubbleMenu(context, text, details.globalPosition),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text, textDirection: dir, style: L.arStyle),
      ),
    );
  }
}

TextDirection _direction(String text) {
  final firstLetter = RegExp(r'\p{L}', unicode: true).firstMatch(text);

  if (firstLetter == null) {
    return TextDirection.ltr;
  }

  final char = firstLetter.group(0)!;

  return RegExp(r'[\u0600-\u06FF]').hasMatch(char)
      ? TextDirection.rtl
      : TextDirection.ltr;
}
