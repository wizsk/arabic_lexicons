import 'package:flutter/services.dart';

Future<String?> getClipboardText() async {
  final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
  return clipboardData?.text;
}
