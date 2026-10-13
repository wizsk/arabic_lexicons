import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/datas/lex_entry_bookmark.dart';
import 'package:arabic_lexicons/lex/data.dart';
import 'package:arabic_lexicons/lex/report_dict_entry.dart';
import 'package:arabic_lexicons/main_widgets.dart';
import 'package:arabic_lexicons/theme.dart';
import 'package:arabic_lexicons/utils/toast_snack.dart';
import 'package:arabic_lexicons/widgets/dahsed_divider.dart';
import 'package:arabic_lexicons/widgets/small_icon_btns.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Widget definitonCard(
  BuildContext context,
  int index,
  SearchLexiconsDatas datas,
  Widget child, {
  required String Function() text,
  required VoidCallback fs,
}) {
  final cs = Theme.of(context).colorScheme;
  final d = datas.selectedDict;
  final r = datas.dbRes[index];

  final ebm = LexEntryBm.contains(d, r);

  final actions = Row(
    // textDirection: TextDirection.rtl,
    mainAxisAlignment: MainAxisAlignment.start,
    spacing: 2,
    children: [
      iconButtonSized(
        context,
        icon: Icons.open_in_full_rounded,
        scheme: IconButtonSizedColor.primary,
        tooltip: 'Open in fullscreen',
        onPressed: fs,
        iconSize: 18,
      ),
      iconButtonSized(
        context,
        icon: Icons.copy_rounded,
        tooltip: 'Copy',
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: text()));
          MsgSv.showSnackbarMsg("Definiton copied");
        },
      ),
      Spacer(),
      iconButtonSized(
        context,
        icon: ebm ? Icons.bookmark_remove_rounded : Icons.bookmark_add_outlined,
        scheme: ebm ? IconButtonSizedColor.err : IconButtonSizedColor.normal,
        tooltip: 'Report an issue',
        onPressed: () async {
          if (ebm) {
            final confirm = await showConfirmDialog(
              context,
              "Remove Bookmark",
              scroolable: true,
              message:
                  'Do you want remove to lexcion entry “${datas.selectedWord}” from bookmarks?',
              confirmText: 'Remove',
              destructive: true,
              constraints: true,
              fontFam: L.arFont,
            );
            if (confirm != true) return;

            await LexEntryBm.remove(d, r);
          } else {
            await LexEntryBm.add(d, r);
          }
          datas.rebuild();
        },
      ),
      iconButtonSized(
        context,
        icon: Icons.flag_outlined,
        tooltip: 'Report an issue',
        onPressed: () async {
          // d9p("Trying to send report");
          final confirm = await showConfirmDialog(
            context,
            "Report an error?",
            scroolable: true,
            message:
                'Would you like to report a possible mistake in the entry “${datas.selectedWord}”? '
                '\n\n'
                'Your email app will open with a prepared report. '
                'If it can\'t be opened, a popup will let you copy the report and send it manually.'
                '\n\n'
                'Thank you for helping improve the lexicon!',
            fontFam: L.arFont,
            constraints: true,
            confirmText: "Report",
          );

          if (confirm != true) return;

          final ok = await reportDefinition(
            datas.dbRes[index],
            datas.selectedDict,
          );
          if (ok || !context.mounted) return;

          await showEmailFallbackDialog(
            context,
            row: datas.dbRes[index],
            dict: datas.selectedDict,
            email: emailAddr,
          );
        },
        scheme: IconButtonSizedColor.err,
      ),
    ],
  );
  const sidesPadd = 12.0;
  final textWidget = Padding(
    padding: const EdgeInsets.fromLTRB(sidesPadd, 12, sidesPadd, 0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        DashedDivider(height: 8, color: cs.outlineVariant),
        Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: actions),
        const SizedBox(height: 6),
      ],
    ),
  );

  final rc = ReaderColors.curr(context);
  final borderRadius = BorderRadius.circular(12);

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

  return DecoratedBox(decoration: decoration, child: textWidget);
}
