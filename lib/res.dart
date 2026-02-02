import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:ara_dict/ar_en.dart';
import 'package:ara_dict/data.dart';

Widget showRes(
  Dict curDict,
  List<Map<String, dynamic>>? dbRes,
  List<Entry>? arEnRes,
) {
  switch (curDict) {
    case Dict.arEn:
      return showArEnRes(arEnRes);
    // case "":
    default:
  }

  var dir = TextDirection.rtl;
  var al = TextAlign.right;
  var fontFam = fontKitab;
  if (curDict == Dict.hanswehr || curDict == Dict.laneLexicon) {
    al = TextAlign.left;
    dir = TextDirection.ltr;
    fontFam = fontAmiri;
  }

  // final hideWordTtl = curDict == Dict.hanswehr;

  if (dbRes != null && dbRes.isNotEmpty) {
    return ListView.separated(
      // padding: EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      itemCount: dbRes.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 24, thickness: 1, color: Colors.grey),
      itemBuilder: (context, index) {
        final row = dbRes[index];
        // return RichText(text: TextSpan(text: row['meanings']));
        return Padding(
          // padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // if (!hideWordTtl)
              Center(
                child: Text(
                  row['word'] ?? '',
                  style: const TextStyle(
                    // fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              meaningView(row['meanings'] ?? '', fontFam, dir, al),
            ],
          ),
        );
      },
    );
  }
  return Center(child: Text("No results"));
}

Widget meaningView(String html, String font, TextDirection dir, TextAlign al) {
  return Directionality(
    textDirection: TextDirection.rtl, // Arabic
    child: Html(
      data: html,
      style: {
        'body': Style(
          // fontSize: FontSize(16),
          fontFamily: font,
          lineHeight: LineHeight.number(1.6),
          direction: dir,
          textAlign: al,
        ),
        'strong': Style(fontWeight: FontWeight.bold, fontFamily: font),
        'i': Style(fontStyle: FontStyle.italic, fontFamily: font),
      },
    ),
  );
}

Widget showArEnRes(List<Entry>? entries) {
  if (entries == null || entries.isEmpty) {
    return const Center(child: Text('No results'));
  }

  return SingleChildScrollView(
    child: Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 12.0,
          columns: const [
            DataColumn(label: Text('Word')),
            DataColumn(label: Text('Definition')),
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
