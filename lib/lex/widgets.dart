import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/datas/word_store.dart';
import 'package:arabic_lexicons/lex/data.dart';
import 'package:arabic_lexicons/main_widgets.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:flutter/material.dart';

Widget lexAppBar(
  BuildContext context,
  SearchLexiconsDatas datas,
  VoidCallback onChange,
) {
  final dictName =
      '${datas.selectedDict.name}${datas.selectedWord.isEmpty ? '' : ':'}';

  Widget title = Text(
    dictName,
    style: L.arStyleOrNew.copyWith(fontWeight: FontWeight.w500),
    textDirection: L.dir,
  );

  if (datas.selectedWord.isNotEmpty) {
    title = Row(
      textDirection: L.dir,
      // textDirection: TextDirection.rtl,
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: 4.0,
      children: [
        title,
        Flexible(
          child: Text(
            datas.selectedWord.replaceAll('_', ' ').takeMax(12),
            style: L.arStyle,
            textDirection: TextDirection.rtl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
  final bm = WordStore.isBm(datas.selectedWord);
  final cs = Theme.of(context).colorScheme;

  final actions = <Widget>[
    IconButton(
      icon: datas.state.isSug
          ? const Icon(Icons.directions)
          : const Icon(Icons.auto_awesome),
      tooltip: 'Toggle search suggestions',
      onPressed:
          datas.selectedWord.isNotEmpty &&
              appConf.showSearchSugg &&
              !datas.state.isQuering
          ? () async {
              final ss = datas.state.isSug;
              await datas.getAndShowResORSugg(
                context,
                forceSugg: !ss,
                forceRes: ss,
              );
            }
          : null,
    ),
    IconButton(
      icon: bm
          ? Icon(Icons.bookmark, color: cs.error)
          : Icon(Icons.bookmark_border),
      tooltip: bm ? 'Unbookmark' : 'BookMark',
      onPressed: datas.selectedWord.isEmpty
          ? null
          : () async {
              if (bm) {
                final confirm = await showConfirmDialog(
                  context,
                  'Remove Bookmark',
                  message: 'Remove: ${datas.selectedWord}',
                  destructive: true,
                  confirmText: 'Remove',
                );
                if (confirm != true) return;
                WordStore.rmBM(datas.selectedWord);
              } else {
                WordStore.addBM(datas.selectedWord);
              }
              onChange();
            },
    ),
  ];

  final bg = datas.appbarReaderBg ? appConf.readerSurface(context) : null;

  return datas.state.isSug
      ? AppBar(
          title: title,
          forceMaterialTransparency: true,
          // most likely unnessesary
          backgroundColor: appConf.readerSurface(context),
          actions: actions,
        )
      : Directionality(
          textDirection: TextDirection.ltr,
          child: SliverAppBar(
            title: title,
            backgroundColor: bg,
            titleSpacing: 0.0,
            floating: true,
            snap: appConf.hideAppbar,
            pinned: !appConf.hideAppbar,
            actions: actions,
          ),
        );
}
