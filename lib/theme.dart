import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:flutter/material.dart';

const double defaultReaderArabicFontSize = 20;
const String defaultReaderArabicFont = fontKitab;
const double defArabicFontHeihgt = 2.00;

const Color uiSeedColorDefualt = Color(0xFFFFC107);
const uiSeedColors = [
  uiSeedColorDefualt,
  Color(0xFF673AB7),
  Color(0xFF3A7BD4),
  Color(0xFF2A9D8E),
  Color(0xFF2ECC71),
  Color(0xFFE76F50),
];

const bookmarkWordBg = Color(0xE0FFF3A3);
const foreignWordBg = Color(0xA0D9F7BE);

const bookmarkWordBgDark = Color(0xE0513f13);
const foreignWordBgDark = Color(0xC025543b);

class ReaderColors {
  final Color surface;
  final Color onSurface;
  final Color definitionSurface;
  final Color outline;
  final Color shadow;

  const ReaderColors({
    required this.surface,
    required this.onSurface,
    required this.definitionSurface,
    required this.outline,
    required this.shadow,
  });

  static ReaderColors curr(BuildContext c) =>
      Theme.of(c).brightness == Brightness.light
      ? readerColorsLight
      : readerColorsDark;

  static ReaderColors m3(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    return ReaderColors(
      onSurface: cs.onSurface,
      surface: cs.surface,
      definitionSurface: cs.surfaceContainerLow,
      outline: cs.outline.withAlpha(180),
      shadow: cs.shadow.withAlpha(30),
    );
  }
}

const readerColorsLight = ReaderColors(
  surface: Color(0xFFFFFAF3),
  // onSurface: Color(0xFF222223),
  onSurface: Color(0xFF302820), // Dark ink
  definitionSurface: Color(0xFFFFFDF8), // Lighter paper
  outline: Color(0xFFE7DCCB), // Soft beige
  shadow: Color(0x163B2A18), // Warm, subtle shadow
);

const readerColorsDark = ReaderColors(
  // surface: Color(0xFF121212),
  // onSurface: Color(0xFFEAEAEA),
  surface: Color(0xFF141311), // Deep charcoal
  onSurface: Color(0xFFE8E0D4), // Warm ivory
  definitionSurface: Color(0xFF1E1C19), // Raised charcoal
  outline: Color(0xFF39342D), // Muted warm border
  shadow: Color(0x55000000), //
);

// class ReaderColors {
//   final Color surface;
//   final Color onSurface;
//
//   const ReaderColors({required this.surface, required this.onSurface});
// }
//
// const readerColorsLight = ReaderColors(
//   surface: Color(0xFFFFFAF3),
//   onSurface: Color(0xFF222223),
// );
//
// const readerColorsDark = ReaderColors(
//   surface: Color(0xFF121212),
//   onSurface: Color(0xFFEAEAEA),
// );

// Borders
final readerBorderLight = readerColorsLight.onSurface.withAlpha(31); // ~0.12
final readerBorderDark = readerColorsDark.onSurface.withAlpha(36); // ~0.14

// Optional odd-row tint
final oddRowLight = readerColorsLight.onSurface.withAlpha(9); // ~0.035
final oddRowDark = readerColorsDark.onSurface.withAlpha(11); // ~0.045

ThemeData buildTheme(
  BuildContext context,
  Brightness b,
  AppSettingsController an, {
  ReaderColors? rs,
}) {
  final csM3 = ColorScheme.fromSeed(seedColor: an.seedColor, brightness: b);

  final cs = rs == null
      ? csM3
      : csM3.copyWith(surface: rs.surface, onSurface: rs.onSurface);

  var td = ThemeData.from(colorScheme: cs, useMaterial3: true);

  const uiEngFont = fontInter;
  const uiArFont = fontNotoSansArabic;
  td = td.copyWith(
    textTheme: td.textTheme.apply(
      fontFamily: uiEngFont,
      fontFamilyFallback: [uiArFont],
    ),
    primaryTextTheme: td.primaryTextTheme.apply(
      fontFamily: uiEngFont,
      fontFamilyFallback: [uiArFont],
    ),

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
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: cs.outlineVariant.withValues(alpha: 0.38),
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
    ),
  );
  return td;
}
