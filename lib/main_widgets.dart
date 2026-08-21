import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/history/page.dart';
import 'package:arabic_lexicons/pages/fams/fams.dart';
import 'package:arabic_lexicons/pages/foreings_all.dart';
import 'package:arabic_lexicons/pages/help/help.dart';
import 'package:arabic_lexicons/pages/settings.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:flutter/material.dart';

Widget buildDrawer(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final currRoute = ModalRoute.of(context)?.settings.name;

  int selectedIndex = switch (currRoute) {
    Routes.dictionary => 0,
    Routes.readerInput || Routes.readerPage => 1,
    Routes.bookMarks => 2,
    _ => -1,
  };

  return NavigationDrawer(
    selectedIndex: selectedIndex >= 0 ? selectedIndex : null,
    onDestinationSelected: (index) async {
      Navigator.pop(context);

      final isReading = currRoute == Routes.readerPage;
      if (isReading && (index == 0 || index == 1)) {
        final res = await showConfirmDialog(
          context,
          'Exit Reader?',
          confirmText: 'Exit',
          destructive: true,
        );
        if (!context.mounted || res != true) return;
      }

      switch (index) {
        case 0:
          if (currRoute != Routes.dictionary) {
            Navigator.pushReplacementNamed(context, Routes.dictionary);
            appConf.saveRoute(Routes.dictionary);
          }
          break;

        case 1:
          if (currRoute != Routes.readerInput) {
            Navigator.pushReplacementNamed(context, Routes.readerInput);
          }
          // appConf.saveRoute(Routes.readerInput);
          break;

        case 2:
          if (currRoute != Routes.bookMarks) {
            Navigator.pushNamed(context, Routes.bookMarks);
          }
          break;

        case 3:
          ForeignWordsPage.open(context);
          break;

        case 4:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HistPage()),
          );
          break;

        case 5:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SettingsPage()),
          );

        case 6:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ArabicFamilyList()),
          );
          break;

        case 7:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HelpPage()),
          );
      }
    },
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
        child: Text(
          appName,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
        ),
      ),

      NavigationDrawerDestination(
        icon: Icon(Icons.book),
        label: Text("Lexicons"),
      ),
      NavigationDrawerDestination(
        icon: Icon(Icons.menu_book_rounded),
        label: Text("Reader"),
      ),

      const Divider(),
      NavigationDrawerDestination(
        icon: Icon(Icons.bookmark_outline),
        label: Text("BookMarks"),
      ),
      NavigationDrawerDestination(
        label: const Text("Foreign Words"),
        icon: const Icon(Icons.g_translate),
      ),
      NavigationDrawerDestination(
        label: const Text("Search History"),
        icon: const Icon(Icons.history),
      ),

      const Divider(),
      NavigationDrawerDestination(
        label: const Text("Settings"),
        icon: const Icon(Icons.settings_outlined),
      ),

      // const Divider(),
      NavigationDrawerDestination(
        label: const Text("Verb Families"),
        icon: const Icon(Icons.info_outline),
      ),
      NavigationDrawerDestination(
        label: const Text("Help"),
        icon: const Icon(Icons.help_outline),
      ),
    ],
  );
}

/// if [useLClass] == true [dir], [fontFam] will be ignored
Future<bool?> showInfoDialog(
  BuildContext context,
  String title, {
  String? message,
  String confirmText = 'Okay',
  TextDirection dir = TextDirection.ltr,
  bool constraints = false,
  bool distructive = false,
  bool useLClass = false,
  String? fontFam,
  bool scroolable = false,
}) async {
  return showConfirmDialog(
    context,
    title,
    message: message,
    dir: dir,
    confirmText: confirmText,
    cancelText: null,
    constraints: constraints,
    destructive: distructive,
    useLClass: useLClass,
    fontFam: fontFam,
    scroolable: scroolable,
  );
}

/// if [useLClass] == true [dir], [fontFam] will be ignored
Future<bool?> showConfirmDialog(
  BuildContext context,
  String title, {
  String? message,
  String confirmText = 'Confirm',
  String? cancelText = 'Cancel',
  bool destructive = false,
  TextDirection dir = TextDirection.ltr,
  bool constraints = false,
  bool useLClass = false,
  String? fontFam,
  bool scroolable = false,
}) {
  if (useLClass && cancelText == 'Cancel') {
    cancelText = L.p('Cancel', 'إغلاق');
  }

  return showDialog<bool>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      final cs = theme.colorScheme;

      return AlertDialog(
        scrollable: scroolable,
        constraints: constraints ? const BoxConstraints(maxWidth: 450) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28), // M3 style
        ),
        backgroundColor: cs.surfaceContainer,
        surfaceTintColor: cs.surfaceTint,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),

        title: Text(
          title,
          textDirection: useLClass ? L.dir : dir,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
            fontFamily: useLClass ? L.arFontIf : fontFam,
            // color: cs.onSurfaceVariant,
          ),
        ),

        content: message != null
            ? Text(
                message,
                textDirection: useLClass ? L.dir : dir,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontFamily: useLClass ? L.arFontIf : fontFam,
                ),
              )
            : null,

        actions: [
          if (cancelText != null)
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                cancelText,
                textDirection: useLClass ? L.dir : dir,
                style: useLClass
                    ? L.arStyleIf
                    : fontFam == null
                    ? null
                    : TextStyle(fontFamily: fontFam),
              ),
            ),

          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: destructive ? cs.error : null,
              foregroundColor: destructive ? cs.onError : null,
            ),
            child: Text(
              confirmText,
              textDirection: useLClass ? L.dir : dir,
              style: useLClass
                  ? L.arStyleIf
                  : fontFam == null
                  ? null
                  : TextStyle(fontFamily: fontFam),
            ),
          ),
        ],
      );
    },
  );
}

class CompactCheckboxTile extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool?> onChanged;
  final Widget title;
  final EdgeInsets padding;
  final double gap;

  const CompactCheckboxTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.padding = const EdgeInsets.all(8),
    this.gap = 6,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // borderRadius: BorderRadius.circular(6),
      onTap: () => onChanged(value == null ? null : !value!),
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: title),
            SizedBox(width: gap),
            Checkbox(
              value: value,
              onChanged: (v) => onChanged(v),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showThemeSelector(BuildContext mainContext) {
  return showDialog(
    context: mainContext,
    useSafeArea: true,
    builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return Dialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 300),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Text('Select Theme'),
                Text(
                  'Select Theme: ${capitalize(appConf.theme.name)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 24),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.settings_suggest),
                          tooltip: 'Sytem',
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode),
                          tooltip: 'Light',
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode),
                          tooltip: 'Dark',
                        ),
                      ],
                      selected: {appConf.theme},
                      onSelectionChanged: (selection) {
                        Navigator.pop(context);
                        final selectedMode = selection.first;
                        appConf.saveTheme(selectedMode);
                      },
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
