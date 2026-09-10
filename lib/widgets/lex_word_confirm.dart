import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/main_widgets.dart';
import 'package:flutter/material.dart';

bool _showingLexWordDelConfirm = false;
Future<bool?> showLexWordDelConfirm(
  BuildContext context,
  String word, {
  final String extramsg = '',
}) async {
  if (_showingLexWordDelConfirm) return null;
  _showingLexWordDelConfirm = true;
  final res = await showConfirmDialog(
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

  _showingLexWordDelConfirm = false;
  return res;
}

Future<bool?> showLexWordClearAllConfirm(
  BuildContext context, {
  final String extramsg = '',
}) async {
  if (_showingLexWordDelConfirm) return null;
  _showingLexWordDelConfirm = true;

  final res = await showConfirmDialog(
    context,
    'Clear Words',
    message:
        'Do you want to clear all searched words?'
        '$extramsg',
    confirmText: 'Clear',
    autofocusConfirm: true,
  );
  _showingLexWordDelConfirm = false;

  return res;
}
