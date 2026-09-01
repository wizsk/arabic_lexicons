import 'dart:async';

import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/first_run.dart';
import 'package:arabic_lexicons/key_shortcuts.dart';
import 'package:arabic_lexicons/lex/data.dart';
import 'package:arabic_lexicons/lex/isolate.dart';
import 'package:arabic_lexicons/lex/rearrange_dicts.dart';
import 'package:arabic_lexicons/lex/res.dart';
import 'package:arabic_lexicons/lex/sugg/widgets.dart';
import 'package:arabic_lexicons/lex/utils.dart';
import 'package:arabic_lexicons/lex/widgets.dart';
import 'package:arabic_lexicons/lex/word_dict_picker.dart';
import 'package:arabic_lexicons/main_widgets.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:arabic_lexicons/widgets/selection_chip.dart';
import 'package:arabic_lexicons/widgets/lex_word_confirm.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class SearchLexicons extends StatefulWidget {
  final bool isPopup;
  final String initialText;
  final Dict? initialDict;

  const SearchLexicons({
    super.key,
    this.isPopup = false,
    this.initialText = '',
    // this.initialText = kDebugMode ? 'عمل وقت' : '',
    this.initialDict,
  });

  @override
  State<SearchLexicons> createState() => _SearchLexiconsState();
}

