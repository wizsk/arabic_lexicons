import 'package:arabic_lexicons/alphabets.dart';
import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/lex/data.dart';
import 'package:arabic_lexicons/lex/expandable_definition.dart';
import 'package:arabic_lexicons/theme.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:arabic_lexicons/utils/toast_snack.dart';
import 'package:arabic_lexicons/widgets/dahsed_divider.dart';
import 'package:arabic_lexicons/widgets/small_icon_btns.dart';
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
  return _arabicLexView(context, ts, datas);
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
) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final ts = tsOg.copyWith(height: defArabicFontHeihgt);
  const tp = EdgeInsets.symmetric(horizontal: 8, vertical: 4);

  final tblHDec = BoxDecoration(
    color: Theme.of(context).brightness == Brightness.light
        ? oddRowLight
        : oddRowDark,
  );

  return SliverToBoxAdapter(
    child: Column(
      children: [
        _resCount(
          theme,
          datas.arEnRes.length,
          true,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        SingleChildScrollView(
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

                return TableRow(
                  decoration: isHi ? tblHDec : null,
                  children: [
                    Padding(
                      padding: tp,
                      child: Center(child: Text(e.word, style: ts)),
                    ),

                    Padding(
                      padding: tp,
                      child: SelectableText(e.def, style: ts),
                    ),

                    InkWell(onTap: rootOnTap, child: rootW),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _resCount(
  ThemeData theme,
  int count,
  bool isEnglish, {
  final EdgeInsets padding = const EdgeInsets.only(top: 12, bottom: 0),
}) {
  final colors = theme.colorScheme;

  return Padding(
    padding: padding,
    child: Center(
      child: Chip(
        // avatar: Icon(
        //   Icons.check_rounded,
        //   // size: 18,
        //   color: colors.onSurfaceVariant,
        // ),
        label: Text(
          isEnglish
              ? 'Found $count results'
              : 'تم العثور على ${enToArNum(count)} نتيجة',
          textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
          style: theme.textTheme.titleMedium?.ar.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurfaceVariant,
          ),
        ),
        backgroundColor: colors.surfaceContainerLowest,
        side: BorderSide(color: colors.outlineVariant),
        shape: const StadiumBorder(),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

  final fontHeight = htmlFontHeight;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final hiColor = isDark ? bookmarkWordBgDark : bookmarkWordBg;

  return SliverList.separated(
    itemCount: datas.dbRes.length + 1,
    separatorBuilder: (_, _) => _defGapInbettenDef,
    itemBuilder: (context, index) {
      if (index == 0) {
        return _resCount(Theme.of(context), datas.dbRes.length, true);
      }
      index--;

      final row = datas.dbRes[index];
      String txt = row.meanings;
      final child = _engMeaningView(
        txt,
        fontSize,
        fontHeight,
        fontFam,
        cs,
        row.isHi,
        hiColor,
        datas.expanded[index],
      );

      final def = _defCard(
        context,
        index,
        datas,
        child,
        text: () => htmlToPlainTextWithLineBr(txt),
      );
      return AutoScrollTag(
        key: ValueKey(index),
        controller: datas.scrollController,
        index: index,
        child: def,
      );
    },
  );
}

Widget _defCard(
  BuildContext context,
  int index,
  SearchLexiconsDatas datas,
  Widget child, {
  required String Function() text,
}) {
  final expanded = datas.expanded[index];
  final cs = Theme.of(context).colorScheme;
  // final colors = cs;

  const sidesPadd = 12.0;
  final textWidget = Padding(
    padding: const EdgeInsets.fromLTRB(sidesPadd, 12, sidesPadd, 0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        // if (expanded) ...[
        DashedDivider(height: 8, color: cs.outlineVariant),
        // ] else
        //   const SizedBox(height: 4),
        Row(
          // mainAxisAlignment: MainAxisAlignment.end,
          // spacing: 2,
          children: [
            iconButtonSized(
              context,
              icon: expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              scheme: IconButtonSizedColor.primary,
              tooltip: 'expan/collaspe',
              onPressed: () {
                datas.expanded[index] = !datas.expanded[index];
                datas.rebuild();

                if (datas.expanded[index]) return;
                postFrame((_) {
                  if (!datas.scrollController.hasClients) return;
                  if (datas.scrollController.offset == 0) {
                    datas.appbarReaderBg = true;
                    datas.rebuild();
                  }
                });
              },
            ),
            Spacer(),
            iconButtonSized(
              context,
              icon: Icons.copy_rounded,
              tooltip: 'Copy',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text()));
                MsgSv.showToast("Definiton copied");
              },
            ),
            iconButtonSized(
              context,
              icon: Icons.flag_outlined,
              tooltip: 'Report an issue',
              onPressed: () {
                // TODO: Report this entry.
              },
              scheme: IconButtonSizedColor.err,
            ),
          ],
        ),
        const SizedBox(height: 6),
      ],
    ),
  );

  final rc = ReaderColors.curr(context);
  final borderRadius = BorderRadius.circular(12);

  final selectable = SelectionArea(
    magnifierConfiguration: TextMagnifierConfiguration.disabled,
    child: expanded
        ? textWidget
        : SelectionContainer.disabled(child: textWidget),
  );

  final decoration = BoxDecoration(
    color: rc.definitionSurface,
    borderRadius: borderRadius,
    border: Border.all(color: rc.outline),
    boxShadow: [
      BoxShadow(
        color: rc.shadow,
        offset: const Offset(2, 3),
        blurRadius: 7,
        spreadRadius: -2,
      ),
    ],
  );

  return expanded
      ? DecoratedBox(decoration: decoration, child: selectable)
      : Ink(
          decoration: decoration,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: () {
              datas.expanded[index] = !datas.expanded[index];
              datas.rebuild();
            },
            child: selectable,
          ),
        );
}

const int _defCollapsedMaxLines = 1;
const _defCollapsedTextOverFlow = TextOverflow.ellipsis;
const _defGapInbettenDef = SizedBox(height: 16);

// Widget _arMeaning(
//   BuildContext context,
//   SearchLexiconsDatas datas,
//   TextStyle ts,
//   bool expanded,
//   DbRow row,
// ) {
//   final ml = expanded ? null : _defCollapsedMaxLines;
//   final of = expanded ? null : _defCollapsedTextOverFlow;
//
//   final txt = expanded
//       ? row.formatMeanings
//       : row.formatMeanings.replaceAll("\n", " ");
//
//   return datas.selectedDict.hasRefs
//       ? Text.rich(
//           ReferenceProcessor.processRich(context, txt, ts),
//           textDirection: TextDirection.rtl,
//           textAlign: TextAlign.right,
//           style: ts.copyWith(leadingDistribution: TextLeadingDistribution.even),
//           maxLines: ml,
//           overflow: of,
//         )
//       : Text(
//           txt,
//           textDirection: TextDirection.rtl,
//           textAlign: TextAlign.right,
//           style: ts.copyWith(leadingDistribution: TextLeadingDistribution.even),
//           maxLines: ml,
//           overflow: of,
//         );
// }

Widget _arabicLexView(
  BuildContext context,
  TextStyle ts,
  SearchLexiconsDatas datas,
) {
  return SliverList.separated(
    itemCount: datas.dbRes.length + 1,
    separatorBuilder: (_, _) => _defGapInbettenDef,
    itemBuilder: (context, index) {
      if (index == 0) {
        return _resCount(Theme.of(context), datas.dbRes.length, false);
      }
      index--;

      final row = datas.dbRes[index];
      // final meanings = row.formatMeanings;

      return ExpandableDefinition(
        row.formatMeanings.replaceAll("\n", " "),
        row.formatMeanings,
        style: ts,
        textAlign: TextAlign.start,
        textDirection: TextDirection.rtl,
      );

      // return _defCard(context, index, datas, child, text: () => row.meanings);
    },
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
  Color hiColor,
  bool expanded,
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
        maxLines: expanded ? null : _defCollapsedMaxLines,
        textOverflow: expanded ? null : _defCollapsedTextOverFlow,
      ),
      'strong': Style(fontWeight: FontWeight.bold),
      'i': Style(fontStyle: FontStyle.italic),
      'center': Style(textAlign: TextAlign.center),
      '.high': Style(backgroundColor: hiColor),
    },
  );
}
