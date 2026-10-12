import 'dart:math';

import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// tafseer.app (maybe) thier refferences are like this...
class ReferenceProcessor {
  static final RegExp _refExp = RegExp(r'\[\[(.*?)\]\]', dotAll: true);

  static InlineSpan processRich(
    BuildContext context,
    String text,
    TextStyle refStyle,
  ) {
    if (text.isEmpty) {
      return const TextSpan();
    }

    final refColor = Theme.of(context).colorScheme.primary;

    final spans = <InlineSpan>[];
    int lastIndex = 0;
    int counter = 1;

    for (final match in _refExp.allMatches(text)) {
      // Text before the reference.
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }

      final refContent = match.group(1);

      if (refContent != null) {
        final ref = refContent.replaceFirst('.', '').trim();
        final number = enToArNum(counter.toString());
        counter++;

        spans.add(
          TextSpan(
            text: '($number)',
            style: TextStyle(color: refColor),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                showReferenceBottomSheet(context, ref, refStyle);
              },
          ),
        );
      }

      lastIndex = match.end;
    }

    // Remaining text.
    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return TextSpan(children: spans);
  }
}

void showReferenceBottomSheet(
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
