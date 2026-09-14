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

Future<(List<_FindWordEnry>, int)> _yo(
  String w,
  String bPath,
  List<BookEntry> books,
) async {
  final List<_FindWordEnry> res = [];
  var totalWords = 0;

  for (final b in books) {
    final d = '${path.join(bPath, b.sha)}.txt';

    try {
      final text = File(d).readAsStringSync();
      final paras = cleanReaderInputAndPrepare(text);

      final PeraEntries en = [];

      for (final p in paras) {
        for (final e in p) {
          if (e.cl == w) {
            totalWords += p.length;
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

  return (res, totalWords);
}

Future<(List<_FindWordEnry>, int)> _getData(String word) async {
  final books = ReaderInputPageData.bookEntries;
  final bpath = ReaderInputPageData.booksDirPath;
  return Isolate.run(() => _yo(word, bpath, books));
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

    _init();
  }

  bool _inited = false;
  Future<void> _init() async {
    if (!ReaderInputPageData.inited) {
      await ReaderInputPageData.init();
    }

    final result = await _getData(widget.word);

    _paras = result.$1;

    setState(() {
      _inited = true;
    });
  }

  @override
  void setState(VoidCallback fn) {
    if (!mounted) return;
    super.setState(fn);
  }

  @override
  void dispose() {
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
    if (!_inited) return;
    _rs.onChange = () {
      if (mounted) setState(() {});
    };
  }

  // Future<void> _settingsPage(BuildContext context) async {
  //   await ReaderModeSettingsSheet.show(context, settings: _rs, paras: _paras);
  // }

  Widget _buildSliverAppBar(BuildContext context, TextStyle arabicFontStyle) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SliverAppBar(
        floating: true,
        snap: appConf.hideAppbar,
        pinned: !appConf.hideAppbar,
        // backgroundColor: _readerAppBarColorBg
        //     ? appConf.readerSurface(context)
        //     : null,
        title: Text(
          _title,
          textDirection: TextDirection.rtl,
          style: TextStyle(fontFamily: arabicFontStyle.fontFamily),
        ),
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
                padding: const EdgeInsets.all(8.0),
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
              ),
            );
          }, childCount: _paras.length + 1),
        ),
      );
    }).toList();
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

    // final isFabVisable = appConf.hideAppbar ? _isFabVisable : true;

    // const lookedUpColor = Color(0xFF2F5FAF); // strong readable blue
    // final lookedUpColor = theme.brightness == Brightness.light
    //     ? Color.fromARGB(255, 0, 0, 255)
    //     : Color.fromARGB(255, 165, 165, 255); // deep teal

    final styleLU = style.copyWith(
      color: cs.onTertiaryContainer,
      backgroundColor: cs.tertiaryContainer,
    );

    final highStyle = style.copyWith(
      color: cs.onErrorContainer,
      backgroundColor: cs.errorContainer,
    );

    final EdgeInsets padd = _inited
        ? _rs.readerPadd(context)
        : EdgeInsets.all(0);

    return PopScope(
      // canPop: false,
      // onPopInvokedWithResult: (didPop, _) {
      //   if (didPop) return;
      //   exitReaderPage(context);
      // },
      child: Scaffold(
        appBar: _inited
            ? null
            : AppBar(
                title: Text(
                  L.p('Loading...', 'جارٍ التحميل...'),
                  textDirection: L.dir,
                  style: L.arStyleIf,
                ),
                // backgroundColor: appConf.readerSurface(context),
              ),
        // backgroundColor: appConf.readerSurface(context),
        body: GestureStack(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: !_inited
                ? const Center(child: CircularProgressIndicator())
                : CustomScrollView(
                    slivers: [
                      _buildSliverAppBar(context, style),
                      if (_paras.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: Text('No Results')),
                        )
                      else
                        ..._buildParagraphSliver(
                          context,
                          padd,
                          style,
                          styleLU,
                          highStyle,
                        ),

                      if (_paras.isNotEmpty)
                        SliverToBoxAdapter(
                          child: SizedBox(height: scrollPadding.bottom),
                        ),
                    ],
                  ),
          ),
        ),
        floatingActionButton: !_inited
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
                            const SettingsSectionSurface(
                              children: [
                                ReaderSelectionTile(
                                  icon: Icons.menu_book,
                                  title: 'Chapters & Paragraphs',
                                  subtitle: 'Navigate book',
                                  value: 'inspect',
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
                  }
                },
              ),
        //     ),
        //   ),
      ),
    );
  }
}
