import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/theme.dart';
import 'package:flutter/material.dart';

/// if [fontSize] is provided
/// then size wont be saved in [appConf]
/// but rather it will be returned
Future<double?> showFontSizeBottomSheet(
  BuildContext context, {
  double? fontSize,
  String? fontFam,
}) async {
  final ogSize = fontSize ?? appConf.readerFontSize;
  double tempSize = ogSize;

  const double minSize = 14;
  const double maxSize = 30;

  return await showModalBottomSheet<double?>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 600),
    builder: (context) {
      // final cs = Theme.of(context).colorScheme;
      final arabicFontStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
        fontFamily: fontFam ?? appConf.readerTS(context).fontFamily,
        fontSize: fontSize ?? appConf.readerFontSize,
      );

      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 8,
            ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Font Size: ${tempSize.toStringAsFixed(0)}",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),

                  const SizedBox(height: 24),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.30,
                    ),
                    child: SizedBox(
                      // height: double.infinity,
                      child: Center(
                        child: Text(
                          /* TXT */ "هذا مثال لتجربة حجم الخط\nهذا هو السطر التالي",
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: arabicFontStyle.copyWith(fontSize: tempSize),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Row(
                    spacing: 12,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.text_decrease),
                        onPressed: tempSize <= minSize
                            ? null
                            : () {
                                setState(() {
                                  tempSize--;
                                });
                              },
                      ),

                      IconButton.filledTonal(
                        icon: const Icon(Icons.restore),
                        onPressed: tempSize == defaultReaderArabicFontSize
                            ? null
                            : () {
                                setState(() {
                                  tempSize = defaultReaderArabicFontSize;
                                });
                              },
                      ),

                      IconButton.filledTonal(
                        icon: const Icon(Icons.text_increase),
                        onPressed: tempSize >= maxSize
                            ? null
                            : () {
                                setState(() {
                                  tempSize++;
                                });
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: tempSize,
                    min: minSize,
                    max: maxSize,
                    divisions: (maxSize - minSize).toInt(),
                    label: tempSize.toInt().toString(),
                    onChanged: (double value) {
                      setState(() {
                        tempSize = value;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     TextButton(
                  //       onPressed: () => Navigator.pop(context),
                  //       child: const Text("Cancel"),
                  //     ),
                  //     const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          if (fontSize != null) {
                            Navigator.pop(context, tempSize);
                            return;
                          }

                          await appConf.setReaderFontSize(tempSize);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        },
                        label: ogSize == tempSize
                            ? const Text('Cancel')
                            : const Text('Save'),
                        icon: ogSize == tempSize
                            ? const Icon(Icons.cancel_outlined)
                            : const Icon(Icons.save_outlined),
                        iconAlignment: IconAlignment.end,
                      ),
                    ),
                  ),
                  // ],
                  // ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> showUiFontSizeBottomSheet(BuildContext context) async {
  final ogSize = L.fontSize;
  final defSize = Theme.of(context).textTheme.bodyMedium?.fontSize ?? 16;

  double tempSize = ogSize ?? defSize;

  const double minSize = 10;
  const double maxSize = 30;

  await showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 600),
    builder: (context) {
      // final cs = Theme.of(context).colorScheme;
      const dt = 'كلمات التي تبحث عنها';
      final tc = TextEditingController(text: dt);
      var selectedDict = allDicts.first;

      return StatefulBuilder(
        builder: (context, setState) {
          final arabicFontStyle = TextStyle(
            fontFamily: L.arFont,
            fontSize: tempSize,
          );

          final cs = Theme.of(context).colorScheme;

          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 8,
            ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Font Size: ${tempSize == defSize ? 'System' : tempSize.toStringAsFixed(0)}",
                    // "Arabic UI Font Size",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),

                  const SizedBox(height: 24),
                  Wrap(
                    runSpacing: 6.0,
                    spacing: 6.0,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.center,
                    textDirection: TextDirection.rtl,
                    children: allDicts.take(4).map((d) {
                      final selected = d == selectedDict;
                      return ChoiceChip(
                        tooltip: d.ar,
                        selected: selected,
                        labelStyle: selected
                            ? arabicFontStyle.copyWith(color: cs.onPrimary)
                            : arabicFontStyle,
                        selectedColor: cs.primary,
                        side: BorderSide(
                          color: selected ? cs.primary : cs.outlineVariant,
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        showCheckmark: false,
                        label: Text(
                          d.ar,
                          textDirection: TextDirection.rtl,
                          style: arabicFontStyle,
                        ),
                        onSelected: (_) {
                          setState(() => selectedDict = d);
                        },
                      );
                    }).toList(),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    child: SizedBox(
                      width: 300,
                      child: TextField(
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.start,
                        style: arabicFontStyle,
                        controller: tc,
                        decoration: InputDecoration(
                          hintText: 'اكتب هنا',
                          hintTextDirection: TextDirection.rtl,
                          prefixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                tc.clear();
                              });
                            },
                            icon: Icon(Icons.clear),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    spacing: 12,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.text_decrease),
                        onPressed: tempSize <= minSize
                            ? null
                            : () {
                                setState(() {
                                  tempSize--;
                                });
                              },
                      ),

                      IconButton.filledTonal(
                        icon: const Icon(Icons.restore),
                        onPressed: tempSize == defSize
                            ? null
                            : () {
                                setState(() {
                                  tempSize = defSize;
                                });
                              },
                      ),

                      IconButton.filledTonal(
                        icon: const Icon(Icons.text_increase),
                        onPressed: tempSize >= maxSize
                            ? null
                            : () {
                                setState(() {
                                  tempSize++;
                                });
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: tempSize,
                    min: minSize,
                    max: maxSize,
                    divisions: (maxSize - minSize).toInt(),
                    label: tempSize.toInt().toString(),
                    onChanged: (double value) {
                      setState(() {
                        tempSize = value;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     TextButton(
                  //       onPressed: () => Navigator.pop(context),
                  //       child: const Text("Cancel"),
                  //     ),
                  //     const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          await appConf.setArUiFontSize(
                            tempSize == defSize ? null : tempSize,
                          );

                          if (!context.mounted) return;
                          Navigator.pop(context);
                        },
                        label: ogSize == tempSize
                            ? const Text('Cancel')
                            : const Text('Save'),
                        icon: ogSize == tempSize
                            ? const Icon(Icons.cancel_outlined)
                            : const Icon(Icons.save_outlined),
                        iconAlignment: IconAlignment.end,
                      ),
                    ),
                  ),
                  // ],
                  // ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
