import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arabic_lexicons/alphabets.dart';
import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/pages/settings.dart';
import 'package:arabic_lexicons/reader/data.dart';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';

// const int _maxAppbarTitleLen = 40;
const int readerAppbarMaxWordCount = 10;

extension ReaderTitle on PeraEntries {
  String readerAppbarTitle(bool tashkil) {
    if (isEmpty) return '';

    final para = first;
    if (para.isEmpty) return '';

    String t;
    if (tashkil) {
      t = para.take(readerAppbarMaxWordCount).map((w) => w.nTk).join(" ");
    } else {
      t = para.take(readerAppbarMaxWordCount).map((w) => w.ar).join(" ");
    }
    return para.length > readerAppbarMaxWordCount ? '$t…' : t;
  }
}

// String readerAppbarTitle(PeraEntries paras, bool tashkil) {
//   String t;
//   if (tashkil) {
//     t = paras.first.take(readerAppbarMaxWordCount).map((w) => w.nTk).join(" ");
//   } else {
//     t = paras.first.take(readerAppbarMaxWordCount).map((w) => w.ar).join(" ");
//   }
//   return paras.first.length > readerAppbarMaxWordCount ? '$t…' : t;
// }

class ReaderSelectionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final IconData trailing;
  final FilledIconVariant variant;

  const ReaderSelectionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    this.trailing = Icons.chevron_right,
    this.variant = FilledIconVariant.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: FilledIcon(icon, variant: variant),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(trailing),
      onTap: () => Navigator.pop(context, value),
    );
  }
}

PeraEntries cleanReaderInputAndPrepare(String text) {
  text = text.trim();
  if (text.isEmpty) return [];

  PeraEntries res = [];
  for (var l in LineSplitter.split(text)) {
    l = l.trim();
    if (l.isEmpty) continue;
    List<WordEntry> curr = [];
    for (var w in l.split(RegExp(r'\s'))) {
      curr.add(
        WordEntry(
          ar: w,
          cl: ArabicNormalizer.keepOnlyAr(w),
          nTk: ArabicNormalizer.rmTashkil(w),
        ),
      );
    }
    if (curr.isNotEmpty) res.add(curr);
  }
  return res;
}

Future<void> showWordReadeActionsDialog(
  BuildContext context,
  String word,
  bool isBookmarked,
  VoidCallback onBookmark,
  VoidCallback onShowDefinition,
  TextStyle ts,
) {
  return showDialog(
    context: context,
    useSafeArea: true,
    builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return Dialog(
        constraints: BoxConstraints(maxWidth: 300),
        // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                word,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: ts.fontFamily,
                ),
              ),

              const SizedBox(height: 24),

              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      ),
                      label: Text(
                        isBookmarked ? "Remove Bookmark" : "Add to Bookmark",
                      ),
                      style: isBookmarked
                          ? FilledButton.styleFrom(
                              backgroundColor: cs.error,
                              foregroundColor: cs.onError,
                            )
                          : null,
                      onPressed: () {
                        Navigator.pop(context);
                        onBookmark();
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.menu_book),
                      label: const Text("Show Definition"),
                      onPressed: () {
                        Navigator.pop(context);
                        onShowDefinition();
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

VoidCallback showSpinningDialog(
  BuildContext context,
  String msg, {
  TextDirection? textDir,
}) {
  bool done = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !done) return;
        done = true;

        Navigator.pop(context);
      },
      child: Center(
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Text(msg, textDirection: textDir),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  return () {
    if (done) return;
    done = true;
    Navigator.pop(context);
  };
}

void showSnackL(
  BuildContext context, {
  required String ar,
  required String en,
  Duration duration = const Duration(seconds: 2),
}) => showSnack(
  context,
  L.p(en, ar),
  duration: duration,
  textStyle: L.arStyleIf,
  textDir: L.dir,
);

Timer? _snackMsgTimmer;
VoidCallback? _snackMsgTimmerCallback;

void snackClearForced() {
  _snackMsgTimmer?.cancel();
  _snackMsgTimmerCallback?.call();
  _snackMsgTimmerCallback = null;
}

void showSnack(
  BuildContext context,
  String message, {
  Widget? messageWidget,
  Duration duration = const Duration(seconds: 2),
  TextStyle? textStyle,
  TextDirection? textDir,
  SnackBarAction? action,
  bool? showCloseIcon,
  Duration? forceCloseAfter,
}) {
  // we are clearing the snaksbars anyways
  _snackMsgTimmerCallback = null;
  _snackMsgTimmer?.cancel();

  final messenger = ScaffoldMessenger.of(context);

  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content:
            messageWidget ??
            Text(message, style: textStyle, textDirection: textDir),
        duration: forceCloseAfter != null ? const Duration(days: 1) : duration,
        behavior: SnackBarBehavior.floating,
        action: action,
        showCloseIcon: showCloseIcon,
      ),
    );

  if (forceCloseAfter != null) {
    void clear() {
      messenger.clearSnackBars();
      _snackMsgTimmerCallback = null;
    }

    _snackMsgTimmerCallback = clear;
    _snackMsgTimmer = Timer(forceCloseAfter, clear);
  }
}

Future<(File, List<int>)> zipFiles(
  List<String> names,
  List<String> sourceFiles,
  String outputZipPath,
) async {
  final archive = Archive();

  for (int i = 0; i < sourceFiles.length; i++) {
    final file = File(sourceFiles[i]);

    final bytes = await file.readAsBytes();

    final archiveFile = ArchiveFile(
      names[i], // name inside zip
      bytes.length,
      bytes,
    );

    archive.addFile(archiveFile);
  }

  final zipData = ZipEncoder().encode(archive);

  final zipFile = File(outputZipPath);
  await zipFile.writeAsBytes(zipData);

  return (zipFile, zipData);
}
