import 'package:ara_dict/book_marks.dart';
import 'package:ara_dict/reader.dart';
import 'package:ara_dict/theme.dart';
import 'package:flutter/material.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/ar_en.dart';
import 'package:ara_dict/db.dart';
import 'package:ara_dict/lexicons.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DbService.init();
  await ArEnDict.init();
  await BookMarks.load();
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
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: appSettingsNotifier.wake.onUserActivity,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Arabic Lexicons',

            theme: buildLightTheme(context, appSettingsNotifier.fontSize),
            darkTheme: buildDarkTheme(context, appSettingsNotifier.fontSize),
            themeMode: appSettingsNotifier.theme,
            initialRoute: Routes.dictionary,
            routes: {
              Routes.dictionary: (_) => const SearchLexicons(),
              Routes.reader: (_) => const ReaderPage(),
              Routes.bookMarks: (_) => const BookMarkPage(),
              // Routes.fams: (_) => const ArabicFamilyList(),
              // Routes.help: (_) => const HelpPage(),
            },
          ),
        );
      },
    );
  }
}
