import 'package:arabic_lexicons/change_logs.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/pages/help/help.dart';
import 'package:arabic_lexicons/play_rate.dart';
import 'package:flutter/material.dart';

Future<void> showWhatsNewSheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 600),
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 1.0,
        builder: (context, scrollController) {
          return ListView.separated(
            controller: scrollController,
            padding: scrollPaddingBottmSheet(context, sides: 20.0),
            itemCount: releases.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    elevatedIcon(
                      Theme.of(context).colorScheme,
                      Icons.new_releases_rounded,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "What's New",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Email sakibul706@gmail.com if you have any questions or encounter any problems",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }

              final release = releases[index - 1];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    release.version,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Divider(height: 1),

                  const SizedBox(height: 12),

                  ...release.changes.map((change) => Bullet(change)),
                ],
              );
            },
          );
        },
      );
    },
  );
}
