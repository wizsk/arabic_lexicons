import 'package:arabic_lexicons/data.dart';
import 'package:flutter/material.dart';

Future<bool?> showLexWordDelConfirm(BuildContext context, String word) async {
  bool dontShow = false;
  return showDialog<bool?>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            scrollable: true,
            constraints: BoxConstraints(maxWidth: 600),
            title: Text('Remove word: $word'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => setState(() => dontShow = !dontShow),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    // .copyWith(left: 8),
                    child: Row(
                      // crossAxisAlignment: CrossAxisAlignment.start,
                      // mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: Checkbox(
                            value: dontShow,
                            onChanged: (val) {
                              setState(() => dontShow = val ?? false);
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(child: Text("Don't show this again")),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  appConf.saveLexWordDelConfirm(!dontShow);
                  Navigator.of(ctx).pop(true);
                },
                child: const Text('Remove'),
              ),
            ],
          );
        },
      );
    },
  );
}
