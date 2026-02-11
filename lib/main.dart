import 'package:ara_dict/help.dart';
import 'package:ara_dict/reader.dart';
import 'package:ara_dict/theme.dart';
import 'package:flutter/material.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/ar_en.dart';
import 'package:ara_dict/db.dart';
import 'package:ara_dict/lexicons.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DbService.init();
  await ArEnDict.init();
  await appSettingsNotifier.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appSettingsNotifier,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: cs.primary,
            statusBarIconBrightness: appSettingsNotifier.theme == ThemeMode.dark
                ? Brightness.light
                : Brightness.dark,
          ),
        );
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Arabic Lexicons',

          theme: buildLightTheme(context, appSettingsNotifier.fontSize),
          darkTheme: buildDarkTheme(context, appSettingsNotifier.fontSize),
          themeMode: appSettingsNotifier.theme,
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
