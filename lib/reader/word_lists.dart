import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/datas/word_store.dart';
import 'package:arabic_lexicons/main_widgets.dart';
import 'package:arabic_lexicons/pages/selectable_word_list_title_widget.dart';
import 'package:arabic_lexicons/reader/data.dart';
import 'package:arabic_lexicons/reader/reader_utils.dart';
import 'package:arabic_lexicons/reader/settings_class.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// CB - Current Book
class CBWordList extends StatefulWidget {
  final ReaderPageSettings rs;
  final PeraEntries paras;

  const CBWordList({super.key, required this.rs, required this.paras});

  static Future<void> open(
    BuildContext context,
    PeraEntries paras,
    ReaderPageSettings rs,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CBWordList(rs: rs, paras: paras),
      ),
    );
  }

  @override
  State<CBWordList> createState() => _CBWordListState();
}

class _CBWordListState extends State<CBWordList> {
  bool _isShowNewToOld = true;
  bool _isFabVisable = true;
  final _scrollController = ScrollController();
  late final ReaderPageSettings rs;
  late final List<String> _fws;

  @override
  void initState() {
    super.initState();
    touggleFullScreen();

    _scrollController.addListener(_scrollListener);
    rs = widget.rs;

    _fws = _toSortedList(widget.paras, WordStore.foreignWords);
    _bookmarked = _toSortedList(widget.paras, WordStore.bookmarkedWords);
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

  int _currentTab = 0;

  bool _bookmarkedShowing = false;

  late final List<String> _bookmarked;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isFabVisable = appConf.hideAppbar ? _isFabVisable : true;
    final List<String> curr = _bookmarkedShowing ? _bookmarked : _fws;

    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (i) {
          _bookmarkedShowing = i == 1;

          /// don't move this, as [_bookmared] is not inited [_currentTab] should not change
          setState(() => _currentTab = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.visibility_rounded),
            label: 'Foreign',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_added),
            label: 'Bookmarked',
          ),
        ],
      ),
      body: GestureStack(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: CustomScrollView(
            key: ValueKey((_isShowNewToOld, _currentTab)),
            controller: _scrollController,
            slivers: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: SliverAppBar(
                  floating: true,
                  snap: appConf.hideAppbar,
                  pinned: !appConf.hideAppbar,
                  title: Text(
                    _bookmarkedShowing
                        ? 'Bookmarked${_bookmarked.isEmpty ? '' : ' ${_bookmarked.length}'}'
                        : 'Foreign${_fws.isEmpty ? "" : " ${_fws.length}"}',
                  ),
                  actions: [
                    if (_bookmarkedShowing && _bookmarked.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_sweep),
                        tooltip: 'Clear Current books bookmarks',
                        onPressed: () async {
                          final confirm = await showConfirmDialog(
                            context,
                            'Clear Bookmarks',
                            message:
                                'Delete all bookmarks for this book? They will also be removed from the bookmarks list.',
                            destructive: true,
                            constraints: true,
                            confirmText: 'Clear',
                          );
                          if (confirm != true) return;

                          await WordStore.rmBMs(_bookmarked);
                          _bookmarked.clear();

                          if (context.mounted) setState(() {});
                        },
                      ),

                    if (_fws.isNotEmpty && !_bookmarkedShowing)
                      IconButton(
                        icon: const Icon(Icons.delete_sweep),
                        tooltip: 'Clear history',
                        onPressed: () async {
                          final confirm = await showConfirmDialog(
                            context,
                            'Clear Foreign History',
                            message:
                                'Clear the foreign history for this book? The entries will also be removed from the main list.',
                            destructive: true,
                            constraints: true,
                            confirmText: 'Clear',
                          );
                          if (confirm != true) return;

                          await WordStore.removeForeignMany(_fws);
                          _fws.clear();

                          if (context.mounted) setState(() {});
                        },
                      ),
                    if (!_bookmarkedShowing)
                      IconButton(
                        icon: const Icon(Icons.info_outlined),
                        tooltip: 'Info',
                        onPressed: () => showLuwInfo(context),
                      ),
                  ],
                ),
              ),
              if (curr.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height * 0.3,
                    ),
                    child: Center(
                      child: Text('No Words', textDirection: L.dir),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: appConf.readerPadd(context),
                  sliver: SliverList.separated(
                    itemCount: curr.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, visualIndex) {
                      final index = _isShowNewToOld
                          ? curr.length - 1 - visualIndex
                          : visualIndex;

                      final word = curr.elementAt(index);
                      final bm = _bookmarkedShowing || WordStore.isBm(word);

                      final child = SelectableWordListTitle(
                        onBmPage: _bookmarkedShowing,
                        word: word,
                        index: visualIndex,
                        length: curr.length,
                        setState: setState,
                        touggleBM: (_, _) async {
                          if (bm) {
                            _bookmarked.remove(word);
                            await WordStore.rmBM(word);
                          } else {
                            _bookmarked.add(word);
                            await WordStore.addBM(word);
                          }
                        },
                        remove: _bookmarkedShowing
                            ? null
                            : () async {
                                _fws.remove(word);
                                await WordStore.removeForeign(word);
                              },
                      );
                      return child;
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: curr.isNotEmpty
          ? AnimatedSlide(
              duration: const Duration(milliseconds: 300),
              offset: isFabVisable ? Offset.zero : const Offset(0, 4),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isFabVisable ? 1.0 : 0.0,
                child: FloatingActionButton(
                  onPressed: () =>
                      setState(() => _isShowNewToOld = !_isShowNewToOld),
                  child: const Icon(Icons.swap_vert),
                ),
              ),
            )
          : null,
    );
  }
}

Future<void> showLuwInfo(BuildContext ctx) async {
  if (!ctx.mounted) return;
  await showInfoDialog(
    ctx,
    'Foreign Words',
    message:
        'While reading, words you look up are saved and highlighted (if enabled). '
        'This is a list of all looked-up words from the current book.',
    constraints: true,
  );
}

Future<void> showLuwAllInfo(BuildContext ctx) async {
  if (!ctx.mounted) return;
  await showInfoDialog(
    ctx,
    'Foreign Words',
    message:
        'While reading, words you look up are saved and highlighted (if enabled). '
        'This is a combined list of all looked-up words from all book entries.',
    constraints: true,
  );
}

List<String> _toSortedList(PeraEntries paras, List<String> srcList) {
  if (srcList.isEmpty) return [];

  final Set<int> indexes = {};

  final indexedMap = {for (var i = 0; i < srcList.length; i++) srcList[i]: i};

  loop:
  for (final l in paras) {
    for (final e in l) {
      final idx = indexedMap[e.cl];
      if (idx == null) continue;

      indexes.add(idx);
      if (indexes.length == indexedMap.length) {
        break loop;
      }
    }
  }

  final sortedIndexes = indexes.toList()..sort((a, b) => a.compareTo(b));
  return sortedIndexes.map((i) => srcList[i]).toList();
}
