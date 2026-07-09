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
  const double pageScrollFraction = 0.65;

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
