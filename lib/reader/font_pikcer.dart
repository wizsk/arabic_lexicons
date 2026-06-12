import 'package:ara_dict/data.dart';
import 'package:ara_dict/utils.dart';
import 'package:flutter/material.dart';

Future<String?> showFontPickerSheet(
  BuildContext context, {
  String? currentFont,
}) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    constraints: const BoxConstraints(maxWidth: 600),
    builder: (context) {
      final theme = Theme.of(context);
      final cs = theme.colorScheme;
      final th = theme.textTheme;

      String? selected = currentFont;

      final titleStyle = th.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      );

      final subtitleStyle = TextStyle(fontSize: 18, color: cs.onSurface);

      return SingleChildScrollView(
        padding: scrollPaddingBottmSheet(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Align(
              alignment: Alignment.center,
              child: Text(
                'Select Font',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ),

            const SizedBox(height: 12),

            ...separatedListBuilder(
              items: arabicFonts,
              separatorBuilder: (_) => SizedBox(height: 8),
              itemBuilder: (font, _) {
                // final font = arabicFonts[index];
                final isSelected = font == selected;

                return Material(
                  color: isSelected ? cs.primaryContainer : cs.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: cs.outlineVariant, width: 1),
                  ),
                  clipBehavior: Clip.antiAlias,

                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    title: Text(
                      font,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: isSelected
                          ? titleStyle?.copyWith(color: cs.onPrimaryContainer)
                          : titleStyle,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 12.0, left: 6.0),
                      child: Text(
                        /* ar */ 'السلام عليكم ورحمة الله',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: isSelected
                            ? subtitleStyle.copyWith(
                                color: cs.onPrimaryContainer,
                                fontFamily: font,
                              )
                            : subtitleStyle.copyWith(fontFamily: font),
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_outlined,
                            color: cs.onPrimaryContainer,
                          )
                        : null,
                    onTap: () => Navigator.pop(context, font),
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}
