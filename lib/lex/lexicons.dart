import 'dart:async';

import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/first_run.dart';
import 'package:ara_dict/lex/data.dart';
import 'package:ara_dict/lex/isolate.dart';
import 'package:ara_dict/lex/rearrange_dicts.dart';
import 'package:ara_dict/lex/res.dart';
import 'package:ara_dict/lex/sugg/widgets.dart';
import 'package:ara_dict/lex/utils.dart';
import 'package:ara_dict/lex/widgets.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/utils.dart';
import 'package:flutter/material.dart';
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

  late final SearchLexiconsDatas _datas;

  bool _showingScrollableSelection = true;
  final _scrollableSelectionSc = AutoScrollController();

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
      setState: setState,
      scrollableSelection: _scrollableSelectionSc,
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

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

  void _setSate() => setState(() {});

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

  @override
  Widget build(BuildContext context) {
    final arTxtTheme = appConf.readerTS(context);
    // final isAr = appSettingsNotifier.useMoreArabic;

    final bg = appConf.readerSurface(context);

    final cs = Theme.of(context).colorScheme;

    final chipTextStyleDictWord = L.arStyle.copyWith(color: cs.onSurface);
    final chipTextStyleDict = L.arStyleOrNew.copyWith(color: cs.onSurface);

    final willShowSugg = _datas.isShowingSugg && _datas.sugg.isNotEmpty;

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
        child: Column(
          children: [
            // FocusManager.instance.primaryFocus?.unfocus();
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_focusNode.hasFocus) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  }
                },
                child: Directionality(
                  textDirection: dir,
                  child: CustomScrollView(
                    key: ValueKey((
                      _datas.selectedDict,
                      _datas.selectedWord,
                      _datas.isShowingSugg,
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
                        sliver: _datas.isSelectedWordEmpty
                            ? noRes(context)
                            : !willShowSugg &&
                                  _datas.resLoaded &&
                                  _datas.resultsAreEmpty
                            ? (Isolates.suggCanBeShown
                                  ? noRes(
                                      context,
                                      currWord: _datas.selectedWord,
                                      noResAr: 'لا توجد نتائج أو اقتراحات لـ',
                                      noResEn: 'No Results or Suggestions for',
                                    )
                                  : noRes(
                                      context,
                                      currWord: _datas.selectedWord,
                                    ))
                            : _datas.isShowingSugg
                            ? (willShowSugg
                                  ? showSearchSugg(
                                      context,
                                      _controller,
                                      arTxtTheme,
                                      _datas,
                                      cs,
                                    )
                                  : noRes(
                                      context,
                                      currWord: _datas.selectedWord,
                                      noResAr: "لا توجد اقتراحات لـ",
                                      noResEn: "No Suggestions for",
                                    ))
                            : _datas.resLoaded
                            ? showRes(context, arTxtTheme, _datas, cs)
                            : const SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Divider(thickness: 0.5, height: 0),
            if (_showingScrollableSelection && appConf.scrollLexSelection) ...[
              Visibility(
                visible: _datas.words.length > 1,
                maintainState: true,
                maintainSize: false,
                child: Padding(
                  padding: EdgeInsetsGeometry.only(
                    left: padd.right,
                    right: padd.right,
                    top: 8.0,
                  ),
                  child: SizedBox(
                    height: 40.0,
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Align(
                        alignment: AlignmentGeometry.centerRight,
                        child: ListView.separated(
                          shrinkWrap: true,
                          // key: const PageStorageKey('word-selector'),
                          controller: _scrollableSelectionSc,
                          itemCount: _datas.words.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (_, index) {
                            final w = _datas.words[index];
                            final selected = w == _datas.selectedWord;
                            return AutoScrollTag(
                              key: ValueKey(index),
                              controller: _scrollableSelectionSc,
                              index: index,
                              child: ChoiceChip(
                                selected: selected,
                                labelStyle: selected
                                    ? chipTextStyleDictWord.copyWith(
                                        color: cs.onPrimary,
                                      )
                                    : chipTextStyleDictWord,
                                selectedColor: cs.primary,
                                backgroundColor: bg,
                                side: BorderSide(
                                  color: selected
                                      ? cs.primary
                                      : cs.outlineVariant,
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                showCheckmark: false,
                                label: Text(
                                  w,
                                  textDirection: TextDirection.rtl,
                                  style: L.arStyle,
                                ),
                                onSelected: (_) {
                                  _datas.selectedWord = w;
                                  _datas.suggDictSorted.clear();
                                  if (context.mounted) {
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
                  top: 8.0,
                ),
                child: SizedBox(
                  height: 40.0,
                  child: Directionality(
                    textDirection: L.dir,
                    child: ListView.separated(
                      shrinkWrap: true,
                      key: const PageStorageKey('dict-selector'),
                      itemCount: allDictsOrd.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (_, index) {
                        final d = allDictsOrd[index];
                        final selected = d == _datas.selectedDict;

                        return ChoiceChip(
                          selected: selected,
                          labelStyle: selected
                              ? chipTextStyleDict.copyWith(color: cs.onPrimary)
                              : chipTextStyleDict,
                          selectedColor: cs.primary,
                          backgroundColor: bg,
                          side: BorderSide(
                            color: selected ? cs.primary : cs.outlineVariant,
                          ),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          showCheckmark: false,
                          label: Text(
                            d.name,
                            textDirection: L.dir,
                            style: L.arStyleIf,
                          ),
                          onSelected: (_) {
                            _datas.selectedDict = d;
                            _datas.suggDictSorted.clear();
                            if (context.mounted) {
                              _datas.getAndShowResORSugg(context);
                            }
                          },
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                    ),
                  ),
                ),
              ),
            ],
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
                      onPressed: () {
                        setState(() {
                          _showingScrollableSelection =
                              !_showingScrollableSelection;
                        });
                      },
                    )
                  else
                    IconButton.filled(
                      icon: Icon(dictWordSelectModalOpenIcon),
                      onPressed: () async {
                        FocusManager.instance.primaryFocus?.unfocus();

                        final res = await showWordPickerBottomSheet(
                          context,
                          _datas,
                        );

                        if (res == null) return;

                        if (res.openSettings == true) {
                          WidgetsBinding.instance.addPostFrameCallback(
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
                          return;
                        }

                        if (res.word != null) {
                          _datas.selectedWord = res.word!;
                        }
                        if (res.d != null) {
                          _datas.selectedDict = res.d!;
                          _datas.suggDictSorted.clear();
                        }
                        if (context.mounted) {
                          _datas.getAndShowResORSugg(context);
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
                      style: L.arStyle,
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
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () => showDictReorderSheet(context),
      // ),
    );
  }
}
