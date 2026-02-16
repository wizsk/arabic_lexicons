import 'dart:async';

import 'package:ara_dict/book_marks.dart';
import 'package:ara_dict/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<({DictEntry de, String? word})?> showWordPickerBottomSheet(
  BuildContext context,
  List<DictEntry> dicts,
  DictEntry selectedDict,
  List<String> words,
  String? selectedWord,
  TextStyle ts,
) {
  final cs = Theme.of(context).colorScheme;
  return showModalBottomSheet<({DictEntry de, String? word})?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: cs.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final sh = MediaQuery.of(context).size.height;
          final maxHeight = sh * 0.8;
          final minHeight = sh * 0.35;

          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: maxHeight,
                minHeight: minHeight,
                minWidth: double.infinity,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  textDirection: TextDirection.rtl,
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    // drag handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade500,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Text('${words.length}'),
                    const SizedBox(height: 12),

                    // Scroll
                    Flexible(
                      child: SingleChildScrollView(
                        child: Wrap(
                          textDirection: TextDirection.rtl,
                          spacing: 8,
                          runSpacing: 8,
                          children: words.map((word) {
                            final s = selectedWord == word;
                            final bm = BookMarks.isSet(word);
                            return InkWell(
                              onLongPress: () {
                                if (bm) {
                                  BookMarks.rm(word);
                                } else {
                                  BookMarks.add(word);
                                }
                                setState(() {});
                              },
                              child: ChoiceChip(
                                showCheckmark: false,
                                avatar: bm
                                    ? Icon(
                                        Icons.bookmark,
                                        color: s
                                            ? cs.onPrimary
                                            : cs.onSurfaceVariant,
                                      )
                                    : null,
                                label: Text(word),
                                selected: s,

                                labelStyle: ts.copyWith(
                                  color: s ? cs.onPrimary : cs.onSurface,
                                ),
                                selectedColor: cs.primary,
                                onSelected: (value) {
                                  Navigator.pop(context, (
                                    de: selectedDict,
                                    word: word,
                                  ));
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    if (words.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 8,
                        ),
                        child: Divider(),
                      ),

                    Wrap(
                      textDirection: TextDirection.rtl,
                      spacing: 8,
                      runSpacing: 8,
                      children: dicts.map((dict) {
                        final s = selectedDict.d == dict.d;
                        return ChoiceChip(
                          showCheckmark: false,
                          label: Text(dict.ar),
                          selected: s,
                          labelStyle: ts.copyWith(
                            color: s ? cs.onPrimary : cs.onSurface,
                          ),
                          selectedColor: cs.primary,
                          onSelected: (value) {
                            Navigator.pop(context, (
                              de: dict,
                              word: selectedWord,
                            ));
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<ReaderPageSettings?> showReaderModeSettings(
  BuildContext context,
  ReaderPageSettings rs,
  List<List<WordEntry>> peras,
  void Function() closeReader,
) {
  final cs = Theme.of(context).colorScheme;

  return showModalBottomSheet<ReaderPageSettings?>(
    context: context,
    // isScrollControlled: true,
    backgroundColor: cs.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      bool isCopiedMsgShowing = false;
      bool isCoping = false;

      void close() {
        Navigator.of(sheetContext).pop((rs));
      }

      return StatefulBuilder(
        builder: (context, setState) {
          final sh = MediaQuery.of(context).size.height;

          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: sh * 0.8,
                // minHeight: sh * 0.2,
              ),
              // child: ListView(
              child: Padding(
                padding: const EdgeInsets.all(8),
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

                    Expanded(
                      child: ListView(
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
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: () {
                            close();
                            closeReader();
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.error, // alert color
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onError, // text/icon color
                          ),
                          child: const Text('Exit Reader'),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: close,
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
