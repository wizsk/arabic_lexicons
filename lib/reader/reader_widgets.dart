import 'dart:math';

import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/datas/word_store.dart';
import 'package:ara_dict/reader/data.dart';
import 'package:ara_dict/reader/settings_class.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:ara_dict/utils.dart';
import 'package:ara_dict/widgets/selectable_text_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

const paraSpacerStart = WidgetSpan(child: SizedBox(width: 20));
const paraSpaceInbetween = EdgeInsets.symmetric(vertical: 8);

class ClickableParagraph extends StatelessWidget {
  final int index;
  final PeraEntries peras;
  final ReaderPageSettings rs;
  final void Function() onChange;
  final TextStyle style;
  final TextStyle styleLU;
  final TextStyle highStyletyle;
  final TextAlign textAlign;
  final ColorScheme cs;

  const ClickableParagraph({
    super.key,
    required this.index,
    required this.peras,
    required this.rs,
    required this.onChange,
    required this.style,
    required this.styleLU,
    required this.highStyletyle,
    required this.cs,
    this.textAlign = TextAlign.justify,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: () {
        SelectableTextScreen.show(
          context,
          (start, end) => _peraSelectTxt(peras, rs, start: start, end: end),
          rs.textAlign,
          TextDirection.rtl,
          style,
          currentIdx: index,
          length: peras.length,
        );
      },
      child: RichText(
        textDirection: TextDirection.rtl,
        textAlign: textAlign,
        text: TextSpan(style: style, children: _buildSpans(context)),
      ),
    );
  }

  List<TextSpan> _buildSpans(BuildContext context) {
    final spans = <TextSpan>[];

    spans.add(TextSpan(children: [paraSpacerStart]));
    for (final word in peras[index]) {
      spans.add(
        _readerWordSpan(
          context: context,
          rs: rs,
          isBmk: WordStore.isBm(word.cl),
          word: word,
          onChange: onChange,
          style: style,
          styleLU: styleLU,
          highStyle: highStyletyle,
        ),
      );
    }
    return spans;
  }
}

class ClickableBayt extends StatelessWidget {
  final PeraEntries paras;
  final int index;
  final ReaderPageSettings rs;
  final void Function() onChange;
  final TextStyle style;
  final TextStyle styleLU;
  final TextStyle highStyletyle;
  final TextAlign textAlign;
  final ColorScheme cs;

  void showSelectableBayt(BuildContext ctx, int index) {
    int? end;
    int? start;

    if (index % 2 == 0) {
      start = index;
      end = min(paras.length, index + 2);
    } else {
      start = index - 1;
      end = index + 1;
    }

    SelectableTextScreen.show(
      ctx,
      (start, end) => _peraSelectTxt(paras, rs, start: start, end: end),
      rs.textAlign,
      TextDirection.rtl,
      style,
      currentIdx: index,
      length: paras.length,
      start: start,
      end: end,
    );
  }

  const ClickableBayt({
    super.key,
    required this.paras,
    required this.index,
    required this.rs,
    required this.onChange,
    required this.style,
    required this.styleLU,
    required this.highStyletyle,
    required this.cs,
    this.textAlign = TextAlign.justify,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: () => showSelectableBayt(context, index),
      child: RichText(
        textDirection: TextDirection.rtl,
        textAlign: textAlign,
        text: TextSpan(style: style, children: _buildSpans(context)),
      ),
    );
  }

  List<TextSpan> _buildSpans(BuildContext context) {
    final spans = <TextSpan>[];

    if (index % 2 == 0) {
      if (rs.qasidahLineNum) {
        spans.add(
          TextSpan(
            text: '${enToArNum((index ~/ 2) + 1)}- ',
            style: style.copyWith(fontWeight: FontWeight.bold, color: cs.error),
          ),
        );
      }
    } else if (!rs.isQasidahCentered) {
      spans.add(
        TextSpan(children: [const WidgetSpan(child: SizedBox(width: 30))]),
      );
    }

    for (final word in paras[index]) {
      spans.add(
        _readerWordSpan(
          context: context,
          rs: rs,
          isBmk: WordStore.isBm(word.cl),
          word: word,
          onChange: onChange,
          style: style,
          styleLU: styleLU,
          highStyle: highStyletyle,
        ),
      );
    }
    return spans;
  }
}

TextSpan _readerWordSpan({
  required BuildContext context,
  required ReaderPageSettings rs,
  required bool isBmk,
  required WordEntry word,
  required void Function() onChange,
  required TextStyle style,
  required TextStyle styleLU,
  required TextStyle highStyle,
}) {
  TextStyle ts;
  if (rs.isBmColored && isBmk) {
    ts = highStyle;
  } else if (rs.foreignColored && WordStore.isForeign(word.cl)) {
    ts = styleLU;
  } else {
    ts = style;
  }

  return TextSpan(
    text: rs.isRmTashkil ? '${word.nTk} ' : '${word.ar} ',
    recognizer: word.cl.isEmpty
        ? null
        : (TapGestureRecognizer()
            ..onTap = appConf.readerIsOpenLexiconDirecly
                ? () {
                    openDictAndAddForeign(context, word.cl, onChange, rs);
                  }
                : () => showWordReadeActionsDialog(
                    context,
                    word.cl,
                    isBmk,
                    () async {
                      if (isBmk) {
                        await WordStore.rmBM(word.cl);
                      } else {
                        await WordStore.addBM(word.cl);
                      }
                      if (context.mounted) onChange();
                    },
                    () {
                      openDictAndAddForeign(context, word.cl, onChange, rs);
                    },
                    style,
                  )),
    style: ts,
  );
}

String _peraSelectTxt(
  PeraEntries peras,
  ReaderPageSettings rs, {
  int? start,
  int? end,
}) {
  if (start == null || end == null || peras.isEmpty) return '';

  if (start < 0) start = 0;
  if (end > peras.length) end = peras.length;

  // print('$start, $end -> ${peras.length}');
  // int line = 1;
  return peras
      .getRange(start, end)
      .map((p) {
        // return '${line++}: ${p.map((w) => rs.isRmTashkil ? w.nTk : w.ar).join(' ')}';
        return p.map((w) => rs.isRmTashkil ? w.nTk : w.ar).join(' ');
      })
      .join('\n\n');
}

Future<void> openDictAndAddForeign(
  BuildContext context,
  String word,
  VoidCallback onChange,
  ReaderPageSettings rs,
) async {
  snackClearForced();

  openDict(context, word).then((_) {
    if (!context.mounted) return;

    onChange();
    if (rs.foreignAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showSnack(
          context,
          '',
          messageWidget: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Foreign added: '),
                TextSpan(text: word, style: L.arStyle),
              ],
            ),
          ),
          forceCloseAfter: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              await WordStore.removeForeign(word);
              if (!context.mounted) return;
              onChange();
            },
          ),
        );
      });
    }
  });

  if (rs.foreignAdd) WordStore.addForeign(word);
}
