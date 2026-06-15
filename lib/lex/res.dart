import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/lex/data.dart';
import 'package:ara_dict/utils.dart';
import 'package:ara_dict/widgets/no_res.dart';
import 'package:ara_dict/widgets/selectable_text_screen.dart';
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
    return _showArEnRes(ts, datas);
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
  return SliverToBoxAdapter(
    child: Padding(
      // padding: const EdgeInsets.all(16.0).copyWith(top: 32),
      padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.3),
      child: Center(
        child: noResUniversal(
          noWordAr: noWordAr,
          noWordEn: noWordEn,
          noResAr: noResAr,
          noResEn: noResEn,
          currWord,
        ),
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
  if (currWord == null || currWord.isEmpty) {
    return NoResults(
      icon: Icons.search_outlined,
      title: L.p(noWordEn, noWordAr),
      titleDir: L.dir,
      titleFont: L.arFontIf,
    );
  }

  return NoResults(
    icon: NoResults.searchEmpty,
    title: L.p(noResEn, noResAr),
    titleDir: L.dir,
    titleFont: L.arFontIf,
    subtitle: currWord.replaceAll("_", " "),
    subtitleFont: L.arFontIf,
    subtitleDir: TextDirection.rtl,
  );
}

Widget _showArEnRes(TextStyle ts, SearchLexiconsDatas datas) {
  return SliverToBoxAdapter(
    child: Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // padding: scrollPadding,
        child: DataTable(
          dataTextStyle: ts,
          // dividerThickness: 0.5,
          columnSpacing: 18.0,
          headingTextStyle: ts.copyWith(fontWeight: FontWeight.bold),
          columns: const [
            DataColumn(label: Text('Word')),
            DataColumn(label: Text('Meanings')),
            DataColumn(label: Text('Root')),
          ],
          rows: datas.arEnRes.map((e) {
            return DataRow(
              cells: [
                DataCell(Text(e.word)),
                // DataCell(Text(e.def)),
                DataCell(SelectableText(e.def, style: ts)),
                // DataCell(Text(e.root)),
                DataCell(
                  InkWell(
                    onTap: () {
                      datas.onChangeTxt(appendTxt: e.root.split('/')[0]);
                    },
                    child: Text(e.root),
                  ),
                ),
              ],
            );
          }).toList(),
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
              (_, _) => cleanTxtBr,
              TextAlign.left,
              TextDirection.ltr,
              // ts,
              ts.copyWith(
                fontFamily: fontAmiri,
                // the html renderer and normal renderer not the same :)
                height: fontAmiriLineHeight + 0.3,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _engMeaningView(txt, ts.fontSize!, cs, row.isHi),
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
        child: _arMeaningView(context, txt, ts),
      );
    },
  );
}

Widget _arMeaningView(BuildContext context, String txt, TextStyle ts) {
  return GestureDetector(
    onLongPress: () {
      SelectableTextScreen.show(
        context,
        (_, _) => txt,
        TextAlign.right,
        TextDirection.rtl,
        ts,
      );
    },
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
  double fsz,
  ColorScheme cs,
  bool isHighResult,
) {
  return Html(
    data: html,
    style: {
      'body': Style(
        fontFamily: fontAmiri,
        lineHeight: LineHeight.number(fontAmiriLineHeight),
        direction: TextDirection.ltr,
        textAlign: TextAlign.left,
        fontSize: FontSize(fsz),
        color: isHighResult ? cs.primary : null,
      ),
      'strong': Style(fontWeight: FontWeight.bold),
      'i': Style(fontStyle: FontStyle.italic),
      'center': Style(textAlign: TextAlign.center),
      '.high': Style(color: cs.onPrimary, backgroundColor: cs.primary),
    },
  );
}
