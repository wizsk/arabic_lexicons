import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/lex/lexicons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final keyModifier = defaultTargetPlatform == TargetPlatform.macOS
    ? LogicalKeyboardKey.meta
    : LogicalKeyboardKey.control;

Map<Type, Action<Intent>> keyActions() {
  return {
    SearchIntent: CallbackAction<SearchIntent>(
      onInvoke: (intent) {
        LxCtrl.tryFocus();
        return null;
      },
    ),

    WordPreIntent: CallbackAction<WordPreIntent>(
      onInvoke: (intent) {
        LxCtrl.tryWordSwitchd(false);
        return null;
      },
    ),
    WordNextIntent: CallbackAction<WordNextIntent>(
      onInvoke: (intent) {
        LxCtrl.tryWordSwitchd(true);
        return null;
      },
    ),

    DictPreIntent: CallbackAction<DictPreIntent>(
      onInvoke: (intent) {
        LxCtrl.tryDictSwitchd(L.isAr);
        return null;
      },
    ),
    DictNextIntent: CallbackAction<DictNextIntent>(
      onInvoke: (intent) {
        LxCtrl.tryDictSwitchd(!L.isAr);
        return null;
      },
    ),

    HideScrollabeSelectorsIntent: CallbackAction<HideScrollabeSelectorsIntent>(
      onInvoke: (intent) {
        LxCtrl.tryTouggleScrolableSelectors();
        return null;
      },
    ),
  };
}

Map<ShortcutActivator, Intent> keyShortcuts() {
  return {
    LogicalKeySet(keyModifier, LogicalKeyboardKey.keyF): const SearchIntent(),

    LogicalKeySet(keyModifier, LogicalKeyboardKey.keyH): const WordNextIntent(),
    LogicalKeySet(keyModifier, LogicalKeyboardKey.keyL): const WordPreIntent(),

    LogicalKeySet(keyModifier, LogicalKeyboardKey.keyJ): const DictPreIntent(),
    LogicalKeySet(keyModifier, LogicalKeyboardKey.keyK): const DictNextIntent(),

    LogicalKeySet(keyModifier, LogicalKeyboardKey.keyB):
        const HideScrollabeSelectorsIntent(),
  };
}

class SearchIntent extends Intent {
  const SearchIntent();
}

class WordPreIntent extends Intent {
  const WordPreIntent();
}

class WordNextIntent extends Intent {
  const WordNextIntent();
}

class DictPreIntent extends Intent {
  const DictPreIntent();
}

class DictNextIntent extends Intent {
  const DictNextIntent();
}

class HideScrollabeSelectorsIntent extends Intent {
  const HideScrollabeSelectorsIntent();
}
