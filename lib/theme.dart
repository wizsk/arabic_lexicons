import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ara_dict/data.dart';

const double mediumFontSize = 18;

final _baseScheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple);

ThemeData buildLightTheme(BuildContext context) {
  final cs = _baseScheme.copyWith(
    brightness: Brightness.light,
    surface: const Color(0xFFFFFAF3),
    onSurface: const Color(0xFF222223),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: cs,
    scaffoldBackgroundColor: const Color(0xFFFFFAF3),
    textTheme: _buildArabicTextTheme(cs),
    drawerTheme: _buildDrawerTheme(cs),
    appBarTheme: _buildAppBarTheme(cs),
    // dividerColor:
  );
}

ThemeData buildDarkTheme(BuildContext context) {
  final cs = _baseScheme.copyWith(
    brightness: Brightness.dark,
    surface: const Color(0xFF121212),
    onSurface: const Color(0xFFEAEAEA),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: cs,
    scaffoldBackgroundColor: const Color(0xFF121212),
    textTheme: _buildArabicTextTheme(cs),
    drawerTheme: _buildDrawerTheme(cs),
    appBarTheme: _buildAppBarTheme(cs),
    // dividerColor: Color.fromARGB(255, 111,111,111),
    iconTheme: IconThemeData(
      color: cs.onSurface, // force readable icons
    ),
  );
}

TextTheme _buildArabicTextTheme(ColorScheme cs) {
  // start from Material 2021
  final base = Typography.material2021().englishLike;

  return base.copyWith(
    bodySmall: base.bodySmall?.copyWith(
      fontFamily: fontKitab,
      height: 1.3,
      color: cs.onSurface,
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      fontSize: mediumFontSize,
      fontFamily: fontKitab,
      height: 1.5,
      color: cs.onSurface,
    ),
    bodyLarge: base.bodyLarge?.copyWith(
      fontFamily: fontKitab,
      height: 1.5,
      color: cs.onSurface,
    ),
    titleLarge: base.titleLarge?.copyWith(
      fontFamily: fontKitab,
      color: cs.onSurface,
    ),
    titleMedium: base.titleMedium?.copyWith(
      fontFamily: fontKitab,
      color: cs.onSurface,
    ),
    titleSmall: base.titleSmall?.copyWith(
      fontFamily: fontKitab,
      color: cs.onSurface,
    ),
  );
}

// TextTheme __buildArabicTextTheme(ColorScheme cs) {
//   return Typography.material2021()
//       .englishLike // base English, then we override for Arabic
//       .apply(
//         fontFamily: fontKitab,
//         fontSizeFactor: 1.2,
//         fontSizeDelta: 2.0,
//         bodyColor: cs.onSurface,
//         displayColor: cs.onSurface,
//       )
//       .copyWith(
//         bodyMedium: Typography.material2021().englishLike.bodyMedium?.copyWith(
//           fontFamily: fontKitab,
//           height: 1.5,
//         ), // better line height for Arabic
//         bodyLarge: Typography.material2021().englishLike.bodyLarge?.copyWith(
//           fontFamily: fontKitab,
//           height: 1.5,
//         ),
//         bodySmall: Typography.material2021().englishLike.bodySmall?.copyWith(
//           fontFamily: fontKitab,
//           height: 1.3,
//         ),
//       );
// }

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

AppBarTheme _buildAppBarTheme(ColorScheme cs) {
  return AppBarTheme(
    backgroundColor: cs.primary, // deepPurple derived
    foregroundColor: cs.onPrimary, // text & icons automatically adapt
    centerTitle: true, // if you want centered
    titleTextStyle: TextStyle(
      fontFamily: fontKitab,
      fontSize: mediumFontSize * 1.15,
      // fontWeight: FontWeight.bold,
      color: cs.onPrimary, // force AppBar title color
    ),
  );
}

class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.light);

  static const _key = 'theme_mode';

  /// Load saved theme from memory
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(_key);

    // if (mode == 'light') {
    // } else
    if (mode == 'dark') {
      value = ThemeMode.dark;
    } else {
      // value = ThemeMode.system;
      value = ThemeMode.light;
    }
  }

  /// Save theme to memory
  Future<void> save(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    value = mode;

    await prefs.setString(_key, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  /// Toggle light/dark
  Future<void> toggle() async {
    if (value == ThemeMode.light) {
      await save(ThemeMode.dark);
    } else {
      await save(ThemeMode.light);
    }
  }
}
