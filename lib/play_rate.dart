import 'package:arabic_lexicons/data.dart';
import 'package:flutter/material.dart';
// import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openRatingFlow() async {
  // final inAppReview = InAppReview.instance;

  // if (await inAppReview.isAvailable()) {
  //   await inAppReview.requestReview();
  //   return;
  // }

  const packageName = 'io.github.wizsk.arabic_lexicons';

  final uri = Uri.parse(
    'https://play.google.com/store/apps/details?id=$packageName',
  );

  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

enum RatePromptResult { rateNow, done, later, never }

Future<RatePromptResult?> showRatePromptBottomSheet(BuildContext context) {
  return showModalBottomSheet<RatePromptResult?>(
    context: context,
    constraints: const BoxConstraints(maxWidth: 600),
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      final cs = theme.colorScheme;
      final tt = theme.textTheme;
      final padd = scrollPaddingBottmSheet(context);

      return SingleChildScrollView(
        padding: padd.copyWith(right: 20, left: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header icon
            elevatedIcon(cs, Icons.menu_book_rounded),
            const SizedBox(height: 20),

            Text(
              'Enjoying the app?',
              textAlign: TextAlign.center,
              style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),
            Text(
              'Your support means a lot. A quick rating helps us improve the app and keep building useful features for you.',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                icon: const Icon(Icons.star_rounded),
                label: const Text("Sure, I'll rate it"),
                onPressed: () {
                  Navigator.pop(context, RatePromptResult.rateNow);
                },
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.schedule_rounded),
                label: const Text('Maybe Later'),
                onPressed: () {
                  Navigator.pop(context, RatePromptResult.later);
                },
              ),
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 6,
              runSpacing: 16,
              children: [
                TextButton.icon(
                  icon: Icon(Icons.done, color: cs.onSurfaceVariant),
                  label: Text(
                    "Already reviewed",
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  onPressed: () {
                    Navigator.pop(context, RatePromptResult.done);
                  },
                ),
                TextButton.icon(
                  icon: Icon(Icons.block_rounded, color: cs.onSurfaceVariant),
                  label: Text(
                    "Don't Ask Again",
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  onPressed: () {
                    Navigator.pop(context, RatePromptResult.never);
                  },
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Widget elevatedIcon(
  ColorScheme cs,
  IconData iconData, {
  final double iconSize = 38.00,
  final double diemtion = 72.00,
  Color? fg,
  Color? bg,
}) {
  fg = fg ?? cs.onPrimaryContainer;
  bg = bg ?? cs.primaryContainer;

  return Container(
    width: diemtion,
    height: diemtion,
    decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
    child: Icon(iconData, size: iconSize, color: fg),
  );
}
