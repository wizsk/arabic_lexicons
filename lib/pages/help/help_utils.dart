import 'package:arabic_lexicons/data.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DictList extends StatelessWidget {
  // final List<Dict> dicts;

  const DictList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 5,
      children: allDicts.indexed.map((i) {
        final (idx, d) = i;
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            await showDialog(
              context: context,
              builder: (BuildContext context) {
                final theme = Theme.of(context);
                final cs = theme.colorScheme;

                return AlertDialog(
                  constraints: const BoxConstraints(maxWidth: 500),
                  backgroundColor: cs.surface,
                  title: Text(
                    '${d.en} (${d.ar})',
                    style: theme.textTheme.titleLarge,
                  ),
                  content: Text(
                    d.description,
                    style: theme.textTheme.bodyMedium,
                  ),
                  actions: [
                    if (d.link != null)
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          launchUrl(Uri.parse(d.link!));
                        },
                        child: Text('More Details'),
                      ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Ok'),
                    ),
                  ],
                );
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${(idx + 1).toString().padLeft(2, " ")}. '),
                Expanded(child: Text('${d.en} (${d.ar}) - ${d.enLong}')),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
