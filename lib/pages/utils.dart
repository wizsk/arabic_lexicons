import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/datas/word_store.dart';
import 'package:arabic_lexicons/main_widgets.dart';
import 'package:arabic_lexicons/multi_selection.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:flutter/material.dart';

class SelectableWordListTitle extends StatelessWidget {
  final Function(VoidCallback) setState;
  final String word;
  final SelectionController<String> selection;
  final EdgeInsetsGeometry contentPadding;
  final Widget? subtitle;
  final Future<void> Function()? remove;
  final Dict? dict;

  const SelectableWordListTitle({
    super.key,
    required this.word,
    required this.selection,
    required this.setState,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 6,
    ),
    this.subtitle,
    required this.remove,
    this.dict,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selection.isSelected(word);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bm = WordStore.isBm(word);

    return Material(
      color: selected ? cs.secondaryContainer : cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        selected: selected,
        onLongPress: () {
          selection.toggle(word);
        },
        contentPadding: contentPadding,
        title: Text(
          word,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: L.arStyle,
        ),
        subtitle: subtitle,
        onTap: () {
          if (selection.hasSelection) {
            selection.toggle(word);
          } else {
            openDict(context, word, dict: dict).then((_) => setState(() {}));
          }
        },
        leading: IconButton(
          icon: bm
              ? Icon(Icons.bookmark, color: cs.error)
              : const Icon(Icons.bookmark_outline),
          onPressed: () async {
            if (bm) {
              final confirm = await showConfirmDialog(
                context,
                'Remove Bookmark: $word',
                destructive: true,
                confirmText: 'Remove',
              );
              if (confirm != true) return;
              await WordStore.rmBM(word);
            } else {
              await WordStore.addBM(word);
            }
            if (context.mounted) setState(() {});
          },
        ),
        trailing: selection.hasSelection
            ? Checkbox(
                value: selected,
                onChanged: (_) => selection.toggle(word),
              )
            : remove != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: L.p('Delete', 'حذف'),
                onPressed: () async {
                  final confirm = await showConfirmDialog(
                    context,
                    '${L.p('Delete: ', 'حذف:')} $word',
                    destructive: true,
                    confirmText: L.p('Delete', 'حذف'),
                    dir: L.dir,
                  );
                  if (confirm != true) return;

                  await remove?.call();
                  if (context.mounted) setState(() {});
                },
              )
            : null,
      ),
    );
  }
}
