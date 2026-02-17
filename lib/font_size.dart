import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/theme.dart';
import 'package:flutter/material.dart';

Future<void> showFontSizeDialog(
  BuildContext context,
  AppSettingsController controller,
) async {
  double tempSize = controller.fontSize;
  final arabicFontStyle = controller.getArabicTextStyle(context);

  await showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: StatefulBuilder(
          builder: (context, setState) {
            // final textBoxHeight = ;
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Font Size: ${tempSize.toStringAsFixed(0)}",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.20,
                    child: Center(
                      child: Text(
                        /* txt */ "هذا مثال لتجربة حجم الخط\nهذا هو السطر التالي",
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: arabicFontStyle.copyWith(fontSize: tempSize),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        icon: Icon(Icons.restore),
                        onPressed: tempSize == defaultArabicFontSize
                            ? null
                            : () {
                                setState(() {
                                  tempSize = defaultArabicFontSize;
                                });
                              },
                      ),
                      const SizedBox(width: 20),
                      IconButton.filledTonal(
                        icon: Icon(Icons.remove),
                        onPressed: tempSize <= 10
                            ? null
                            : () {
                                setState(() => tempSize -= 1);
                              },
                      ),
                      const SizedBox(width: 20),
                      IconButton.filledTonal(
                        icon: Icon(Icons.add),
                        onPressed: tempSize >= 30
                            ? null
                            : () {
                                setState(() => tempSize += 1);
                              },
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          await controller.setFontSize(tempSize);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        },
                        child: const Text("Save"),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

Future<void> showFontSizeBottomSheet(BuildContext context) async {
  double tempSize = appSettingsNotifier.fontSize;
  final arabicFontStyle = appSettingsNotifier.getArabicTextStyle(context);
  final cs = Theme.of(context).colorScheme;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: cs.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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

                  SizedBox(height: 8),
                  Text(
                    "Font Size: ${tempSize.toStringAsFixed(0)}",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.30,
                    child: Center(
                      child: Text(
                        /* TXT */ "هذا مثال لتجربة حجم الخط\nهذا هو السطر التالي",
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: arabicFontStyle.copyWith(fontSize: tempSize),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.restore),
                        onPressed: tempSize == defaultArabicFontSize
                            ? null
                            : () {
                                setState(() {
                                  tempSize = defaultArabicFontSize;
                                });
                              },
                      ),
                      const SizedBox(width: 20),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove),
                        onPressed: tempSize <= 10
                            ? null
                            : () {
                                setState(() => tempSize -= 1);
                              },
                      ),
                      const SizedBox(width: 20),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add),
                        onPressed: tempSize >= 30
                            ? null
                            : () {
                                setState(() => tempSize += 1);
                              },
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

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
                          await appSettingsNotifier.setFontSize(tempSize);
                          if (!context.mounted) return;
                          Navigator.pop(context);
                        },
                        label: const Text("Save"),
                        icon: Icon(Icons.save_outlined),
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
