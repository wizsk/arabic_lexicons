import 'package:arabic_lexicons/review/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DaysDialog extends StatefulWidget {
  final int initial;
  final bool showShowAfter10m;
  const DaysDialog({
    super.key,
    required this.initial,
    required this.showShowAfter10m,
  });

  static Future<int?> show(
    BuildContext context, {
    int initial = 0,
    bool showShowAfter10m = false,
  }) {
    return showDialog<int>(
      context: context,
      builder: (_) =>
          DaysDialog(initial: initial, showShowAfter10m: showShowAfter10m),
    );
  }

  @override
  State<DaysDialog> createState() => _DaysDialogState();
}

class _DaysDialogState extends State<DaysDialog> {
  late final _ctrl = TextEditingController(
    text: widget.initial > 0 ? '${widget.initial}' : '',
  );

  bool _showAfter10m = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_showAfter10m) {
      Navigator.pop(context, -1);
      return;
    }

    final d = int.tryParse(_ctrl.text.trim());
    if (d == null || d < 0) return;
    Navigator.pop(context, d);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      constraints: const BoxConstraints(maxWidth: 300),
      title: const Text('Show after (days)'),
      // contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          TextField(
            enabled: !_showAfter10m,
            controller: _ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              suffixText: 'days',
              hintText: 'after',
            ),
            onSubmitted: (_) => _submit(),
          ),

          if (widget.showShowAfter10m)
            InkWell(
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Checkbox.adaptive(
                      value: _showAfter10m,
                      onChanged: (v) {
                        final val = v ?? false;
                        setState(() {
                          _showAfter10m = val;
                        });
                      },
                    ),
                    Text('Repeat after ${repeatDurMin}m'),
                  ],
                ),
              ),
              onTap: () {
                setState(() {
                  _showAfter10m = !_showAfter10m;
                });
              },
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
