import 'package:arabic_lexicons/alphabets.dart';
import 'package:arabic_lexicons/lex/data.dart';
import 'package:arabic_lexicons/reader/reader_utils.dart';
import 'package:flutter/material.dart';

const int _maxTextSize = 500;

Future<void> onTextChanged(
  BuildContext context,
  TextEditingController controller,
  SearchLexiconsDatas datas,
  VoidCallback afterChange,
) async {
  String value = controller.text.trim();
  // if (datas.preQuery == value) return;

  datas.preQuery = value;

  if (value.length > _maxTextSize) {
    value = value.length > _maxTextSize
        ? value.substring(0, _maxTextSize)
        : value;

    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );

    showSnack(context, 'Text too long, reduced to $_maxTextSize chars');
  }

  final (parts, currWord) = getNextWord(
    value,
    controller.selection.base.offset,
  );

  if (currWord == datas.selectedWord) {
    if (parts.length != datas.words.length) {
      datas.words = parts;
    }
    return;
  }

  if (currWord == null) {
    datas.resetAll();
    afterChange();
    return;
  }

  datas.words = parts;
  datas.selectedWord = currWord;

  datas.getAndShowResORSugg(context);
}

(List<String> res, String? word) getNextWord(String query, int curPos) {
  List<String> res = [];
  query = query.trim();

  if (query.isEmpty) {
    return (res, null);
  } else if (query.length == curPos || !query.contains(" ")) {
    res = ArabicNormalizer.keepOnlyArListUnique(query);
    if (res.isNotEmpty) return (res, res.last);
    return (res, null);
  }

  String? word;

  for (int i = 0; i < query.length;) {
    while (i < query.length && query[i] == " ") {
      i++;
    }
    if (i >= query.length) break;

    // Get the remaining characters
    final sub = query.substring(i);
    final spaceIdx = sub.indexOf(" ");
    String curWord = "";
    if (spaceIdx < 0) {
      // No more spaces, take the rest
      curWord = sub;
    } else {
      curWord = sub.substring(0, spaceIdx);
    }
    i += curWord.length;
    // Skip trailing spaces
    while (i < query.length && query[i] == " ") {
      i++;
    }

    final cw = ArabicNormalizer.keepOnlyAr(curWord);

    if (cw != "") {
      res.remove(cw);
      res.add(cw);
      if (word == null && curPos < i) {
        word = cw;
      }
    }
  }

  if (res.isNotEmpty && word == null) word = res.last;

  return (res, word);
}
