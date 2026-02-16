class ArabicNormalizer {
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
    r'[^\u0621-\u063A\u0641-\u064A\u0649\u0629\u06CC]',
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

  /// 1️⃣ Keep only Arabic letters.
  /// - Removes tashkīl
  /// - Removes symbols, numbers, spaces
  /// - Normalizes Farsi ya (ی)
  static String keepOnlyAr(String word) {
    if (word.isEmpty) return word;

    return word
        .replaceAll(_nonArabicLetters, '')
        .replaceAll(_farsiYaEnd, '')
        .replaceAll(_farsiYaMiddle, 'ي');
  }

  static List<String> keepOnlyArList(String sentence) {
    sentence = sentence.trim();
    if (sentence.isEmpty) return [];

    List<String> res = [];
    for (final w in sentence.split(RegExp(r'\s+'))) {
      final cw = keepOnlyAr(w);
      if (cw.isEmpty) continue;
      res.add(cw);
    }
    return res;
  }

  /// 2️⃣ Remove only tashkīl.
  /// Keeps letters, symbols, spaces, everything else.
  static String rmTashkil(String word) {
    if (word.isEmpty) return word;
    return word.replaceAll(_tashkil, '');
  }
}
