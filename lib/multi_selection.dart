import 'package:ara_dict/main_widgets.dart';
import 'package:flutter/material.dart';

class SelectionController<T> {
  final selected = <T>{};

  final VoidCallback afterChange;

  SelectionController(this.afterChange);

  bool isSelected(T item) => selected.contains(item);

  void toggle(T item) {
    if (!selected.remove(item)) {
      selected.add(item);
    }
    afterChange();
  }

  void toggleAll(Iterable<T> items) {
    selected.addAll(items);
    afterChange();
  }

  void clear({final bool runAfterChange = true}) {
    selected.clear();
    if (runAfterChange) afterChange();
  }

  bool get hasSelection => selected.isNotEmpty;
  int get count => selected.length;

  Widget appBarTitle(String def, {TextStyle? style}) {
    if (hasSelection) return Text('Selected $count');

    return Text(def, style: style);
  }

  List<Widget> genricAppBarActions(
    BuildContext context, {
    required Iterable<T> Function() all,
    required Future<void> Function(Iterable<T>)? rm,
    String? confirmMsg,
  }) {
    return [
      IconButton(
        icon: Icon(Icons.select_all),
        onPressed: () => toggleAll(all()),
      ),

      IconButton(icon: Icon(Icons.clear_all), onPressed: clear),

      if (rm != null)
        IconButton(
          icon: Icon(Icons.delete_sweep),
          onPressed: () async {
            final res = await showConfirmDialog(
              context,
              confirmMsg ?? 'Delete $count words?',
            );
            if (res != true) return;

            await rm.call(selected);
            clear();
          },
        ),
    ];
  }
}
