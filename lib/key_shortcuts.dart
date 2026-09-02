import 'package:arabic_lexicons/utils.dart';
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

  rmCurrentlySelectedWord(
    key: LogicalKeyboardKey.keyD,
    description: 'Remove currently selected word',
  ),

  toggleArabic(
    key: LogicalKeyboardKey.keyM,
    description: 'Toggle use-more-Arabic',
  ),

  showHelp(
    key: LogicalKeyboardKey.slash,
    description: 'Toggle keyboard shortcuts help overlay',
  );

  const AppShortcut({required this.key, required this.description});

  final LogicalKeyboardKey key;
  final String description;

  String get label => 'Ctrl+${key.keyLabel.toUpperCase()}';

  static void assertUniqueKeys() {
    final seen = <LogicalKeyboardKey>{};
    for (final shortcut in values) {
      assert(
        seen.add(shortcut.key),
        'Duplicate shortcut key "${shortcut.key.keyLabel}" on $shortcut',
      );
    }
  }
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
  required VoidCallback delCurr,
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
    KeyBinding(AppShortcut.rmCurrentlySelectedWord.key, delCurr),
    KeyBinding(AppShortcut.showHelp.key, help),
  ];

  final seen = <LogicalKeyboardKey>{};
  for (final r in res) {
    assert(
      seen.add(r.key),
      'Duplicate shortcut key "${r.key.keyLabel}" on has dubpilcates',
    );
  }

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
    final cs = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
        ],
        ...separatedBuilder(
          itemCount: shortcuts.length,
          separatorBuilder: (_) => Divider(height: 1, color: cs.outlineVariant),
          itemBuilder: (i) {
            final shortcut = shortcuts[i];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      shortcut.description,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    constraints: const BoxConstraints(minWidth: 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: cs.outlineVariant),
                      borderRadius: BorderRadius.circular(8),
                      color: cs.secondaryContainer,
                    ),
                    child: Text(
                      shortcut.label,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontFamily: 'monospace',
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: cs.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
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
        insetPadding: EdgeInsets.all(14.0),
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
