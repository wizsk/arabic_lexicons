import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:flutter/material.dart';

const double mediumFontSize = 18;
const double defaultReaderArabicFontSize = 18;
const String defaultReaderArabicFont = fontKitab;
const double defArabicFontHeihgt = 2.00;

const Color uiSeedColorDefualt = Color(0xFF673AB7);
const uiSeedColors = [
  uiSeedColorDefualt,
  Color(0xFF3A7BD4),
  Color(0xFF2A9D8E),
  Color(0xFF2ECC71),
  Color(0xFFE76F50),
];

class ReaderColors {
  final Color surface;
  final Color onSurface;

  const ReaderColors({required this.surface, required this.onSurface});
}

const readerColorsLight = ReaderColors(
  surface: Color(0xFFFFFAF3),
  onSurface: Color(0xFF222223),
);

const readerColorsDark = ReaderColors(
  surface: Color(0xFF121212),
  onSurface: Color(0xFFEAEAEA),
);

ThemeData buildTheme(
  BuildContext context,
  Brightness b,
  AppSettingsController an,
) {
  final cs = ColorScheme.fromSeed(seedColor: an.seedColor, brightness: b);
  var td = ThemeData.from(colorScheme: cs, useMaterial3: true);
  td = td.copyWith(
    appBarTheme: td.appBarTheme.copyWith(
      centerTitle: true,
      actionsPadding: const EdgeInsets.only(right: 8),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cs.surfaceContainerHigh,
      hintStyle: TextStyle(color: cs.onSurfaceVariant.withAlpha(128)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.outlineVariant, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.outlineVariant, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
    ),
  );
  return td;
}
