import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/pages/data.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:flutter/material.dart';

Future<int?> showStoryPicker(BuildContext context) {
  return showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 650),
    builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return Padding(
        // padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: scrollPaddingBottmSheet(context, sides: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    color: cs.primary,
                    size: 38,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stories & Texts',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${stories.length} stories and texts available',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Stories
            Flexible(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: stories.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return Material(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => Navigator.pop(context, index),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              // Story number
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  enToArNum(index + 1),
                                  style: TextStyle(
                                    color: cs.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: L.arFont,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 14),

                              // Story details
                              Expanded(
                                child: Text(
                                  stories[index].first,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontFamily: L.arFont,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              Icon(
                                Icons.chevron_right_rounded,
                                color: cs.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
