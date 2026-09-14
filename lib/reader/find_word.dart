import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/pages/settings/settings.dart';
import 'package:arabic_lexicons/reader/book_entries_data.dart';
import 'package:arabic_lexicons/reader/data.dart';
import 'package:arabic_lexicons/reader/reader_utils.dart';
import 'package:arabic_lexicons/reader/reader_widgets.dart';
import 'package:arabic_lexicons/reader/settings.dart';
import 'package:arabic_lexicons/reader/settings_class.dart';
import 'package:arabic_lexicons/theme.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

Future<void> showOpendictOrFindword(
  BuildContext context,
  String word,
  VoidCallback onOpenDict,
  VoidCallback onFindWord,
  TextStyle ts,
) {
  return showDialog(
    context: context,
    useSafeArea: true,
    builder: (context) {
      return Dialog(
        constraints: BoxConstraints(maxWidth: 300),
        // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                word,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: ts.fontFamily,
                ),
              ),

              const SizedBox(height: 24),

              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: Icon(Icons.book),
                      label: Text('Open Lexicon'),
                      onPressed: () {
                        Navigator.pop(context);
                        onOpenDict();
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.search),
                      label: const Text("Find in Books"),
                      onPressed: () {
                        Navigator.pop(context);
                        onFindWord();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _FindWordEnry {
  final String title;
  final PeraEntries paras;

  const _FindWordEnry(this.title, this.paras);
}

Future<List<_FindWordEnry>> _yo(
  String w,
  String bPath,
  List<BookEntry> books,
  bool exatctMatch,
) async {
  final List<_FindWordEnry> res = [];

  bool matchExact(String word) => w == word;
  bool matchContains(String word) => word.contains(w);

  final matchFunc = exatctMatch ? matchExact : matchContains;

  for (final b in books) {
    final d = '${path.join(bPath, b.sha)}.txt';

    try {
      final text = File(d).readAsStringSync();
      final paras = cleanReaderInputAndPrepare(text);

      final PeraEntries en = [];

      for (final p in paras) {
        for (final e in p) {
          if (matchFunc(e.cl)) {
            en.add(p);
            break;
          }
        }
      }
      if (en.isNotEmpty) {
        res.add(_FindWordEnry(b.title, en));
      }
    } catch (_) {}
  }

  return res;
}

Future<List<_FindWordEnry>> _getData(String word, bool exactMatch) async {
  final books = ReaderInputPageData.bookEntries;
  final bpath = ReaderInputPageData.booksDirPath;
  return Isolate.run(() => _yo(word, bpath, books, exactMatch));
}

class FindWordReaderPage extends StatefulWidget {
  const FindWordReaderPage({super.key, required this.word});

  final String word;

  static Future<void> open(BuildContext context, String word) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FindWordReaderPage(word: word)),
    );
  }

  @override
  State<FindWordReaderPage> createState() => _FindWordReaderPageState();
}

class _FindWordReaderPageState extends State<FindWordReaderPage> {
  List<_FindWordEnry> _paras = [];
  late String _title;
  late ReaderPageSettings _rs;

  final _sc = ScrollController();

  // bool _isFabVisable = true;

  // File? _peraIndexSave;

  // /// this is used for indicating that it's auto scrolling
  // bool _initalAutoScrolling = false;

  // int _currPeraIndex = 0;

  @override
  void initState() {
    super.initState();
    touggleFullScreen();

    _title = widget.word;

    _rs = ReaderPageSettings.def().copyWith(
      isFindWordMode: true,
      findWordWord: widget.word,
    );
    _setOnChange();

    _init();
  }

  bool _exactMath = true;
  var _initState = InitState.not;

  Future<void> _init([bool firstRun = true]) async {
    if (_initState.isIniting) return;

    if (!firstRun) {
      setState(() {
        _initState = InitState.initing;
        _paras.clear();
      });
    }

    if (!ReaderInputPageData.inited) {
      await ReaderInputPageData.init();
    }

    final result = await _getData(widget.word, _exactMath);
    final count = result.isEmpty
        ? null
        : enToArNum(result.map((e) => e.paras.length).reduce((a, b) => a + b));

    setState(() {
      _paras = result;
      _title = count == null ? widget.word : '${widget.word} $count';
      _initState = InitState.done;
    });
  }

