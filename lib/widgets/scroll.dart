import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

void scrollReaderUpmost(
  AutoScrollController sc, {
  bool scrollup = false,
  int index = -1,
}) {
  if (scrollup) {
    sc.animateTo(
      0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
    return;
  }

  if (index < 0) return;

  sc.scrollToIndex(index, preferPosition: AutoScrollPosition.end);
}

void scrollReader(AutoScrollController sc, {bool scrollup = false}) {
  double pageScrollFraction = appConf.readerScrollPersent / 100.00;

  final pos = sc.position;
  final delta = pos.viewportDimension * pageScrollFraction;
  final dy = scrollup ? pos.pixels - delta : pos.pixels + delta;

  sc.animateTo(
    dy.clamp(0.0, pos.maxScrollExtent),
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
  );
}

List<Widget> scrollUpDownBtns(AutoScrollController sc, int lastItemIndex) {
  return [
    IconButton(
      tooltip: 'Page up or long press to go to top',
      icon: const Icon(Icons.keyboard_arrow_up),
      onPressed: () => scrollReader(sc, scrollup: true),
      onLongPress: () => scrollReaderUpmost(sc, scrollup: true),
    ),
    IconButton(
      tooltip: 'Page down or long press to go to bottom',
      icon: const Icon(Icons.keyboard_arrow_down),
      onPressed: () => scrollReader(sc),
      onLongPress: () => scrollReaderUpmost(sc, index: lastItemIndex),
    ),
  ];
}

class ReaderScrollSettingsBottomSheet extends StatefulWidget {
  const ReaderScrollSettingsBottomSheet({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (context) {
        return const ReaderScrollSettingsBottomSheet();
      },
    );
  }

  @override
  State<ReaderScrollSettingsBottomSheet> createState() =>
      _ReaderScrollSettingsBottomSheetState();
}

class _ReaderScrollSettingsBottomSheetState
    extends State<ReaderScrollSettingsBottomSheet> {
  double _value = appConf.readerScrollPersent.toDouble();
  final _def = AppSettingsController.readerScrollPersentDef.toDouble();

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return SingleChildScrollView(
      padding: scrollPaddingBottmSheet(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Scroll: ${_value.round()}%',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Slider(
            min: 40,
            max: 90,
            divisions: 10,
            value: _value,
            label: '${_value.round()}%',
            onChanged: (v) {
              setState(() => _value = v);
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8.0,
            spacing: 8.0,
            children: [
              ...(const [60, 65, 70, 75, 80]).map(
                (v) => OutlinedButton(
                  child: Text('$v%'),
                  onPressed: () {
                    setState(() => _value = v.toDouble());
                  },
                ),
              ),

              IconButton.filledTonal(
                icon: Icon(Icons.restore),
                onPressed: _value != _def
                    ? () => setState(() => _value = _def)
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await appConf.saveReaderScrollPersent(_value.round());
                  if (context.mounted) Navigator.pop(context);
                },

                icon: const Icon(Icons.check),
                label: const Text('Save'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
