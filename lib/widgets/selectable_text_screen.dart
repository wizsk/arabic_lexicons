import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/pages/width_padd.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

enum _ChatData { none, selected, all }

class Chat {
  final String user;
  final String bot;
  final String prompt;
  final DateTime? time;

  const Chat({
    required this.user,
    required this.bot,
    required this.prompt,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
    'user': user,
    'bot': bot,
    'prompt': prompt,
    if (time != null) 'time': time!.millisecondsSinceEpoch,
  };

  static Chat fromJson(Map<String, dynamic> json) {
    DateTime? t;
    final unix = json['time'] as int?;
    if (unix != null) {
      t = DateTime.fromMillisecondsSinceEpoch(unix, isUtc: true);
    }
    return Chat(
      user: json['user'] as String,
      bot: json['bot'] as String,
      prompt: json['prompt'] as String,
      time: t,
    );
  }
}

abstract final class Chats {
  static List<Chat> chats = [];

  static int get length => chats.length;

  static const _fileName = 'chats.json';

  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<void> add(Chat c) async {
    chats.add(c);
    return saveToFile();
  }

  static Future<void> saveToFile() async {
    try {
      final file = await _getFile();

      final tmpFile = File('${file.path}.tmp');

      final data = jsonEncode(chats.map((e) => e.toJson()).toList());

      await tmpFile.writeAsString(data, flush: true);

      // atomic replace
      if (await file.exists()) {
        await file.delete();
      }
      await tmpFile.rename(file.path);
    } catch (_) {}
  }

  static bool _inited = false;
  static Future<void> load() async {
    if (_inited) return;
    _inited = true;

    try {
      final file = await _getFile();

      if (!await file.exists()) {
        chats = [];
        return;
      }

      final content = await file.readAsString();
      final List decoded = jsonDecode(content);

      chats = decoded
          .map((e) => Chat.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('while loading chat history: $e');
    }
  }
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

  final List<Chat> _chats = Chats.chats;

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

  void _setTxt() {
    _txt = widget.fullTextFunc.call(_start, _end);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final th = theme.textTheme;
    final cs = theme.colorScheme;

    final readerPadd = readerPadding(
      context,
      maxWidth: appConf.maxWidth,
      sidePadd: appConf.padding,
    );

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

                      ListView.builder(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        controller: _sc,
                        reverse: true,
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: sidePadd,
                        ),
                        itemCount: _chats.length,
                        itemBuilder: (context, index) {
                          index = (_chats.length - 1) - index;
                          final c = _chats[index];

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: ChatBubble(
                                  text: c.user,
                                  isUser: true,
                                  onReply: () {},
                                ),
                              ),

                              const SizedBox(height: 8),

                              Align(
                                alignment: Alignment.centerLeft,
                                child: ChatBubble(
                                  text: c.bot,
                                  isUser: false,
                                  onReply: () {},
                                ),
                              ),

                              const SizedBox(height: 16),
                            ],
                          );
                        },
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
                                        // ActionChip(
                                        //   visualDensity: VisualDensity.compact,
                                        //   avatar: Icon(
                                        //     Icons.auto_awesome_rounded,
                                        //     size: 18,
                                        //   ),
                                        //   label: Text('Gemini'),
                                        //   onPressed: () {
                                        //     // setState(() {
                                        //     // });
                                        //   },
                                        // ),
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

                                            Chats.chats.clear();
                                            Chats.saveToFile();

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

                                                  final pre = switch (_include) {
                                                    _ChatData.none => '',
                                                    _ChatData.all => _txt,
                                                    _ChatData.selected =>
                                                      _selectedTxtSaved != null
                                                          ? '$_selectedTxtSaved'
                                                          : '',
                                                  };

                                                  final (
                                                    msg,
                                                    prompt,
                                                  ) = pre.isEmpty
                                                      ? (question, question)
                                                      : (
                                                          '$pre\n\n$question',
                                                          '''<context>
                            $pre
</context>

Question: $question

(Reply in ${_chatDirection == TextDirection.ltr ? 'English' : 'Arabic'})''',
                                                        );

                                                  FocusManager
                                                      .instance
                                                      .primaryFocus
                                                      ?.unfocus();

