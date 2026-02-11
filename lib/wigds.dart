import 'package:ara_dict/data.dart';
import 'package:ara_dict/main.dart';
import 'package:ara_dict/theme.dart';
import 'package:flutter/material.dart';

Widget buildDrawer(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final currRoute = ModalRoute.of(context)?.settings.name;
  return Drawer(
    child: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: cs.primary,
                  ),
                  child: Text(
                    appName,
                    style: TextStyle(
                      color: cs.onInverseSurface,
                      fontSize: mediumFontSize * 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  selected: currRoute == Routes.dictionary,
                  title: Text("Lexicons"),
                  leading: Icon(Icons.book),
                  onTap: () {
                    Navigator.pop(context);
                    if (currRoute != Routes.dictionary) {
                      Navigator.pushReplacementNamed(
                        context,
                        Routes.dictionary,
                      );
                    }
                  },
                ),
                ListTile(
                  selected: currRoute == Routes.reader,
                  title: Text("Reader"),
                  leading: Icon(Icons.notes),
                  onTap: () {
                    Navigator.pop(context);
                    if (currRoute != Routes.reader) {
                      Navigator.pushReplacementNamed(context, Routes.reader);
                    }
                  },
                ),
                ListTile(
                  selected: currRoute == Routes.help,
                  title: Text("Help"),
                  leading: Icon(Icons.help),
                  onTap: () {
                    Navigator.pop(context);
                    if (currRoute != Routes.help) {
                      Navigator.pushReplacementNamed(context, Routes.help);
                    }
                  },
                ),

                // ListTile(
                //   title: Text("Dict pop"),
                //   leading: Icon(Icons.book),
                //   onTap: () {
                //     Navigator.pop(context);
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder: (_) => SearchWithSelection(showDrawer: false),
                //       ),
                //     );
                //   },
                // ),
              ],
            ),
          ),

          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeModeNotifier,
            builder: (context, mode, _) {
              final isDark = mode == ThemeMode.dark;
              return SwitchListTile(
                title: const Text('Dark mode'),
                secondary: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  //,
                ),
                value: isDark,
                onChanged: (value) {
                  Navigator.pop(context);
                  themeModeNotifier.save(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
                },
              );
            },
          ),
        ],
      ),
    ),
  );
}

Future<bool?> showInfoDialog(
  BuildContext context, {
  required String message,
  String? title,
  String confirmText = 'Ok',
  TextDirection dir = TextDirection.ltr,
}) async {
  return showConfirmDialog(
    context,
    message: message,
    dir: dir,
    cancelText: null,
  );
}

Future<bool?> showConfirmDialog(
  BuildContext context, {
  String message = 'Are you sure?',
  String? title,
  String confirmText = 'Confirm',
  String? cancelText = 'Cancel',
  TextDirection dir = TextDirection.ltr,
}) async {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      final theme = Theme.of(context);
      final cs = theme.colorScheme;

      return AlertDialog(
        backgroundColor: cs.surface,
        title: title != null
            ? Text(title, style: theme.textTheme.titleLarge, textDirection: dir)
            : null,
        content: Text(
          message,
          style: theme.textTheme.bodyMedium,
          textDirection: dir,
        ),
        actions: [
          if (cancelText != null)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
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
