import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:arabic_lexicons/alphabets.dart';
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
import 'package:flutter/services.dart';
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
                      label: const Text("Find Word"),
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

Future<(PeraEntries, int)> _yo(
  String w,
  String bPath,
  List<String> books,
) async {
  final PeraEntries res = [];
  var totalWords = 0;

  for (final s in books) {
    final d = '${path.join(bPath, s)}.txt';

    try {
      final text = File(d).readAsStringSync();
      final paras = cleanReaderInputAndPrepare(text);

      for (final p in paras) {
        for (final e in p) {
          if (e.cl == w) {
            totalWords += p.length;
            res.add(p);
            break;
          }
        }
      }
    } catch (_) {}
  }

  return (res, totalWords);
}

Future<(PeraEntries, int)> _getData(String word) async {
  final books = ReaderInputPageData.bookEntries.map((b) => b.sha).toList();
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
  PeraEntries _paras = [];
  late final int _totalWords;
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
    _totalWords = result.$2;

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

        return Padding(
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
                        SliverPadding(
                          padding: padd,
                          sliver: _buildParagraphSliver(
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
                      final theme = Theme.of(context);
                      final cs = theme.colorScheme;

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
                        paras: _paras,
                      );
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
                  }
                },
              ),
        //     ),
        //   ),
      ),
    );
  }
}
