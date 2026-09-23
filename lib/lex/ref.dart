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
  const pad = 24.00;
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: EdgeInsets.all(14.0),
        constraints: BoxConstraints(
          maxWidth: appConf.maxWidth > 0
              ? appConf.maxWidth
              : maxUiWidth.maxWidth,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: pad),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  child: SelectionArea(
                    magnifierConfiguration: TextMagnifierConfiguration.disabled,
                    child: Text(
                      ref,
                      style: refStyle.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),

                const SizedBox(height: 18),
                OutlinedButton.icon(
                  label: Text('Close'),
                  icon: Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
