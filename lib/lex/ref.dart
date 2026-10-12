import 'dart:math';

import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// tafseer.app (maybe) thier refferences are like this...
abstract final class ReferenceProcessor {
  static TextSpan processRich(
    BuildContext context,
    String text,
    TextStyle refStyle,
  ) {
    final initial = text.split("]]").toList();
    final iLen = initial.length;
    for (int i = 1; i < iLen; i++) {
      if (initial[i].startsWith("]")) {
        initial[i] = initial[i].replaceFirst("]", "");
        initial[i - 1] = '${initial[i - 1]}]';
      }
    }

    final refColor = Theme.of(context).colorScheme.primary;
    final spans = <InlineSpan>[];

    int count = 0;
    for (final e in initial) {
      // even if it has [[[ then the last one will remain at the right pos
      // as the split works by spliting by the 1st one
      if (e.contains("[[")) {
        var (:pre, :suf) = e.splitOnce("[[");
        pre ??= "";
        suf ??= "";

        if (pre.isNotEmpty) spans.add(TextSpan(text: pre));
        if (suf.isEmpty) continue;
        if (suf.startsWith(".")) {
          suf = suf.replaceFirst(".", " ").trim();
        }

        count++;
        final number = enToArNum(count);
        spans.add(
          TextSpan(
            text: '($number)',
            style: TextStyle(color: refColor),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _showReferenceBottomSheet(context, suf!, refStyle);
              },
          ),
        );
      } else {
        spans.add(TextSpan(text: e));
      }
    }

    return TextSpan(children: spans);
  }
}

void _showReferenceBottomSheet(
  BuildContext context,
  String ref,
  TextStyle refStyle,
) {
  showDialog(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      final cs = theme.colorScheme;

      final maxWidth = appConf.maxWidth > 0
          ? appConf.maxWidth
          : maxUiWidth.maxWidth;

      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          scrollable: true,
          insetPadding: const EdgeInsets.all(14),
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            minWidth: min(400, maxWidth - 1),
          ),
          icon: Icon(Icons.menu_book_rounded, color: cs.primary, size: 28),
          iconPadding: const EdgeInsets.only(top: 24, bottom: 8),
          title: Text(
            'المراجع والملاحظات',
            style: theme.textTheme.titleMedium?.ar.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          content: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: SelectionArea(
              magnifierConfiguration: TextMagnifierConfiguration.disabled,
              child: Text.rich(
                TextSpan(
                  text: ref,
                  style: refStyle.copyWith(color: cs.onSurface),
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.start,
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          actionsAlignment: MainAxisAlignment.start,
          actions: [
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: Text('إغلاق', style: L.arStyle),
            ),
          ],
        ),
      );
    },
  );
}
