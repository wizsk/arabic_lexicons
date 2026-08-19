import 'package:arabic_lexicons/word_list/page.dart';
import 'package:flutter/material.dart';

abstract final class ForeignWordsPage {
  static Future<void> open(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const WordListPage(listType: WordListType.foreings),
      ),
    );
  }
}
