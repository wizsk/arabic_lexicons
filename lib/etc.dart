import 'package:ara_dict/data.dart';
import 'package:flutter/material.dart';

Future<({DictEntry de, String? word})?> showWordPickerBottomSheet(
  BuildContext context,
  List<DictEntry> dicts,
  DictEntry selectedDict,
  List<String> words,
  String? selectedWord,
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
      final sh = MediaQuery.of(context).size.height;
      final maxHeight = sh * 0.8;
      final minHeight = sh * 0.35;

      final chipTextStyle = Theme.of(context).textTheme.bodyMedium!;

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

                            labelStyle: chipTextStyle.copyWith(
                              color: s ? cs.onPrimary : cs.onSurface,
                            ),
                            selectedColor: cs.primary,
                            onSelected: (value) {
                              Navigator.pop(context, (
                                de: selectedDict,
                                word: word,
                              ));
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                if (words.length > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 8,
                    ),
                    child: Divider(thickness: 0.5),
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
                      labelStyle: chipTextStyle.copyWith(
                        color: s ? cs.onPrimary : cs.onSurface,
                      ),
                      selectedColor: cs.primary,
                      onSelected: (value) {
                        Navigator.pop(context, (de: dict, word: selectedWord));
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
}

Future<({bool isQadiah, TextAlign textAlign})?> _showReaderModeSettings(
  BuildContext context,
  bool isQasidah,
  TextAlign textAlign,
) {
  final cs = Theme.of(context).colorScheme;

  return showModalBottomSheet<({bool isQadiah, TextAlign textAlign})?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: cs.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      final sh = MediaQuery.of(context).size.height;
      final maxHeight = sh * 0.8;
      final minHeight = sh * 0.35;

      final chipTextStyle = Theme.of(context).textTheme.bodyMedium!;

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
              // mainAxisSize: MainAxisSize.,
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

                Row(
                  children: [
                    Text("Text Align:"),
                    ChoiceChip(
                      showCheckmark: false,
                      label: Text("Right"),
                      selected: TextAlign.right == textAlign,
                      labelStyle: chipTextStyle.copyWith(
                        color: TextAlign.right == textAlign
                            ? cs.onPrimary
                            : cs.onSurface,
                      ),
                      selectedColor: cs.primary,
                      onSelected: isQasidah
                          ? null
                          : (val) {
                              textAlign = TextAlign.right;
                            },
                    ),
                    ChoiceChip(
                      showCheckmark: false,
                      label: Text("Justify"),
                      selected: TextAlign.justify == textAlign,
                      labelStyle: chipTextStyle.copyWith(
                        color: TextAlign.justify == textAlign
                            ? cs.onPrimary
                            : cs.onSurface,
                      ),
                      selectedColor: cs.primary,
                      onSelected: isQasidah
                          ? null
                          : (val) {
                              textAlign = TextAlign.justify;
                            },
                    ),
                  ],
                ),

                SwitchListTile(
                  title: const Text('Dark mode'),
                  secondary: Icon(
                    isQasidah ? Icons.dark_mode : Icons.light_mode,
                  ),
                  value: isQasidah,
                  onChanged: (value) {
                    isQasidah = value;
                    // Navigator.pop(context);
                    // themeModeNotifier.save(
                    //   value ? ThemeMode.dark : ThemeMode.light,
                    // );
                  },
                ),

                TextButton(
                  child: Text("Done"),
                  onPressed: () {
                    Navigator.pop(context, (
                      isQasidah: isQasidah,
                      textAlign: textAlign,
                    ));
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<({bool isQasidah, TextAlign textAlign})?> showReaderModeSettings(
  BuildContext context,
  bool initialIsQasidah,
  TextAlign initialTextAlign,
  void Function() closeReader,
) {
  final cs = Theme.of(context).colorScheme;

  return showModalBottomSheet<({bool isQasidah, TextAlign textAlign})>(
    context: context,
    // isScrollControlled: true,
    backgroundColor: cs.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      bool isQasidah = initialIsQasidah;
      TextAlign textAlign = initialTextAlign;
      bool isClosing = false; // 🔒 prevents double pop

      void close() {
        if (isClosing) return;
        isClosing = true;

        Navigator.of(
          sheetContext,
        ).pop((isQasidah: isQasidah, textAlign: textAlign));
      }

      return PopScope(
        canPop: false, // 👈 critical
        onPopInvokedWithResult: (_, _) => close(),
        child: StatefulBuilder(
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
                  padding: const EdgeInsets.all(16),
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

                      SwitchListTile(
                        title: const Text('Qasidah mode'),
                        secondary: Icon(Icons.notes),
                        value: isQasidah,
                        onChanged: (v) {
                          setState(() {
                            isQasidah = v;
                            // optional safety:
                            // force right-align in Qasidah mode
                            // if (isQasidah) {
                            //   textAlign = TextAlign.right;
                            // }
                          });
                        },
                      ),

                      const Divider(),

                      SwitchListTile(
                        title: const Text('Right-aligned text'),
                        secondary: Icon(Icons.format_align_right),
                        value: textAlign == TextAlign.right,
                        onChanged: isQasidah
                            ? null
                            : (v) {
                                setState(() {
                                  textAlign = v
                                      ? TextAlign.right
                                      : TextAlign.justify;
                                });
                              },
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
                              textStyle: Theme.of(context).textTheme.bodyMedium,
                            ),
                            child: const Text('Exit Reader'),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: close,
                              style: FilledButton.styleFrom(
                                textStyle: Theme.of(
                                  context,
                                ).textTheme.bodyMedium,
                              ),
                              child: const Text('Done'),
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
        ),
      );
    },
  );
}
