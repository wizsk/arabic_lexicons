import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart'; // for hashing
import 'package:ara_dict/data.dart';
import 'package:ara_dict/main.dart';
import 'package:ara_dict/theme.dart';
import 'package:ara_dict/wigds.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class BookEntry {
  final String hash;
  final String name;
  BookEntry(this.hash, this.name);
}

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
    _paragraphs = _splitLines(text);
    setState(() {});
    _saveFile();
  }

  List<String> _splitLines(String text) {
    text = text.trim();
    if (text.isEmpty) return [];
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split(RegExp(r'\n+'));
  }

  Directory? _booksDir;
  File? _indexFile;
  List<BookEntry> _books = [];

  @override
  void initState() {
    super.initState();
    _initStorage();
  }

  Future<void> _initStorage() async {
    final dir = await getApplicationDocumentsDirectory();
    _booksDir = Directory(join(dir.path, 'books'));
    if (!await _booksDir!.exists()) await _booksDir!.create();

    _indexFile = File(join(_booksDir!.path, 'books.txt'));
    if (!await _indexFile!.exists()) await _indexFile!.writeAsString('');

    await _loadBooks();
  }

  Future<void> _loadBooks() async {
    if (_indexFile == null) return;

    final lines = await _indexFile!.readAsLines();
    _books = lines
        .map((line) {
          final parts = line.split(':');
          if (parts.length >= 2) {
            final hash = parts[0];
            final name = parts.sublist(1).join(':'); // in case name has colon
            return BookEntry(hash, name);
          }
          return null;
        })
        .whereType<BookEntry>()
        .toList();

    setState(() {});
  }

  String _hashText(String text) {
    final bytes = utf8.encode(text);
    return sha1.convert(bytes).toString(); // short but unique
  }

  Future<void> _saveFile() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final lines = _splitLines(content);
    String displayName = lines.isNotEmpty ? lines.first : 'Untitled';
    if (displayName.length > 100) displayName = displayName.substring(0, 100);

    final hash = _hashText(content); // filename
    final file = File(join(_booksDir!.path, '$hash.txt'));
    try {
      await file.writeAsString(content);
    } catch (_) {
      return;
    }

    // update index file
    final exists = _books.any((b) => b.hash == hash);
    if (!exists) {
      await _indexFile?.writeAsString(
        '$hash:$displayName\n',
        mode: FileMode.append,
      );
    }

    setState(() {
      _books.add(BookEntry(hash, displayName));
    });
  }

  Future<void> _openBook(BookEntry entry) async {
    final file = File(join(_booksDir!.path, '${entry.hash}.txt'));
    if (!await file.exists()) return;

    final content = await file.readAsString();
    setState(() {
      _paragraphs = _splitLines(content);
    });
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

              if (_paragraphs.isEmpty && _books.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _books.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: TextButton(
                          child: Text(_books[index].name),
                          onPressed: () {
                            _openBook(_books[index]);
                          },
                        ),
                      );
                    },
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
