import 'dart:async';
import 'dart:collection';

import 'package:arabic_lexicons/alphabets.dart';
import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/reader/data.dart';
import 'package:arabic_lexicons/reader/settings_class.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

// keep your existing _tashkil regex here
String cleanBookTitle(String title) {
  return ArabicNormalizer.cleanLineForSearch(title);
}

class _PeraLine {
  final int index;
  final String clPera;
  final String arPera;

  /// used for how many perass a chapters contain
  final int peraCount;

  const _PeraLine({
    required this.index,
    this.clPera = '',
    required this.arPera,
    this.peraCount = 0,
  });
}

Future<int?> showNavigateBook(
  BuildContext context,
  ReaderPageSettings rs,
  PeraEntries peras,
  int currPeraIdx,
) {
  return showModalBottomSheet<int?>(
    context: context,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) {
      return _PeraPickerSheet(rs: rs, peras: peras, currPeraIdx: currPeraIdx);
    },
  );
}

class _PeraPickerSheet extends StatefulWidget {
  final ReaderPageSettings rs;
  final PeraEntries peras;
  final int currPeraIdx;

  const _PeraPickerSheet({
    required this.rs,
    required this.peras,
    required this.currPeraIdx,
  });

  @override
  State<_PeraPickerSheet> createState() => _PeraPickerSheetState();
}

