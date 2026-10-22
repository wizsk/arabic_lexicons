import 'dart:async';

import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/datas/word_store.dart';
import 'package:arabic_lexicons/first_run.dart';
import 'package:arabic_lexicons/history/page.dart';
import 'package:arabic_lexicons/key_shortcuts.dart';
import 'package:arabic_lexicons/lex/data.dart';
import 'package:arabic_lexicons/lex/isolate.dart';
import 'package:arabic_lexicons/lex/rearrange_dicts.dart';
import 'package:arabic_lexicons/lex/res.dart';
import 'package:arabic_lexicons/lex/sugg/widgets.dart';
import 'package:arabic_lexicons/lex/utils.dart';
import 'package:arabic_lexicons/lex/word_dict_picker.dart';
import 'package:arabic_lexicons/main_widgets.dart';
import 'package:arabic_lexicons/pages/fams/fams.dart';
import 'package:arabic_lexicons/reader/find_word.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:arabic_lexicons/utils/scroll_funcs.dart';
import 'package:arabic_lexicons/utils/toast_snack.dart';
import 'package:arabic_lexicons/widgets/lex_word_confirm.dart';
import 'package:arabic_lexicons/widgets/reader_theme.dart';
import 'package:arabic_lexicons/widgets/selection_chip.dart';
import 'package:arabic_lexicons/widgets/small_icon_btns.dart';
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
    this.initialDict,
    // this.initialText = kDebugMode ? 'عاملون' : '',
    // this.initialDict = kDebugMode ? Dict.mujamulGhoni : null,
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

    sc.addListener(() {
      final shouldShowUpDownArrow = sc.offset > 100;

      if (shouldShowUpDownArrow != _datas.shouldShowUpDownArrow) {
        setState(() {
          _datas.shouldShowUpDownArrow = shouldShowUpDownArrow;
        });
      }
    });

    if (!_isPopup) {
      // TODO: fix this
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
      delCurr: () {
        final w = _datas.selectedWord;
        if (w.isEmpty && mounted) return;
        _deleteWord(w, true, keyShort: true);
      },
      clearWords: () async {
        if (!mounted || _controller.text.isEmpty) return;

        final res = await showLexWordClearAllConfirm(
          context,
          extramsg: keyShortConfirmMsg,
        );

        if (res == true && mounted) {
          setState(() {
            _controller.clear();
            _datas.resetAll();
          });
        }
      },
      closePopup: () {
        if (!_isPopup) return;
        if (mounted) Navigator.of(context).pop();
      },
      help: () {
        if (!mounted) return;
        showShortcutsHelpOverlay(context);
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

    final modifierPressed = isMac
        ? HardwareKeyboard.instance.isMetaPressed
        : HardwareKeyboard.instance.isControlPressed;

    if (!modifierPressed) {
      return false;
    }

    final k = event.logicalKey;
    for (final b in _keyBindings) {
      if (b.key == k) {
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
                            : () => _deleteWord(w, selected),
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
                itemCount: allDictsOrd.length + 1,
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, index) {
                  if (index == allDictsOrd.length) {
                    // do stuff
                    return Selection(
                      Dict.reOrdLabel,
                      onTab: () {
                        showDictReorderScreen(
                          context,
                          after: () {
                            if (!context.mounted) return;

                            if (allDictsOrd.contains(_datas.selectedDict)) {
                              setState(() {});
                              _datas.scrollSelectors();
                            } else {
                              _datas.selectedDict = allDictsOrd.first;
                              _datas.getAndShowResORSugg(context);
                              _datas.scrollSelectors();
                            }
                          },
                        );
                      },
                      selected: false,
                      backgroundColor: bg,
                      avatar: Icon(
                        Icons.settings,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      isAr: L.isAr,
                      color: Theme.of(context).colorScheme.outline,
                      tooltip: 'Open reorder lexicons popup',
                    );
                  }
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

  Widget _appbarPopupOptions(BuildContext context, bool hasSideActionButtons) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        switch (value) {
          case 'fam':
            ArabicFamilyList.open(context);
            break;

          case 'hist':
            HistPage.open(context);
            break;

          case 'hidef':
            setState(() {
              _floatingBtnExpanded = !_floatingBtnExpanded;
            });
            break;

          case 'switch':
            await appConf.saveScrollLexSelection(!appConf.scrollLexSelection);
            if (context.mounted) setState(() {});
            MsgSv.showSnackbarMsg(
              'Scrollable selections ${appConf.scrollLexSelection ? 'on' : 'off'}',
              duration: const Duration(seconds: 0, milliseconds: 700),
            );
            break;
        }
      },
      itemBuilder: (context) => [
        ...[
          const PopupMenuItem(
            value: 'fam',
            child: Row(
              children: [
                Icon(Icons.account_tree_outlined),
                SizedBox(width: 10),
                Text("Verb Families"),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'hist',
            child: Row(
              children: [
                Icon(Icons.history),
                SizedBox(width: 10),
                Text("Search History"),
              ],
            ),
          ),
          const PopupMenuDivider(),
        ],

        PopupMenuItem(
          value: 'switch',
          child: Row(
            children: [
              Icon(
                appConf.scrollLexSelection
                    ? Icons.check_box_outlined
                    : Icons.check_box_outline_blank,
              ),
              const SizedBox(width: 10),
              const Text('Scrollable selections'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _lexAppBar(BuildContext context, bool hasSideActionButtons) {
    final datas = _datas;
    final noSelectedWord = datas.selectedWord.isEmpty;
    final dictName = '${datas.selectedDict.name}${noSelectedWord ? '' : ':'}';

    Widget title = Text(dictName, style: L.arStyleIf, textDirection: L.dir);

    if (datas.selectedWord.isNotEmpty) {
      title = Row(
        textDirection: L.dir,
        // textDirection: TextDirection.rtl,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 4.0,
        children: [
          title,
          Flexible(
            child: Text(
              datas.selectedWord.replaceAll('_', ' ').takeMax(12),
              style: L.arStyle,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    final actions = <Widget>[
      if (!hasSideActionButtons)
        IconButton(
          tooltip:
              '${_floatingBtnExpanded ? 'Hide' : 'Show'} floating action buttons',
          icon: Icon(
            _floatingBtnExpanded
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          color: Theme.of(context).colorScheme.primary,
          onPressed: () {
            setState(() {
              _floatingBtnExpanded = !_floatingBtnExpanded;
            });
          },
        ),
      _appbarPopupOptions(context, hasSideActionButtons),
    ];

    return datas.state.isSug
        ? AppBar(
            title: title,
            forceMaterialTransparency: true,
            actions: actions,
          )
        : Directionality(
            textDirection: TextDirection.ltr,
            child: SliverAppBar(
              title: title,
              titleSpacing: 0.0,
              floating: true,
              snap: appConf.hideAppbar,
              pinned: !appConf.hideAppbar,
              actions: actions,
            ),
          );
  }

  void _deleteWord(
    final String word,
    final bool selected, {
    final bool keyShort = false,
  }) async {
    if (word.isEmpty) return;

    if (appConf.lexWordDelConfirm) {
      final res = await showLexWordDelConfirm(
        context,
        word,
        extramsg: keyShort ? keyShortConfirmMsg : '',
      );
      if (res != true) return;
    }

    final index = _datas.words.indexOf(word);
    if (index == -1) return;
    _datas.words.removeAt(index);

    _controller.text = _datas.words.join(' ');

    if (_datas.words.isEmpty) {
      _datas.resetAll();
      if (mounted) setState(() {});
      return;
    }

    if (selected) {
      final next = index == 0 ? 0 : index - 1;
      _datas.selectedWord = _datas.words[next];
    }

    if (mounted) {
      _datas.getAndShowResORSugg(context);
    }
  }

  bool _floatingBtnExpanded = true;

  (bool, Widget) _floatingBtn(
    BuildContext context,
    ColorScheme cs,
    bool willShowSugg,
    EdgeInsets padd,
  ) {
    const empty = SizedBox.shrink(key: ValueKey("floating-btn-srink"));

    if (!_floatingBtnExpanded) return (false, empty);

    const minSize = 44.00;
    const maxSize = 54.0;

    // size icon total size
    final totalIconListSize = maxSize + 50;

    final sh = MediaQuery.sizeOf(context).height;

    final hasSpaceinSides =
        sh > 520.0 &&
        padd.right - 16 > (appConf.readerSidePadd + totalIconListSize);

    final iconBtnSize = hasSpaceinSides
        ? maxSize
        : (L.fontSize == null ? minSize : L.fontSize! * 1.85).clamp(
            minSize,
            maxSize,
          );

    final datas = _datas;
    final bm =
        datas.selectedWord.isNotEmpty && WordStore.isBm(datas.selectedWord);

    Widget b({
      required IconData icon,
      required VoidCallback? onPressed,
      VoidCallback? onLongPress,
      required String tooltip,
      final IconButtonSizedColor scheme = IconButtonSizedColor.normal,
    }) => iconButtonSized(
      context,
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed,
      onLongPress: onLongPress,
      scheme: scheme,
      size: iconBtnSize,
      iconSize: iconBtnSize / 2,
    );

    final divs = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: iconBtnSize / 2,
        maxHeight: iconBtnSize / 2,
      ),
      child: hasSpaceinSides
          ? Divider(indent: 2, thickness: 1.5)
          : VerticalDivider(
              indent: 2,
              width: 6,
              thickness: 1.5,
              color: cs.outlineVariant,
            ),
    );

    final btns = separatedList(
      separatorBuilder: (_) {
        return divs;
      },
      list: [
        if (_floatingBtnExpanded || hasSpaceinSides) ...[
          b(
            icon: datas.state.isSug ? Icons.directions : Icons.auto_awesome,
            tooltip: 'Toggle search suggestions',
            onPressed:
                datas.selectedWord.isNotEmpty &&
                    appConf.showSearchSugg &&
                    !datas.state.isQuering
                ? () async {
                    final ss = datas.state.isSug;
                    await datas.getAndShowResORSugg(
                      context,
                      forceSugg: !ss,
                      forceRes: ss,
                    );
                  }
                : null,
          ),
          b(
            icon: Icons.image_search_outlined,
            tooltip: 'Search current word in saved book entries',
            onPressed: datas.selectedWord.isEmpty
                ? null
                : () {
                    FindWordReaderPage.open(context, datas.selectedWord);
                  },
          ),
          b(
            icon: bm ? Icons.bookmark_remove : Icons.bookmark_add_outlined,
            scheme: bm ? IconButtonSizedColor.err : IconButtonSizedColor.normal,
            tooltip: bm ? 'Unbookmark' : 'BookMark',
            onPressed: datas.selectedWord.isEmpty
                ? null
                : () async {
                    if (bm) {
                      final confirm = await showConfirmDialog(
                        context,
                        'Remove Bookmark',
                        message: 'Remove: ${datas.selectedWord}',
                        destructive: true,
                        confirmText: 'Remove',
                      );
                      if (confirm != true) return;
                      await WordStore.rmBM(datas.selectedWord);
                    } else {
                      await WordStore.addBM(datas.selectedWord);
                    }
                    if (mounted) setState(() {});
                  },
          ),
          b(
            icon: willShowSugg ? Icons.arrow_downward : Icons.arrow_upward,
            tooltip: willShowSugg
                ? 'Go bottom (or long press to go to top)'
                : 'Go top (or long press to go to bottom)',
            onPressed: !willShowSugg && datas.resultsAreEmpty
                ? null
                : () {
                    postFrame((_) {
                      final sc = _datas.scrollController;
                      if (!sc.hasClients) return;

                      sc.animateTo(
                        0.0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                      );
                    });
                  },
            onLongPress: () {
              scrollToBottomSmooth(_datas.scrollController);
            },
          ),
        ],

        if (!hasSpaceinSides)
          b(
            icon: Icons.cancel_outlined,
            tooltip: 'Minimize',
            onPressed: () {
              setState(() {
                _floatingBtnExpanded = !_floatingBtnExpanded;
              });
            },
          ),
      ],
    );

    final child = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: padd.right + (hasSpaceinSides ? -totalIconListSize : 12.0),
      ),
      child: Align(
        alignment: hasSpaceinSides
            ? Alignment.bottomRight
            : _floatingBtnExpanded
            ? Alignment.bottomCenter
            : Alignment.bottomRight,
        child: Container(
          margin: EdgeInsetsGeometry.only(bottom: 16),
          key: const ValueKey('floating-options'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: cs.surfaceContainer,
            boxShadow: hasSpaceinSides
                ? null
                : [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.1),
                      blurRadius: 12,
                    ),
                  ],
            border: BoxBorder.all(color: cs.outlineVariant, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: hasSpaceinSides
              ? Column(mainAxisSize: MainAxisSize.min, children: btns)
              : Row(mainAxisSize: MainAxisSize.min, children: btns),
        ),
      ),
    );

    return (hasSpaceinSides, child);
  }

  Widget _dictView(
    BuildContext context,
    TextDirection dir,
    bool willShowSugg,
    EdgeInsets padd,
    ColorScheme cs,
    bool floatingBtnOnSides,
  ) {
    final arTxtTheme = appConf.readerTS(context);
    return Directionality(
      textDirection: dir,
      child: CustomScrollView(
        key: ValueKey((_datas.selectedDict, _datas.selectedWord, _datas.state)),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        // physics: NeverScrollableScrollPhysics(),
        reverse: willShowSugg,
        controller: _datas.scrollController,
        slivers: [
          if (!willShowSugg) _lexAppBar(context, floatingBtnOnSides),

          SliverPadding(
            padding: _datas.sugg.isEmpty && _datas.resultsAreEmpty
                ? EdgeInsets.zero
                : willShowSugg
                ? padd.copyWith(
                    bottom: floatingBtnOnSides || !_floatingBtnExpanded
                        ? 0
                        : 68,
                  )
                : padd.copyWith(top: 12),
            sliver: _mainDict(context, cs, arTxtTheme),
          ),
        ],
      ),
    );
  }

  Widget _searchSectin(
    BuildContext context,
    EdgeInsets padd,
    Color bg,
    bool floatingBtnOnSides,
  ) {
    final children = [
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
                    _showingScrollableSelection = !_showingScrollableSelection;
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

                  final res = await showWordPickerBottomSheet(context, _datas);

                  if (res != null && res.openSettings == true) {
                    postFrame(
                      (_) => showDictReorderScreen(
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

                  if ((newWord || previousDict != _datas.selectedDict) &&
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
                  suffixIcon: _floatingBtnExpanded || floatingBtnOnSides
                      ? null
                      : IconButton(
                          tooltip: 'Show floating action buttons',
                          icon: Icon(Icons.apps),
                          onPressed: () {
                            setState(() {
                              _floatingBtnExpanded = true;
                            });
                          },
                        ),
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
    ];

    return Material(
      color: bg,
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
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

    final padd = appConf.readerPadd(context, bottom: scrollPaddingBottom + 68);

    final (floatingBtnOnSides, floatingBtn) = _floatingBtn(
      context,
      cs,
      willShowSugg,
      padd,
    );

    // if (kDebugMode) debugPrint('rebuild at: ${formatDateTime(context)}');
    return ReaderThemed(
      child: Scaffold(
        appBar: willShowSugg
            ? _lexAppBar(context, floatingBtnOnSides) as AppBar
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
                  child: Stack(
                    children: [
                      _dictView(
                        context,
                        dir,
                        willShowSugg,
                        padd,
                        cs,
                        floatingBtnOnSides,
                      ),
                      floatingBtn,
                    ],
                  ),
                ),
                _searchSectin(context, padd, bg, floatingBtnOnSides),
              ],
            ),
          ),
        ),
        // floatingActionButton: FloatingActionButton(
        //   onPressed: () => showDictReorderSheet(context),
        // ),
      ),
    );
  }
}
