import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/main_widgets.dart';
import 'package:flutter/cupertino.dart';

class ArabicNormalizer {
  // arabic only numbers
  static final arabicDigits = RegExp(r'^[\u0660-\u0669]+$');

  static bool isArabicNum(String s) => arabicDigits.hasMatch(s);

  // Arabic diacritics (tashkil)
  // static final RegExp _tashkil = RegExp(r'[\u064B-\u0652\u0670\u06D6-\u06ED]');
  // Only the 8 main tashkil marks
  static final RegExp _tashkil = RegExp(
    r'[\u064B-\u0652]', // Covers all 8: fathatan, dammatan, kasratan, fatha, damma, kasra, shadda, sukun
  );

  // Comprehensive tashkil pattern
  // static final RegExp _tashkil = RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED]' );

  // Fixed: removed redundant range
  static final RegExp _nonArabicLetters = RegExp(
    r'[^\u0621-\u063A\u0641-\u064A\u0649\u0629\u06CC_]',
  );

  // Remove everything except Arabic letters AND spaces
  // static final RegExp _nonArabicLettersKeepSpace = RegExp(
  //   r'[^\u0621-\u063A\u0641-\u064A\u0649\u0629\u06CC\u0020]',
  // );
  // // Keep only core Arabic letters (no tashkīl, no symbols)
  // static final RegExp _nonArabicLetters = RegExp(
  //   r'[^\u0621-\u063A\u0641-\u064A\u0649\u0629\u0622-\u0626\u06CC]',
  // );

  static final RegExp _farsiYaEnd = RegExp(r'\u06CC(?=\s|$)');
  static final RegExp _farsiYaMiddle = RegExp(r'\u06CC');
  static final RegExp _multiUnderscore = RegExp(r'_{2,}');
  static final RegExp _edgeUnderscore = RegExp(r'^_+|_+$');

  ///  Keep only Arabic letters.
  /// - Removes tashkīl
  /// - Removes symbols, numbers, spaces expect '_'
  /// - Normalizes Farsi ya (ی)
  static String keepOnlyAr(String word) {
    if (word.isEmpty) return word;

    final cleannedWord = word
        .replaceAll(_nonArabicLetters, '')
        .replaceAll(_multiUnderscore, '_')
        .replaceAll(_edgeUnderscore, '')
        .replaceAll(_farsiYaEnd, 'ى')
        .replaceAll(_farsiYaMiddle, 'ي');

    // print('og: $word\nou: $cleannedWord');
    return cleannedWord == '_' ? '' : cleannedWord;
  }

  static final RegExp _nonArabicLettersSpace = RegExp(
    r'[^\u0621-\u063A\u0641-\u064A\u0649\u0629\u06CC ]',
  );

  static final RegExp _whiteSpace = RegExp(r'\s+');
  static String keepOnlyArWithSpace(String word) {
    if (word.isEmpty) return word;

    return word
        .replaceAll(_nonArabicLettersSpace, '')
        .replaceAll(_farsiYaEnd, 'ى')
        .replaceAll(_farsiYaMiddle, 'ي')
        .replaceAll(_whiteSpace, ' ')
        .trim();
  }

  static List<String> keepOnlyArListUnique(String sentence) {
    sentence = sentence.trim();
    if (sentence.isEmpty) return [];

    List<String> res = [];
    for (final w in sentence.split(RegExp(r'\s+'))) {
      final cw = keepOnlyAr(w);
      if (cw.isEmpty) continue;
      res.remove(cw);
      res.add(cw);
    }
    return res;
  }

  /// Remove only tashkīl.
  /// Keeps letters, symbols, spaces, everything else.
  static String rmTashkil(String word) {
    if (word.isEmpty) return word;
    return word.replaceAll(_tashkil, '');
  }

  static final _multiSpace = RegExp(r'\s{2,}');

  static String cleanLineForSearch(String title) {
    title = title.trim();
    if (title.isEmpty) return '';
    final res = title
        .replaceAll(_tashkil, '')
        .replaceAll(_multiSpace, ' ')
        .trim();
    return res;
  }
}

Future<bool?> showCleanLineForSearchInfo(BuildContext context) async {
  final input = "نَعم، يَبدُو... أنك";
  final clInput = ArabicNormalizer.cleanLineForSearch(input);
  return showInfoDialog(
    context,
    fontFam: L.arFont,
    scroolable: true,
    'Info',
    message:
        // 'Search ignores diacritics (like ـُ ـِ ) and symbols (like ،.).\n'
        // 'Only Arabic letters and enlgish or arabic numbers are kept.\n\n'
        // // 'Example: نَعم، يَبدُو → نعم يبدو\n\n'
        // // 'Example: "نَعم، يَبدُو... أنك" becomes "نعم يبدو أنك"\n\n'
        // 'Example: "«نَعم، يَبدُو... أنك»" becomes "نعم يبدو أنك"\n\n'
        // 'Both your input and the book text are processed this way.',
        'Search is simplified before matching:\n'
        '• Diacritics are removed (e.g. َ ِ ُ )\n'
        'Example:\n'
        '"$input"\n'
        'becomes\n'
        '"$clInput"\n\n'
        'This same simplification is applied to both your input and the book text.',
    constraints: true,
  );
}
