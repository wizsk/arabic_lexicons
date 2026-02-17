import 'dart:async';

import 'package:ara_dict/book_marks.dart';
import 'package:ara_dict/data.dart';
import 'package:flutter/material.dart';

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
