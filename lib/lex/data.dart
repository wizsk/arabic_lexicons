import 'package:ara_dict/data.dart';
import 'package:ara_dict/datas/word_store.dart';
import 'package:ara_dict/lex/dicts/ar_en/ar_en.dart';
import 'package:ara_dict/lex/dicts/db.dart';
import 'package:ara_dict/lex/isolate.dart';
import 'package:ara_dict/lex/sugg/data.dart';
import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class SearchLexiconsDatas {
  final AutoScrollController scrollController;
  final AutoScrollController scrollableSelection;

  // final FocusNode inputFocusNode;
  final Future<void> Function({String? appendTxt}) onChangeTxt;
  final void Function(void Function()) setState;

  bool appbarReaderBg = true;

  SearchLexiconsDatas({
    required this.selectedDict,
    required this.scrollController,
    required this.onChangeTxt,
    required this.setState,
    required this.scrollableSelection,
  });

  Dict selectedDict;

  String preQuery = '';

  bool isShowingSugg = false;
  SuggestionEntries sugg = {};
  List<Dict> suggDictSorted = [];

  List<String> words = [];
  String selectedWord = "";

  List<DbRow> dbRes = [];
  List<ArEnEntry> arEnRes = [];
  bool resLoaded = false;

  void resetLoadedValues() {
    appbarReaderBg = true;

    sugg = {};
    isShowingSugg = false;

    resLoaded = false;
    dbRes = [];
    arEnRes = [];
  }

  void resetWords() {
    words.clear();
    selectedWord = "";

    appbarReaderBg = true;
  }

  void resetAll() {
    resetLoadedValues();
    resetWords();
  }

  bool get isSelectedWordEmpty {
    return selectedWord.isEmpty;
  }

  bool get areWordsEmpty {
    return words.isEmpty;
  }

  bool get resultsAreEmpty => (dbRes.isEmpty) && (arEnRes.isEmpty);

  void rebuild() => setState(() {});

  Future<void> _loadSearchSugg() async {
    sugg = await Isolates.getSugg(selectedWord);
    isShowingSugg = true;
    rebuild();
  }

  Future<bool> _loadResults(BuildContext context) async {
    if (selectedDict == Dict.arEn) {
      arEnRes = await Isolates.arEnSearch(selectedWord);
    } else {
      dbRes = await DbService.search(selectedDict, selectedWord);
    }

    resLoaded = true;
    if (resultsAreEmpty) return false;
    rebuild();

    if (dbRes.isNotEmpty &&
        (selectedDict == Dict.hanswehr || selectedDict == Dict.laneLexicon)) {
      for (int i = 0; i < dbRes.length; i++) {
        if (dbRes[i].isHi) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            scrollController.scrollToIndex(
              i,
              preferPosition: AutoScrollPosition.begin,
              duration: const Duration(milliseconds: 120),
            );
          });
          break;
        }
      }
    }
    return true;
  }

  /// for onSettings change
  Future<void> getAndShowResORSugg(
    BuildContext context, {
    bool forceSugg = false,
    bool forceRes = false,
  }) async {
    if (forceSugg && forceRes) {
      throw Exception('Can not have both forceSugg and forceRes == true');
    }

    resetLoadedValues();

    // insanity check!
    if (selectedWord.isEmpty) {
      resLoaded = true;
      rebuild();

      // if (appConf.scrollLexSelection && scrollableSelection.hasClients) {
      //   // reset it
      //   scrollableSelection.jumpTo(0);
      // }
      return;
    }

    if (forceSugg) {
      await _loadSearchSugg();
      return;
    }

    rebuild(); // rebuild: show loading animation

    if (appConf.scrollLexSelection) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!scrollableSelection.hasClients) return;

        final index = words.indexOf(selectedWord);
        if (index < 0) return;

        scrollableSelection.scrollToIndex(
          index,
          preferPosition: AutoScrollPosition.middle,
        );
      });
    }

    final hasResults = await _loadResults(context);
    if (hasResults) {
      WordStore.histAdd(selectedDict, selectedWord);
      return;
    }

    if (forceRes) {
      rebuild();
      return;
    }

    if (Isolates.suggCanBeShown) {
      await _loadSearchSugg();
    }
  }

  @override
  String toString() {
    return '''
SearchLexiconsDatas(
  selectedDict: $selectedDict,
  words: $words,
  selectedWord: $selectedWord,
  dbRes length: ${dbRes.length},
  arEnRes length: ${arEnRes.length},
  resLoaded: $resLoaded
)
''';
  }
}