class _SearchLexiconsState extends State<SearchLexicons>
    with WidgetsBindingObserver {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  // final _autoScrollControler = AutoScrollController();
  late bool _isPopup;

  late final List<KeyBinding> _keyBindings;

  late final SearchLexiconsDatas _datas;

  bool _showingScrollableSelection = true;
  final _scrollableSelectionSc = AutoScrollController();
  final _scrollableSelectionDictSc = AutoScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    touggleFullScreen();

    _isPopup = widget.isPopup;
    _controller = TextEditingController(text: widget.initialText);

    final sc = AutoScrollController(
      viewportBoundaryGetter: () {
        final top = MediaQuery.of(context).padding.top + 18;
        return Rect.fromLTRB(0, top, 0, 0);
      },
    );

    _datas = SearchLexiconsDatas(
      selectedDict: widget.initialDict ?? allDictsOrd.first,
      scrollController: sc,
      onChangeTxt: _onChangeTxt,
      setState: () {
        if (mounted) setState(() {});
      },
      scrollableSelection: _scrollableSelectionSc,
      scrollableSelectionDict: _scrollableSelectionDictSc,
    );

    // this is mainly for the appbar

    sc.addListener(() {
      final appbarColor = readerAppBarColorBg(sc.offset);

      if (_datas.appbarReaderBg != appbarColor) {
        setState(() => _datas.appbarReaderBg = appbarColor);
      }
    });

    if (!_isPopup) {
      appConf.refetchLexResultsFunc = () => _datas.getAndShowResORSugg(context);

      // show msg
      showFirstRunPopupPostFrame(context);

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final shown = await appConf.showChangeChangelog(context);

        if (shown || !mounted) return;
        await appConf.playRating(context);
      });
    }

    // after initing
    if (widget.initialText.isNotEmpty) _onChangeTxt();

    if (appConf.showSearchSugg && !Isolates.suggInited) {
      Isolates.suggInitCompleter.future.then((_) {
        if (mounted) setState(() {});
      });
    }

    _keyBindings = keybindingsGen(
      focusTF: () => _focusNode.requestFocus(),
      cycleWord: _cycleWord,
      cycleDict: _cycleDict,
      tgleScSl: () async {
        if (!appConf.scrollLexSelection) return;
        if (!mounted) return;
        setState(() {
          _showingScrollableSelection = !_showingScrollableSelection;
        });
      },
      tglAr: () async {
        await appConf.saveUseMoreArabicToggle();
        if (!mounted) return;
        setState(() {});
      },
    );

    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    WidgetsBinding.instance.removeObserver(this);

    _scrollableSelectionSc.dispose();
    _scrollableSelectionDictSc.dispose();
    _controller.dispose();
    _focusNode.dispose();
    _datas.scrollController.dispose();
    if (!_isPopup) {
      appConf.rmRefetchLexResultsFunc();
      // showStatusBar();
      // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // debugPrint('STATE: $state');
    if (state == AppLifecycleState.resumed) {
      WakelockController.toggle();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    touggleFullScreen();
  }

  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final isMac = defaultTargetPlatform == TargetPlatform.macOS;
    final modifierPressed = isMac
        ? HardwareKeyboard.instance.isMetaPressed
        : HardwareKeyboard.instance.isControlPressed;

    if (modifierPressed) {
      return false;
    }

    for (final b in _keyBindings) {
      if (b.key == event.logicalKey) {
        if (mounted) b.action();
        return true;
      }
    }
    return false;
  }

  void _cycleWord(bool n) {
    final wl = _datas.words.length;
    if (wl <= 1) return;

    var idx = _datas.words.indexOf(_datas.selectedWord);
    if (idx == -1) return;

    int newIdx;
    if (n) {
      idx++;
      newIdx = idx < wl ? idx : 0;
    } else {
      idx--;
      newIdx = idx < 0 ? wl - 1 : idx;
    }
    if (mounted) {
      _datas.selectedWord = _datas.words[newIdx];
      _datas.getAndShowResORSugg(context);
    }
  }

  void _cycleDict(bool n) {
    final dl = allDictsOrd.length;
    if (dl <= 1) return;

    var idx = allDictsOrd.indexOf(_datas.selectedDict);
    if (idx == -1) return;

    int newIdx;
    if (n) {
      idx++;
      newIdx = idx < dl ? idx : 0;
    } else {
      idx--;
      newIdx = idx < 0 ? dl - 1 : idx;
    }

    if (mounted) {
      _datas.selectedDict = allDictsOrd[newIdx];
      _datas.suggDictSorted.clear();
      _datas.getAndShowResORSugg(context);
    }
  }

  void _setSate() => setState(() {});

  void toggleWLSelectionMethod() async {
    await appConf.saveScrollLexSelection(!appConf.scrollLexSelection);
    if (!context.mounted) return;
    setState(() {});
    if (appConf.scrollLexSelection) {
      _datas.scrollSelectors();
    }
  }

  int? _selectionOffsetOld;
  Timer? _debouce;
  Future<void> _onChangeTxt({String? appendTxt}) async {
    // this is for adding words by clicking on roots in the results it
    if (appendTxt != null) {
      final t = _controller.text;
      final newText = "$t${t.isNotEmpty ? ' ' : ''}$appendTxt";

      _controller.text = newText;

      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: newText.length),
      );
    }
    _selectionOffsetOld = _controller.selection.base.offset;
    await onTextChanged(context, _controller, _datas, _setSate);
  }

  Widget _mainDict(BuildContext context, ColorScheme cs, TextStyle arTxtTheme) {
    if (_datas.state.isEmpty) {
      return noRes(
        context,
        currWord: _datas.selectedWord,
        showOpenReaderBtn: !_isPopup,
      );
    }

    if (_datas.state.isQuering) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_datas.state.isRes) {
      if (_datas.resultsAreEmpty) {
        return noRes(context, currWord: _datas.selectedWord);
      }
      return showRes(context, arTxtTheme, _datas, cs);
    }

    if (_datas.state.isSug) {
      return showSearchSugg(context, _controller, arTxtTheme, _datas, cs);
    }

    return noRes(
      context,
      currWord: _datas.selectedWord,
      noResAr: 'لا توجد نتائج أو اقتراحات لـ',
      noResEn: 'No Results or Suggestions for',
    );
  }

  static const _chipContainerMainHeight = 38.00;

  List<Widget> _scrolabeSelectors(final EdgeInsets padd, final Color bg) {
    final chipContainerHeight = L.fontSize == null
        ? _chipContainerMainHeight
        : (_chipContainerMainHeight * L.fontSize!) / 14;

    return [
      Visibility(
        visible: _datas.words.length > 1,
        maintainState: true,
        maintainSize: false,
        child: Padding(
          padding: EdgeInsetsGeometry.only(
            left: padd.right,
            right: padd.right,
            top: 6.0,
          ),
          child: SizedBox(
            height: chipContainerHeight,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Align(
                alignment: AlignmentGeometry.centerRight,
                child: ListView.separated(
                  shrinkWrap: true,
                  key: const PageStorageKey('word-selector'),
                  controller: _scrollableSelectionSc,
                  itemCount: _datas.words.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, index) {
                    final w = _datas.words[index];
                    final selected = w == _datas.selectedWord;

                    var label = w.replaceAll('_', ' ').trim();
                    if (label.length > 30) {
                      label = '${label.substring(0, 30)}…';
                    }

                    return AutoScrollTag(
                      key: ValueKey(index),
                      controller: _scrollableSelectionSc,
                      index: index,
                      child: Selection(
                        label,
                        selected: selected,
                        backgroundColor: bg,
                        onTab: () {
                          _datas.selectedWord = w;
                          _datas.suggDictSorted.clear();
                          if (context.mounted) {
                            _datas.getAndShowResORSugg(context);
                          }
                        },
                        onDelete: !appConf.lexWordRmIcon
                            ? null
                            : () async {
                                if (appConf.lexWordDelConfirm) {
                                  final res = await showLexWordDelConfirm(
                                    context,
                                    label,
                                  );
                                  if (res != true) return;
                                }

                                _datas.words.removeAt(index);
                                _controller.text = _datas.words.join(' ');

                                // _datas.words.isEmpty will never be true because we won't even show
                                // word picker if there is less than 2 words!

                                if (selected) {
                                  final next = index == 0 ? 0 : index - 1;
                                  _datas.selectedWord = _datas.words[next];
                                }

                                if (mounted) {
                                  _datas.getAndShowResORSugg(context);
                                }
                              },
                      ),
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                ),
              ),
            ),
          ),
        ),
      ),
      Padding(
        padding: EdgeInsetsGeometry.only(
          left: padd.right,
          right: padd.right,
          top: 6.0,
        ),
        child: SizedBox(
          height: chipContainerHeight,
          child: Directionality(
            textDirection: L.dir,
            child: Align(
              alignment: L.alignmentCenterLR,
              child: ListView.separated(
                shrinkWrap: true,
                controller: _scrollableSelectionDictSc,
                key: const PageStorageKey('dict-selector'),
                itemCount: allDictsOrd.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, index) {
                  final d = allDictsOrd[index];
                  final selected = d == _datas.selectedDict;

                  return AutoScrollTag(
                    key: ValueKey(index),
                    controller: _scrollableSelectionDictSc,
                    index: index,
                    child: Selection(
                      d.name,
                      tooltip: d.enLong,
                      onTab: () {
                        _datas.selectedDict = d;
                        _datas.suggDictSorted.clear();
                        if (context.mounted) {
                          _datas.getAndShowResORSugg(context);
                        }
                      },
                      selected: selected,
                      backgroundColor: bg,
                      isAr: L.isAr,
                    ),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(width: 6),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final arTxtTheme = appConf.readerTS(context);
    // final isAr = appSettingsNotifier.useMoreArabic;

    final bg = appConf.readerSurface(context);

    final cs = Theme.of(context).colorScheme;

    final willShowSugg = _datas.state.isSug;

    final dir = willShowSugg
        ? TextDirection.rtl
        : _datas.selectedDict == Dict.arEn ||
              _datas.selectedDict == Dict.hanswehr ||
              _datas.selectedDict == Dict.laneLexicon
        ? TextDirection.ltr
        : TextDirection.rtl;

    final padd = appConf.readerPadd(context);

    // if (kDebugMode) debugPrint('rebuild at: ${formatDateTime(context)}');
    return Scaffold(
      appBar: willShowSugg
          ? lexAppBar(context, _datas, _setSate) as AppBar
          : null,
      drawer: _isPopup ? null : buildDrawer(context),
      backgroundColor: bg,
      body: SafeArea(
        top: willShowSugg,
        bottom: !appConf.fullScreen,
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
                child: Directionality(
                  textDirection: dir,
                  child: CustomScrollView(
                    key: ValueKey((
                      _datas.selectedDict,
                      _datas.selectedWord,
                      _datas.state,
                    )),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    // physics: NeverScrollableScrollPhysics(),
                    reverse: willShowSugg,
                    controller: _datas.scrollController,
                    slivers: [
                      if (!willShowSugg) lexAppBar(context, _datas, _setSate),

                      SliverPadding(
                        padding: _datas.sugg.isEmpty && _datas.resultsAreEmpty
                            ? EdgeInsets.zero
                            : willShowSugg
                            ? padd.copyWith(bottom: 0)
                            : padd,
                        sliver: _mainDict(context, cs, arTxtTheme),
                      ),
                    ],
                  ),
                ),
              ),

              Divider(thickness: 0.5, height: 0),
              if (_showingScrollableSelection && appConf.scrollLexSelection)
                ..._scrolabeSelectors(padd, bg),
              Padding(
                padding: EdgeInsetsGeometry.symmetric(
                  horizontal: padd.right,
                  vertical: 8,
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    if (appConf.scrollLexSelection)
                      IconButton.filled(
                        tooltip: 'hide/show selections',
                        icon: _showingScrollableSelection
                            ? Icon(Icons.keyboard_arrow_down_rounded)
                            : Icon(Icons.keyboard_arrow_up_rounded),
                        onLongPress: toggleWLSelectionMethod,
                        onPressed: () {
                          setState(() {
                            _showingScrollableSelection =
                                !_showingScrollableSelection;
                          });

                          // it seems like we don't need it, if we use PageStorageKey(...)
                          _datas.scrollSelectors();
                        },
                      )
                    else
                      IconButton.filled(
                        icon: Icon(dictWordSelectModalOpenIcon),
                        onLongPress: toggleWLSelectionMethod,
                        onPressed: () async {
                          FocusManager.instance.primaryFocus?.unfocus();

                          final previousWordListSize = _datas.words.length;
                          final previousWord = _datas.selectedWord;
                          final previousDict = _datas.selectedDict;

                          final res = await showWordPickerBottomSheet(
                            context,
                            _datas,
                          );

                          if (res != null && res.openSettings == true) {
                            postFrame(
                              (_) => showDictReorderSheet(
                                context,
                                after: () {
                                  if (!context.mounted) return;
                                  setState(() {
                                    _datas.suggDictSorted.clear();
                                  });
                                },
                              ),
                            );
                          }

                          if (previousWordListSize != _datas.words.length) {
                            _controller.text = _datas.words.join(' ');
                          }

                          final newWord =
                              previousWord != _datas.selectedWord &&
                              _datas.selectedWord.isNotEmpty;

                          if ((newWord ||
                                  previousDict != _datas.selectedDict) &&
                              context.mounted) {
                            _datas.getAndShowResORSugg(context);
                          } else if (context.mounted) {
                            setState(() {});
                          }
                        },
                      ),
                    SizedBox(width: 5),
                    Expanded(
                      child: TextField(
                        onTap: () async {
                          if (_controller.selection.base.offset !=
                              _selectionOffsetOld) {
                            await _onChangeTxt();
                          }
                        },
                        controller: _controller,
                        focusNode: _focusNode,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.start,
                        onChanged: (_) async {
                          if (_debouce?.isActive ?? false) _debouce!.cancel();
                          _debouce = Timer(
                            const Duration(milliseconds: 200),
                            () async => await _onChangeTxt(),
                          );
                        },
                        // style: arTxtTheme,
                        style: L.arStyleSized,
                        decoration: InputDecoration(
                          hintText: L.p('Search Words', 'ابحث'),
                          hintTextDirection: L.dir,
                          prefixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _controller.clear();
                                _datas.resetAll();
                              });
                              // this is when it's focued but keyboard is not oppended
                              _focusNode.requestFocus();
                            },
                            icon: Icon(Icons.clear),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (appConf.fullScreen) const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => showDictReorderSheet(context),
      // ),
    );
  }
}
