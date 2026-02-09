import 'package:ara_dict/main.dart';
import 'package:ara_dict/theme.dart';
import 'package:flutter/material.dart';

Widget buildDrawer(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        Theme(
          data: Theme.of(context).copyWith(
            dividerTheme: const DividerThemeData(
              color: Colors.transparent,
              thickness: 0,
              space: 0,
            ),
          ),
          child: DrawerHeader(
            margin: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: mediumFontSize * 1.75,
                fontWeight: FontWeight.bold,
              ),
            ),
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
                color: cs.onSurface,
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
        ListTile(
          title: Text("Lexicons"),
          leading: Icon(Icons.home, color: cs.onSurface),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, Routes.dictionary);
          },
        ),
        ListTile(
          title: Text("Reader"),
          leading: Icon(Icons.read_more, color: cs.onSurface),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, Routes.reader);
          },
        ),
        ListTile(
          title: Text("Help"),
          leading: Icon(Icons.help, color: cs.onSurface),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, Routes.help);
          },
        ),

        ListTile(
          title: Text("Dict pop"),
          leading: Icon(Icons.book, color: cs.onSurface),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SearchWithSelection(showDrawer: false),
              ),
            );
          },
        ),
      ],
    ),
  );
}


