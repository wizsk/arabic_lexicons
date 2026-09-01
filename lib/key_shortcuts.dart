import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final isMac = defaultTargetPlatform == TargetPlatform.macOS;
// final keybardModifier = isMac
//     ? LogicalKeyboardKey.meta
//     : LogicalKeyboardKey.control;

enum AppShortcut {
  focusSearch(key: LogicalKeyboardKey.keyN, description: 'Focus search field'),

  nextWord(key: LogicalKeyboardKey.keyH, description: 'Next word'),
  prevWord(key: LogicalKeyboardKey.keyL, description: 'Previous word'),

  nextDict(key: LogicalKeyboardKey.keyJ, description: 'Next dictionary'),
  prevDict(key: LogicalKeyboardKey.keyK, description: 'Previous dictionary'),

  toggleScrollableSelectors(
    key: LogicalKeyboardKey.keyB,
    description: 'Toggle scrollable lexicon selection',
  ),

  toggleArabic(
    key: LogicalKeyboardKey.keyM,
    description: 'Toggle use-more-Arabic',
  );

  const AppShortcut({required this.key, required this.description});

  final LogicalKeyboardKey key;
  final String description;

  String get label => 'Ctrl+${key.keyLabel.toUpperCase()}';
}

class KeyBinding {
  final LogicalKeyboardKey key;
  // final bool Function()? isEnabled;
  final VoidCallback action;
  const KeyBinding(this.key, this.action);

  // bool get enabled => isEnabled?.call() ?? true;
}

List<KeyBinding> keybindingsGen({
  required VoidCallback focusTF,
  required void Function(bool) cycleWord,
  required void Function(bool) cycleDict,
  required VoidCallback tgleScSl,
  required VoidCallback tglAr,
}) {
  final res = [
    KeyBinding(AppShortcut.focusSearch.key, focusTF),
    KeyBinding(AppShortcut.nextWord.key, () => cycleWord(true)),
    KeyBinding(AppShortcut.prevWord.key, () => cycleWord(false)),
    KeyBinding(AppShortcut.nextDict.key, () => cycleDict(true)),
    KeyBinding(AppShortcut.prevDict.key, () => cycleDict(false)),
    KeyBinding(AppShortcut.toggleScrollableSelectors.key, tgleScSl),
    KeyBinding(AppShortcut.toggleArabic.key, tglAr),
  ];

  assert(
    res.length == AppShortcut.values.length,
    "The total key binds enum and total applied not same",
  );

  return List.unmodifiable(res);
}

class ShortcutsHelpList extends StatelessWidget {
  final List<AppShortcut> shortcuts;

  const ShortcutsHelpList({super.key, this.shortcuts = AppShortcut.values});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.dividerColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < shortcuts.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              border: i < shortcuts.length - 1
                  ? Border(bottom: BorderSide(color: borderColor, width: 0.8))
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    shortcuts[i].description,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    border: Border.all(color: borderColor, width: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    shortcuts[i].label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
