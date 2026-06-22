import 'dart:convert';
import 'dart:io';

import 'package:ara_dict/data.dart';
import 'package:ara_dict/pages/width_padd.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

const readerConfDirName = 'reader_conf';

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
        fontSize == rs.fontSize;
  }

  void applyRAD(ReaderAdjustData d) {
    maxWidth = d.maxWidth;
    padding = d.padding;
    fontFam = d.fontFam;
    fontSize = d.fontSize;
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

  static String? _confDirPath;
  static Future<String> get _confDir async {
    if (_confDirPath != null) return _confDirPath!;

    final dir = await getApplicationDocumentsDirectory();
    final p = join(dir.path, readerConfDirName);
    _confDirPath = p;
    return p;
  }

  static Future<File> lurFile(String bookHash) async {
    final dir = await _confDir;
    return File(join(dir, '${bookHash}_visited.txt'));
  }

  static Future<ReaderPageSettings> loadFromFile(
    String hash, {
    bool? isQasidah,
  }) async {
    if (hash.isEmpty) return def(isQasidah: isQasidah);

    try {
      final file = File(join(await _confDir, '$hash.json'));
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

    final parent = Directory(await _confDir);
    await parent.create(recursive: true); // ensures parent dirs exist

    final file = File(join(parent.path, '$bookHash.json'));
    await file.writeAsString(toJson());
  }

  static Future<void> delete(String bookHash) async {
    try {
      if (bookHash.isEmpty) return;
      var f = File(join(await _confDir, '$bookHash.json'));
      await f.delete();
      await (await lastReadPosFile(bookHash))?.delete();
    } catch (_) {}
  }

  static Future<File?> lastReadPosFile(String? bookHash) async {
    if (bookHash == null || bookHash.isEmpty) return null;

    return File(join(await _confDir, '${bookHash}_scrollIdx.txt'));
  }
}
