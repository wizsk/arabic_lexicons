import 'package:ara_dict/help.dart';
import 'package:ara_dict/reader.dart';
import 'package:ara_dict/theme.dart';
import 'package:flutter/material.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/ar_en.dart';
import 'package:ara_dict/db.dart';
import 'package:ara_dict/lexicons.dart';

final themeModeNotifier = ThemeController();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DbService.init();
  await ArEnDict.init();
  await themeModeNotifier.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Arabic Lexicons',

          theme: buildLightTheme(context),
          darkTheme: buildDarkTheme(context),
          themeMode: mode,
          initialRoute: Routes.dictionary,
          routes: {
            Routes.dictionary: (_) => const SearchLexicons(),
            Routes.reader: (_) => const ReaderPage(),
            Routes.help: (_) => const HelpPage(),
          },
        );
      },
    );
  }
}
