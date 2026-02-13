import 'package:ara_dict/conf.dart';
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
