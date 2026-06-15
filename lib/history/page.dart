import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/datas/word_store.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/multi_selection.dart';
import 'package:ara_dict/pages/utils.dart';
import 'package:ara_dict/utils.dart';
import 'package:ara_dict/widgets/no_res.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class HistPage extends StatefulWidget {
  const HistPage({super.key});

  @override
  State<HistPage> createState() => _HistPageState();
}

class _HistPageState extends State<HistPage> {
  bool _isShowNewToOld = true;
  bool _isFabVisable = true;
  final _scrollController = ScrollController();
  late final SelectionController<String> _selection;

  @override
  void initState() {
    super.initState();
    _selection = SelectionController(() {
      if (mounted) setState(() {});
    });

    _scrollController.addListener(_scrollListener);

    touggleFullScreen();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    touggleFullScreen();
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection ==
            ScrollDirection.reverse &&
        _isFabVisable) {
      setState(() {
        _isFabVisable = false;
      });
    } else if (_scrollController.position.userScrollDirection ==
            ScrollDirection.forward &&
        !_isFabVisable) {
      setState(() {
        _isFabVisable = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFabVisable = appConf.hideAppbar ? _isFabVisable : true;

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
      child: Scaffold(
        body: GestureStack(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: SliverAppBar(
                    floating: true,
                    snap: appConf.hideAppbar,
                    pinned: !appConf.hideAppbar,
                    title: _selection.appBarTitle(
                      'History${WordStore.histEmpty ? "" : " ${WordStore.histLen}"}',
                    ),
                    actions: _selection.hasSelection
                        ? _selection.genricAppBarActions(
                            context,
                            all: () => WordStore.searchHist.map((e) => e.word),
                            rm: (items) => WordStore.rmHistItems(items),
                          )
                        : [
                            if (WordStore.histNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.delete_sweep),
                                tooltip: 'Clear history',
                                onPressed: () async {
                                  final confirm = await showConfirmDialog(
                                    context,
                                    'Clear History',
                                    destructive: true,
                                    confirmText: 'Clear',
                                  );
                                  if (confirm != true) return;
                                  await WordStore.clearHist();
                                  setState(() {});
                                },
                              ),
                          ],
                  ),
                ),
                if (WordStore.histEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.3,
                      ),
                      child: NoResults(
                        icon: NoResults.searchEmpty,
                        title: L.p(
                          'Search some words',
                          /*ar */ 'ابحث بعض الكلمات',
                        ),
                        titleFont: L.arFontIf,
                        titleDir: L.dir,
                      ),
                      // child: Center(
                      //   child: Text(
                      //     L.p('Search some words', /*ar */ 'ابحث بعض الكلمات'),
                      //     style: L.arStyleIf,
                      //     textDirection: L.dir,
                      //   ),
                      // ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: appConf.readerPadd(context),
                    sliver: SliverList.separated(
                      itemCount: WordStore.histLen,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, visualIndex) {
                        final index = _isShowNewToOld
                            ? WordStore.histLen - 1 - visualIndex
                            : visualIndex;

                        final itm = WordStore.histAt(index);

                        return SelectableWordListTitle(
                          word: itm.word,
                          selection: _selection,
                          setState: setState,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          subtitle: Text(
                            itm.dict.name,
                            style: Theme.of(context).textTheme.bodySmall?.ar,
                            textAlign: TextAlign.right,
                          ),
                          remove: () async => await WordStore.rmHistItem(itm),
                        );

                        // return Material(
                        //   color: cs.surfaceContainer,
                        //   shape: RoundedRectangleBorder(
                        //     borderRadius: BorderRadius.circular(16),
                        //     side: BorderSide(color: cs.outlineVariant),
                        //   ),
                        //   clipBehavior: Clip.antiAlias,
                        //   child: ListTile(
                        //     contentPadding: const EdgeInsets.symmetric(
                        //       horizontal: 12,
                        //       vertical: 4,
                        //     ),

                        //     title: Text(
                        //       // '${itm.word} • ${itm.dict.name}',
                        //       itm.word,
                        //       maxLines: 1,
                        //       overflow: TextOverflow.ellipsis,
                        //       textDirection: TextDirection.rtl,
                        //       textAlign: TextAlign.right,
                        //       style: L.arStyle,
                        //     ),
                        //     onTap: () {
                        //       openDict(
                        //         context,
                        //         itm.word,
                        //         dict: itm.dict,
                        //       ).then((_) => setState(() {}));
                        //     },
                        //     leading: IconButton(
                        //       icon: bm
                        //           ? Icon(Icons.bookmark, color: cs.error)
                        //           : Icon(Icons.bookmark_outline),
                        //       onPressed: () async {
                        //         if (bm) {
                        //           final confirm = await showConfirmDialog(
                        //             context,
                        //             'Remove Bookmark',
                        //             message: 'Remove: ${itm.word}',
                        //             destructive: true,
                        //             confirmText: 'Remove',
                        //           );
                        //           if (confirm != true) return;
                        //           WordStore.rmBM(itm.word);
                        //         } else {
                        //           WordStore.addBM(itm.word);
                        //         }
                        //         setState(() {});
                        //       },
                        //     ),
                        //     trailing: IconButton(
                        //       icon: const Icon(Icons.delete_outline),
                        //       tooltip: L.p('Delete', 'حذف'),
                        //       onPressed: () async {
                        //         final confirm = await showConfirmDialog(
                        //           context,
                        //           '${L.p('Delete: ', 'حذف:')} ${itm.word}',
                        //           destructive: true,
                        //           confirmText: L.p('Delete', 'حذف'),
                        //           useLClass: true,
                        //           dir: L.dir,
                        //         );
                        //         if (confirm != true) return;

                        //         await WordStore.rmHistItem(itm);
                        //         setState(() {});
                        //         if (context.mounted) {
                        //           showSnackL(
                        //             context,
                        //             en: 'Deleted: ${itm.word}',
                        //             ar: 'تم الحذف: ${itm.word}',
                        //           );
                        //         }
                        //       },
                        //     ),
                        //   ),
                        // );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        floatingActionButton: WordStore.histNotEmpty
            ? AnimatedSlide(
                duration: const Duration(milliseconds: 300),
                offset: isFabVisable ? Offset.zero : const Offset(0, 2),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: isFabVisable ? 1.0 : 0.0,
                  child: FloatingActionButton(
                    onPressed: () {
                      _isShowNewToOld = !_isShowNewToOld;
                      setState(() {});
                    },
                    child: const Icon(Icons.swap_vert),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
