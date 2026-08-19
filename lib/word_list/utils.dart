import 'dart:convert';
import 'dart:io';

import 'package:arabic_lexicons/alphabets.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/helper_widgets.dart';
import 'package:arabic_lexicons/lex/isolate.dart';
import 'package:arabic_lexicons/main_widgets.dart';
import 'package:arabic_lexicons/reader/reader_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

Widget buildWordListAppbarMenu(
  BuildContext context, {
  required VoidCallback stateChanged,
  required List<String> Function() getSelectedWords,
  required List<String> allWords,
  required Future<void> Function(String) add,
  required Future<int> Function(Iterable<String>) addMulti,
  required Future<void> Function(String) remove,
  required Future<int> Function(Iterable<String>) removeMuli,
  required Future<void> Function() clearAll,
  required String exportFileName,
}) {
  Iterable<String>? getWords(bool all) {
    if (all) {
      if (allWords.isEmpty) {
        showSnack(context, 'No words');
        return null;
      }
      return allWords;
    } else {
      final words = getSelectedWords();
      if (words.isEmpty) {
        showSnack(context, 'No words Selected. Long press to select.');
        return null;
      }
      return words;
    }
  }

  return PopupMenuButton<String>(
    icon: const Icon(Icons.more_vert),
    onSelected: (value) async {
      switch (value) {
        case 'share_all_anki':
        case 'share_selected_anki':
          final words = getWords(value == 'share_all_anki');
          if (words == null || words.isEmpty) return;
          stateChanged();

          final res = await showAnkiCardShareOptions(context);
          if (res == null || res.$1 != true) return;

          VoidCallback? stopSpinner;
          if (context.mounted) {
            stopSpinner = showSpinningDialog(context, 'Sharing...');
          }

          final (filePath, fileBytes) = await makeAnki(words, res.$2);

          stopSpinner?.call();

          if (!context.mounted) return;
          showBackupOptionsButtomSheet(
            context,
            title: 'Import into Anki',
            saveDialogTitle: 'Save anki notes',
            filePaht: filePath,
            fileName: ankiExportFileName,
            fileData: fileBytes,
            allowedExt: ['txt'],
            shareTxt: 'Share with anki',
          );

          break;

        case 'delete_selected':
          final words = getSelectedWords();
          if (words.isEmpty) {
            if (context.mounted) {
              showSnack(context, 'No words Selected. Long press to select.');
            }
            return;
          }

          final count = words.length;

          final confrim = await showConfirmDialog(
            context,
            'Delete $count word${count > 1 ? "s" : ""}',
            message:
                'Are you sure you want to delete selected words?'
                '\nThis action cannot be undone.',
            confirmText: 'Delete Selected',
            destructive: true,
            constraints: true,
          );

          if (confrim != true) return;

          final rmCount = words.length;
          VoidCallback? stopSpinner;
          if (context.mounted) {
            stopSpinner = showSpinningDialog(context, 'Deleting...');
          }
          await removeMuli(words);

          stopSpinner?.call();
          stateChanged();

          if (context.mounted) {
            showSnack(
              context,
              'Deleted $rmCount word${rmCount > 1 ? "s" : ""}',
            );
          }
          break;

        case 'delete_all':
          if (allWords.isEmpty) return;
          final confrim = await showConfirmDialog(
            context,
            'Delete All',
            message: 'Are you sure you want to delete all words?',
            confirmText: 'Delete All',
            destructive: true,
            constraints: true,
          );

          if (confrim != true) return;
          VoidCallback? stopSpinner;
          if (context.mounted) {
            stopSpinner = showSpinningDialog(context, 'Deleting...');
          }

          final rmCount = allWords.length;

          await clearAll();

          stopSpinner?.call();
          stateChanged();

          if (context.mounted) {
            showSnack(
              context,
              'Deleted $rmCount word${rmCount > 1 ? "s" : ""}',
            );
          }
          break;

        case 'export':
        case 'export_selected':
          Iterable<String> words;
          if (value == 'export') {
            if (allWords.isEmpty) {
              showSnack(context, 'No words');
              return;
            }
            words = allWords;
          } else {
            words = getSelectedWords();
            if (words.isEmpty) {
              showSnack(context, 'No words Selected. Long press to select.');
              return;
            }
          }

          stateChanged();

          VoidCallback? stopSpinner;
          if (context.mounted) {
            stopSpinner = showSpinningDialog(context, 'Exporting...');
          }
          try {
            Uint8List fileBytes = utf8.encode(words.join("\n"));
            final tmp = await getTemporaryDirectory();
            final filePath = join(tmp.path, exportFileName);
            File(filePath).writeAsBytes(fileBytes);

            stopSpinner?.call();

            if (!context.mounted) return;
            showBackupOptionsButtomSheet(
              context,
              title: 'Export Ready',
              saveDialogTitle: 'Export',
              filePaht: filePath,
              fileName: exportFileName,
              fileData: fileBytes,
              allowedExt: ['txt'],
            );
          } catch (e) {
            stopSpinner?.call();
            if (kDebugMode) debugPrint('Export err: $e');
            stopSpinner?.call();

            if (context.mounted) {
              showSnack(context, 'Export failed');
            }
          }
          break;

        case 'import':
          final confirmed = await showConfirmDialog(
            context,
            'Import',
            message:
                'If a word in the backup already exists in your list, '
                'it will be skipped.\n\n'
                'Do you want to import?',
            confirmText: 'Select File',
            constraints: true,
          );
          if (confirmed != true) return;

          stateChanged();

          VoidCallback? stopSpinner;
          if (context.mounted) {
            stopSpinner = showSpinningDialog(context, 'Importing...');
          }

          try {
            final result = await FilePicker.pickFile(dialogTitle: 'Import');

            if (result == null) return;

            // final data = await result.readAsByteStream().toList();
            final data = await result.readAsByteStream().fold<List<int>>(
              <int>[],
              (prev, chunk) {
                prev.addAll(chunk);
                return prev;
              },
            );

            // final result = Uint8List.fromList(bytes);

            final content = utf8.decode(data);

            final res = <String>[];
            for (var w in LineSplitter.split(content)) {
              w = ArabicNormalizer.keepOnlyAr(w);
              if (w.isEmpty) continue;
              res.add(w);
            }

            final addedCount = await addMulti(res);

            stateChanged();

            if (context.mounted) {
              showSnack(
                context,
                'Added $addedCount word${addedCount > 1 ? "s" : ""}',
              );
            }
          } catch (e) {
            if (context.mounted) {
              showSnack(context, 'Import failed');
            }
            if (kDebugMode) debugPrint('Import failed: $e');
          } finally {
            stopSpinner?.call();
          }
          break;
      }
    },
    itemBuilder: (context) => [
      const PopupMenuItem(
        value: 'export',
        child: Row(
          children: [
            Icon(Icons.upload_file),
            SizedBox(width: 10),
            Text('Export'),
          ],
        ),
      ),

      const PopupMenuItem(
        value: 'export_selected',
        child: Row(
          children: [
            Icon(Icons.outbox),
            SizedBox(width: 10),
            Text('Export Selected'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'import',
        child: Row(
          children: [
            Icon(Icons.file_download),
            SizedBox(width: 10),
            Text('Import'),
          ],
        ),
      ),

      const PopupMenuDivider(),

      const PopupMenuItem(
        value: 'share_all_anki',
        child: Row(
          children: [
            Icon(Icons.school), // 📚 better for Anki
            SizedBox(width: 10),
            Text('Anki (All)'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'share_selected_anki',
        child: Row(
          children: [
            Icon(Icons.auto_stories), // 📖 distinct from above
            SizedBox(width: 10),
            Text('Anki (Selected)'),
          ],
        ),
      ),

      const PopupMenuDivider(),

      const PopupMenuItem(
        value: 'delete_all',
        child: Row(
          children: [
            Icon(Icons.delete_sweep),
            SizedBox(width: 10),
            Text('Delete All'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'delete_selected',
        child: Row(
          children: [
            Icon(Icons.delete),
            SizedBox(width: 10),
            Text('Delete Selected'),
          ],
        ),
      ),
    ],
  );
}

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