                                                  setState(() {
                                                    _requesting = true;
                                                  });

                                                  try {
                                                    final r =
                                                        await getGeminiReply(
                                                          prompt,
                                                        );

                                                    Chats.chats.add(
                                                      Chat(
                                                        user: msg,
                                                        prompt: prompt,
                                                        bot: r,
                                                        time: DateTime.now(),
                                                      ),
                                                    );

                                                    Chats.saveToFile();

                                                    if (!context.mounted) {
                                                      return;
                                                    }

                                                    setState(() {
                                                      _tc.clear();
                                                      _requesting = false;
                                                      _selectedTxtSaved = null;
                                                      _tabController.index = 1;
                                                    });

                                                    if (_sc.hasClients) {
                                                      _sc.jumpTo(0);
                                                    }

                                                    Chats.saveToFile();
                                                  } catch (e) {
                                                    if (kDebugMode) {
                                                      debugPrint('$e');
                                                    }

                                                    showInfoDialog(
                                                      context,
                                                      'Error',
                                                      message:
                                                          'Please try again, could not get any response.',
                                                      constraints: true,
                                                    );

                                                    setState(() {
                                                      _requesting = false;
                                                    });
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
    required this.text,
    required this.isUser,
    this.onReply,
  });

  final String text;
  final bool isUser;
  final VoidCallback? onReply; // parent wires this to its reply handler

  Future<void> _showBubbleMenu(
    BuildContext context,
    Offset globalPosition,
  ) async {
    HapticFeedback.mediumImpact(); // tactile confirmation before menu appears

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
      items: const [
        PopupMenuItem(
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
      case 'reply':
        onReply?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dir = _direction(text);

    return GestureDetector(
      onLongPressStart: (details) =>
          _showBubbleMenu(context, details.globalPosition),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          textDirection: dir,
          style: dir == TextDirection.rtl ? L.arStyle : null,
        ),
      ),
    );
  }
}

TextDirection _direction(String text) {
  final arabic = RegExp(r'[\u0600-\u06FF]');
  return arabic.hasMatch(text) ? TextDirection.rtl : TextDirection.ltr;
}

Future<String> getGeminiReply(String message) async {
  // Pass your Google AI Studio API key via compile-time variables
  const apiKey = String.fromEnvironment('GK', defaultValue: '');
  const apiKey2 = String.fromEnvironment('GK2', defaultValue: '');
  const apiKey3 = String.fromEnvironment('GK3', defaultValue: '');
  const apiKey4 = String.fromEnvironment('GK4', defaultValue: '');

  const keys = [
    if (apiKey != '') apiKey,
    if (apiKey2 != '') apiKey2,
    if (apiKey3 != '') apiKey3,
    if (apiKey4 != '') apiKey4,
  ];

  const models = [
    // 'gemma-4-26b-a4b-it', // gives crazy replies
    'gemini-3.5-flash',
    'gemini-3-flash',
    'gemini-2.5-flash',
    'gemini-3.1-flash-lite',
    'gemini-2.5-flash-lite',
  ];

  // Native endpoint string using the stable free-tier flash model
  for (final m in models) {
    for (final k in keys) {
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
          return parts[0]["text"].toString().trim();
        }
      } catch (e) {
        // if (kDebugMode) debugPrint('while getting res: $e');
      }
    }
  }
  throw Exception('No response fround from all the models');
}

Future<String> getOpenAIReply(String message) async {
  const apiKey = 'api-key';

  final res = await http.post(
    Uri.parse('https://api.openai.com/v1/chat/completions'),
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      "model": "gpt-4o-mini",
      "messages": [
        {
          "role": "system",
          "content":
              "You are a helpful assistant for an Arabic reader app. "
              "Answer questions about the book the user is reading. "
              "Keep replies VERY short, plain text only, no emojis, no formatting, no extra explanation unless necessary. "
              "There may be a context section then user quesion. if the quesiton in arabic then reply in arabic otherwise just english",
        },
        {"role": "user", "content": message},
      ],
      "temperature": 0.3,
    }),
  );

  final data = jsonDecode(res.body);
  return data["choices"][0]["message"]["content"].trim();
}
