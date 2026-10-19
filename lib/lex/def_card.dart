import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/datas/lex_entry_bookmark.dart';
import 'package:arabic_lexicons/lex/dicts/db.dart';
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
  Widget child, {
  required int id,
  required Dict d,
  required String word,
  required String Function() text,
  required VoidCallback rebuild,
  required Future<void> Function() save,
  VoidCallback? fs,
  (Dict, DbRow) Function()? report,
  final bool useM3Colors = false,
}) {
  final cs = Theme.of(context).colorScheme;

  final ebm = LexEntryBm.containsId(d, id);

  final actions = Row(
    textDirection: TextDirection.ltr,
    spacing: 4,
    children: [
      if (!d.isArEn && report != null)
        iconButtonSized(
          context,
          icon: Icons.flag_outlined,
          tooltip: 'Report an issue',
          onPressed: () async {
            final (d, r) = report();

            final confirm = await showConfirmDialog(
              context,
              "Report an error?",
              scroolable: true,
              message:
                  'Would you like to report a possible mistake in the entry “${r.word}”? '
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

            final ok = await reportDefinition(r, d);
            if (ok || !context.mounted) return;

            await showEmailFallbackDialog(
              context,
              row: r,
              dict: d,
              email: emailAddr,
            );
          },
          scheme: IconButtonSizedColor.err,
        ),
      const Spacer(),
      iconButtonSized(
        context,
        icon: ebm ? Icons.bookmark_remove_rounded : Icons.bookmark_add_outlined,
        scheme: ebm ? IconButtonSizedColor.err : IconButtonSizedColor.normal,
        tooltip: ebm ? 'Remove' : 'Save',
        onPressed: () async {
          if (ebm) {
            final confirm = await showConfirmDialog(
              context,
              "Remove Bookmark",
              scroolable: true,
              message:
                  'Do you want remove to lexcion entry “$word” from bookmarks?',
              confirmText: 'Remove',
              destructive: true,
              constraints: true,
              fontFam: L.arFont,
            );
            if (confirm != true) return;

            await LexEntryBm.remove(d.table, id);
            MsgSv.showSnackbarMsg("Definiton removed: $word");
          } else {
            await save();
            MsgSv.showSnackbarMsg("Definiton added: $word");
          }
          rebuild();
        },
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
      if (fs != null)
        iconButtonSized(
          context,
          icon: Icons.open_in_full_rounded,
          scheme: IconButtonSizedColor.primary,
          tooltip: 'Open in fullscreen',
          onPressed: fs,
          iconSize: 18,
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

  final rc = useM3Colors
      ? ReaderColors.m3(context)
      : ReaderColors.curr(context);

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

  final b = DecoratedBox(decoration: decoration, child: textWidget);
  return fs == null ? b : GestureDetector(onTap: fs, child: b);
}

Widget definitonCardDbRow(
  BuildContext context,
  Dict d,
  DbRow r,
  Widget child, {
  required String Function() text,
  required VoidCallback fs,
  required VoidCallback rebuild,
  VoidCallback? onRemove,
  final bool useM3Colors = false,
}) {
  final res = definitonCard(
    context,
    child,
    d: d,
    id: r.id,
    text: text,
    word: r.word,
    fs: fs,
    save: () async {
      await LexEntryBm.addDbRow(d, r);
    },
    rebuild: rebuild,
    report: () => (d, r),
  );

  return res;
}
