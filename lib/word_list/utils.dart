import 'dart:convert';
import 'dart:io';

import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/lex/isolate.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

const ankiExportFileName = 'Arabic_Lexicons_anki_import.txt';

Future<(String, Uint8List)> makeAnki(
  Iterable<String> words,
  bool addMeanings,
) async {
  // header
  final sb = StringBuffer(
    addMeanings
        ? '#separator:Tab\n#html:true\n#notetype:Basic\n'
        : '#separator:Tab\n#html:false\n#notetype:Basic\n',
  );

  for (final w in words) {
    sb.write(w);

    if (!addMeanings) {
      sb.write('\n');
      continue;
    }

    final meanings = await Isolates.arEnSearch(w);
    if (meanings.isEmpty) {
      sb.write('\n');
      continue;
    }
    final esc = HtmlEscape();
    final m = meanings
        .map((e) => esc.convert('${e.def} ${e.word}'))
        .join('<br>');
    sb.write('\t');
    sb.write(m);
    sb.write('\n');
  }

  final dir = await getTemporaryDirectory();
  final file = File(join(dir.path, ankiExportFileName));

  final data = utf8.encode(sb.toString());
  await file.writeAsBytes(data);

  return (file.path, data);
}

Future<(bool, bool)?> showAnkiCardShareOptions(BuildContext context) async {
  bool addMeanings = false;
  return showDialog<(bool, bool)?>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final theme = Theme.of(context);
          // final cs = theme.colorScheme;

          return AlertDialog(
            constraints: const BoxConstraints(maxWidth: 450),
            title: Text(
              'Anki Cards',
              // style: theme.textTheme.titleLarge,
            ),
            content: Column(
              spacing: 4,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share as Anki cards. After exporting, '
                  'tap "Share with Anki" and select Anki. '
                  'By default, only the words are exported. '
                  'You can toggle "Add meanings" below to include meanings from the '
                  '"${Dict.arEn.en}" (${Dict.arEn.ar}) dictionary on the back of the cards. '
                  'All available meanings for each word will be added.',
                  style: theme.textTheme.bodyMedium,
                ),
                SizedBox(height: 8),
                InkWell(
                  onTap: () => setState(() => addMeanings = !addMeanings),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Checkbox(
                        onChanged: (val) =>
                            setState(() => addMeanings = val ?? false),
                        value: addMeanings,
                      ),
                      Flexible(child: Text('Add meanigs')),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop((false, false)),
                child: Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop((true, addMeanings)),
                child: Text('Export'),
              ),
            ],
          );
        },
      );
    },
  );
}
