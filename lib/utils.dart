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

String formatDateTime(BuildContext context, DateTime dt) {
  final local = dt.toLocal();
  final use24h = MediaQuery.of(context).alwaysUse24HourFormat;

  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year;

  if (use24h) {
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$hour:$minute $day/$month/$year';
  } else {
    int hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');

    final isPm = hour >= 12;
    final period = isPm ? 'PM' : 'AM';

    hour = hour % 12;
    if (hour == 0) hour = 12;

    final hourStr = hour.toString().padLeft(2, '0');

    return '$hourStr:$minute $period $day/$month/$year';
  }
}
