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
  bool showOpenReaderBtn = false,
}) {
  return SliverFillRemaining(
    hasScrollBody: false,
    child: Center(
      child: _noResUniversal(
        context,
        currWord,
        noWordAr: noWordAr,
        noWordEn: noWordEn,
        noResAr: noResAr,
        noResEn: noResEn,
        showOpenReaderBtn: showOpenReaderBtn,
      ),
    ),
  );
}

Widget _noResUniversal(
  BuildContext context,
  String? currWord, {
  String noWordAr = 'ابجث عن كلمة',
  String noWordEn = 'Search for a word',
  String noResAr = "لا توجد نتائج لـ",
  String noResEn = "No resuts for",
  bool showOpenReaderBtn = false,
}) {
  final cs = Theme.of(context).colorScheme;
  final ic = cs.secondary;
  // final ts = Theme.of(context).textTheme.bodyLarge;

  if (currWord == null || currWord.isEmpty) {
    final l = Row(
      textDirection: L.dir,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.search, color: ic, size: 18),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            L.p(noWordEn, noWordAr),
            textDirection: L.dir,
            style: L.arStyleIf,
          ),
        ),
      ],
    );

    if (!showOpenReaderBtn) return l;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Container(
        padding: EdgeInsets.all(8.0),
        width: double.infinity,
        height: double.infinity,
        constraints: const BoxConstraints(maxWidth: 260, maxHeight: 200),
        alignment: AlignmentGeometry.center,
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(14.00),
        ),
        child: Column(
          textDirection: L.dir,
          mainAxisSize: MainAxisSize.min,
          spacing: 8.00,
          children: [
            l,
            Text(L.p('or', 'أو'), textDirection: L.dir, style: L.arStyleIf),

            // const SizedBox(height: 8.00),
            Material(
              color: cs.primary,
              borderRadius: BorderRadius.circular(14),
              // shape: RoundedRectangleBorder(
              //   borderRadius: BorderRadius.circular(14),
              //   side: BorderSide(
              //     color: cs.outlineVariant,
              //     width: 1.2,
              //   ),
              // ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.pushReplacementNamed(context, Routes.readerInput);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.00,
                    horizontal: 18.00,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    textDirection: L.dir,
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        color: cs.onPrimary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        // L.p('Open Reader', 'افتح القارئ'),
                        L.p('Go to Reader', 'اذهب إلى القارئ'),
                        style: L.arStyleOrNew.copyWith(
                          fontWeight: FontWeight.w500,
                        color: cs.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  return Column(
    spacing: 6,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.search_off, size: 32.00, color: ic),
      Text(
        L.p(noResEn, noResAr),
        style: L.arStyleIf,
        textDirection: L.dir,
        textAlign: TextAlign.center,
      ),
      Text(currWord, style: L.arStyle),
    ],
  );
}

Widget _showArEnRes(
  BuildContext context,
  TextStyle tsOg,
  SearchLexiconsDatas datas,
) {
  final cs = Theme.of(context).colorScheme;
  final ts = tsOg.copyWith(height: defArabicFontHeihgt);
  const tp = EdgeInsets.symmetric(horizontal: 8, vertical: 4);

  final tblHDec = BoxDecoration(
    color: Theme.of(context).brightness == Brightness.light
        ? cs.surfaceContainerLow.withAlpha(120)
        : cs.surfaceContainerLow.withAlpha(240),
  );

  final tiSplashColor = cs.onSurface.withAlpha(80);
  final tiHighlightColor = cs.onSurface.withAlpha(50);
  final tiHoverColor = cs.onSurface.withAlpha(35);
  final tiFocusColor = cs.onSurface.withAlpha(30);

  return SliverToBoxAdapter(
    child: Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(top: 8),
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
              final isHi = a.$1.isOdd;

              Future<void> onTab() async {
                await Clipboard.setData(ClipboardData(text: e.def));

                if (context.mounted) {
                  showSnack(
                    context,
                    'Definition copied. Long-press to select text',
                  );
                }
              }

              void onLongPress() {
                if (context.mounted) {
                  SelectableTextScreen.show(
                    context,
                    dir: TextDirection.ltr,
                    textAlign: TextAlign.center,
                    fullTextFunc: (_) => e.def,
                    start: 0,
                    length: 1,
                    textStyleBodyMedium: ts,
                  );
                }
              }

              final defW = Padding(
                padding: tp,
                child: Text(e.def, style: ts),
              );

              final rootOnTap = e.root.isEmpty
                  ? null
                  : () {
                      final s = e.root.split('/');
                      if (s.isEmpty) return;

                      final t = ArabicNormalizer.keepOnlyAr(s[0]);
                      if (t.isEmpty) return;

                      datas.onChangeTxt(appendTxt: t);
                    };

              final rootW = Padding(
                padding: tp,
                child: Center(child: Text(e.root, style: ts)),
              );

              return TableRow(
                decoration: isHi ? tblHDec : null,
                children: [
                  Padding(
                    padding: tp,
                    child: Center(child: Text(e.word, style: ts)),
                  ),

                  if (isHi)
                    InkWell(
                      splashColor: tiSplashColor,
                      highlightColor: tiHighlightColor,
                      hoverColor: tiHoverColor,
                      focusColor: tiFocusColor,
                      onTap: onTab,
                      onLongPress: onLongPress,
                      child: defW,
                    )
                  else
                    InkWell(
                      onTap: onTab,
                      onLongPress: onLongPress,
                      child: defW,
                    ),

                  if (isHi)
                    InkWell(
                      splashColor: tiSplashColor,
                      highlightColor: tiHighlightColor,
                      hoverColor: tiHoverColor,
                      focusColor: tiFocusColor,
                      onTap: rootOnTap,
                      child: rootW,
                    )
                  else
                    InkWell(onTap: rootOnTap, child: rootW),
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
