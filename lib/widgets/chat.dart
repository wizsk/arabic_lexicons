import 'package:ara_dict/data.dart';
import 'package:flutter/material.dart';

class ChatView {
  static Future<void> screen(BuildContext context) async {
    await Navigator.pushNamed(context, Routes.chatHist);
  }
}
