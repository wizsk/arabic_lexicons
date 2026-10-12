import 'package:arabic_lexicons/theme.dart';
import 'package:arabic_lexicons/utils/toast_snack.dart';
import 'package:arabic_lexicons/widgets/dahsed_divider.dart';
import 'package:arabic_lexicons/widgets/small_icon_btns.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExpandableDefinition extends StatefulWidget {
  const ExpandableDefinition(
    this.text,
    this.expandedText, {
    super.key,
    this.maxLines = 1,
    required this.style,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.expanded = false,
    this.onExpandedChanged,
    this.expandIcon = Icons.expand_more,
    this.collapseIcon = Icons.expand_less,
    this.expandTooltip,
    this.collapseTooltip,
    this.animationDuration = const Duration(milliseconds: 200),
  }) : assert(maxLines > 0);

  final String text;
  final String expandedText;
  final int maxLines;
  final TextStyle style;
  final TextAlign textAlign;
  final TextDirection? textDirection;
  final bool expanded;
  final ValueChanged<bool>? onExpandedChanged;

  final IconData expandIcon;
  final IconData collapseIcon;
  final String? expandTooltip;
  final String? collapseTooltip;
  final Duration animationDuration;

  @override
  State<ExpandableDefinition> createState() => _ExpandableDefinitionState();
}

class _ExpandableDefinitionState extends State<ExpandableDefinition> {
  late bool _expanded = widget.expanded;

  @override
  void didUpdateWidget(ExpandableDefinition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded != widget.expanded) {
      _expanded = widget.expanded;
    }
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    widget.onExpandedChanged?.call(_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context);
    final style = defaultStyle.style.merge(widget.style);
    final textAlign = widget.textAlign;
    final textDirection = widget.textDirection ?? Directionality.of(context);
    final text = _expanded ? widget.expandedText : widget.text;
    final colors = Theme.of(context).colorScheme;

    Widget child = LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: widget.maxLines,
          textDirection: textDirection,
          textScaler: MediaQuery.textScalerOf(context),
          locale: Localizations.maybeLocaleOf(context),
        )..layout(maxWidth: constraints.maxWidth);

        final overflows = painter.didExceedMaxLines;
        painter.dispose();

        final expanded = _expanded;
        final alreadyExpanded =
            !widget.expandedText.contains("\n") && !overflows;

        final textWidget = Text(
          text,
          style: style,
          textAlign: textAlign,
          textDirection: textDirection,
          maxLines: _expanded ? null : widget.maxLines,
          overflow: _expanded ? TextOverflow.clip : TextOverflow.ellipsis,
        );

        final selectableTextWz = SelectionArea(
          magnifierConfiguration: TextMagnifierConfiguration.disabled,
          child: _expanded || alreadyExpanded
              ? textWidget
              : SelectionContainer.disabled(child: textWidget),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: widget.animationDuration,
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: SizedBox(width: double.infinity, child: selectableTextWz),
            ),
            DashedDivider(height: 6),
            Row(
              // mainAxisAlignment: MainAxisAlignment.end,
              // spacing: 2,
              children: [
                iconButtonSized(
                  context,
                  icon: expanded || alreadyExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  scheme: IconButtonSizedColor.primary,
                  tooltip: 'expan/collaspe',
                  onPressed: alreadyExpanded ? null : _toggle,
                  //() {
                  //                           datas.expanded[index] = !datas.expanded[index];
                  //                           datas.rebuild();
                  //
                  //                           if (datas.expanded[index]) return;
                  //                           postFrame((_) {
                  //                             if (!datas.scrollController.hasClients) return;
                  //                             if (datas.scrollController.offset == 0) {
                  //                               datas.appbarReaderBg = true;
                  //                               datas.rebuild();
                  //                             }
                  //                           });
                  // },
                ),
                Spacer(),
                iconButtonSized(
                  context,
                  icon: Icons.copy_rounded,
                  tooltip: 'Copy',
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: widget.expandedText),
                    );
                    MsgSv.showSnackbarMsg("Definiton copied");
                  },
                ),
                iconButtonSized(
                  context,
                  icon: Icons.flag_outlined,
                  tooltip: 'Report an issue',
                  onPressed: () {
                    // TODO: Report this entry.
                    MsgSv.showSnackbarMsg("IMPLIMENT IT!!!");
                  },
                  scheme: IconButtonSizedColor.err,
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
        );
      },
    );

    final rc = ReaderColors.curr(context);
    final borderRadius = BorderRadius.circular(12);

    const sidesPadd = 12.0;
    const padding = EdgeInsets.fromLTRB(sidesPadd, 12, sidesPadd, 0);

    child = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: rc.definitionSurface,
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
            offset: const Offset(-1, -1),
            blurRadius: 2,
          ),
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.12),
            offset: const Offset(2, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    return _expanded
        ? child
        : InkWell(borderRadius: borderRadius, onTap: _toggle, child: child);
  }
}

