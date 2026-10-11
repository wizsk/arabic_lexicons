import 'package:arabic_lexicons/pages/settings/theme_color_font.dart';
import 'package:arabic_lexicons/reader/reader_widgets.dart';
import 'package:arabic_lexicons/theme.dart';
import 'package:flutter/material.dart';

class ExpandableText extends StatefulWidget {
  const ExpandableText(
    this.text,
    this.expandedText, {
    super.key,
    this.maxLines = 2,
    this.style,
    this.textAlign,
    this.textDirection,
    this.expanded = false,
    this.onExpandedChanged,
    this.actions = const [],
    this.expandIcon = Icons.expand_more,
    this.collapseIcon = Icons.expand_less,
    this.expandTooltip,
    this.collapseTooltip,
    this.animationDuration = const Duration(milliseconds: 200),
    this.bg,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  }) : assert(maxLines > 0);

  final String text;
  final String expandedText;
  final int maxLines;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final bool expanded;
  final ValueChanged<bool>? onExpandedChanged;

  /// Widgets shown after the expand/collapse button, in the same row.
  final List<Widget> actions;

  final IconData expandIcon;
  final IconData collapseIcon;
  final String? expandTooltip;
  final String? collapseTooltip;
  final Duration animationDuration;

  final Color? bg;
  final BorderRadius borderRadius;
  final EdgeInsets padding;

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  late bool _expanded = widget.expanded;

  @override
  void didUpdateWidget(ExpandableText oldWidget) {
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
    final textAlign = widget.textAlign ?? defaultStyle.textAlign;
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

        final showToggle = overflows;
        final showRow = showToggle || widget.actions.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: widget.animationDuration,
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: double.infinity,
                child: _expanded
                    ? SelectableText(
                        text,
                        style: style,
                        textAlign: textAlign,
                        textDirection: textDirection,
                      )
                    : Text(
                        text,
                        style: style,
                        textAlign: textAlign,
                        textDirection: textDirection,
                        maxLines: widget.maxLines,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ),
            if (showRow)
              Row(
                children: [
                  if (showToggle)
                    iconButtonSized(
                      context,
                      onPressed: _toggle,
                      tooltip: _expanded
                          ? widget.collapseTooltip
                          : widget.expandTooltip,
                      icon: _expanded ? widget.collapseIcon : widget.expandIcon,
                    ),
                  ...widget.actions,
                ],
              ),
          ],
        );
      },
    );

    final bg = widget.bg ?? Color.fromARGB(223, 255, 250, 220);

    child = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        color: bg,
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
      child: Padding(padding: widget.padding, child: child),
    );

    return _expanded
        ? child
        : InkWell(
            borderRadius: widget.borderRadius,
            onTap: _toggle,
            child: child,
          );
  }
}

enum IconButtonSizedColor { normal, err, primary }

Widget iconButtonSized(
  BuildContext context, {
  required IconData icon,
  String? tooltip,
  required VoidCallback onPressed,
  final IconButtonSizedColor scheme = IconButtonSizedColor.normal,
  final double size = 40.00,
  final double iconSize = 20.00,
}) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;

  final (color, fg) = switch (scheme) {
    IconButtonSizedColor.normal => (null, cs.onSurfaceVariant),
    IconButtonSizedColor.primary => (cs.onPrimary, cs.primary),
    IconButtonSizedColor.err => (cs.onError, cs.error),
  };

  return IconButton(
    onPressed: onPressed,
    tooltip: tooltip,
    icon: Icon(icon, size: iconSize),
    color: color,
    style: IconButton.styleFrom(
      foregroundColor: fg,
      minimumSize: Size(size, size),
      maximumSize: Size(size, size),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    visualDensity: VisualDensity.compact,
  );
}
