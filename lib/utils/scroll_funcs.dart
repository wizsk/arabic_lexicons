import 'package:flutter/material.dart';

void scrollToBottomSmooth(ScrollController sc) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!sc.hasClients) return;
    // silent correction jump, no animation, user doesn't see this
    sc.jumpTo(sc.position.maxScrollExtent);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!sc.hasClients) return;
      // now extent is stable, animate the final bit smoothly
      sc.animateTo(
        sc.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  });
}
