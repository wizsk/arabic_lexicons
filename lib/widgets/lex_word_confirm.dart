import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/main_widgets.dart';
import 'package:flutter/material.dart';

Future<bool?> showLexWordDelConfirm(
  BuildContext context,
  String word, {
  final String extramsg = '',
}) async {
  return showConfirmDialog(
    context,
    'Remove: $word',
    message:
        'Are you sure you want to remove “$word” from your current search?'
        '$extramsg',
    fontFam: L.arFont,
    confirmText: 'Remove',
    constraints: true,
    autofocusConfirm: true,
  );
}
