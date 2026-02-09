import 'package:ara_dict/alphabets.dart';

(List<String> res, String? word) getNextWord(String query, int curPos) {
  List<String> res = [];
  if (query.isEmpty) {
    return (res, null);
  } else if (query.length == curPos) {
    res = cleanQeury(query);
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

    final cw = cleanWord(curWord);

    if (cw != "") {
      res.add(cw);
      if (word == null && curPos < i) {
        word = cw;
      }
    }
  }

  if (res.isNotEmpty && word == null) word = res.last;

  return (res, word);
}
