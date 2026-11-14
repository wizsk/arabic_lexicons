import 'package:arabic_lexicons/data.dart';
import 'package:material_ui/material_ui.dart';

class UiWidth extends StatelessWidget {
  final Widget child;

  const UiWidth({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(constraints: maxBottomSheetWidth, child: child),
    );
  }
}
