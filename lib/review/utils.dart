import 'dart:convert';
import 'dart:io';

import 'package:arabic_lexicons/helper_widgets.dart';
import 'package:arabic_lexicons/main_widgets.dart';
import 'package:arabic_lexicons/multi_selection.dart';
import 'package:arabic_lexicons/review/models.dart';
import 'package:arabic_lexicons/review/provider.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:arabic_lexicons/utils/toast_snack.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

Future<void> importRevWords(BuildContext context, ReviewRepo rr) async {
  final pickedFile = await FilePicker.pickFile(
    dialogTitle: 'Import Review Words',
    type: FileType.custom,
    allowedExtensions: ['json'],
  );

  if (pickedFile == null || !context.mounted) return;

  final data = utf8.decode(await pickedFile.readAsBytes());
  final items = RevItem.listFromJsonString(data);

  if (!context.mounted) return;
  final addMetadata = await showConfirmDialog(
    context,
    'Keep Metadata & Override',
    message:
        'Keep metadata such as due dates and last-seen times, and overwrite existing dates? '
        'Otherwise, cards will be added as new, and existing words will be skipped.',
    barrierDismissible: false,
    constraints: true,
    confirmText: 'Keep',
    cancelText: 'Discard',
  );

  if (addMetadata == null) {
    MsgSv.showToast('Cancelled');
    return;
  }

  final lens = await rr.insertRevItems(items, addMetadata);

  final totalAdded = lens.nowLen - lens.preLen;
  final totalSkipped = items.length - totalAdded;
  final msg = addMetadata
      ? 'Total added: ${items.length}'
      : 'Total added: $totalAdded and total skipped: $totalSkipped';
  MsgSv.showSnackbarMsg(msg, duration: const Duration(seconds: 3));
}

Future<void> exportImportRevWords(
  BuildContext context,
  List<RevItem> itsms,
  ReviewRepo rr,
  SelectionController sc,
) async {
  final todo = await showExportImportDialuge(context, sc.hasSelection);
  if (todo == null || !context.mounted) return;

  if (todo == 'import') {
    return importRevWords(context, rr);
  }

  final List<RevItem> toBeExported;
  if (todo == 'export-sel') {
    toBeExported = itsms
        .where((e) => sc.isSelected(e.word))
        .toList(growable: false);
    sc.clear(runAfterChange: false);
  } else {
    toBeExported = itsms;
  }

  await exportRevWords(context, toBeExported);
}

Future<void> exportRevWords(BuildContext context, List<RevItem> items) async {
  final fileNmae =
      'arabic_lexicons_review_words_${formatDateTimeForFileName()}.json';
  final filePath = path.join((await getTemporaryDirectory()).path, fileNmae);

  final fileBytes = utf8.encode(filePath);

  await File(
    filePath,
  ).writeAsString(RevItem.listToJsonString(items), flush: true);

  if (!context.mounted) return;
  await showBackupOptionsButtomSheet(
    context,
    title: 'Export Ready',
    saveDialogTitle: 'Export',
    filePaht: filePath,
    fileName: fileNmae,
    fileData: fileBytes,
    allowedExt: ['json'],
  );

  MsgSv.showSnackbarMsg(
    'Exported ${items.length} words',
    duration: const Duration(seconds: 2),
  );
}

Future<String?> showExportImportDialuge(
  BuildContext context,
  bool hasSelection,
) {
  return showDialog<String>(
    context: context,
    useSafeArea: true,
    builder: (context) {
      return Dialog(
        constraints: BoxConstraints(maxWidth: 300),
        // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Export or Import',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  // fontFamily: ts.fontFamily,
                ),
              ),

              const SizedBox(height: 24),

              Column(
                spacing: 20,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: Icon(Icons.upload),
                      label: Text('Export'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(50, 50),
                      ),
                      onPressed: () {
                        Navigator.pop(context, 'export');
                        // onOpenDict();
                      },
                    ),
                  ),

                  if (hasSelection) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.upload_file),

                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(50, 50),
                        ),
                        label: const Text('Export Selected'),
                        onPressed: () {
                          Navigator.pop(context, 'export-sel');
                        },
                      ),
                    ),

                    const Divider(height: 6),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Import'),

                      style: FilledButton.styleFrom(
                        minimumSize: const Size(50, 50),
                      ),
                      onPressed: () {
                        Navigator.pop(context, 'import');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
