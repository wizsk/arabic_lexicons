import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/datas/word_store.dart';
import 'package:arabic_lexicons/main_widgets.dart';
import 'package:arabic_lexicons/multi_selection.dart';
import 'package:arabic_lexicons/reader/find_word.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:flutter/material.dart';

class SelectableWordListTitle extends StatelessWidget {
  final Function(VoidCallback) setState;
  final String word;
  final String wordMatch;
  final SelectionController<String> selection;
  final EdgeInsetsGeometry contentPadding;
  final Widget? subtitle;
  final Future<void> Function()? remove;
  final Dict? dict;
  final int index;
  final int length;
  final bool onBmPage;

  const SelectableWordListTitle({
    super.key,
    required this.word,
    required this.selection,
    required this.setState,
    required this.index,
    required this.length,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 6,
    ),
    this.subtitle,
    required this.remove,
    this.dict,
    this.wordMatch = '',
    this.onBmPage = false,
  });

  static Future<bool?> _confirmDelete(BuildContext context, String word) {
    return showConfirmDialog(
      context,
      'Delete: $word',
      message: 'Do you really want to delete $word?',
      destructive: true,
      confirmText: 'Delete',
      fontFam: L.arFont,
    );
  }

  static Future<bool?> _confirmRmBm(BuildContext context, String word) {
    return showConfirmDialog(
      context,
      'Remove Bookmark: $word',
      message: 'Do you really want to remove $word?',
      destructive: true,
      confirmText: 'Remove',
      fontFam: L.arFont,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = selection.isSelected(word);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bm = WordStore.isBm(word);
    final selecting = selection.hasSelection;

    Widget title;
    if (wordMatch.isEmpty) {
      title = Text(
        word,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: L.arStyle,
      );
    } else {
      final (:pre, :suf) = word.splitOnce(wordMatch);
      title = Text.rich(
        TextSpan(
          children: [
            if (pre != null) TextSpan(text: pre),
            TextSpan(
              text: wordMatch,
              style: TextStyle(color: cs.error),
            ),
            if (suf != null) TextSpan(text: suf),
          ],
        ),
        maxLines: 1,

        overflow: TextOverflow.ellipsis,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,

        style: L.arStyle,
      );
    }

    final child = ListTile(
      selected: selected,
      onLongPress: () {
        selection.toggle(word);
      },
      contentPadding: contentPadding,
      title: title,
      subtitle: subtitle,
      onTap: () {
        if (selecting) {
          selection.toggle(word);
        } else {
          showOpendictOrFindword(
            context,
            word,
            () {
              openDict(context, word, dict: dict).then((_) => setState(() {}));
            },
            () {
              FindWordReaderPage.open(context, word).then((_) {
                setState(() {});
              });
            },
            L.arStyle,
          );
        }
      },

      leading: IconButton(
        icon: bm
            ? Icon(Icons.bookmark, color: cs.error)
            : const Icon(Icons.bookmark_outline),
        onPressed: selecting
            ? null
            : () async {
                if (bm) {
                  final confirm = await _confirmRmBm(context, word);
                  if (confirm != true) return;
                  await WordStore.rmBM(word);
                } else {
                  await WordStore.addBM(word);
                }
                if (context.mounted) setState(() {});
              },
      ),
      trailing: selection.hasSelection
          ? Checkbox(value: selected, onChanged: (_) => selection.toggle(word))
          : remove != null
          ? IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: L.p('Delete', 'حذف'),
              onPressed: () async {
                final confirm = await _confirmDelete(context, word);
                if (confirm != true) return;

                await remove?.call();
                if (context.mounted) setState(() {});
              },
            )
          : null,
    );

    final dissmiss = selecting
        ? child
        : Dismissible(
            key: ValueKey(word),
            direction: remove == null
                ? DismissDirection.startToEnd
                : DismissDirection.horizontal,
            background: Container(
              color: bm ? cs.errorContainer : cs.secondaryContainer,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: bm
                  ? Icon(Icons.bookmark_remove, color: cs.onErrorContainer)
                  : Icon(Icons.bookmark_add, color: cs.onSecondaryContainer),
            ),
            secondaryBackground: remove == null
                ? null
                : Container(
                    color: cs.errorContainer,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 24),
                    child: Icon(Icons.delete, color: cs.onErrorContainer),
                  ),
            confirmDismiss: (dir) async {
              if (dir == DismissDirection.startToEnd) {
                if (bm) {
                  final confirm = await _confirmRmBm(context, word);
                  if (confirm != true) return false;

                  await WordStore.rmBM(word);
                  if (onBmPage) return true;
                  if (context.mounted) setState(() {});
                  return false; // keep the row, just toggle
                } else {
                  await WordStore.addBM(word);
                  if (context.mounted) setState(() {});
                  return false;
                }
              }

              if (remove == null) return false;
              final confirm = await _confirmDelete(context, word);
              if (confirm != true) return false;

              await remove!.call();
              return true;
            },
            onDismissed: (_) {
              if (context.mounted) setState(() {});
            },
            child: child,
          );

    final bgColor = selected ? cs.secondaryContainer : cs.surfaceContainer;
    return segmentedListItem(
      bg: bgColor,
      index: index,
      length: length,
      item: dissmiss,
    );
  }
}
