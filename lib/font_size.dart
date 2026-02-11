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
                    height: MediaQuery.of(context).size.height * 0.18,
                    child: Center(
                      child: Text(
                        /* txt */ "هذا مثال لتجربة حجم الخط\nهذا هو السطر التالي",
                        textAlign: TextAlign.right,
                        style: arabicFontStyle.copyWith(fontSize: tempSize),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _sizeButton(
                        context,
                        icon: Icons.restore,
                        onTap: tempSize == defaultArabicFontSize
                            ? null
                            : () {
                                setState(() {
                                  tempSize = defaultArabicFontSize;
                                });
                              },
                      ),
                      const SizedBox(width: 20),
                      _sizeButton(
                        context,
                        icon: Icons.remove,
                        onTap: tempSize <= 10
                            ? null
                            : () {
                                setState(() => tempSize -= 1);
                              },
                      ),
                      const SizedBox(width: 20),
                      _sizeButton(
                        context,
                        icon: Icons.add,
                        onTap: tempSize >= 30
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

// Widget _sizeButton(
//   BuildContext context, {
//   required IconData icon,
//   required VoidCallback? onTap,
// }) {

//   return InkWell(
//     borderRadius: BorderRadius.circular(50),
//     onTap: onTap,
//     child: Container(
//       padding: const EdgeInsets.all(10),
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: Theme.of(context).colorScheme.primary.withAlpha(10),
//       ),
//       child: Icon(icon, color: Theme.of(context).colorScheme.primary),
//     ),
//   );
// }

Widget _sizeButton(
  BuildContext context, {
  required IconData icon,
  VoidCallback? onTap,
}) {
  final cs = Theme.of(context).colorScheme;
  final isEnabled = onTap != null;

  return InkWell(
    borderRadius: BorderRadius.circular(50),
    onTap: onTap, // null disables tap automatically
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isEnabled
            ? cs.primary.withAlpha(25)
            : cs.onSurface.withAlpha(10),
      ),
      child: Icon(
        icon,
        color: isEnabled ? cs.primary : cs.onSurface.withAlpha(40),
      ),
    ),
  );
}
