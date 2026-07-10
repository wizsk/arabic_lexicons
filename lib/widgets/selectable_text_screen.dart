import 'dart:math';

import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/pages/width_padd.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef SelectableTextScreenFunc = String Function(SelectionBounds);

class SelectionBounds {
  int start;
  int end;

  SelectionBounds(this.start, this.end);

  SelectionBounds copyWith({int? start, int? end}) =>
      SelectionBounds(start ?? this.start, end ?? this.end);

  SelectionBounds copy() => copyWith();

  int get count => end - start;

  bool eq(SelectionBounds other) => start == other.start && end == other.end;
}

class SelectableTextScreen extends StatefulWidget {
  final SelectableTextScreenFunc fullTextFunc;
  final int start;
  // exclusive aka upuntil
  final int? end;
  final int length;

  final TextAlign textAlign;
  final TextDirection dir;
  final TextStyle textStyleBodyMedium;

  const SelectableTextScreen({
    super.key,
    required this.fullTextFunc,
    required this.start,
    this.end,
    required this.length,
    required this.textAlign,
    required this.dir,
    required this.textStyleBodyMedium,
  });

  static Future<void> show(
    BuildContext context, {
    required SelectableTextScreenFunc fullTextFunc,
    required TextAlign textAlign,
    required TextDirection dir,
    required TextStyle textStyleBodyMedium,
    required int length,
    required int start,
    int? end,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectableTextScreen(
          fullTextFunc: fullTextFunc,
          textAlign: textAlign,
          dir: dir,
          textStyleBodyMedium: textStyleBodyMedium,
          length: length,
          start: start,
          end: end,
        ),
      ),
    );
  }

  @override
  State<SelectableTextScreen> createState() => _SelectableTextScreenState();
}

class _SelectableTextScreenState extends State<SelectableTextScreen> {
  late String _txt;

  late final int _length;
  late final SelectionBounds _def;

  /// [_end] is exclusive
  ///
  /// but when we promt user for range we show it as is, cause user sees 1 based index
  late SelectionBounds _curr;

  @override
  void initState() {
    super.initState();

    _length = widget.length;
    _def = SelectionBounds(widget.start, widget.end ?? widget.start + 1);

    _curr = _def.copy();

    _setTxt();
  }

  void _setTxt() {
    _txt = widget.fullTextFunc.call(_curr);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final readerPadd = appConf.readerPadd(context);

    final sidePadd = max(24.0, readerPadd.right);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          L.p('Select Text', /* txt */ 'حدد النص'),
          style: TextStyle(fontFamily: L.arFontIf),
        ),
        actions: [
          IconButton(
            tooltip: 'Copy All',
            icon: const Icon(Icons.copy_all),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _txt));

              if (!context.mounted) return;
              showSnack(context, 'Text copied');
            },
          ),
          if (_length > 1)
            IconButton(
              tooltip: 'Select range',
              icon: Icon(Icons.tune),
              onPressed: () async {
                final result = await _ParaRangeDialouge.show(
                  context,
                  curr: _curr,
                  def: _def,
                  length: _length,
                );

                if (result == null) return;

                if (!context.mounted) return;

                setState(() {
                  _curr = result;
                  _setTxt();
                });
                showSnack(
                  context,
                  result.count == 1
                      ? 'Showing a single para ${result.start + 1}'
                      : 'Showing paras from ${result.start + 1} to ${result.end} '
                            '(total: ${result.count})',
                  duration: const Duration(seconds: 3),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Directionality(
          textDirection: widget.dir,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: ListView(
              padding: EdgeInsetsGeometry.fromLTRB(
                sidePadd,
                12,
                sidePadd,
                readerPadd.bottom,
              ),
              children: [
                SelectionArea(
                  magnifierConfiguration: TextMagnifierConfiguration.disabled,
                  contextMenuBuilder: (context, selectableRegionState) {
                    return AdaptiveTextSelectionToolbar.buttonItems(
                      anchors: selectableRegionState.contextMenuAnchors,
                      buttonItems: selectableRegionState.contextMenuButtonItems,
                    );
                  },
                  child: Text(
                    _txt,
                    textAlign: widget.textAlign,
                    style: widget.textStyleBodyMedium.copyWith(
                      // height: 2.0,
                      leadingDistribution: TextLeadingDistribution.even,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ParaRangeDialouge extends StatefulWidget {
  final SelectionBounds def;
  final SelectionBounds curr;
  final int lenght;
  final String title;

  const _ParaRangeDialouge({
    required this.def,
    required this.curr,
    required this.lenght,
    this.title = 'Show Paras',
  });

  static Future<SelectionBounds?> show(
    BuildContext context, {
    required SelectionBounds def,
    required SelectionBounds curr,
    required int length,
    String title = 'Show Paras',
  }) {
    // assert(currStart <= maxUp);
    // print('min: $minLow \t max: $maxUp \t curr: $currIdx');
    return showDialog<SelectionBounds>(
      context: context,
      builder: (context) {
        return _ParaRangeDialouge(
          curr: curr,
          def: def,
          lenght: length,
          title: title,
        );
      },
    );
  }

  @override
  State<_ParaRangeDialouge> createState() => _ParaRangeDialougeState();
}

class _ParaRangeDialougeState extends State<_ParaRangeDialouge> {
  late SelectionBounds _mod;
  late final String _title;

  @override
  void initState() {
    super.initState();
    _mod = widget.curr.copy();
    _title = widget.title;
  }

  void changeStart(int delta) {
    setState(() {
      _mod.start = (_mod.start + delta).clamp(0, _mod.end);
    });
  }

  void changeEnd(int delta) {
    setState(() {
      _mod.end = (_mod.end + delta).clamp(_mod.start, widget.lenght);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // icon: const Icon(Icons.linear_scale),
      title: Text(
        '$_title ${_mod.count.toString().padLeft(2, " ")}',
        textAlign: TextAlign.center,
      ),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              _ValueEditor(
                label: 'Start',
                value: _mod.start + 1,
                onDecrease: _mod.start <= 0 ? null : () => changeStart(-1),
                onIncrease: _mod.start + 1 >= _mod.end
                    ? null
                    : () => changeStart(1),
              ),
              const Icon(Icons.arrow_right_alt_outlined, size: 28),
              _ValueEditor(
                label: 'End',
                value: _mod.end,
                dash: _mod.start + 1 == _mod.end,
                onDecrease: _mod.end <= _mod.start + 1
                    ? null
                    : () => changeEnd(-1),
                onIncrease: _mod.end > widget.lenght
                    ? null
                    : () => changeEnd(1),
              ),
            ],
          ),

          const SizedBox(height: 20),
          OutlinedButton.icon(
            label: Text('Reset'),
            icon: Icon(Icons.restore),
            onPressed: widget.def.eq(_mod)
                ? null
                : () {
                    setState(() {
                      _mod = widget.def.copy();
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
        FilledButton(
          onPressed: () {
            Navigator.pop(context, _mod);
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _ValueEditor extends StatelessWidget {
  final String label;
  final int value;
  final bool dash;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  const _ValueEditor({
    required this.label,
    required this.value,
    this.dash = false,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 18,
      children: [
        // Text(label, style: Theme.of(context).textTheme.titleMedium),
        IconButton.outlined(
          visualDensity: VisualDensity.compact,
          onPressed: onDecrease,
          icon: const Icon(Icons.remove),
        ),

        Text(
          dash ? '-' : '$value',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),

        IconButton.outlined(
          visualDensity: VisualDensity.compact,
          onPressed: onIncrease,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
