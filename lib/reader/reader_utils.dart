import 'dart:async';
import 'dart:convert';

import 'package:ara_dict/alphabets.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/font_size.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

Future<ReaderPageSettings?> showReaderModeSettings(
  BuildContext context,
  ReaderPageSettings rs,
  List<List<WordEntry>> peras,
) {
  final cs = Theme.of(context).colorScheme;

  return showModalBottomSheet<ReaderPageSettings?>(
    context: context,
    backgroundColor: cs.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      bool isCopiedMsgShowing = false;
      bool isCoping = false;

      return StatefulBuilder(
        builder: (context, setState) {
          // final sh = MediaQuery.of(context).size.height;

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min, // 🔥 THIS is the magic
                children: [
                  // drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade500,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Qasidah mode'),
                            secondary: Icon(Icons.notes),
                            value: rs.isQasidah,
                            onChanged: (v) {
                              setState(() {
                                rs.isQasidah = v;
                              });
                            },
                          ),

                          // const Divider(),
                          SwitchListTile(
                            title: const Text('Right-aligned text'),
                            secondary: Icon(Icons.format_align_right),
                            value:
                                rs.textAlign == TextAlign.right || rs.isQasidah,
                            onChanged: rs.isQasidah
                                ? null
                                : (v) {
                                    setState(() {
                                      rs.textAlign = v
                                          ? TextAlign.right
                                          : TextAlign.justify;
                                    });
                                  },
                          ),
                          SwitchListTile(
                            title: const Text('Remove Tashkil'),
                            secondary: Icon(Icons.do_not_disturb),
                            value: rs.isRmTashkil,
                            onChanged: (v) {
                              setState(() {
                                rs.isRmTashkil = v;
                              });
                            },
                          ),
                          SwitchListTile(
                            title: const Text('Open Lexicon Direcly'),
                            secondary: Icon(Icons.directions),
                            value: rs.isOpenLexiconDirecly,
                            onChanged: (v) {
                              setState(() {
                                rs.isOpenLexiconDirecly = v;
                              });
                            },
                          ),
                          ListTile(
                            title: const Text('Change Font Size'),
                            leading: Icon(Icons.text_fields),
                            onTap: () {
                              showFontSizeBottomSheet(context);
                            },
                          ),
                          const Divider(),
                          ListTile(
                            title: isCopiedMsgShowing
                                ? const Text('Text Copied')
                                : const Text('Copy Text'),
                            leading: const Icon(Icons.copy),
                            onTap: () async {
                              if (isCoping) return;
                              isCoping = true;
                              await Clipboard.setData(
                                ClipboardData(
                                  text: peras
                                      .map((p) => p.map((w) => w.ar).join(" "))
                                      .join("\n"),
                                ),
                              );

                              isCopiedMsgShowing = true;
                              setState(() {});
                              Timer(Duration(seconds: 1), () {
                                isCopiedMsgShowing = false;
                                isCoping = false;
                                setState(() {});
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  // const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 12,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop((rs));
                        },
                        label: const Text('Save'),
                        icon: Icon(Icons.save_outlined),
                        iconAlignment: IconAlignment.end,
                      ),
                    ),
                  ),
                  // const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
