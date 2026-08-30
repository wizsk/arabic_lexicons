import 'package:arabic_lexicons/conf.dart';
import 'package:flutter/material.dart';

class Selection extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isAr;
  final VoidCallback onTab;
  final VoidCallback? onDelete;
  final String? tooltip;
  final String deleteButtonTooltipMessage;

  const Selection(
    this.label, {
    super.key,
    required this.selected,
    this.isAr = true,
    required this.onTab,
    this.onDelete,
    this.tooltip,
    this.deleteButtonTooltipMessage = 'Remove',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RawChip(
      tooltip: tooltip,
      label: Text(
        label,
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        style: isAr
            ? L.arStyleSized.copyWith(color: selected ? cs.onPrimary : null)
            : TextStyle(color: selected ? cs.onPrimary : null),
      ),
      selected: selected,
      selectedColor: cs.primary,
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: selected ? cs.primary : cs.outlineVariant),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      deleteIconColor: selected ? cs.onPrimary : null,
      showCheckmark: false,
      onDeleted: onDelete,
      onPressed: onTab,
      deleteButtonTooltipMessage: deleteButtonTooltipMessage,
    );
  }
}
