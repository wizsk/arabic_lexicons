import 'package:arabic_lexicons/data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ScrollButtons extends StatefulWidget {
  const ScrollButtons({
    super.key,
    required this.controller,
    this.pageFraction = 0.65,
  });

  final ScrollController controller;
  final double pageFraction;

  @override
  State<ScrollButtons> createState() => _ScrollButtonsState();
}

class _ScrollButtonsState extends State<ScrollButtons> {
  bool __visible = true;

  bool get _visible => appConf.hideAppbar ? __visible : true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final direction = widget.controller.position.userScrollDirection;

    final shouldShow = direction != ScrollDirection.reverse;

    if (shouldShow != __visible) {
      setState(() => __visible = shouldShow);
    }
  }

  Future<void> _page(bool down) async {
    final pos = widget.controller.position;
    final delta = pos.viewportDimension * widget.pageFraction;

    await widget.controller.animateTo(
      (pos.pixels + (down ? delta : -delta)).clamp(0.0, pos.maxScrollExtent),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            scale: _visible ? 1 : 0.75,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: _visible ? 1 : 0,
              child: IgnorePointer(
                ignoring: !_visible,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: .95),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: scheme.outlineVariant),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 18,
                        spreadRadius: -4,
                        offset: Offset(0, 6),
                        color: Colors.black26,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ScrollButton(
                          icon: Icons.keyboard_arrow_up_rounded,
                          onPressed: () => _page(false),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 1,
                          height: 28,
                          color: scheme.outlineVariant,
                        ),
                        const SizedBox(width: 6),
                        _ScrollButton(
                          icon: Icons.keyboard_arrow_down_rounded,
                          onPressed: () => _page(true),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScrollButton extends StatelessWidget {
  const _ScrollButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onPressed,
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: scheme.onPrimaryContainer),
        ),
      ),
    );
  }
}
