import 'package:ara_dict/data.dart';
import 'package:ara_dict/fams.dart';
import 'package:ara_dict/font_size.dart';
import 'package:ara_dict/help.dart';

import 'package:flutter/material.dart';

Widget buildDrawer(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final currRoute = ModalRoute.of(context)?.settings.name;
  return Drawer(
    child: Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: cs.primary),
                child: Text(
                  appName,
                  style: TextStyle(
                    color: cs.onInverseSurface,
                    fontSize: 26,
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
                    Navigator.pushReplacementNamed(context, Routes.dictionary);
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
                selected: currRoute == Routes.bookMarks,
                title: Text("BookMarks"),
                leading: Icon(Icons.bookmark),
                onTap: () {
                  Navigator.pop(context);
                  if (currRoute != Routes.bookMarks) {
                    Navigator.pushReplacementNamed(context, Routes.bookMarks);
                  }
                },
              ),
              ListTile(
                // selected: currRoute == Routes.fams,
                title: Text("Verb Famalies"),
                leading: Icon(Icons.info),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ArabicFamilyList()),
                  );
                },
              ),
              ListTile(
                // selected: currRoute == Routes.help,
                title: Text("Help"),
                leading: Icon(Icons.help),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HelpPage()),
                  );
                },
              ),
            ],
          ),
        ),

        Divider(),
        ListTile(
          title: const Text('Change Font Size'),
          leading: const Icon(Icons.text_fields),
          onTap: () {
            Navigator.pop(context);
            showFontSizeDialog(context, appSettingsNotifier);
          },
        ),
        SwitchListTile(
          title: const Text('Keep Screen on'),
          secondary: Icon(Icons.screen_lock_portrait),
          value: appSettingsNotifier.wake.isEnabled(),
          onChanged: (value) {
            Navigator.pop(context);
            appSettingsNotifier.wake.tougle(enable: value);
          },
        ),
        SwitchListTile(
          title: const Text('Dark mode'),
          secondary: Icon(
            appSettingsNotifier.theme == ThemeMode.dark
                ? Icons.dark_mode
                : Icons.light_mode,
          ),
          value: appSettingsNotifier.theme == ThemeMode.dark,
          onChanged: (value) {
            Navigator.pop(context);
            appSettingsNotifier.saveTheme(
              value ? ThemeMode.dark : ThemeMode.light,
            );
          },
        ),
        SizedBox(height: 30),
      ],
    ),
  );
}

Future<bool?> showInfoDialog(
  BuildContext context,
  String title, {
  String? message,
  String confirmText = 'Ok',
  TextDirection dir = TextDirection.ltr,
}) async {
  return showConfirmDialog(
    context,
    title,
    message: message,
    dir: dir,
    cancelText: null,
  );
}

Future<bool?> showConfirmDialog(
  BuildContext context,
  String title, {
  String? message,
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
        title: Text(
          title,
          style: theme.textTheme.titleLarge,
          textDirection: dir,
        ),
        content: message == null
            ? null
            : Text(
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
