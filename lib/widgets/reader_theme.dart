import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/theme.dart';
import 'package:flutter/material.dart';

class ReaderThemed extends StatelessWidget {
  final Widget child;
  const ReaderThemed({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildTheme(
        context,
        Theme.of(context).brightness,
        appConf,
        rs: ReaderColors.curr(context),
      ),
      child: child,
    );
  }
}
