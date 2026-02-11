import 'package:ara_dict/theme.dart';
import 'package:flutter/material.dart';

final appSettingsNotifier = AppSettingsController();

const appName = 'Arabic Lexcions';

const fontAmiri = 'Amiri';
const fontKitab = 'Kitab';

const scrollPadding = EdgeInsets.only(left: 8, right: 8, top: 0, bottom: 16);

const dictWordSelectModalOpenIcon = Icon(Icons.book);

class Routes {
  static const dictionary = '/dictionary';
  static const reader = '/reader';
  static const help = '/help';
}

class DictEntry {
  final Dict d;
  final String ar;
  final String en;

  const DictEntry({required this.d, required this.ar, required this.en});
}

enum Dict {
  arEn,
  hanswehr,
  laneLexicon,
  mujamulGhoni,
  mujamulShihah,
  lisanAlArab,
  mujamulMuashiroh,
  mujamulWasith,
  mujamulMuhith,
}

String getDictTableName(Dict d) {
  switch (d) {
    case Dict.arEn:
      return "arEn";
    case Dict.hanswehr:
      return "hanswehr";
    case Dict.laneLexicon:
      return "lanelexcon";
    case Dict.mujamulGhoni:
      return "mujamul_ghoni";
    case Dict.mujamulShihah:
      return "mujamul_shihah";
    case Dict.lisanAlArab:
      return "lisanularab";
    case Dict.mujamulMuashiroh:
      return "mujamul_muashiroh";
    case Dict.mujamulWasith:
      return "mujamul_wasith";
    case Dict.mujamulMuhith:
      return "mujamul_muhith";
  }
}

// final List<DictEntry> dictNames = [
//   DictEntry(d: Dict.arEn, ar: "مباشر", en: "Dicrect dictionary"),
//   DictEntry(d: Dict.hanswehr, ar: "هانز", en: "Hans"),
//   DictEntry(d: Dict.laneLexicon, ar: "لين", en: "Lane"),
//   DictEntry(d: Dict.mujamulGhoni, ar: "الغني", en: "Ghani"),
//   DictEntry(d: Dict.mujamulShihah, ar: "مختار", en: "Mukhtar"),
//   DictEntry(d: Dict.lisanAlArab, ar: "لسان", en: "Lisan"),
//   DictEntry(d: Dict.mujamulMuashiroh, ar: "المعاصرة", en: "Muasiroh"),
//   DictEntry(d: Dict.mujamulWasith, ar: "الوسيط", en: "Wasat"),
//   DictEntry(d: Dict.mujamulMuhith, ar: "المحيط", en: "Muthktar"),
// ];

final List<DictEntry> dictNames = [
  DictEntry(d: Dict.arEn, ar: "مباشر", en: "Direct Dictionary"),
  DictEntry(d: Dict.hanswehr, ar: "هانز", en: "Hans Wehr"),
  DictEntry(d: Dict.laneLexicon, ar: "لين", en: "Lane Lexicon"),
  DictEntry(d: Dict.mujamulGhoni, ar: "الغني", en: "Al-Ghani"),
  DictEntry(d: Dict.mujamulShihah, ar: "مختار", en: "Mukhtar"),
  DictEntry(d: Dict.lisanAlArab, ar: "لسان", en: "Lisan Al-Arab"),
  DictEntry(d: Dict.mujamulMuashiroh, ar: "المعاصرة", en: "Al-Muashirah"),
  DictEntry(d: Dict.mujamulWasith, ar: "الوسيط", en: "Al-Waseet"),
  DictEntry(d: Dict.mujamulMuhith, ar: "المحيط", en: "Al-Muhit"),
];
