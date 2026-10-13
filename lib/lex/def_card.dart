import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/lex/data.dart';
import 'package:arabic_lexicons/lex/report_dict_entry.dart';
import 'package:arabic_lexicons/theme.dart';
import 'package:arabic_lexicons/utils.dart';
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
  // final colors = cs;

  final actions = Row(
    textDirection: TextDirection.ltr,
    mainAxisAlignment: MainAxisAlignment.end,
    // spacing: 2,
    children: [
      iconButtonSized(
        context,
        icon: Icons.copy_rounded,
        tooltip: 'Copy',
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: text()));
          MsgSv.showSnackbarMsg("Definiton copied");
        },
      ),
      iconButtonSized(
        context,
        icon: Icons.flag_outlined,
        tooltip: 'Report an issue',
        onPressed: () async {
          dp("Trying to send report");

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
      Spacer(),
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
