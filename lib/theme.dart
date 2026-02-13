import 'package:flutter/material.dart';

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
