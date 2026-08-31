import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/history/page.dart';
import 'package:arabic_lexicons/lex/lexicons.dart';
import 'package:arabic_lexicons/pages/fams/fams.dart';
import 'package:arabic_lexicons/pages/help/help.dart';
import 'package:arabic_lexicons/pages/settings/settings.dart';
import 'package:arabic_lexicons/pages/startup_screen.dart';
import 'package:arabic_lexicons/pages/welcome_screen.dart';
import 'package:arabic_lexicons/reader/input.dart';
import 'package:arabic_lexicons/reader/reader.dart';
import 'package:arabic_lexicons/theme.dart';
import 'package:arabic_lexicons/word_list/page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() {
  // WidgetsFlutterBinding.ensureInitialized();
  // await appSettingsNotifier.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appConf,
      builder: (context, _) {
        return Listener(
          // makes sure it's triggered every click
          behavior: HitTestBehavior.translucent,
          onPointerDown: WakelockController.isEnabled
              ? WakelockController.onUserActivity
              : null,
          // onPointerMove: WakelockController.onUserActivity,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: kDebugMode ? '(D) Arabic Lexicons' : 'Arabic Lexicons',

            theme: buildTheme(context, Brightness.light, appConf),
            darkTheme: buildTheme(context, Brightness.dark, appConf),
            themeMode: appConf.theme,
            initialRoute: Routes.startupscreen,
            routes: {
              Routes.startupscreen: (_) => const StartupScreen(),
              Routes.welcome: (_) => const WelcomeScreen(),

              Routes.dictionary: (_) => const SearchLexicons(),
              Routes.readerInput: (_) => const ReaderInputPage(),
              Routes.readerPage: (_) => const ReaderPage(bookHash: null),

              Routes.bookMarks: (_) =>
                  const WordListPage(listType: WordListType.bookmarks),
              Routes.foreings: (_) =>
                  const WordListPage(listType: WordListType.foreings),
              Routes.searhHist: (_) => const HistPage(),

              Routes.settings: (_) => const SettingsPage(),
              Routes.fams: (_) => const ArabicFamilyList(),
              Routes.help: (_) => const HelpPage(),
            },
          ),
        );
      },
    );
  }
}
