import 'package:ara_dict/data.dart';
import 'package:ara_dict/main.dart';
import 'package:ara_dict/theme.dart';
import 'package:flutter/material.dart';

Widget buildDrawer(BuildContext context) {
  // final cs = Theme.of(context).colorScheme;
  return Drawer(
    child: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  child: Text(
                    appName,
                    style: TextStyle(
                      // color: Colors.white,
                      fontSize: mediumFontSize * 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  title: Text("Lexicons"),
                  leading: Icon(Icons.book),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, Routes.dictionary);
                  },
                ),
                ListTile(
                  title: Text("Reader"),
                  leading: Icon(Icons.notes),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, Routes.reader);
                  },
                ),
                ListTile(
                  title: Text("Help"),
                  leading: Icon(Icons.help),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, Routes.help);
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      );
    },
  );
}
