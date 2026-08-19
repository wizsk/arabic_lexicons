import 'package:ara_dict/conf.dart';
import 'package:flutter/material.dart';

final appConf = AppSettingsController();

const appName = 'Arabic Lexcions';

const fontAmiri = 'Amiri';
const fontKitab = 'Kitab';
const fontNotoSansArabic = 'NotoSansArabic';
const fontPlayPen = 'Playpen';
// const fontRubik = 'Rubik';
// const fontUthman = 'Uthman';
// const fontTajawal = 'Tajawal';

const double htmlFontHeight = 1.7;

const arabicFonts = [
  fontKitab,
  fontAmiri,
  fontNotoSansArabic,
  fontPlayPen,
  // fontRubik,
  // fontTajawal,
];

const scrollPadding = EdgeInsets.only(left: 10, right: 10, top: 0, bottom: 140);

@pragma("vm:prefer-inline")
EdgeInsets scrollPaddingW({
  double? top,
  double? bottom,
  double? right,
  double? left,
}) =>
    scrollPadding.copyWith(bottom: bottom, top: top, right: right, left: left);

@pragma("vm:prefer-inline")
EdgeInsets scrollPaddingS({
  double? horizontal, //sides
  double? vertical, //up down
}) => scrollPadding.copyWith(
  bottom: vertical,
  top: vertical,
  right: horizontal,
  left: horizontal,
);

@pragma("vm:prefer-inline")
EdgeInsets scrollPaddingBottmSheet(BuildContext context, {double? sides}) =>
    scrollPadding.copyWith(
      right: sides,
      left: sides,
      bottom: appConf.fullScreen
          ? 12
          : MediaQuery.of(context).padding.bottom + 12,
    );

const dictWordSelectModalOpenIcon = Icons.swap_horiz_rounded;

BorderRadius roundedTop(double round) => BorderRadius.only(
  topLeft: Radius.circular(round),
  topRight: Radius.circular(round),
);

BorderRadius roundedBottm(double round) => BorderRadius.only(
  bottomLeft: Radius.circular(round),
  bottomRight: Radius.circular(round),
);

abstract final class Routes {
  static const startupscreen = '/startupscreen';

  static const dictionary = '/dictionary';
  static const readerInput = '/readerInput';
  static const readerPage = '/readerPage';

  static const bookMarks = '/bookMarks';
  static const foreings = '/foreigns';
  static const searhHist = '/sHist';

  static const settings = '/settings';
  static const fams = '/fams';
  static const help = '/help';
}

const routesToBeSavedInPref = [
  Routes.dictionary,
  Routes.readerInput,
  Routes.readerPage,
];

// class DictEntry {
//   final Dict d;
//   final String ar;
//   final String en;

//   const DictEntry({required this.d, required this.ar, required this.en});
// }

List<Dict> allDictsOrd = List.from(allDicts);

const List<Dict> allDicts = [
  Dict.arEn,
  Dict.hanswehr,
  Dict.laneLexicon,
  Dict.mujamulGhoni,
  Dict.mujamulShihah,
  Dict.lisanAlArab,
  Dict.mujamulMuashiroh,
  Dict.mujamulWasith,
  Dict.mujamulMuhith,
  Dict.maqayeesulLuga,
  Dict.mufradatAlfajulQuran,
];

/// DictLang
extension DL on Dict {
  /// returns the dict name for the current language
  String get name => L.p(en, ar);
}

enum Dict {
  arEn(
    table: "arEn",
    ar: "مباشر",
    en: "Direct",
    enLong: "Aratools Arabic–English",
    description:
        "GPL-licensed components of the Aratools Arabic-English dictionary. "
        "Based on Tim Buckwalter’s Aramorph Arabic morphological analyzer "
        "(dictprefixes, dictstems, dictsuffixes, tableab, tableac, tablebc). "
        "Distributed via Aramorph and Linguistic Data Consortium sources.",
    link: "http://www.nongnu.org/aramorph/",
  ),

  hanswehr(
    table: "hanswehr",
    ar: "هانز",
    en: "Hans",
    enLong: "Hans Wehr Dictionary",
    description:
        "Modern Arabic–English dictionary compiled by Hans Wehr. "
        "Widely used academic reference organized by triliteral roots.",
    link: "https://en.wikipedia.org/wiki/Hans_Wehr_dictionary",
  ),