// Widget _defCard(
//   BuildContext context,
//   int index,
//   SearchLexiconsDatas datas,
//   Widget child, {
//   required String Function() text,
// }) {
//   final expanded = datas.expanded[index];
//   final cs = Theme.of(context).colorScheme;
//   // final colors = cs;
//
//   const sidesPadd = 12.0;
//   final textWidget = Padding(
//     padding: const EdgeInsets.fromLTRB(sidesPadd, 12, sidesPadd, 0),
//     child: Column(
//       mainAxisAlignment: MainAxisAlignment.start,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         child,
//         // if (expanded) ...[
//         DashedDivider(height: 8, color: cs.outlineVariant),
//         // ] else
//         //   const SizedBox(height: 4),
//         Row(
//           // mainAxisAlignment: MainAxisAlignment.end,
//           // spacing: 2,
//           children: [
//             iconButtonSized(
//               context,
//               icon: expanded
//                   ? Icons.keyboard_arrow_up_rounded
//                   : Icons.keyboard_arrow_down_rounded,
//               scheme: IconButtonSizedColor.primary,
//               tooltip: 'expan/collaspe',
//               onPressed: () {
//                 datas.expanded[index] = !datas.expanded[index];
//                 datas.rebuild();
//
//                 if (datas.expanded[index]) return;
//                 postFrame((_) {
//                   if (!datas.scrollController.hasClients) return;
//                   if (datas.scrollController.offset == 0) {
//                     datas.appbarReaderBg = true;
//                     datas.rebuild();
//                   }
//                 });
//               },
//             ),
//             Spacer(),
//             iconButtonSized(
//               context,
//               icon: Icons.copy_rounded,
//               tooltip: 'Copy',
//               onPressed: () async {
//                 await Clipboard.setData(ClipboardData(text: text()));
//                 MsgSv.showToast("Definiton copied");
//               },
//             ),
//             iconButtonSized(
//               context,
//               icon: Icons.flag_outlined,
//               tooltip: 'Report an issue',
//               onPressed: () {
//                 // TODO: Report this entry.
//               },
//               scheme: IconButtonSizedColor.err,
//             ),
//           ],
//         ),
//         const SizedBox(height: 6),
//       ],
//     ),
//   );
//
//   final rc = ReaderColors.curr(context);
//   final borderRadius = BorderRadius.circular(12);
//
//   final selectable = expanded
//       ? SelectionArea(
//           magnifierConfiguration: TextMagnifierConfiguration.disabled,
//           child: textWidget,
//         )
//       : textWidget;
//
//   final decoration = BoxDecoration(
//     color: rc.definitionSurface,
//     borderRadius: borderRadius,
//     border: Border.all(color: rc.outline),
//     boxShadow: [
//       BoxShadow(
//         color: rc.shadow,
//         offset: const Offset(2, 3),
//         blurRadius: 7,
//         spreadRadius: -2,
//       ),
//     ],
//   );
//
//   return expanded
//       ? DecoratedBox(decoration: decoration, child: selectable)
//       : Ink(
//           decoration: decoration,
//           child: InkWell(
//             borderRadius: borderRadius,
//             onTap: () {
//               datas.expanded[index] = !datas.expanded[index];
//               datas.rebuild();
//             },
//             child: selectable,
//           ),
//         );
// }
