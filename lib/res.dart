import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:ara_dict/ar_en.dart';
import 'package:ara_dict/data.dart';

Widget showRes(
  TextStyle ts,
  Dict curDict,
  List<Map<String, dynamic>>? dbRes,
  List<Entry>? arEnRes,
) {
  if (curDict == Dict.arEn) {
    return showArEnRes(ts, arEnRes);
  }

  var dir = TextDirection.rtl;
  var al = TextAlign.right;
  var fontFam = fontKitab;
  if (curDict == Dict.hanswehr || curDict == Dict.laneLexicon) {
    al = TextAlign.left;
    dir = TextDirection.ltr;
    fontFam = fontAmiri;
  }

  var showWordTitle = curDict == Dict.mujamulGhoni;

  if (dbRes != null && dbRes.isNotEmpty) {
    return ListView.separated(
      // padding: EdgeInsets.only(top: 16),
      padding: scrollPadding,
      itemCount: dbRes.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 0, thickness: 0.5),
      itemBuilder: (context, index) {
        final row = dbRes[index];
        String txt;
        if (showWordTitle) {
          final word = row['word'] ?? '';
          final meaning = row['meanings'] ?? '';
          txt = '$word: $meaning';
        } else {
          txt = row['meanings'] ?? '';
        }
        // return RichText(text: TextSpan(text: row['meanings']));
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: meaningView(txt, fontFam, dir, al, ts.fontSize!, ts.height!),
        );
      },
    );
  }
  return _noRes(ts);
}

Widget meaningView(
  String html,
  String font,
  TextDirection dir,
  TextAlign al,
  double fsz,
  double lh,
) {
  return Html(
    data: html,
    style: {
      'body': Style(
        fontFamily: font,
        lineHeight: LineHeight.number(lh),
        direction: dir,
        textAlign: al,
        fontSize: FontSize(fsz),
      ),
      'strong': Style(fontWeight: FontWeight.bold),
      'i': Style(fontStyle: FontStyle.italic),
      'center': Style(textAlign: TextAlign.center),
    },
  );
}

Widget _noRes(TextStyle ts) {
  const txt = "لا توجد نتائج";
  return Center(child: Text(txt, style: ts));
}

Widget showArEnRes(TextStyle ts, List<Entry>? entries) {
  if (entries == null || entries.isEmpty) {
    return _noRes(ts);
  }

  return SingleChildScrollView(
    child: Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: scrollPadding,
        child: DataTable(
          dataTextStyle: ts,
          dividerThickness: 0.5,
          columnSpacing: 12.0,
          headingTextStyle: const TextStyle(fontWeight: FontWeight.w600),
          columns: const [
            DataColumn(label: Text('Word')),
            DataColumn(label: Text('Def')),
            DataColumn(label: Text('Root')),
          ],
          rows: entries.map((e) {
            return DataRow(
              cells: [
                DataCell(Text(e.word)),
                DataCell(Text(e.def)),
                DataCell(Text(e.root)),
              ],
            );
          }).toList(),
        ),
      ),
    ),
  );
}