  @override
  void setState(VoidCallback fn) {
    if (!mounted) return;
    super.setState(fn);
  }

  @override
  void dispose() {
    _rs.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    touggleFullScreen();
    _setOnChange();

    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _setOnChange() {
    if (!_initState.isInited) return;
    _rs.onChange = () {
      setState(() {});
    };
  }

  // Future<void> _settingsPage(BuildContext context) async {
  //   await ReaderModeSettingsSheet.show(context, settings: _rs, paras: _paras);
  // }

  Widget _buildSliverAppBar(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SliverAppBar(
        floating: true,
        snap: appConf.hideAppbar,
        pinned: !appConf.hideAppbar,
        // backgroundColor: _readerAppBarColorBg
        //     ? appConf.readerSurface(context)
        //     : null,
        title: Text(_title, textDirection: TextDirection.rtl, style: L.arStyle),
        centerTitle: false,
        actions: [
          SizedBox(
            width: 140,
            child: FilledButton.icon(
              icon: Icon(Icons.search),
              label: Text(_exactMath ? 'Exact' : 'Contains'),
              onPressed: !_initState.isInited
                  ? null
                  : () {
                      _exactMath = !_exactMath;
                      _init(false);
                    },
            ),
          ),
        ],
        // actions: [...scrollUpDownBtns(_sc, _paras.length - 1)],
      ),
    );
  }

