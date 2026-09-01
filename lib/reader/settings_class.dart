import 'dart:convert';
import 'dart:io';

import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/pages/width_padd.dart';
import 'package:arabic_lexicons/reader/book_entries_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

const readerConfDirNameOld = 'reader_conf';

sealed class ReaderSettingsRes {}

class RPS extends ReaderSettingsRes {
  final ReaderPageSettings res;
  RPS(this.res);
}

// class OpenPopup extends ReaderSettingsRes {
//   final ReaderPopup value;
//   OpenPopup(this.value);
// }

// enum ReaderPopup { width, padding }

class ReaderPageSettings {
  static const double maxWidthDef = 720;
  static const double paddingDef = 10;

  VoidCallback? _onChange;

  void callOnChange() {
    _onChange?.call();
  }

  set onChange(VoidCallback f) {
    _onChange = f;
  }

  final String bookHash;
  bool isQasidah;
  bool isQasidahCentered;
  bool qasidahLineNum;
  bool isRmTashkil;
  bool isBmColored;
  bool saveLastPeraIdx;
  bool foreignAdd;
  bool foreignColored;
  TextAlign textAlign;
  String fontFam;
  double fontSize;
  double fontHeight;
  double maxWidth;
  double padding;

  ReaderPageSettings({
    required this.bookHash,
    required this.isQasidah,
    required this.isQasidahCentered,
    required this.qasidahLineNum,
    required this.isRmTashkil,
    required this.isBmColored,
    required this.saveLastPeraIdx,
    required this.fontFam,
    required this.textAlign,
    required this.fontSize,
    required this.fontHeight,
    required this.foreignAdd,
    required this.foreignColored,
    required this.maxWidth,
    required this.padding,
  });

  static ReaderPageSettings def({String hash = "", bool? isQasidah}) =>
      ReaderPageSettings(
        bookHash: hash,
        isQasidah: isQasidah ?? false,
        isQasidahCentered: false,
        qasidahLineNum: true,
        isRmTashkil: false,
        isBmColored: true,
        saveLastPeraIdx: true,
        fontFam: appConf.readerFont,
        fontSize: appConf.readerFontSize,
        fontHeight: appConf.readerFontHeight,
        textAlign: TextAlign.justify,
        foreignAdd: true,
        foreignColored: appConf.luwColored,
        maxWidth: appConf.maxWidth,
        padding: appConf.padding,
      );

  bool isEqual(ReaderPageSettings rs) {
    return isQasidah == rs.isQasidah &&
        isQasidahCentered == rs.isQasidahCentered &&
        qasidahLineNum == rs.qasidahLineNum &&
        isRmTashkil == rs.isRmTashkil &&
        isBmColored == rs.isBmColored &&
        saveLastPeraIdx == rs.saveLastPeraIdx &&
        fontFam == rs.fontFam &&
        textAlign == rs.textAlign &&
        foreignAdd == rs.foreignAdd &&
        foreignColored == rs.foreignColored &&
        maxWidth == rs.maxWidth &&
        padding == rs.padding &&
        fontHeight == rs.fontHeight &&
        fontSize == rs.fontSize;
  }

  void applyRAD(ReaderAdjustData d) {
    maxWidth = d.maxWidth;
    padding = d.padding;
    fontFam = d.fontFam;
    fontSize = d.fontSize;
    fontHeight = d.fontHeight;
  }

  ReaderPageSettings copyWith({
    String? bookHash,
    bool? isQasidah,
    bool? isQasidahCentered,
    bool? qasidahLineNum,
    bool? isRmTashkil,
    bool? isBmColored,
    bool? isOpenLexiconDirecly,
    bool? saveLastPeraIdx,
    String? fontFam,
    TextAlign? textAlign,
    double? fontSize,
    double? fontHeight,
    bool? foreignAdd,
    bool? foreignColored,
    double? padding,
    double? maxWidth,
  }) {
    return ReaderPageSettings(
      bookHash: bookHash ?? this.bookHash,
      isQasidah: isQasidah ?? this.isQasidah,
      isQasidahCentered: isQasidahCentered ?? this.isQasidahCentered,
      qasidahLineNum: qasidahLineNum ?? this.qasidahLineNum,
      isRmTashkil: isRmTashkil ?? this.isRmTashkil,
      isBmColored: isBmColored ?? this.isBmColored,
      saveLastPeraIdx: saveLastPeraIdx ?? this.saveLastPeraIdx,
      fontFam: fontFam ?? this.fontFam,
      textAlign: textAlign ?? this.textAlign,
      fontSize: fontSize ?? this.fontSize,
      fontHeight: fontHeight ?? this.fontHeight,
      foreignAdd: foreignAdd ?? this.foreignAdd,
      foreignColored: foreignColored ?? this.foreignColored,
      maxWidth: maxWidth ?? this.maxWidth,
      padding: padding ?? this.padding,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isQasidah': isQasidah,
      'isQasidahCentered': isQasidahCentered,
      'qasidahLineNum': qasidahLineNum,
      'isRmTashkil': isRmTashkil,
      'isBmColored': isBmColored,
      'fontFam': fontFam,
      'textAlign': textAlign.name,
      'saveLastPeraIdx': saveLastPeraIdx,
      'fontSize': fontSize,
      'fontHeight': fontHeight,
      'luwAdd': foreignAdd,
      'luwColored': foreignColored,
      'maxWidth': maxWidth,
      'padding': padding,
    };
  }

