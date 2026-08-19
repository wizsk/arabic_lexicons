import 'package:arabic_lexicons/alphabets.dart';
import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/lex/data.dart';
import 'package:arabic_lexicons/reader/reader_utils.dart';
import 'package:arabic_lexicons/theme.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:arabic_lexicons/widgets/selectable_text_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

Widget showRes(
  BuildContext context,
  TextStyle ts,
  SearchLexiconsDatas datas,
  ColorScheme cs,
) {
  if (datas.resultsAreEmpty) {
    return noRes(context, currWord: datas.selectedWord);
  }

  final curDict = datas.selectedDict;
  if (curDict == Dict.arEn) {
    return _showArEnRes(context, ts, datas);
  }

  if (curDict == Dict.hanswehr || curDict == Dict.laneLexicon) {
    return _hansLaneView(context, ts, datas, cs);
  }
  return _arabicLexView(ts, datas);
}

Widget noRes(
  BuildContext context, {
  String? currWord,
  String noWordAr = 'ابجث عن كلمة',
  String noWordEn = 'Search for a word',
  String noResAr = "لا توجد نتائج لـ",
  String noResEn = "No resuts for",
}) {
  return SliverFillRemaining(
    hasScrollBody: false,
    child: Center(
      child: noResUniversal(
        noWordAr: noWordAr,
        noWordEn: noWordEn,
        noResAr: noResAr,
        noResEn: noResEn,
        currWord,
      ),
    ),
  );
}

Widget noResUniversal(
  String? currWord, {
  String noWordAr = 'ابجث عن كلمة',
  String noWordEn = 'Search for a word',
  String noResAr = "لا توجد نتائج لـ",
  String noResEn = "No resuts for",
}) {
  Widget w;
  if (currWord == null || currWord.isEmpty) {
    w = Text(L.p(noWordEn, noWordAr), textDirection: L.dir, style: L.arStyleIf);
  } else {
    w = Column(
      spacing: 6,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(L.p(noResEn, noResAr), style: L.arStyleIf, textDirection: L.dir),
        Text(currWord, style: L.arStyle),
      ],
    );
  }

  // style: L.arStyleIf,
  // textDirection: L.dir,

  return w;
}

