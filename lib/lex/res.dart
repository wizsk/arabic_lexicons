import 'package:arabic_lexicons/alphabets.dart';
import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/datas/lex_entry_bookmark.dart';
import 'package:arabic_lexicons/lex/data.dart';
import 'package:arabic_lexicons/lex/def_card.dart';
import 'package:arabic_lexicons/lex/dicts/db.dart';
import 'package:arabic_lexicons/lex/ref.dart';
import 'package:arabic_lexicons/theme.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:arabic_lexicons/utils/toast_snack.dart';
import 'package:arabic_lexicons/widgets/selectable_text_screen.dart';
import 'package:arabic_lexicons/widgets/small_icon_btns.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
      child: Padding(
        padding: const EdgeInsets.all(8.0),
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
            style: L.arStyleSizedIf,
          ),
        ),
      ],
    );

    if (!showOpenReaderBtn) return l;

    // return Padding(
    //   padding: const EdgeInsets.all(12.0),
    //   child: Container(
    //     padding: EdgeInsets.all(8.0),
    //     width: double.infinity,
    //     height: double.infinity,
    //     constraints: const BoxConstraints(maxWidth: 260, maxHeight: 200),
    //     alignment: AlignmentGeometry.center,
    //     decoration: BoxDecoration(
    //       color: cs.surfaceContainer,
    //       borderRadius: BorderRadius.circular(14.00),
    //     ),
    // child:
    return Column(
      textDirection: L.dir,
      mainAxisSize: MainAxisSize.min,
      spacing: 8.00,
      children: [
        l,
        Text(L.p('or', 'أو'), textDirection: L.dir, style: L.arStyleSizedIf),

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
                  Icon(Icons.menu_book_rounded, color: cs.onPrimary),
                  SizedBox(width: 8),
                  Text(
                    // L.p('Open Reader', 'افتح القارئ'),
                    L.p('Go to Reader', 'اذهب إلى القارئ'),
                    style: L.arStyleSizedOrNew.copyWith(
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
      //   ),
      // ),
    );
  }

  return Column(
    spacing: 6,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.search_off, size: 32.00, color: ic),
      Text(
        L.p(noResEn, noResAr),
        style: L.arStyleSizedIf,
        textDirection: L.dir,
        textAlign: TextAlign.center,
      ),
      Text(
        currWord.takeMax(10),
        style: L.arStyleSized,
        textDirection: TextDirection.rtl,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ],
  );
}

Widget _showArEnRes(
  BuildContext context,
  TextStyle tsOg,
  SearchLexiconsDatas datas,
) => appConf.arEnDefShowCard
    ? _showArEnResCard(context, tsOg, datas)
    : _showArEnResTbl(context, tsOg, datas);

Widget _showArEnResCard(
  BuildContext context,
  TextStyle tsOg,
  SearchLexiconsDatas datas,
) {
  final cs = Theme.of(context).colorScheme;
  final ts = tsOg.copyWith(height: defArabicFontHeihgt);
  final list = datas.arEnRes;

  return SliverList.separated(
    itemCount: list.length,
    separatorBuilder: (_, _) => spaceBetweenDefs,
    itemBuilder: (context, i) {
      final e = list[i];

      void onRootTap() {
        final t = ArabicNormalizer.keepOnlyAr(e.root.split('/').first);
        if (t.isNotEmpty) datas.onChangeTxt(appendTxt: t);
      }

      const ltr = '\u202A';
      const pop = '\u202C';

      final txt = TextSpan(
        children: [
          TextSpan(text: '$ltr${e.word}$pop '),
          if (e.root.isNotEmpty)
            TextSpan(
              text: '$ltr(${e.root})$pop ',
              style: ts.copyWith(
                // fontSize: (ts.fontSize ?? appConf.readerFontSize) * 0.85,
                color: cs.secondary,
              ),
              recognizer: TapGestureRecognizer()..onTap = onRootTap,
            ),
          // const TextSpan(text: ' : '),
          TextSpan(text: e.def),
        ],
      );

      final child = SelectableText.rich(
        txt,
        textDirection: TextDirection.ltr,
        style: ts,
      );

      return definitonCard(
        context,
        child,
        id: e.id,
        d: Dict.arEn,
        rebuild: datas.rebuild,
        save: () async {
          await LexEntryBm.add(
            id: e.id,
            d: Dict.arEn,
            word: ArabicNormalizer.removeTashkilAndNomarize(e.word),
            meaning: e.toJsonString(),
          );
        },
        text: () => e.def,
        word: e.word,
      );
    },
  );
}