  factory ReaderPageSettings.fromMap(String hash, Map<String, dynamic> map) {
    final bookHash = hash;
    final isQasidah = map['isQasidah'] as bool?;
    final isQasidahCentered = map['isQasidahCentered'] as bool?;
    final qasidahLineNum = map['qasidahLineNum'] as bool?;
    final isRmTashkil = map['isRmTashkil'] as bool?;
    final isBmColored = map['isBmColored'] as bool?;
    final saveLastPeraIdx = map['saveLastPeraIdx'] as bool?;
    final fontSize = map['fontSize'] as double?;
    final fontHeight = map['fontHeight'] as double?;
    final luwAdd = map['luwAdd'] as bool?;
    final luwColored = map['luwColored'] as bool?;
    final maxWidth = map['maxWidth'] as double?;
    final padding = map['padding'] as double?;

    final fontFam = arabicFonts.firstWhere(
      (e) => e == map['fontFam'],
      orElse: () => fontKitab,
    );

    final textAlign = TextAlign.values.firstWhere(
      (e) => e.name == map['textAlign'],
      orElse: () => TextAlign.justify,
    );

    return def(hash: hash).copyWith(
      bookHash: bookHash,
      isQasidah: isQasidah,
      isQasidahCentered: isQasidahCentered,
      qasidahLineNum: qasidahLineNum,
      isRmTashkil: isRmTashkil,
      isBmColored: isBmColored,
      fontFam: fontFam,
      textAlign: textAlign,
      saveLastPeraIdx: saveLastPeraIdx,
      fontSize: fontSize,
      fontHeight: fontHeight,
      foreignAdd: luwAdd,
      foreignColored: luwColored,
      padding: padding,
      maxWidth: maxWidth,
    );
  }

  String toJson() => jsonEncode(toMap());

  /// Deserialize from a JSON string
  factory ReaderPageSettings.fromJson(String hash, String source) =>
      ReaderPageSettings.fromMap(
        hash,
        jsonDecode(source) as Map<String, dynamic>,
      );

  EdgeInsets readerPadd(BuildContext context) =>
      readerPadding(context, maxWidth: maxWidth, sidePadd: padding);

  static String get _confDir => ReaderInputPageData.confDirPath;

  static Future<File> lurFile(String bookHash) async {
    final dir = _confDir;
    return File(join(dir, '${bookHash}_visited.txt'));
  }

  static Future<ReaderPageSettings> loadFromFile(
    String hash, {
    bool? isQasidah,
  }) async {
    if (hash.isEmpty) return def(isQasidah: isQasidah);

    try {
      final file = File(join(_confDir, '$hash.json'));
      if (!await file.exists()) return def(hash: hash, isQasidah: isQasidah);

      final content = await file.readAsString();
      final rs = ReaderPageSettings.fromJson(hash, content);

      if (isQasidah != null) rs.isQasidah = isQasidah;

      return rs;
    } catch (e) {
      return def(hash: hash, isQasidah: isQasidah);
    }
  }

  /// Saves the settings to the given path, creating the file if needed
  Future<void> saveToFile() async {
    if (bookHash.isEmpty) return;

    final parent = _confDir;

    try {
      final file = File(join(parent, '$bookHash.json'));
      await file.writeAsString(toJson());
    } catch (err) {
      if (kDebugMode) debugPrint('while saving book conf: $err');
    }
  }

  static Future<void> delete(String bookHash) async {
    if (bookHash.isEmpty) {
      throw Exception('Cannot delete book without its hash');
    }

    try {
      var f = File(join(_confDir, '$bookHash.json'));
      if (await f.exists()) await f.delete();

      final l = lastReadPosFile(bookHash)!;
      if (await l.exists()) await l.delete();
    } catch (err) {
      if (kDebugMode) debugPrint('while deleting book conf: $err');
    }
  }

  static File? lastReadPosFile(String? bookHash) {
    if (bookHash == null || bookHash.isEmpty) return null;

    return File(join(_confDir, '${bookHash}_scrollIdx.txt'));
  }
}