Widget _showArEnRes(
  BuildContext context,
  TextStyle tsOg,
  SearchLexiconsDatas datas,
) {
  final cs = Theme.of(context).colorScheme;
  final ts = tsOg.copyWith(height: defArabicFontHeihgt);
  const tp = EdgeInsets.symmetric(horizontal: 8, vertical: 4);

  return SliverToBoxAdapter(
    child: Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          border: TableBorder.all(color: cs.outlineVariant, width: 0.5),
          columnWidths: const {
            0: IntrinsicColumnWidth(),
            1: IntrinsicColumnWidth(),
            // 1: FlexColumnWidth(),
            2: IntrinsicColumnWidth(),
          },
          children: [
            // Header
            TableRow(
              decoration: BoxDecoration(color: cs.surfaceContainerLow),
              children: [
                Padding(
                  padding: tp,
                  child: Center(
                    child: Text(
                      'Word',
                      style: ts.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Padding(
                  padding: tp,
                  child: Center(
                    child: Text(
                      'Meanings',
                      style: ts.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Padding(
                  padding: tp,
                  child: Center(
                    child: Text(
                      'Root',
                      style: ts.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            ...datas.arEnRes.indexed.map((a) {
              final e = a.$2;

              return TableRow(
                decoration: BoxDecoration(
                  color: a.$1.isEven
                      ? null
                      : cs.surfaceContainerLow.withAlpha(150),
                ),
                children: [
                  Padding(
                    padding: tp,
                    child: Center(child: Text(e.word, style: ts)),
                  ),

                  GestureDetector(
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: e.def));

                      if (!context.mounted) return;
                      showSnack(
                        context,
                        '',
                        messageWidget: Text(
                          'Copied: ${e.def}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                    onLongPress: () {
                      if (!context.mounted) return;

                      SelectableTextScreen.show(
                        context,
                        dir: TextDirection.ltr,
                        textAlign: TextAlign.center,
                        fullTextFunc: (_) => e.def,
                        start: 0,
                        length: 1,
                        textStyleBodyMedium: ts,
                      );
                    },
                    child: Padding(
                      padding: tp,
                      child: Text(e.def, style: ts),
                    ),
                  ),

                  GestureDetector(
                    onTap: e.root.isEmpty
                        ? null
                        : () {
                            final s = e.root.split('/');
                            if (s.isEmpty) return;

                            final t = ArabicNormalizer.keepOnlyAr(s[0]);
                            if (t.isEmpty) return;

                            datas.onChangeTxt(appendTxt: t);
                          },
                    child: Padding(
                      padding: tp,
                      child: Center(child: Text(e.root, style: ts)),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    ),
  );
}

Widget _hansLaneView(
  BuildContext context,
  TextStyle ts,
  SearchLexiconsDatas datas,
  ColorScheme cs,
) {
  final fontFam = appConf.useHansLaneDefRDStyle
      ? appConf.readerFont
      : fontAmiri;

  final fontSize = appConf.readerFontSize;
  // final fontHeight = appConf.useHansLaneDefRDStyle
  //     ? appConf.readerFontHeight
  //     : fontAmiriLineHeight;

  final fontHeight = htmlFontHeight;
  return SliverList.separated(
    itemCount: datas.dbRes.length,
    separatorBuilder: (context, index) =>
        const Divider(height: 0, thickness: 0.5),
    itemBuilder: (context, index) {
      final row = datas.dbRes[index];
      String txt = row.meanings;
      return AutoScrollTag(
        key: ValueKey(index),
        controller: datas.scrollController,
        index: index,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPress: () {
            // final cleanTxt = htmlToPlainText(txt);
            final cleanTxtBr = htmlToPlainTextWithLineBr(txt);
            SelectableTextScreen.show(
              context,
              fullTextFunc: (_) => cleanTxtBr,
              textAlign: TextAlign.left,
              dir: TextDirection.ltr,
              // ts,
              textStyleBodyMedium: ts.copyWith(
                fontFamily: fontFam,
                // the html renderer and normal renderer not the same :)
                height: appConf.useHansLaneDefRDStyle
                    ? htmlFontHeight + 0.3
                    : fontHeight,
              ),
              start: 0,
              length: 1,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _engMeaningView(
              txt,
              fontSize,
              fontHeight,
              fontFam,
              cs,
              row.isHi,
            ),
          ),
        ),
      );
    },
  );
}

Widget _arabicLexView(TextStyle ts, SearchLexiconsDatas datas) {
  final showWordTitle = datas.selectedDict.showTitle;
  return SliverList.separated(
    itemCount: datas.dbRes.length,
    separatorBuilder: (context, index) =>
        const Divider(height: 0, thickness: 0.5),
    itemBuilder: (context, index) {
      final row = datas.dbRes[index];
      final txt = showWordTitle ? '${row.word}: ${row.meanings}' : row.meanings;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: _arMeaningView(txt, ts),
      );
    },
  );
}

Widget _arMeaningView(String txt, TextStyle ts) {
  return SelectionArea(
    magnifierConfiguration: TextMagnifierConfiguration.disabled,
    child: Text(
      txt,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      style: ts.copyWith(
        // height: 2,
        leadingDistribution: TextLeadingDistribution.even,
      ),
    ),
  );
}

Widget _engMeaningView(
  String html,
  // String fontFam,
  double fontSize,
  double fontHeihgt,
  String fontFam,
  ColorScheme cs,
  bool isHighResult,
) {
  return Html(
    data: html,
    style: {
      'body': Style(
        fontFamily: fontFam,
        lineHeight: LineHeight.number(fontHeihgt),
        direction: TextDirection.ltr,
        textAlign: TextAlign.left,
        fontSize: FontSize(fontSize),
        color: isHighResult ? cs.primary : null,
      ),
      'strong': Style(fontWeight: FontWeight.bold),
      'i': Style(fontStyle: FontStyle.italic),
      'center': Style(textAlign: TextAlign.center),
      '.high': Style(color: cs.onPrimary, backgroundColor: cs.primary),
    },
  );
}
