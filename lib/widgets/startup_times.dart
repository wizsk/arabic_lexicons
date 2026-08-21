import 'dart:io';

import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/main_widgets.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StartupTimeData {
  final int took;
  final int msecondsSinceEpoch;
  const StartupTimeData(this.took, this.msecondsSinceEpoch);

  static Future<File> get dest async {
    final d = await getApplicationDocumentsDirectory();
    return File(p.join(d.path, 'app-lauch-data-times.txt'));
  }

  static Future<void> loadAndSave(int took, int msecondsSinceEpoch) async {
    final data = await dest;

    try {
      for (final l in await data.readAsLines()) {
        final r = l.trim();
        if (r.isEmpty) continue;
        final s = r.split(':');
        if (s.length != 2) continue;
        startupTimes.add(StartupTimeData(int.parse(s[0]), int.parse(s[1])));
      }
    } catch (_) {}
    startupTimes.add(StartupTimeData(took, msecondsSinceEpoch));
    try {
      data.writeAsString(
        startupTimes.map((e) => '${e.took}:${e.msecondsSinceEpoch}').join('\n'),
      );
    } catch (_) {}
  }
}

List<StartupTimeData> startupTimes = [];

void showStartupTimesBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          final avg = startupTimes.isEmpty
              ? 0
              : (startupTimes.fold<int>(0, (sum, item) => sum + item.took) /
                        startupTimes.length)
                    .round();

          return Column(
            children: [
              Padding(
                padding: scrollPaddingBottmSheet(context, sides: 24),
                child: Row(
                  children: [
                    const Icon(Icons.speed_rounded, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Startup Performance',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${startupTimes.length} operations${startupTimes.isEmpty ? '' : ' · ${avg}ms average'}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton.outlined(
                      icon: Icon(Icons.clear_all),
                      tooltip: 'Clear all',
                      onPressed: startupTimes.isEmpty
                          ? null
                          : () async {
                              final res = await showConfirmDialog(
                                context,
                                'Clear?',
                              );
                              if (res != true) return;
                              try {
                                startupTimes.clear();
                                await (await StartupTimeData.dest).delete();
                              } catch (_) {}
                              if (context.mounted) Navigator.of(context).pop();
                            },
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              Expanded(
                child: startupTimes.isEmpty
                    ? Center(
                        child: Text(
                          'No startup measurements',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: startupTimes.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, indent: 72),
                        itemBuilder: (context, index) {
                          final item = startupTimes[index];

                          return ListTile(
                            leading: CircleAvatar(child: Text('${index + 1}')),
                            title: Text(
                              '${item.took} ms',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              formatDateTime(
                                context,
                                dt: DateTime.fromMillisecondsSinceEpoch(
                                  item.msecondsSinceEpoch,
                                  isUtc: true,
                                ).toLocal(),
                              ),
                            ),
                            trailing: item.took >= 1000
                                ? Icon(
                                    Icons.warning_amber_rounded,
                                    color: Theme.of(context).colorScheme.error,
                                  )
                                : null,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      );
    },
  );
}