class _PeraPickerSheetState extends State<_PeraPickerSheet>
    with TickerProviderStateMixin {
  late final int _currPeraIdx;
  int? _currChapterIdx;

  final _sc = AutoScrollController();
  late final TabController _tabController;
  late final TextEditingController _searchController;

  late final List<_PeraLine> _allLines;
  final List<_PeraLine> _chapterLines = [];

  List<_PeraLine> _filteredLines = [];

  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();

    _currPeraIdx = widget.currPeraIdx;

    const takeWordsCount = 15;
    _allLines = widget.peras.indexed.map((e) {
      final isSub = e.$2.length > takeWordsCount;
      final words = isSub ? e.$2.sublist(0, takeWordsCount) : e.$2;

      var arPera = words.map((w) => w.ar).join(' ');
      final clPera = cleanBookTitle(words.map((w) => w.ar).join(' '));

      if (isSub) arPera = '$arPera...';

      return _PeraLine(index: e.$1, arPera: arPera, clPera: clPera);
    }).toList();

    final List<(int, String)> chapters = [];
    for (final (index, words) in widget.peras.indexed) {
      if (words.length == 1 && ArabicNormalizer.isArabicNum(words.first.ar)) {
        chapters.add((index, words.first.ar));
      }
    }

    if (chapters.isNotEmpty) {
      for (int i = 0; i < chapters.length; i++) {
        final (index, chapterTxt) = chapters[i];
        int peraCount;
        if (i == chapters.length - 1) {
          peraCount = widget.peras.length - index - 1;
        } else {
          final nextChapterIndex = chapters[i + 1].$1;
          peraCount = nextChapterIndex - index - 1;
        }
        _chapterLines.add(
          _PeraLine(index: index, arPera: chapterTxt, peraCount: peraCount),
        );

        if (index > _currPeraIdx) continue;
        if (_currPeraIdx >= index) {
          _currChapterIdx = index;
        }
      }
    }

    _filteredLines = _allLines;

    _searchController = TextEditingController();

    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _chapterLines.isNotEmpty ? 1 : 0,
    );

    _tabController.addListener(_onTabChange);

    // if (_chapterLines.isEmpty && _currPeraIdx > 0) {
    //   WidgetsBinding.instance.addPostFrameCallback((_) async {
    //     // here we don't need to care about is index same or not
    //     _scrollToCurrPeraIdx();
    //   });
    // }
  }

  void _scrollToCurrPeraIdx() {
    if (!_sc.hasClients) return;
    _sc.scrollToIndex(
      _currPeraIdx,
      preferPosition: AutoScrollPosition.begin,
      duration: const Duration(milliseconds: 100),
    );
  }

  void _onTabChange() {
    // if (!mounted) return;
    // setState(() {});
  }

  void _applySearch(String input) {
    final cleaned = cleanBookTitle(input);

    if (cleaned.isEmpty && input.isNotEmpty) {
      if (context.mounted) setState(() {});
    }

    if (cleaned == _query) return;
    _query = cleaned;

    if (cleaned.isEmpty) {
      _filteredLines = _allLines;
    } else {
      final List<(int, int)> matchIndexs = [];
      for (int i = 0; i < _allLines.length; i++) {
        final idx = _allLines[i].clPera.indexOf(cleaned);
        if (idx > -1) matchIndexs.add((i, idx));
      }
      // matchIndexs.sort((a, b) => a.$2 - b.$2);
      matchIndexs.sort((a, b) => a.$2.compareTo(b.$2));

      final List<_PeraLine> matches = [];
      for (final idx in matchIndexs) {
        matches.add(_allLines[idx.$1]);
      }
      _filteredLines = matches;
    }

    if (mounted) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_sc.hasClients) _sc.jumpTo(0);
      });
    }
  }

  void _onSearchChanged(String input) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      _applySearch(input);
    });
  }

  // String _shorten(String text, [int max = 70]) {
  //   if (text.length <= max) return text;
  //   return '${text.substring(0, max)}…';
  // }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.removeListener(_onTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final arFont = Theme.of(context).textTheme.titleMedium!.ar.copyWith(
      fontWeight: FontWeight.normal,
      fontSize: L.fontSize,
    );

    return Material(
      color: cs.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: 12, bottom: 6),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withAlpha(70),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Paragraphs'),
                    Tab(text: 'Chapters'),
                  ],
                ),
                SizedBox(height: 8),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              right: 18,
                              left: 18,
                              bottom: 10,
                            ),
                            child: TextField(
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.start,
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              style: L.arStyleSized,
                              decoration: InputDecoration(
                                hintText: L.pr(
                                  'ابحث عن النص…',
                                  'Search paragraphs…',
                                ),
                                hintTextDirection: L.dir,
                                prefixIcon: IconButton(
                                  tooltip: 'Go to current paragraph',
                                  icon: const Icon(Icons.my_location),
                                  onPressed: _scrollToCurrPeraIdx,
                                ),
                                suffixIcon: _searchController.text.isEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.help),
                                        onPressed: () {
                                          showCleanLineForSearchInfo(context);
                                        },
                                      )
                                    : IconButton(
                                        onPressed: () => setState(() {
                                          setState(() {
                                            _searchController.clear();
                                            _filteredLines = _allLines;
                                          });
                                        }),
                                        icon: Icon(Icons.clear),
                                      ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: _buildList(
                              sc: _sc,
                              items: _filteredLines,
                              emptyText: 'No peras found',
                              arFont: arFont,
                              onTapItem: (item) =>
                                  Navigator.of(context).pop(item.index),
                              itemBuilder: (item) {
                                if (_filteredLines.length == _allLines.length) {
                                  return Text(
                                    item.arPera,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: arFont,
                                  );
                                }

                                final (:pre, :suf) = item.clPera.splitOnce(
                                  _query,
                                );

                                return Text.rich(
                                  TextSpan(
                                    children: [
                                      if (pre != null) TextSpan(text: pre),
                                      TextSpan(
                                        text: _query,
                                        style: TextStyle(
                                          color: cs.error,
                                          // fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (suf != null) TextSpan(text: suf),
                                    ],
                                  ),
                                  style: arFont,
                                );
                              },
                              isHigh: (_, itm) => itm.index == _currPeraIdx,
                            ),
                          ),
                        ],
                      ),
                      _buildList(
                        sc: null,
                        items: _chapterLines,
                        emptyText:
                            'No chapters found\n\n'
                            'Chapter numbers written with Arabic numerals (١٢٣) are automatically detected as chapters',
                        arFont: arFont,
                        onTapItem: (item) =>
                            Navigator.of(context).pop(item.index),
                        itemBuilder: (item) {
                          final chapterWord = widget.peras[item.index].first.ar;
                          final chapter = 'الباب  ${chapterWord.padRight(2)}';
                          final font = item.index == _currPeraIdx
                              ? arFont.copyWith(color: cs.onPrimaryContainer)
                              : arFont;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(chapter, style: font),
                              Text(
                                L
                                    .p(
                                      item.peraCount.toString(),
                                      enToArNum(item.peraCount),
                                    )
                                    .padRight(3),
                                style: font,
                              ),
                            ],
                          );
                        },
                        isHigh: (_, itm) => itm.index == _currChapterIdx,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList({
    required ScrollController? sc,
    required List<_PeraLine> items,
    required String emptyText,
    required TextStyle arFont,
    required ValueChanged<_PeraLine> onTapItem,
    required Widget Function(_PeraLine item) itemBuilder,
    required bool Function(int index, _PeraLine itm) isHigh,
  }) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Center(
          child: Text(
            emptyText,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;

    final highDecor = BoxDecoration(color: cs.primaryContainer);

    return Material(
      color: cs.surface,
      child: ListView.separated(
        controller: sc,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: scrollPadding,
        itemCount: items.length,
        separatorBuilder: (_, _) => const Divider(height: 0),
        itemBuilder: (context, index) {
          final item = items[index];
          final hi = isHigh(index, item);
          return AutoScrollTag(
            controller: _sc,
            key: ValueKey(item.index),
            index: item.index,
            child: Ink(
              decoration: hi ? highDecor : null,
              child: InkWell(
                onTap: () => onTapItem(item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  child: itemBuilder(item),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
