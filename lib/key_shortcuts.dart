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
    description: 'Toggle scrollable lexicon selections (if enabled)',
  ),

  toggleArabic(
    key: LogicalKeyboardKey.keyM,
    description: 'Toggle use-more-Arabic',
  ),

  showHelp(key: LogicalKeyboardKey.slash, description: 'Toggle help overlay');

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
  required VoidCallback help,
}) {
  final res = [
    KeyBinding(AppShortcut.focusSearch.key, focusTF),
    KeyBinding(AppShortcut.nextWord.key, () => cycleWord(true)),
    KeyBinding(AppShortcut.prevWord.key, () => cycleWord(false)),
    KeyBinding(AppShortcut.nextDict.key, () => cycleDict(true)),
    KeyBinding(AppShortcut.prevDict.key, () => cycleDict(false)),
    KeyBinding(AppShortcut.toggleScrollableSelectors.key, tgleScSl),
    KeyBinding(AppShortcut.toggleArabic.key, tglAr),
    KeyBinding(AppShortcut.showHelp.key, help),
  ];

  assert(
    res.length == AppShortcut.values.length,
    "The total key binds enum and total applied not same",
  );

  return List.unmodifiable(res);
}

class ShortcutsHelpList extends StatelessWidget {
  final List<AppShortcut> shortcuts;
  final String? title;

  const ShortcutsHelpList({
    super.key,
    this.shortcuts = AppShortcut.values,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.dividerColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
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
                      fontFamily: 'monospace',
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

bool _showing = false;
Future<void> showShortcutsHelpOverlay(BuildContext context) async {
  if (_showing) {
    _showing = false;

    Navigator.of(context).pop();
    return;
  }

  _showing = true;

  const pad = 24.00;
  await showDialog(
    context: context,
    builder: (context) {
      return const Dialog(
        constraints: BoxConstraints(maxWidth: 700),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: pad),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: pad),
              child: ShortcutsHelpList(title: 'Keybaord Shortcuts'),
            ),
          ),
        ),
      );
    },
  );
  _showing = false;
}