  List<Widget> _buildParagraphSliver(
    BuildContext context,
    EdgeInsets padd,
    TextStyle style,
    TextStyle styleLU,
    TextStyle highStyletyle,
  ) {
    final cs = Theme.of(context).colorScheme;

    padd = padd.copyWith(top: 12, bottom: 22);
    return _paras.map((p) {
      return SliverPadding(
        padding: padd,
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.all(8.0).copyWith(bottom: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      p.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.ar
                          .copyWith(
                            color: cs.onSecondaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ),
              );
            }

            index--;
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: padd.right,
                vertical: paraSpaceInbetween(_rs.fontSize).right,
              ),
              child: ClickableParagraph(
                rs: _rs,
                index: index,
                peras: p.paras,
                style: style,
                styleLU: styleLU,
                highStyletyle: highStyletyle,
                cs: cs,
                textAlign: _rs.textAlign,
                onChange: () => setState(() {}),
                matchExact: _exactMath,
              ),
            );
          }, childCount: p.paras.length + 1),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    // final cs = theme.colorScheme;

    final style = !_initState.isInited
        ? TextStyle()
        : appConf
              .readerTS(context)
              .copyWith(
                fontFamily: _rs.fontFam,
                fontSize: _rs.fontSize,
                fontFamilyFallback: [fontKitab],
                height: _rs.fontHeight,
              );

    // final isFabVisable = appConf.hideAppbar ? _isFabVisable : true;

    // const lookedUpColor = Color(0xFF2F5FAF); // strong readable blue
    // final lookedUpColor = theme.brightness == Brightness.light
    //     ? Color.fromARGB(255, 0, 0, 255)
    //     : Color.fromARGB(255, 165, 165, 255); // deep teal

    // final styleLU = style.copyWith(
    //   color: cs.onTertiaryContainer,
    //   backgroundColor: cs.tertiaryContainer,
    // );

    // final highStyle = style.copyWith(
    //   color: cs.onErrorContainer,
    //   backgroundColor: cs.errorContainer,
    // );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final styleLU = style.copyWith(
      backgroundColor: isDark ? foreignWordBgDark : foreignWordBg,
    );
    final highStyle = style.copyWith(
      backgroundColor: isDark ? bookmarkWordBgDark : bookmarkWordBg,
    );

    final EdgeInsets padd = _initState.isInited
        ? _rs.readerPadd(context)
        : EdgeInsets.all(0);

    return PopScope(
      // canPop: false,
      // onPopInvokedWithResult: (didPop, _) {
      //   if (didPop) return;
      //   exitReaderPage(context);
      // },
      child: Scaffold(
        // backgroundColor: appConf.readerSurface(context),
        body: GestureStack(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: CustomScrollView(
              controller: _sc,
              key: ValueKey(_exactMath),
              slivers: [
                _buildSliverAppBar(context),

                if (!_initState.isInited)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_paras.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text('No Results')),
                  )
                else ...[
                  ..._buildParagraphSliver(
                    context,
                    padd,
                    style,
                    styleLU,
                    highStyle,
                  ),

                  SliverToBoxAdapter(
                    child: SizedBox(height: scrollPadding.bottom),
                  ),
                ],
              ],
            ),
          ),
        ),
        floatingActionButton: !_initState.isInited
            ? null
            :
              // : AnimatedSlide(
              //     duration: Duration(milliseconds: 300),
              //     offset: isFabVisable ? Offset.zero : Offset(0, 2),
              //     child: AnimatedOpacity(
              //       duration: Duration(milliseconds: 300),
              //       opacity: isFabVisable ? 1.0 : 0.0,
              //       child:
              FloatingActionButton(
                child: Icon(Icons.menu_book),
                onPressed: () async {
                  final result = await showModalBottomSheet<String>(
                    context: context,
                    showDragHandle: true,
                    useSafeArea: true,
                    isScrollControlled: true,
                    constraints: const BoxConstraints(maxWidth: 600),
                    builder: (context) {
                      // final theme = Theme.of(context);
                      // final cs = theme.colorScheme;

                      return SingleChildScrollView(
                        padding: scrollPaddingBottmSheet(context),
                        child: Column(
                          spacing: 12,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_paras.isNotEmpty)
                              const SettingsSectionSurface(
                                children: [
                                  ReaderSelectionTile(
                                    icon: Icons.vertical_align_top,
                                    title: 'Scroll to top',
                                    subtitle: 'Jump to the beginning',
                                    value: 'scroll-top',
                                  ),
                                  ReaderSelectionTile(
                                    icon: Icons.vertical_align_bottom,
                                    title: 'Scroll to bottom',
                                    subtitle: 'Jump to the end',
                                    value: 'scroll-bot',
                                  ),
                                ],
                              ),

                            /// Main actions
                            SettingsSectionSurface(
                              children: [
                                ReaderSelectionTile(
                                  icon: Icons.settings,
                                  title: 'Settings',
                                  subtitle: 'Reader preferences',
                                  value: 'settings',
                                ),
                                if (_paras.isNotEmpty)
                                  ReaderSelectionTile(
                                    icon: Icons.copy_all,
                                    title: 'Copy Text',
                                    subtitle: 'Copy original content',
                                    value: 'copy-txt',
                                  ),
                              ],
                            ),

                            /// Exit (destructive)
                            const SettingsSectionSurface(
                              // mode: SettingsSectionSurfaceMode.alert,
                              children: [
                                ReaderSelectionTile(
                                  icon: Icons.logout,
                                  title: 'Exit Reader',
                                  subtitle: 'Return to input screen',
                                  value: 'exit',
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
                      Navigator.of(context).pop();
                      break;

                    case 'settings':
                      await ReaderModeSettingsSheet.show(
                        context,
                        settings: _rs,
                        paras: null,
                      );
                      break;

                    case 'scroll-top':
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!_sc.hasClients) return;
                        _sc.animateTo(
                          0.0,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                        );
                      });

                      break;

                    case 'scroll-bot':
                      if (_sc.hasClients) {
                        WidgetsBinding.instance.addPostFrameCallback((_) async {
                          if (!_sc.hasClients) return;

                          double prePos = 0.0;
                          while (prePos < _sc.position.maxScrollExtent) {
                            if (!_sc.hasClients) return;

                            prePos = _sc.position.maxScrollExtent;

                            await _sc.animateTo(
                              prePos,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.linear,
                            );
                          }
                        });
                      }
                      break;
                  }
                },
              ),
        //     ),
        //   ),
      ),
    );
  }
}
