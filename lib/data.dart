const fontAmiri = 'Amiri';
const fontKitab = 'Kitab';

class DictEntry {
  final Dict d;
  final String ar;

  const DictEntry({required this.d, required this.ar});
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

final List<DictEntry> dictNames = [
  DictEntry(d: Dict.arEn, ar: "مباشر"),
  DictEntry(d: Dict.hanswehr, ar: "هانز"),
  DictEntry(d: Dict.laneLexicon, ar: "لين"),
  DictEntry(d: Dict.mujamulGhoni, ar: "الغني"),
  DictEntry(d: Dict.mujamulShihah, ar: "مختار"),
  DictEntry(d: Dict.lisanAlArab, ar: "لسان"),
  DictEntry(d: Dict.mujamulMuashiroh, ar: "المعاصرة"),
  DictEntry(d: Dict.mujamulWasith, ar: "الوسيط"),
  DictEntry(d: Dict.mujamulMuhith, ar: "المحيط"),
];
