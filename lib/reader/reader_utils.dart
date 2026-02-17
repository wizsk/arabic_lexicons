import 'dart:convert';

import 'package:ara_dict/alphabets.dart';
import 'package:ara_dict/data.dart';
import 'package:flutter/material.dart';

const int _maxAppbarTitleLen = 40;

String readerAppbarTitle(List<List<WordEntry>> paras, bool tashkil) {
  String t;
  if (tashkil) {
    t = paras.first.map((w) => w.nTk).join(" ");
  } else {
    t = paras.first.map((w) => w.ar).join(" ");
  }
  return t.length > _maxAppbarTitleLen ? t.substring(0, _maxAppbarTitleLen) : t;
}

List<List<WordEntry>> cleanReaderInputAndPrepare(String text) {
  text = text.trim();
  if (text.isEmpty) return [];

  List<List<WordEntry>> res = [];
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
  // final cs = Theme.of(context).colorScheme;

  return showDialog(
    context: context,
    builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Title
                Text(
                  word,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: ts.fontFamily,
                  ),
                ),

                const SizedBox(height: 24),

                /// Buttons
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
        ),
      );
    },
  );
}
