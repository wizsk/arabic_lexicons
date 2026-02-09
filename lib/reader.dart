import 'package:ara_dict/data.dart';
import 'package:ara_dict/main.dart';
import 'package:ara_dict/theme.dart';
import 'package:ara_dict/wigds.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final TextEditingController _controller = TextEditingController();
  List<String> _paragraphs = [];

  void _showText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _paragraphs = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split(RegExp(r'\n+'));

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    return Scaffold(
      appBar: AppBar(title: const Text('القارئ')),
      drawer: buildDrawer(context),
      body: SafeArea(
        child: Padding(
          padding: scrollPadding.copyWith(top: 16, bottom: 0),
          child: Column(
            textDirection: TextDirection.rtl,
            children: [
              if (_paragraphs.isEmpty)
                TextField(
                  controller: _controller,
                  maxLines: 8,
                  textDirection: TextDirection.rtl,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'اكتب هنا…',
                    hintTextDirection: TextDirection.rtl,
                    hintStyle: themeModeNotifier.value == ThemeMode.dark
                        ? const TextStyle(color: Colors.grey)
                        : null,
                  ),
                ),

              if (_paragraphs.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 4,
                    children: [
                      IconButton(
                        icon: Icon(Icons.clear),
                        iconSize: mediumFontSize * 2,
                        onPressed: () => setState(() {
                          _controller.clear();
                        }),
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_circle_right),
                        iconSize: mediumFontSize * 2,
                        onPressed: _showText,
                      ),
                    ],
                  ),
                ),

              if (_paragraphs.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    // padding: const EdgeInsets.all(16),
                    itemCount: _paragraphs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: ClickableParagraph(
                          text: _paragraphs[index],
                          textStyle: textStyle,
                          onWordTap: (word) {
                            openDict(context, word);
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClickableParagraph extends StatelessWidget {
  final String text;
  final void Function(String word) onWordTap;
  final TextStyle? textStyle;

  const ClickableParagraph({
    super.key,
    required this.textStyle,
    required this.text,
    required this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      textDirection: TextDirection.rtl,
      text: TextSpan(style: textStyle, children: _buildSpans()),
    );
  }

  List<TextSpan> _buildSpans() {
    final spans = <TextSpan>[];

    for (final word in text.split(RegExp(r'\s+'))) {
      spans.add(
        TextSpan(
          text: '$word ',
          recognizer: TapGestureRecognizer()..onTap = () => onWordTap(word),
        ),
      );
    }
    return spans;
  }
}

void openDict(BuildContext context, String word) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SearchWithSelection(showDrawer: false, initialText: word),
    ),
  );
}