Widget _showArEnResTbl(
  BuildContext context,
  TextStyle tsOg,
  SearchLexiconsDatas datas,
) {
  final cs = Theme.of(context).colorScheme;
  final ts = tsOg.copyWith(height: defArabicFontHeihgt);
  const tp = EdgeInsets.symmetric(horizontal: 8, vertical: 4);

  final tblHDec = BoxDecoration(
    color: Theme.of(context).brightness == Brightness.light
        ? oddRowLight
        : oddRowDark,
  );

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
              decoration: tblHDec,
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

              final isBm = LexEntryBm.containsId(Dict.arEn, e.id);

              return TableRow(
                decoration: isHi ? tblHDec : null,
                children: [
                  Padding(
                    padding: tp,
                    child: Center(child: Text(e.word, style: ts)),
                  ),

                  Padding(
                    padding: tp,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 6,
                      children: [
                        Expanded(child: SelectableText(e.def, style: ts)),
                        iconButtonSized(
                          context,
                          icon: isBm
                              ? Icons.bookmark_remove
                              : Icons.bookmark_add_outlined,
                          scheme: isBm
                              ? IconButtonSizedColor.err
                              : IconButtonSizedColor.normal,
                          onPressed: () async {
                            if (isBm) {
                              await LexEntryBm.remove(Dict.arEn.table, e.id);
                              MsgSv.showSnackbarMsg(
                                "Definition removed: ${e.word}",
                              );
                              if (context.mounted) datas.rebuild();
                            } else {
                              await LexEntryBm.add(
                                id: e.id,
                                d: Dict.arEn,
                                word: ArabicNormalizer.removeTashkilAndNomarize(
                                  e.word,
                                ),
                                meaning: e.toJsonString(),
                              );
                              MsgSv.showSnackbarMsg(
                                "Definition saved: ${e.word}",
                              );
                              if (context.mounted) datas.rebuild();
                            }
                          },
                        ),
                      ],
                    ),
                  ),

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

const spaceBetweenDefs = SizedBox(height: 18);

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
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final hiColor = isDark ? bookmarkWordBgDark : bookmarkWordBg;

  return SliverList.separated(
    itemCount: datas.dbRes.length,
    separatorBuilder: (_, _) => spaceBetweenDefs,
    itemBuilder: (context, index) {
      final row = datas.dbRes[index];
      String txt = row.meanings;
      return AutoScrollTag(
        key: ValueKey(index),
        controller: datas.scrollController,
        index: index,
        child: definitonCardDbRow(
          context,
          datas.selectedDict,
          datas.dbRes[index],
          engMeaningView(
            txt,
            fontSize,
            fontHeight,
            fontFam,
            cs,
            row.isHi,
            hiColor,
          ),
          text: () => htmlToPlainTextWithLineBr(txt),
          rebuild: () {
            if (context.mounted) datas.rebuild();
          },
          fs: () {
            SelectableTextScreen.show(
              context,
              title: datas.selectedWord,
              fullTextFunc: (_) => htmlToPlainTextWithLineBr(txt),
              textAlign: TextAlign.left,
              dir: TextDirection.ltr,
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
        ),
      );
    },
  );
}

Widget _arabicLexView(TextStyle ts, SearchLexiconsDatas datas) {
  return SliverList.separated(
    itemCount: datas.dbRes.length,
    separatorBuilder: (_, _) => spaceBetweenDefs,
    itemBuilder: (context, index) {
      final row = datas.dbRes[index];

      final child = row.arMeaningView(
        context,
        ts: ts,
        hasRefs: datas.selectedDict.hasRefs,
      );

      return definitonCardDbRow(
        context,
        datas.selectedDict,
        datas.dbRes[index],
        // SelectionArea(
        //   magnifierConfiguration: TextMagnifierConfiguration.disabled,
        //   child:
        child,
        // ),
        rebuild: () {
          if (context.mounted) datas.rebuild();
        },
        text: () => row.formatMeanings,
        fs: () {
          SelectableTextScreen.show(
            context,
            title: datas.selectedWord,
            fullTextFunc: (_) => row.formatMeanings,
            textAlign: TextAlign.right,
            dir: TextDirection.rtl,
            textStyleBodyMedium: ts,
            start: 0,
            length: 1,
          );
        },
      );
    },
  );
}

extension DbRowWidget on DbRow {
  Widget arMeaningView(
    BuildContext context, {
    required bool hasRefs,
    required TextStyle ts,
    final int? maxlines,
    final TextOverflow? textOverFlow,
  }) {
    final txt = formatMeanings;

    return hasRefs
        ? Text.rich(
            ReferenceProcessor.processRich(context, meanings, ts),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: ts.copyWith(
              leadingDistribution: TextLeadingDistribution.even,
            ),
            maxLines: maxlines,
            overflow: textOverFlow,
          )
        : Text(
            txt,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: ts.copyWith(
              leadingDistribution: TextLeadingDistribution.even,
            ),
            maxLines: maxlines,
            overflow: textOverFlow,
          );
  }
}

Widget engMeaningView(
  String html,
  // String fontFam,
  double fontSize,
  double fontHeihgt,
  String fontFam,
  ColorScheme cs,
  bool isHighResult,
  Color hiColor, {
  final int? maxlines,
  final TextOverflow? textOverFlow,
}) {
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
        maxLines: maxlines,
        textOverflow: textOverFlow,
      ),
      'strong': Style(fontWeight: FontWeight.bold),
      'i': Style(fontStyle: FontStyle.italic),
      'center': Style(textAlign: TextAlign.center),
      '.high': Style(backgroundColor: hiColor),
    },
  );
}
