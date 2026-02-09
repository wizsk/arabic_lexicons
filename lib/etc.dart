import 'package:ara_dict/data.dart';
import 'package:flutter/material.dart';

Future<({DictEntry de, String? word})?> showWordPickerBottomSheet(
  BuildContext context,
  List<DictEntry> dicts,
  DictEntry selectedDict,
  List<String> words,
  String? selectedWord,
) {
  return showModalBottomSheet<({DictEntry de, String? word})?>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      final sh = MediaQuery.of(context).size.height;
      final maxHeight = sh * 0.8;
      final minHeight = sh * 0.35;

      return StatefulBuilder(
        builder: (context, setState) {
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
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Text('${words.length}'),
                    const SizedBox(height: 12),

                    // Scroll
                    if (words.length > 1)
                      Flexible(
                        child: SingleChildScrollView(
                          child: Wrap(
                            textDirection: TextDirection.rtl,
                            spacing: 8,
                            runSpacing: 8,
                            children: words.map((word) {
                              final s = selectedWord == word;
                              return ChoiceChip(
                                showCheckmark: false,
                                label: Text(word),
                                selected: s,
                                onSelected: (value) {
                                  setState(() {
                                    Navigator.pop(context, (
                                      de: selectedDict,
                                      word: word,
                                    ));
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                    if (words.length > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 1,
                          vertical: 2,
                        ),
                        child: Divider(color: Colors.grey, thickness: 0.5),
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
                          onSelected: (value) {
                            setState(() {
                              Navigator.pop(context, (
                                de: dict,
                                word: selectedWord,
                              ));
                            });
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
