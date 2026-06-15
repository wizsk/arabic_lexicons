import 'package:ara_dict/data.dart';
import 'package:ara_dict/datas/word_store.dart';
import 'package:ara_dict/multi_selection.dart';
import 'package:ara_dict/pages/utils.dart';
import 'package:ara_dict/reader/word_lists.dart';
import 'package:ara_dict/utils.dart';
import 'package:ara_dict/widgets/no_res.dart';
import 'package:ara_dict/word_list/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

enum WordListType { bookmarks, foreings }

class WordListPage extends StatefulWidget {
  final WordListType listType;

  const WordListPage({super.key, required this.listType});

  @override
  State<WordListPage> createState() => _WordListPageState();
}

class _WordListPageState extends State<WordListPage> {
  late final WordListType _listType;
  late final String _titleMain;
  late final List<String> _words;
  late final Future<void> Function(String) _add;
  late final Future<int> Function(Iterable<String>) _addMulti;
  late final Future<void> Function(String) _remove;
  late final Future<int> Function(Iterable<String>) _removeMuli;
  late final Future<void> Function() _clearAll;
  late final String _exportFileName;
  late final bool _hasDeleteInList;

  bool _isShowNewToOld = true;
  bool _isFabVisable = true;
  final ScrollController _scrollController = ScrollController();
  late final SelectionController<String> _selection;

  @override
  void initState() {
    super.initState();

    _listType = widget.listType;

    switch (_listType) {
      case WordListType.bookmarks:
        _titleMain = 'Bookmarks';
        _words = WordStore.bookmarkedWords;
        _add = WordStore.addBM;
        _addMulti = WordStore.addBMs;
        _remove = WordStore.rmBM;
        _removeMuli = WordStore.rmBMs;
        _clearAll = WordStore.clearBookmarks;
        _exportFileName = 'Arabic_Lexicons_Boookamrks.txt';
        _hasDeleteInList = false;
        break;

      case WordListType.foreings:
        _titleMain = 'Foreigns';
        _words = WordStore.foreignWords;
        _add = WordStore.addForeign;
        _addMulti = WordStore.addForeigns;
        _remove = WordStore.removeForeign;
        _removeMuli = WordStore.removeForeignMany;
        _clearAll = WordStore.clearForeign;
        _exportFileName = 'Arabic_Lexicons_Foreings.txt';
        _hasDeleteInList = true;
        break;
    }

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

  String get _title =>
      '$_titleMain${_words.isEmpty ? "" : " (${_words.length})"}';

  List<String> _selectedWordsList() {
    return _selection.selected.toList();
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
        // appBar: AppBar(),
        // drawer: buildDrawer(context),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: GestureStack(
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
                      _title,
                      // style: L.arStyleIf,
                    ),
                    actions: [
                      if (_selection.hasSelection)
                        ..._selection.genricAppBarActions(
                          context,
                          all: () => _words,
                          rm: null,
                        )
                      else if (_listType == WordListType.foreings)
                        IconButton(
                          icon: const Icon(Icons.info_outlined),
                          tooltip: 'Info',
                          onPressed: () => showLuwAllInfo(context),
                        ),
                      buildWordListAppbarMenu(
                        context,
                        stateChanged: _selection.clear,
                        allWords: _words,
                        add: _add,
                        addMulti: _addMulti,
                        exportFileName: _exportFileName,
                        remove: _remove,
                        removeMuli: _removeMuli,
                        clearAll: _clearAll,
                        getSelectedWords: _selectedWordsList,
                      ),
                    ],
                  ),
                ),
                if (_words.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height * 0.3,
                      ),
                      child: const NoResults(
                        icon: NoResults.playlistEmpty,
                        title: 'No words',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: appConf.readerPadd(context),
                    sliver: SliverList.separated(
                      itemCount: _words.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, visualIndex) {
                        final index = _isShowNewToOld
                            ? _words.length - 1 - visualIndex
                            : visualIndex;

                        final word = _words[index];

                        return SelectableWordListTitle(
                          word: word,
                          selection: _selection,
                          setState: setState,
                          remove: _hasDeleteInList
                              ? () async => await _remove(word)
                              : null,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        floatingActionButton: _words.isNotEmpty
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
