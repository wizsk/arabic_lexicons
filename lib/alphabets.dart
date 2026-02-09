import 'package:flutter/cupertino.dart';

String cleanWord(String w) {
  return w.characters.where((c) => arabicLetters.contains(c)).join("");
}

List<String> cleanQeury(String query) {
  final res = query
      .trim()
      .split(RegExp(r'\s+'))
      .map((e) {
        return e.split("").where((c) => arabicLetters.contains(c)).join("");
      })
      .where((e) => e.isNotEmpty)
      .toList();

  return res;
}

final Set<String> arabicLetters = {
  String.fromCharCode(0x0623), // أ
  String.fromCharCode(0x0627), // ا
  String.fromCharCode(0x0622), // آ
  String.fromCharCode(0x0621), // ء
  String.fromCharCode(0x0624), // ؤ
  String.fromCharCode(0x0625), // أ
  String.fromCharCode(0x0626), // ئ
  String.fromCharCode(0x0628), // ب
  String.fromCharCode(0x062A), // ت
  String.fromCharCode(0x0629), // ة
  String.fromCharCode(0x062b), // ث
  String.fromCharCode(0x062c), // ج
  String.fromCharCode(0x062d), // ح
  String.fromCharCode(0x062e), // خ
  String.fromCharCode(0x062f), // د
  String.fromCharCode(0x0630), // ذ
  String.fromCharCode(0x0631), // ر
  String.fromCharCode(0x0632), // ز
  String.fromCharCode(0x0633), // س
  String.fromCharCode(0x0634), // ش
  String.fromCharCode(0x0635), // ص
  String.fromCharCode(0x0636), // ض
  String.fromCharCode(0x0637), // ط
  String.fromCharCode(0x0638), // ظ
  String.fromCharCode(0x0639), // ع
  String.fromCharCode(0x063a), // غ
  String.fromCharCode(0x0641), // ف
  String.fromCharCode(0x0642), // ق
  String.fromCharCode(0x0643), // ك
  String.fromCharCode(0x0644), // ل
  String.fromCharCode(0x0645), // م
  String.fromCharCode(0x0646), // ن
  String.fromCharCode(0x0647), // ه
  String.fromCharCode(0x0648), // و
  String.fromCharCode(0x06cc), // یfasrsi yaaa
  String.fromCharCode(0x064a), // ي
  String.fromCharCode(0x0649), // ى
  String.fromCharCode(0xfefb), // لا
  String.fromCharCode(0xfef7), // ﻷ
};
