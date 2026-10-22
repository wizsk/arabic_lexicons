import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/datas/lex_entry_bookmark.dart';
import 'package:arabic_lexicons/lex/def_card.dart';
import 'package:arabic_lexicons/lex/res.dart';
import 'package:arabic_lexicons/multi_selection.dart';
import 'package:arabic_lexicons/pages/lex_bm/def.dart';
import 'package:arabic_lexicons/pages/width_padd.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:arabic_lexicons/widgets/reader_theme.dart';
import 'package:flutter/material.dart';

class LexDefBmPage extends StatefulWidget {
  const LexDefBmPage({super.key});

  @override
  State<LexDefBmPage> createState() => _LexDefBmPageState();

  static Future<void> open(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LexDefBmPage()),
    );
  }
}

class _LexDefBmPageState extends State<LexDefBmPage> {
  final bool _isShowNewToOld = true;
  final ScrollController _scrollController = ScrollController();
  late final SelectionController<String> _selection;
  final _tc = TextEditingController();
  // String _shearced = '';

  late final List<LexEntryBmEnty> _defList;

  bool _inited = false;

  @override
  void initState() {
    super.initState();

    _selection = SelectionController(() {
      if (mounted) setState(() {});
    });

    LexEntryBm.getAll().then((v) {
      _defList = v;
      _inited = true;
      if (!mounted) return;
      setState(() {});
    });

    touggleFullScreen();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    touggleFullScreen();
  }

  @override
  void dispose() {
    _tc.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // List<String> _selectedWordsList() {
  //   return _selection.selected.toList();
  // }

  // void _onSearchChange(String s) {
  // if (!context.mounted) return;
  //     setState(() {
  //       _shearced = ArabicNormalizer.keepOnlyAr(s);
  //       if (_shearced.isEmpty) {
  //         // _words = _getDefWordList();
  //         return;
  //       }
  //
  //       final l = <(int, String)>[];
  //       for (final w in _getDefWordList()) {
  //         final idx = w.indexOf(_shearced);
  //         if (idx != -1) l.add((idx, w));
  //       }
  //       l.sort((a, b) => b.$1.compareTo(a.$1));
  //
  //       _words = l.map((e) => e.$2).toList(growable: false);
  //     });
  // }

  @override
  Widget build(BuildContext context) {
    final padd = uiPadding(context);
    // final cs = Theme.of(context).colorScheme;

    final ts = appConf.readerTS(context);

    final (fontFam, fontHeight) = appConf.useHansLaneDefRDStyle
        ? (appConf.readerFont, appConf.readerFontHeight)
        : (fontAmiri, htmlFontHeight);

    final fontSize = appConf.readerFontSize;
    // final isDark = Theme.of(context).brightness == Brightness.dark;
    // final hiColor = isDark ? bookmarkWordBgDark : bookmarkWordBg;

    return PopScope(
      canPop: !_selection.hasSelection,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_selection.hasSelection) {
          _selection.clear();
          return;
        }
        Navigator.pop(context);
      },
      child: ReaderThemed(
        child: Scaffold(
          body: GestureStack(
            child: Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: SliverAppBar(
                          floating: true,
                          snap: appConf.hideAppbar,
                          pinned: !appConf.hideAppbar,
                          title: _selection.appBarTitle("Saved Definitions"),
                        ),
                      ),
                      if (!_inited)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_defList.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: Text("Emtpty")),
                        )
                      else
                        SliverPadding(
                          padding: padd,
                          sliver: SliverList.separated(
                            itemCount: _defList.length,
                            separatorBuilder: (_, _) {
                              return spaceBetweenDefs;
                            },
                            itemBuilder: (context, visualIndex) {
                              final index = _isShowNewToOld
                                  ? _defList.length - 1 - visualIndex
                                  : visualIndex;

                              final def = _defList[index];
                              void onRemove() => _defList.removeAt(index);

                              final child = def.formatDef(
                                context,
                                ts: ts,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                hlFont: fontFam,
                                hlFontSize: fontSize,
                              );

                              final d = definitonCardDbRow(
                                context,
                                def.dict,
                                def.r,
                                child,
                                text: () =>
                                    htmlToPlainTextWithLineBr(def.meanings),
                                rebuild: () {
                                  if (context.mounted) setState(() {});
                                },
                                onRemove: onRemove,
                                fs: () {
                                  LexBnDefPage.open(
                                    context,
                                    en: def,
                                    onRemove: onRemove,
                                    onAdd: () => _defList.add(def),
                                  );
                                },
                              );

                              return d;
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                // Padding(
                //   padding: EdgeInsetsGeometry.symmetric(horizontal: padd.right),
                //   child: const Divider(height: 0),
                // ),
                // SizedBox(width: 8),
                // Padding(
                //   padding: EdgeInsetsGeometry.symmetric(
                //     horizontal: padd.right,
                //     vertical: 8,
                //   ),
                //   child: TextField(
                //     controller: _tc,
                //     // focusNode: _focusNode,
                //     textDirection: TextDirection.rtl,
                //     textAlign: TextAlign.start,
                //     onChanged: _onSearchChange,
                //     // style: arTxtTheme,
                //     style: L.arStyleSized,
                //     decoration: InputDecoration(
                //       hintText: L.p('Search Words', 'ابحث'),
                //       hintTextDirection: L.dir,
                //       suffixIcon: IconButton(
                //         onPressed: () {
                //           setState(() {
                //             _tc.clear();
                //             _shearced = '';
                //           });
                //         },
                //         icon: Icon(Icons.clear),
                //       ),
                //     ),
                //   ),
                // ),
                // if (appConf.fullScreen) const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
