import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/lex/data.dart';
import 'package:ara_dict/lex/res.dart';
import 'package:ara_dict/lex/sugg/data.dart';
import 'package:ara_dict/utils.dart';
import 'package:flutter/material.dart';

Widget showSearchSugg(
  BuildContext context,
  TextEditingController controller,
  TextStyle ts,
  SearchLexiconsDatas datas,
  ColorScheme cs,
) {
  if (datas.sugg.isEmpty) {
    return noRes(
      context,
      currWord: datas.selectedWord,
      noResAr: "لا توجد اقتراحات لـ",
      noResEn: "No Suggestions for",
    );
  }

  if (datas.suggDictSorted.isEmpty) {
    datas.suggDictSorted.add(datas.selectedDict);
    for (final d in allDictsOrd) {
      if (d != datas.selectedDict) {
        datas.suggDictSorted.add(d);
      }
    }
  }

  List<Widget> resList = [];

  final word = datas.selectedWord;
  final choiceChipTxtStyle = L.arStyleSized;
  final highColor = cs.error;

  final choiceChipTxtStyleHigh = choiceChipTxtStyle.copyWith(color: highColor);

  final titleStyle = L.isAr
      ? choiceChipTxtStyle.copyWith(color: cs.onSurface)
      : TextStyle(color: cs.onSurface);

  resList.add(const SizedBox(height: 120));

  for (int i = datas.suggDictSorted.length - 1; i >= 0; i--) {
    final d = datas.suggDictSorted[i];
    final Set<SuggestionEntry>? res = datas.sugg[d];
    final bool isPrimary = d == datas.selectedDict;

    if (!isPrimary && (res?.isEmpty ?? true)) continue;

    resList.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TITLE
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isPrimary)
                      Icon(Icons.check_circle, size: 16, color: cs.primary),
                    if (isPrimary) const SizedBox(width: 6),
                    Text(
                      L.pr(d.ar, d.en),
                      style: titleStyle.copyWith(
                        color: isPrimary ? cs.primary : cs.onSurface,
                      ),
                      textDirection: L.dir,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // CONTENT
                if (res == null || res.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Text(
                        L.pr(/*n */ 'لا توجد نتائج', 'No results'),
                        textDirection: L.dir,
                        style: L.arStyleIf,
                      ),
                    ),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: res.map((r) {
                        Widget txt;
                        if (r.word == word) {
                          txt = Text(
                            word,
                            textDirection: TextDirection.rtl,
                            style: choiceChipTxtStyleHigh,
                          );
                        } else {
                          final (:pre, :suf) = r.word
                              .replaceAll('_', ' ')
                              .splitOnce(word);

                          txt = Text.rich(
                            TextSpan(
                              children: [
                                if (pre != null) TextSpan(text: pre),
                                TextSpan(
                                  text: word,
                                  style: TextStyle(color: highColor),
                                ),
                                if (suf != null) TextSpan(text: suf),
                              ],
                            ),
                            style: choiceChipTxtStyle,
                            textDirection: TextDirection.rtl,
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ActionChip(
                            backgroundColor: cs.surfaceContainerHighest,
                            side: BorderSide(color: cs.outlineVariant),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            label: !r.isRoot
                                ? txt
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Icon(
                                          Icons.star,
                                          size: 14,
                                          color: cs.primary,
                                        ),
                                      ),
                                      txt,
                                    ],
                                  ),
                            onPressed: () {
                              FocusManager.instance.primaryFocus?.unfocus();

                              if (r.word != datas.selectedWord) {
                                final wordSet = datas.words.map((i) {
                                  return i == datas.selectedWord ? r.word : i;
                                }).toSet();

                                wordSet.remove(r.word);
                                wordSet.add(r.word);

                                datas.words = wordSet.toList();

                                controller.text = wordSet.join(' ');
                                controller
                                    .selection = TextSelection.fromPosition(
                                  TextPosition(offset: controller.text.length),
                                );

                                datas.selectedWord = r.word;
                              }

                              if (datas.selectedDict != d) {
                                datas.selectedDict = d;
                                datas.suggDictSorted.clear();
                              }

                              datas.isShowingSugg = false;

                              datas.getAndShowResORSugg(
                                context,
                                forceRes: true,
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  resList.add(const SizedBox(height: 12));
  return SliverToBoxAdapter(child: Column(children: resList));
}
