import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/lex/lexicons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart' as html_parser;

enum InitState {
  not,
  initing,
  done;

  bool get isInited => this == done;
  bool get isNotInited => this == not;
  bool get isIniting => this == initing;
}

void postFrame(void Function(Duration) callb) {
  WidgetsBinding.instance.addPostFrameCallback(callb);
}

Future<void> openDict(BuildContext context, String word, {Dict? dict}) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          SearchLexicons(isPopup: true, initialText: word, initialDict: dict),
    ),
  );
}

String enToArNum(dynamic n) {
  return n.toString().replaceAllMapped(
    RegExp(r'[0-9]'),
    (m) => String.fromCharCode(0x0660 + int.parse(m.group(0)!)),
  );
}

String formatDateTime(BuildContext context, {DateTime? dt}) {
  dt ??= DateTime.now();
  final local = dt.toLocal();
  final use24h = MediaQuery.of(context).alwaysUse24HourFormat;

  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year;

  if (use24h) {
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$hour:$minute $day/$month/$year';
  } else {
    int hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');

    final isPm = hour >= 12;
    final period = isPm ? 'PM' : 'AM';

    hour = hour % 12;
    if (hour == 0) hour = 12;

    final hourStr = hour.toString().padLeft(2, '0');

    return '$hourStr:$minute $period $day/$month/$year';
  }
}

String formatDateTimeForFileName({DateTime? dt}) {
  dt ??= DateTime.now();
  final local = dt.toLocal();

  final year = local.year.toString();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  final second = local.second.toString().padLeft(2, '0');

  return '$year-$month-${day}_$hour-$minute-$second';
}

/// Capitalize the 1st char only 'fo' -> 'Fo'; '_fo' -> '_fo'
String capitalize(String? s) {
  if (s == null || s.isEmpty) return "";

  if (s.length == 1) s.characters.first.toUpperCase();

  return s.substring(0, 1).toUpperCase() + s.substring(1, s.length);
}

class LruCache<K, V> {
  final int capacity;
  final _map = <K, V>{};

  LruCache(this.capacity);

  V? get(K key) {
    final value = _map.remove(key);
    if (value != null) {
      _map[key] = value; // move to end
    }
    return value;
  }

  void put(K key, V value) {
    if (_map.containsKey(key)) {
      _map.remove(key); // take it to first
    } else if (_map.length >= capacity) {
      _map.remove(_map.keys.first);
    }
    _map[key] = value;
  }
}

String htmlToPlainText(String html) {
  final document = html_parser.parse(html);
  return document.body?.text ?? '';
}

String htmlToPlainTextWithLineBr(String html) {
  // handle block-level tags BEFORE parsing
  html = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<h[1-6][^>]*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<center>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</center>', caseSensitive: false), '\n');

  final document = html_parser.parse(html);

  if (document.body != null) {
    return document.body!.text
        .split("\n")
        .map((l) => l.trim())
        .where((l) => l != "")
        .join("\n");
  }

  return '';
}

@pragma("vm:prefer-inline")
void touggleFullScreen({final bool forceNonFs = false}) {
  if (!forceNonFs && appConf.fullScreen) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  } else if (appConf.hideStatusbar) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.bottom],
    );
  } else {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }
}

List<Widget> separatedList<T>({
  required List<T> items,
  required Widget Function(T item, int index) itemBuilder,
  required Widget Function(int index) separatorBuilder,
}) {
  final result = <Widget>[];

  for (int i = 0; i < items.length; i++) {
    result.add(itemBuilder(items[i], i));

    if (i != items.length - 1) {
      result.add(separatorBuilder(i));
    }
  }

  return result;
}

@pragma("vm:prefer-inline")
bool readerAppBarColorBg(double offset) {
  return offset <= kToolbarHeight;
}

Future<String?> getClipboardText() async {
  final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
  return clipboardData?.text;
}

class GestureStack extends StatelessWidget {
  final Widget child;

  // final bool safeTop;
  // final bool safeBot;
  // final bool safeRight;
  // final bool safeLeft;

  const GestureStack({
    super.key,
    required this.child,
    // this.safeTop = false,
    // this.safeBot = false,
    // this.safeRight = true,
    // this.safeLeft = true,
  });

  // static const _color = Color.fromARGB(53, 255, 78, 78);

  @override
  Widget build(BuildContext context) {
    if (!appConf.fullScreen) {
      // return SafeArea(top: false, child: child);
      // continue being an stack for scrolling consistancy ;0
      return Stack(children: [SafeArea(top: false, child: child)]);
    }

    return Stack(
      children: [
        SafeArea(
          top: false,
          bottom: false,
          right: true,
          left: true,
          child: child,
        ),

        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 14,
          // child: IgnorePointer(child: ColoredBox(color: _color)),
          child: ColoredBox(color: Colors.transparent),
        ),

        // // left
        // const Positioned(
        //   left: 0,
        //   top: 0,
        //   bottom: 0,
        //   width: 6,
        //   child: ColoredBox(color: _color),
        // ),

        // // Right
        // const Positioned(
        //   right: 0,
        //   top: 0,
        //   bottom: 0,
        //   width: 6,
        //   child: ColoredBox(color: _color),
        // ),

        // // top
        // const Positioned(
        //   top: 0,
        //   right: 0,
        //   left: 0,
        //   height: 6,
        //   child: ColoredBox(color: _color),
        // ),
      ],
    );
  }
}

extension StringExtentions on String {
  ({String? pre, String? suf}) splitOnce(String pattern) {
    final idx = indexOf(pattern);
    if (idx == -1) return (pre: null, suf: null);
    final suf = substring(idx + pattern.length);
    return (pre: substring(0, idx), suf: suf.isEmpty ? null : suf);
  }

  String takeMax(final int take, {final ellipsis = '…'}) {
    if (length <= take) return this;

    return '${substring(0, take)}$ellipsis';
  }
}
