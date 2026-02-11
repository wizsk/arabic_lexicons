import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ara_dict/data.dart';

double mediumFontSize = 18;
double defaultArabicFontSize = 18;
const _seedColor = Colors.deepPurple;

ThemeData buildLightTheme(BuildContext context, double mediumFontSizeArg) {
  final cs = ColorScheme.fromSeed(seedColor: _seedColor).copyWith(
    brightness: Brightness.light,
    surface: const Color(0xFFFFFAF3),
    onSurface: const Color(0xFF222223),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: cs,
    scaffoldBackgroundColor: const Color(0xFFFFFAF3),
    drawerTheme: _buildDrawerTheme(cs),
    appBarTheme: _buildAppBarTheme(cs, mediumFontSizeArg),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(color: Color(0xFFAAAAAA)),
    ),
  );
}

ThemeData buildDarkTheme(BuildContext context, double mediumFontSizeArg) {
  final cs =
      ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ).copyWith(
        brightness: Brightness.dark,
        surface: const Color(0xFF121212),
        onSurface: const Color(0xFFEAEAEA),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: cs,
    scaffoldBackgroundColor: const Color(0xFF121212),
    drawerTheme: _buildDrawerTheme(cs),
    appBarTheme: _buildAppBarTheme(cs, mediumFontSizeArg),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(color: Color(0xFF777777)),
    ),
  );
}

DrawerThemeData _buildDrawerTheme(ColorScheme cs) {
  return DrawerThemeData(
    backgroundColor: cs.surface, // your paper color
    scrimColor: cs.onSurface.withAlpha(30), // overlay when drawer opens
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
    ),
  );
}

AppBarTheme _buildAppBarTheme(ColorScheme cs, double mediumFontSizeArg) {
  return AppBarTheme(
    backgroundColor: cs.primary,
    foregroundColor: cs.onPrimary,
    centerTitle: true,
    titleTextStyle: TextStyle(fontSize: 20, color: cs.onPrimary),
  );
}

class AppSettingsController extends ChangeNotifier {
  static const _themeKey = 'theme_mode';
  static const _fontKey = 'ar_font_size';

  late double fontSize;
  late ThemeMode theme;

  /// Load saved theme & font size from memory
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final mode = prefs.getString(_themeKey);
    theme = mode == 'dark' ? ThemeMode.dark : ThemeMode.light;

    fontSize = prefs.getDouble(_fontKey) ?? defaultArabicFontSize;
  }

  Future<void> saveTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    theme = mode;
    notifyListeners();
    prefs.setString(_themeKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> setFontSize(double size) async {
    fontSize = size;
    final prefs = await SharedPreferences.getInstance();
    notifyListeners();
    prefs.setDouble(_fontKey, size);
  }

  TextStyle getArabicTextStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontFamily: fontKitab,
      fontSize: fontSize,
      height: 1.5,
    );
  }
}
