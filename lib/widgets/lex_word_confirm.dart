import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/main_widgets.dart';
import 'package:flutter/material.dart';

Future<bool?> showLexWordDelConfirm(BuildContext context, String word) async {
  return showConfirmDialog(
    context,
    'Remove: $word',
    message:
        'Are you sure you want to remove “$word” from your current search? '
        'You can disable this confirmation in Settings',
    fontFam: L.arFont,
    confirmText: 'Remove',
    constraints: true,
    destructive: true,
    autofocusConfirm: true,
  );
}
