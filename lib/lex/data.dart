import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/datas/word_store.dart';
import 'package:arabic_lexicons/lex/dicts/ar_en/ar_en.dart';
import 'package:arabic_lexicons/lex/dicts/db.dart';
import 'package:arabic_lexicons/lex/isolate.dart';
import 'package:arabic_lexicons/lex/sugg/data.dart';
import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

/// lexicon result type
enum LexRT {
  empty,

  /// used when both res and sugg are emtpy
  emptyTotally,

  quering,
  res,
  sug;

  bool get isSug => this == sug;
  bool get isQuering => this == quering;
  bool get isRes => this == res;
  bool get isEmpty => this == empty;
  // bool get isEmptyTotally => this == emptyTotally;
}

class SearchLexiconsDatas {
  final AutoScrollController scrollController;
  final AutoScrollController scrollableSelection;
  final AutoScrollController scrollableSelectionDict;

  // final FocusNode inputFocusNode;
  final Future<void> Function({String? appendTxt}) onChangeTxt;
  final VoidCallback setState;

  bool appbarReaderBg = true;

  SearchLexiconsDatas({
    required this.selectedDict,
    required this.scrollController,
    required this.onChangeTxt,
    required this.setState,
    required this.scrollableSelection,
    required this.scrollableSelectionDict,
  });

  Dict selectedDict;

  String preQuery = '';

  LexRT state = LexRT.empty;

  SuggestionEntries sugg = {};
  List<Dict> suggDictSorted = [];

  List<String> words = [];
  String selectedWord = "";

  List<DbRow> dbRes = [];
  List<ArEnEntry> arEnRes = [];

  void resetAll() {
    words.clear();
    selectedWord = '';

    _resetLoadedValues();
  }

  void _resetLoadedValues() {
    appbarReaderBg = true;
    state = LexRT.empty;

    /// don't clear because they are cached if u clear the cached version is cleared also!
    sugg = {};
    dbRes = [];
    arEnRes = [];
  }

  bool get isSelectedWordEmpty {
    return selectedWord.isEmpty;
  }

  bool get areWordsEmpty {
    return words.isEmpty;
  }

  bool get resultsAreEmpty => (dbRes.isEmpty) && (arEnRes.isEmpty);

  void rebuild() => setState();

  Future<void> _loadSearchSugg({bool forced = false}) async {
    sugg = await Isolates.getSugg(selectedWord);
    if (forced) {
      state = LexRT.sug;
    } else {
      state = sugg.isEmpty ? LexRT.emptyTotally : LexRT.sug;
    }
    rebuild();
  }

  Future<bool> _loadResults(BuildContext context, {bool forced = false}) async {
    if (selectedDict == Dict.arEn) {
      arEnRes = await Isolates.arEnSearch(selectedWord);
    } else {
      dbRes = await DbService.search(selectedDict, selectedWord);
    }

    final empty = resultsAreEmpty;

    // we will still be on query mode
    if (empty && !forced) return false;

    state = LexRT.res;

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

    if (!empty) {
      WordStore.histAdd(selectedDict, selectedWord);
    }

    return true;
  }

  /// for onSettings change
  Future<void> getAndShowResORSugg(
    BuildContext context, {
    bool forceSugg = false,
    bool forceRes = false,
    // bool scrollDictSelector = false,
  }) async {
    if (forceSugg && forceRes) {
      throw Exception('Can not have both forceSugg and forceRes == true');
    }

    _resetLoadedValues();

    state = selectedWord.isEmpty ? LexRT.empty : LexRT.quering;

    rebuild(); // rebuild: show loading animation

    if (appConf.scrollLexSelection) {
      scrollSelectors();
    }

    if (selectedWord.isEmpty) return;

    if (forceSugg) {
      await _loadSearchSugg(forced: forceSugg);
      return;
    }

    final hasRes = await _loadResults(context, forced: forceRes);
    if (hasRes || forceRes) {
      return;
    }

    if (appConf.showSearchSugg) {
      await _loadSearchSugg();
    } else {
      state = LexRT.empty;
      rebuild();
    }
  }

  void scrollSelectors() {
    if (!appConf.scrollLexSelectionAutoSc) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollableSelection.hasClients && words.length > 2) {
        final index = words.indexOf(selectedWord);
        if (index > -1) {
          scrollableSelection.scrollToIndex(
            index,
            // preferPosition: AutoScrollPosition.,
          );
        }
      }
      if (scrollableSelectionDict.hasClients) {
        final index = allDictsOrd.indexOf(selectedDict);
        if (index > -1) {
          scrollableSelectionDict.scrollToIndex(
            index,
            // preferPosition: AutoScrollPosition.middle,
          );
        }
      }
    });
  }
}
