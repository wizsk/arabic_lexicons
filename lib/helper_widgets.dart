import 'dart:io';

import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/main_widgets.dart';
import 'package:arabic_lexicons/pages/settings/settings.dart';
import 'package:arabic_lexicons/reader/reader_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

void showBackupOptionsButtomSheet(
  BuildContext context, {
  required String title,
  required String saveDialogTitle,
  required String fileName,
  IconData fileIcon = Icons.insert_drive_file_rounded,
  required String filePaht,
  required List<int> fileData,
  required List<String> allowedExt,
  Future<void> Function()? afterSave,
  String shareTxt = "Share",
  String saveToDeviceTxt = "Save to device",
  bool useLclass = false,
}) {
  final afterSaveCallback =
      afterSave ??
      () async => await showInfoDialog(
        context,
        "Warning!",
        message:
            "Make sure the file was written properly. "
            "Check the file size to confirm it is not empty.",
        confirmText: 'Okay',
      );

  showModalBottomSheet(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    constraints: BoxConstraints(maxWidth: 600),
    builder: (_) {
      final theme = Theme.of(context);
      final cs = theme.colorScheme;

      Widget tile({
        required IconData icon,
        required String text,
        required VoidCallback onTap,
      }) {
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
              child: Row(
                children: [
                  Icon(icon, color: cs.primary),
                  const SizedBox(width: 16),
                  Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
                  Icon(Icons.chevron_right, color: cs.outline),
                ],
              ),
            ),
          ),
        );
      }

      return SingleChildScrollView(
        padding: scrollPaddingBottmSheet(context),
        child: Column(
          spacing: 12,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Directionality(
              textDirection: useLclass ? L.dir : TextDirection.ltr,
              child: SettingsSectionSurface(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      spacing: 8,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFamily: useLclass ? L.arFontIf : null,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 6,
                          children: [
                            Icon(fileIcon, color: cs.primary),
                            Flexible(
                              child: Text(
                                fileName,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontFamily: useLclass ? L.arFontIf : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Actions group
            tile(
              icon: Icons.save_alt,
              text: saveToDeviceTxt,
              onTap: () async {
                final outputFile = await FilePicker.saveFile(
                  dialogTitle: saveDialogTitle,
                  fileName: fileName,
                  type: FileType.custom,
                  bytes: Uint8List.fromList(fileData),
                  allowedExtensions: allowedExt,
                );

                if (context.mounted) Navigator.pop(context);

                if (context.mounted && outputFile != null) {
                  await afterSaveCallback();
                  if (context.mounted) {
                    showSnack(context, 'Saved to: $outputFile');
                  }
                }
              },
            ),

            if (!Platform.isLinux)
              tile(
                icon: Icons.share,
                text: shareTxt,
                onTap: () async {
                  Navigator.pop(context);
                  await SharePlus.instance.share(
                    ShareParams(files: [XFile(filePaht)], text: 'Export Books'),
                  );
                },
              ),

            tile(
              icon: Icons.close,
              text: "Cancel",
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    },
  );
}
