import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/pages/settings/settings.dart';
import 'package:arabic_lexicons/review/models.dart';
import 'package:flutter/material.dart';

Future<RevOrdData?> showRevOrdSheet(BuildContext context, RevOrdData initial) {
  return showModalBottomSheet<RevOrdData>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    constraints: maxUiWidth,
    builder: (_) => _RevOrdSheet(initial: initial),
  );
}

class _RevOrdSheet extends StatefulWidget {
  final RevOrdData initial;

  const _RevOrdSheet({required this.initial});

  @override
  State<_RevOrdSheet> createState() => _RevOrdSheetState();
}

class _RevOrdSheetState extends State<_RevOrdSheet> {
  late RevOrdData data;

  @override
  void initState() {
    super.initState();
    data = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final orderDescription = data.onlyNew
        ? 'Only new words will be shown, using the selected order.'
        : data.ord.description;

    return Padding(
      padding: scrollPaddingBottmSheet(context, sides: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Word review order',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),

                  RadioGroup<RevOrder>(
                    groupValue: data.ord,
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        data = data.copyWith(ord: value);
                      });
                    },
                    child: Column(
                      children: [
                        ...RevOrder.values.map(
                          (ord) => RadioListTile<RevOrder>(
                            value: ord,
                            title: Text(ord.label),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Description of the currently selected order.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 22,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            orderDescription,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  SettingsSectionSurface(
                    children: [
                      SwitchListTile(
                        value: data.onlyNew,
                        onChanged: (value) {
                          setState(() {
                            data = data.copyWith(onlyNew: value);
                          });
                        },
                        secondary: const FilledIcon(Icons.update),
                        title: const Text('Only new words'),
                        subtitle: const Text(
                          'Skip due words and show only new, unseen words',
                        ),
                      ),

                      SwitchListTile(
                        value: data.bookMarksFirst,
                        onChanged: (value) {
                          setState(() {
                            data = data.copyWith(bookMarksFirst: value);
                          });
                        },
                        secondary: const FilledIcon(Icons.bookmark),
                        title: const Text('Bookmarks first'),
                        subtitle: const Text(
                          'Show bookmarked words before foreign words',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

          // const Divider(height: 0),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(context, data),
              style: FilledButton.styleFrom(minimumSize: const Size(50, 50)),
              label: const Text('Save'),
              icon: const Icon(Icons.save),
            ),
          ),
        ],
      ),
    );
  }
}
