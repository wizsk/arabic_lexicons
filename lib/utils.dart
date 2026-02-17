import 'package:ara_dict/lexicons.dart';
import 'package:flutter/material.dart';

Future<void> openDict(BuildContext context, String word) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SearchLexicons(showDrawer: false, initialText: word),
    ),
  );
}

String enToArNum(dynamic n) {
  return n.toString().replaceAllMapped(
    RegExp(r'[0-9]'),
    (m) => String.fromCharCode(0x0660 + int.parse(m.group(0)!)),
  );
}
