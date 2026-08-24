import 'dart:async';
import 'dart:io';

import 'package:arabic_lexicons/alphabets.dart';
import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/main_widgets.dart';
import 'package:arabic_lexicons/pages/settings.dart';
import 'package:arabic_lexicons/reader/book_entries_data.dart';
import 'package:arabic_lexicons/reader/data.dart';
import 'package:arabic_lexicons/reader/inspect.dart';
import 'package:arabic_lexicons/reader/reader_utils.dart';
import 'package:arabic_lexicons/reader/reader_widgets.dart';
import 'package:arabic_lexicons/reader/settings.dart';
import 'package:arabic_lexicons/reader/settings_class.dart';
import 'package:arabic_lexicons/reader/word_lists.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:arabic_lexicons/widgets/scroll.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class ReaderPage extends StatefulWidget {
  final PeraEntries? paras;
  final String? bookHash;
  final bool? isQasidah;

  const ReaderPage({
    super.key,
    this.paras,
    required this.bookHash,
    this.isQasidah,
  });

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> with WidgetsBindingObserver {
  late final PeraEntries _paras;
  late final int _totalWords;
  late String _title;
  late ReaderPageSettings _rs;
  late final List<GlobalKey> _keys;
  late final AutoScrollController _sc;

  bool _isFabVisable = true;

  File? _peraIndexSave;

  /// this is used for indicating that it's auto scrolling
  bool _initalAutoScrolling = false;

  int _currPeraIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    touggleFullScreen();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _init();
      // appConf.playRating(context);
    });
  }

  bool _inited = false;
  Future<void> _init() async {
    try {
      String? bookHash = widget.bookHash;

      if (widget.paras != null) {
        _paras = widget.paras!;

        // incase of a new book
        // bookHash = widget.bookHash; // see above
      } else {
        if (bookHash == null) {
          if (appConf.lastRoute != Routes.readerPage ||
              appConf.lastBook.isEmpty) {
            throw Exception('book valid hash not provided');
          }
          bookHash = appConf.lastBook;
          await ReaderInputPageData.init();
          if (!ReaderInputPageData.inited) {
            throw Exception('cound not init readerinputpage data');
          }

          if (ReaderInputPageData.bookEnsUnord.indexWhere(
                (b) => b.sha == bookHash,
              ) ==
              -1) {
            throw Exception('cound not find book in the book entries');
          }
        }

        final data = await File(
          ReaderInputPageData.bookDataDest(bookHash),
        ).readAsString();
        _paras = cleanReaderInputAndPrepare(data);
      }

      _rs = await ReaderPageSettings.loadFromFile(
        bookHash ?? '',
        isQasidah: widget.isQasidah,
      );

      if (_rs.bookHash.isNotEmpty) {
        appConf.saveRoute(Routes.readerPage, bookHash: _rs.bookHash);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('while opeing book: $e');

      if (mounted) {
        showSnack(context, 'Could not open requested book enty');
        Navigator.pushReplacementNamed(context, Routes.readerInput);
      }
      return;
    }

    _sc = AutoScrollController(
      viewportBoundaryGetter: () =>
          Rect.fromLTRB(0, MediaQuery.of(context).padding.top + 18, 0, 0),
    );
    _sc.addListener(_onScroll);

    _keys = List.generate(_paras.length, (_) => GlobalKey(), growable: false);
    _title = _paras.readerAppbarTitle(_rs.isRmTashkil);

    // await Future.delayed(Duration(milliseconds: 1000));
    setState(() {
      _inited = true;
    });

    _setOnChange();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_rs.bookHash.isEmpty) {
        showSnack(
          context,
          "This book entry won't be saved",
          duration: Duration(seconds: 6),
        );
        return;
      }

      _peraIndexSave = await ReaderPageSettings.lastReadPosFile(_rs.bookHash);

      // inilization done, now check if we need to scroll
      if (!_rs.saveLastPeraIdx) return;

      int idx = 0;
      try {
        final idxStr = await _peraIndexSave?.readAsString();
        if (idxStr != null) idx = int.tryParse(idxStr) ?? 0;
      } catch (_) {}

      if (idx == 0 || !_sc.hasClients) return;

      _currPeraIndex = idx;
      _initalAutoScrolling = true;

      _sc.scrollToIndex(
        idx,
        preferPosition: AutoScrollPosition.begin,
        duration: const Duration(microseconds: 100),
      );
    });

    int totalWords = 0;
    for (int i = 0; i < _paras.length; i++) {
      totalWords += _paras[i].length;
    }
    _totalWords = totalWords;

    _rs.saveToFile();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    try {
      _scrollPosBuf?.cancel();
      _sc.dispose();
    } catch (_) {}

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    touggleFullScreen();
    _setOnChange();

    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WakelockController.toggle();
    }
  }

  void _setOnChange() {
    if (!_inited) return;
    _rs.onChange = () {
      if (mounted) setState(() {});
    };
  }

  Timer? _scrollPosBuf;
  bool _readerAppBarColorBg = true;
  void _onScroll() {
    final appbarColor = readerAppBarColorBg(_sc.offset);
    if (_readerAppBarColorBg != appbarColor) {
      setState(() => _readerAppBarColorBg = appbarColor);
    }

    final sd = _sc.position.userScrollDirection;
    if (sd == ScrollDirection.reverse && _isFabVisable) {
      setState(() {
        _isFabVisable = false;
      });
    } else if (sd == ScrollDirection.forward && !_isFabVisable) {
      setState(() {
        _isFabVisable = true;
      });
    }
    _scrollPosBuf?.cancel();
    _scrollPosBuf = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;

      if (_initalAutoScrolling) {
        _initalAutoScrolling = false;
        return;
      }
      final height = MediaQuery.of(context).size.height;
      final minVisableHeight = height * 0.3;

      int? bestIndex;

      for (int i = 0; i < _keys.length; i++) {
        final ctx = _keys[i].currentContext;
        if (ctx == null) continue;

        final box = ctx.findRenderObject() as RenderBox;
        final pos = box.localToGlobal(Offset.zero);

        // pos.dy is negetive so we are subtracting
        final visableAmmount = box.size.height + pos.dy;

        if (pos.dy >= 0 || visableAmmount > minVisableHeight) {
          bestIndex = i;
          if (_rs.isQasidah && i % 2 != 0) {
            bestIndex = i - 1;
          }
          break;
        }
      }

      if (bestIndex != null) {
        // if (kDebugMode) {
        //   debugPrint('saved: $bestIndex -> ${_peraIndexSave?.path} -- ${_paras[bestIndex].first.ar}');
        // }
        if (_currPeraIndex == bestIndex) return;
        _currPeraIndex = bestIndex;
        if (_rs.bookHash.isNotEmpty) {
          try {
            await _peraIndexSave?.writeAsString('$bestIndex');
          } catch (_) {}
        }
      }
    });
  }

  Future<void> _settingsPage(BuildContext context) async {
    await ReaderModeSettingsSheet.show(context, settings: _rs, paras: _paras);
  }

  Widget _buildSliverAppBar(BuildContext context, TextStyle arabicFontStyle) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SliverAppBar(
        floating: true,
        snap: appConf.hideAppbar,
        pinned: !appConf.hideAppbar,
        backgroundColor: _readerAppBarColorBg
            ? appConf.readerSurface(context)
            : null,
        title: Text(
          _title,
          textDirection: TextDirection.rtl,
          style: TextStyle(fontFamily: arabicFontStyle.fontFamily),
        ),
        actions: [...scrollUpDownBtns(_sc, _paras.length - 1)],
      ),
    );
  }

  Widget _buildQasidahSliver(
    BuildContext context,
    TextStyle style,
    TextStyle styleLU,
    TextStyle highStyletyle,
  ) {
    final align = _rs.isQasidahCentered ? TextAlign.center : TextAlign.right;
    final cs = Theme.of(context).colorScheme;

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        return AutoScrollTag(
          controller: _sc,
          key: _keys[index],
          index: index,
          child: Padding(
            padding: paraSpaceInbetween(_rs.fontSize),
            child: ClickableBayt(
              index: index,
              rs: _rs,
              paras: _paras,
              style: style,
              styleLU: styleLU,
              highStyletyle: highStyletyle,
              cs: cs,
              textAlign: align,
              onChange: () => setState(() {}),
            ),
          ),
        );
      }, childCount: _paras.length),
    );
  }

  Widget _buildParagraphSliver(
    BuildContext context,
    TextStyle style,
    TextStyle styleLU,
    TextStyle highStyletyle,
  ) {
    final cs = Theme.of(context).colorScheme;

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final first = _paras[index].length == 1 ? _paras[index][0] : null;

        return AutoScrollTag(
          controller: _sc,
          key: _keys[index],
          index: index,
          child: Padding(
            padding: paraSpaceInbetween(_rs.fontSize),
            child: first != null && first.cl.isEmpty
                ? Center(
                    child: Text(
                      first.ar,
                      style: ArabicNormalizer.isArabicNum(first.ar)
                          ? style.copyWith(fontWeight: FontWeight.bold)
                          : style,
                    ),
                  )
                : ClickableParagraph(
                    rs: _rs,
                    index: index,
                    peras: _paras,
                    style: style,
                    styleLU: styleLU,
                    highStyletyle: highStyletyle,
                    cs: cs,
                    textAlign: _rs.textAlign,
                    onChange: () => setState(() {}),
                  ),
          ),
        );
      }, childCount: _paras.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final style = !_inited
        ? TextStyle()
        : appConf
              .readerTS(context)
              .copyWith(
                fontFamily: _rs.fontFam,
                fontSize: _rs.fontSize,
                fontFamilyFallback: [fontKitab],
                height: _rs.fontHeight,
              );

    final isFabVisable = appConf.hideAppbar ? _isFabVisable : true;

    // const lookedUpColor = Color(0xFF2F5FAF); // strong readable blue
    final lookedUpColor = theme.brightness == Brightness.light
        ? Color.fromARGB(255, 0, 0, 255)
        : Color.fromARGB(255, 165, 165, 255); // deep teal

    final styleLU = style.copyWith(color: lookedUpColor);

    final highStyle = style.copyWith(color: cs.error);

    final EdgeInsets padd = _inited
        ? _rs.readerPadd(context)
        : EdgeInsets.all(0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        exitReaderPage(context);
      },
      child: Scaffold(
        appBar: _inited
            ? null
            : AppBar(
                title: Text(
                  L.p('Loading...', 'جارٍ التحميل...'),
                  textDirection: L.dir,
                  style: L.arStyleIf,
                ),
                backgroundColor: appConf.readerSurface(context),
              ),
        drawer: buildDrawer(context),
        backgroundColor: appConf.readerSurface(context),
        body: GestureStack(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: !_inited
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
                    controller: _sc,
                    slivers: [
                      _buildSliverAppBar(context, style),
                      SliverPadding(
                        padding: padd,
                        sliver: _rs.isQasidah
                            ? _buildQasidahSliver(
                                context,
                                style,
                                styleLU,
                                highStyle,
                              )
                            : _buildParagraphSliver(
                                context,
                                style,
                                styleLU,
                                highStyle,
                              ),
                      ),
                    ],
                  ),
          ),
        ),
        floatingActionButton: !_inited
            ? null
            : AnimatedSlide(
                duration: Duration(milliseconds: 300),
                offset: isFabVisable ? Offset.zero : Offset(0, 2),
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 300),
                  opacity: isFabVisable ? 1.0 : 0.0,
                  child: FloatingActionButton(
                    child: Icon(Icons.menu_book),
                    onPressed: () async {
                      int readWords = 0;
                      for (int i = 0; i < _currPeraIndex; i++) {
                        readWords += _paras[i].length;
                      }
                      final readPercent = ((readWords * 100) / _totalWords)
                          .round();
                      final result = await showModalBottomSheet<String>(
                        context: context,
                        showDragHandle: true,
                        useSafeArea: true,
                        isScrollControlled: true,
                        constraints: const BoxConstraints(maxWidth: 600),
                        builder: (context) {
                          final theme = Theme.of(context);
                          final cs = theme.colorScheme;

                          return SingleChildScrollView(
                            padding: scrollPaddingBottmSheet(context),
                            child: Column(
                              // spacing: 12,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                /// Progress
                                SettingsSectionSurface(
                                  children: [
                                    Tooltip(
                                      message:
                                          'Read words (scrolled past) determine the %.',
                                      margin: EdgeInsets.symmetric(
                                        horizontal: scrollPadding.left,
                                      ),
                                      triggerMode: TooltipTriggerMode.tap,
                                      // exitDuration: const Duration(seconds: 1),
                                      child: SizedBox(
                                        width: double.infinity,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 18,
                                            bottom: 18,
                                            right: 8,
                                            left: 16,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            spacing: 16,
                                            children: [
                                              SizedBox(
                                                width: 64,
                                                height: 64,
                                                child: Stack(
                                                  fit: StackFit.expand,
                                                  children: [
                                                    CircularProgressIndicator(
                                                      value: readPercent / 100,
                                                      strokeWidth: 6,
                                                      backgroundColor: cs
                                                          .surfaceContainerHighest,
                                                      color: cs.primary,
                                                      strokeCap:
                                                          StrokeCap.round,
                                                    ),
                                                    Center(
                                                      child: Text(
                                                        '$readPercent%',
                                                        style: theme
                                                            .textTheme
                                                            .titleMedium,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                spacing: 2,
                                                children: [
                                                  _StatRow(
                                                    label: 'Words',
                                                    current: readWords,
                                                    total: _totalWords,
                                                  ),
                                                  _StatRow(
                                                    label: 'Paras',
                                                    current: _currPeraIndex,
                                                    total: _paras.length,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                /// Navigation
                                const SettingsSectionSurface(
                                  children: [
                                    ReaderSelectionTile(
                                      icon: Icons.menu_book,
                                      title: 'Chapters & Paragraphs',
                                      subtitle: 'Navigate book',
                                      value: 'inspect',
                                    ),
                                    // ReaderSelectionTile(
                                    //   icon: Icons.vertical_align_top,
                                    //   title: 'Scroll to top',
                                    //   subtitle: 'Jump to the beginning',
                                    //   value: 'scroll-top',
                                    // ),
                                    // ReaderSelectionTile(
                                    //   icon: Icons.vertical_align_bottom,
                                    //   title: 'Scroll to bottom',
                                    //   subtitle: 'Jump to the end',
                                    //   value: 'scroll-bot',
                                    // ),
                                    ReaderSelectionTile(
                                      icon: Icons.list,
                                      title: 'Foreign & Bookmarked',
                                      subtitle:
                                          'Word list for the current book',
                                      value: 'lookedup',
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                /// Main actions
                                const SettingsSectionSurface(
                                  children: [
                                    ReaderSelectionTile(
                                      icon: Icons.settings,
                                      title: 'Settings',
                                      subtitle: 'Reader preferences',
                                      value: 'settings',
                                    ),
                                    ReaderSelectionTile(
                                      icon: Icons.copy_all,
                                      title: 'Copy Text',
                                      subtitle: 'Copy original content',
                                      value: 'copy-txt',
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                /// Exit (destructive)
                                SettingsSectionSurface(
                                  mode: SettingsSectionSurfaceMode.alert,
                                  children: [
                                    ListTile(
                                      leading: const FilledIcon(
                                        Icons.logout,
                                        variant: FilledIconVariant.error,
                                        // outlined: false,
                                      ),
                                      title: Text(
                                        'Exit Reader',
                                        style: TextStyle(
                                          color: cs.onErrorContainer,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Return to input screen',
                                        style: TextStyle(
                                          color: cs.onErrorContainer.withAlpha(
                                            200,
                                          ),
                                        ),
                                      ),
                                      onTap: () =>
                                          Navigator.pop(context, 'exit'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );

                      if (result == null || !context.mounted) return;

                      switch (result) {
                        case 'exit':
                          exitReaderPage(context);
                          break;

                        case 'lookedup':
                          CBWordList.open(
                            context,
                            _paras,
                            _rs,
                          ).then((_) => setState(() {}));
                          break;

                        case 'settings':
                          _settingsPage(context);
                          break;

                        case 'inspect':
                          final idx = await showNavigateBook(
                            context,
                            _rs,
                            _paras,
                            _currPeraIndex,
                          );
                          if (idx == null) return;

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _sc.scrollToIndex(
                              idx,
                              duration: const Duration(milliseconds: 100),
                              preferPosition: AutoScrollPosition.begin,
                            );
                          });
                          break;

                        case 'copy-txt':
                          Clipboard.setData(
                            ClipboardData(
                              text: _paras
                                  .map((p) => p.map((w) => w.ar).join(" "))
                                  .join("\n"),
                            ),
                          ).then((_) {
                            if (context.mounted) {
                              showSnack(context, 'Text Copied');
                            }
                          });

                          break;

                        case 'scroll-top':
                        case 'scroll-bot':
                          if (_sc.hasClients) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _sc.scrollToIndex(
                                result == 'scroll-top' ? 0 : _paras.length - 1,
                                preferPosition: AutoScrollPosition.begin,
                                duration: const Duration(milliseconds: 100),
                              );
                            });
                          }
                          break;
                      }
                    },
                  ),
                ),
              ),
      ),
    );
  }
}

Future<bool?> exitReaderPage(BuildContext context, {bool exit = true}) async {
  if (!context.mounted) return false;
  final res = await showConfirmDialog(
    context,
    'Exit Reader',
    message: 'Go to reader input page?',
    // confirmText: 'Exit'
    destructive: true,
  );

  if (!context.mounted) return res;

  if (exit && res == true) {
    Navigator.pushReplacementNamed(context, Routes.readerInput);
  }

  return res;
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.current,
    required this.total,
  });

  final String label;
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          '$current',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '/ $total',
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