  laneLexicon(
    table: "lanelexcon",
    ar: "لين",
    en: "Lane",
    enLong: "Lane’s Arabic-English Lexicon",
    description:
        "Comprehensive 19th-century Arabic-English lexicon by Edward William Lane, "
        "based on major classical sources.",
    link: "https://en.wikipedia.org/wiki/Edward_William_Lane",
  ),

  mujamulGhoni(
    table: "mujamul_ghoni",
    ar: "غني",
    en: "Ghani",
    enLong: "Al-Muʿjam al-Ghani",
    description:
        "Contemporary Arabic dictionary focusing on modern vocabulary and usage.",
  ),

  mujamulShihah(
    table: "mujamul_shihah",
    ar: "صحاح",
    en: "Sihah",
    enLong: "Al-Sihah (al-Jawhari)",
    description:
        "Classical Arabic dictionary by al-Jawhari (4th century AH), "
        "one of the foundational root-based lexicons.",
    link: "https://ar.wikipedia.org/wiki/الصحاح_في_اللغة",
    hasRefs: true,
  ),

  lisanAlArab(
    table: "lisanularab",
    ar: "لسان",
    en: "Lisan",
    enLong: "Lisan al-Arab",
    description:
        "Major classical Arabic lexicon compiled by Ibn Manzur (7th century AH), "
        "drawing from earlier authoritative sources.",
    link: "https://en.wikipedia.org/wiki/Lisan_al-Arab",
    hasRefs: true,
  ),

  mujamulMuashiroh(
    table: "mujamul_muashiroh",
    ar: "معاصرة",
    en: "Muasiroh",
    enLong: "Al-Muʿjam al-Muʿasirah",
    description:
        "Modern Arabic dictionary emphasizing contemporary terminology and usage.",
  ),

  mujamulWasith(
    table: "mujamul_wasith",
    ar: "وسيط",
    en: "Wasit",
    enLong: "Al-Muʿjam al-Wasit",
    description:
        "Standard modern Arabic dictionary published by the Arabic Language Academy in Cairo.",
    link: "https://ar.wikipedia.org/wiki/المعجم_الوسيط",
  ),

  mujamulMuhith(
    table: "mujamul_muhith",
    ar: "محيط",
    en: "Muhit",
    enLong: "Al-Qamus al-Muhit",
    description:
        "Influential classical dictionary by al-Firuzabadi (8th century AH), "
        "widely cited in later lexicons.",
    link: "https://ar.wikipedia.org/wiki/القاموس_المحيط",
  ),

  maqayeesulLuga(
    table: "maqayeesul_luga",
    ar: "مقاييس",
    en: "Maqayes",
    enLong: "Maqayis al-Lugha",
    description:
        "Root-based semantic analysis by Ibn Faris (4th century AH), "
        "reducing each root to its core conceptual meanings.",
    link: "https://ar.wikipedia.org/wiki/مقاييس_اللغة",
    hasRefs: true,
  ),

  mufradatAlfajulQuran(
    table: "mufradat_alfajul_quran",
    ar: "مفردات",
    en: "Mufradat",
    enLong: "Mufradat Alfaz al-Qur’an",
    description:
        "Qur’anic lexicon by al-Raghib al-Isfahani, "
        "analyzing vocabulary and semantic nuances of Qur’anic terms.",
    link: "https://ar.wikipedia.org/wiki/المفردات_في_غريب_القرآن",
    hasRefs: true,
  );

  final String table;
  final String ar;
  final String en;
  final String enLong;
  final String description;
  final String? link;
  final bool hasRefs;

  const Dict({
    required this.table,
    required this.ar,
    required this.en,
    required this.enLong,
    required this.description,
    this.link,
    this.hasRefs = false,
  });

  bool get showTitle => this == mujamulGhoni;
}

int encode(Set<Dict> selected) {
  int mask = 0;
  for (final d in selected) {
    mask |= (1 << d.index);
  }
  return mask;
}

Set<Dict> decode(int mask) {
  final result = <Dict>{};

  for (final d in Dict.values) {
    if ((mask & (1 << d.index)) != 0) {
      result.add(d);
    }
  }

  return result;
}

bool isDictHasRefs(Dict d) {
  return switch (d) {
    Dict.mujamulShihah ||
    Dict.lisanAlArab ||
    Dict.mufradatAlfajulQuran ||
    Dict.maqayeesulLuga => true,
    _ => false,
  };
}
