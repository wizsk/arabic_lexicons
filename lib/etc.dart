import 'package:flutter/material.dart';

Future<String?> showWordPickerBottomSheet(
  BuildContext context,
  List<String> words,
  String selected,
) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      final sh = MediaQuery.of(context).size.height;
      final maxHeight = sh * 0.7;
      final minHeight = sh * 0.3;

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

                    const SizedBox(height: 12),

                    // Scroll
                    Flexible(
                      child: SingleChildScrollView(
                        child: Wrap(
                          textDirection: TextDirection.rtl,
                          spacing: 8,
                          runSpacing: 8,
                          children: words.map((word) {
                            final s = selected == word;
                            return ChoiceChip(
                              showCheckmark: false,
                              label: Text(word),
                              selected: s,
                              labelStyle: s
                                  ? const TextStyle(color: Colors.white)
                                  : null,
                              onSelected: (value) {
                                setState(() {
                                  Navigator.pop(context, word);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
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
