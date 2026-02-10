import 'dart:convert';
import 'dart:io';
import 'package:ara_dict/sv.dart';
import 'package:crypto/crypto.dart'; // for hashing
import 'package:ara_dict/main.dart';
import 'package:ara_dict/theme.dart';
import 'package:ara_dict/wigds.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  final ScrollController _scrollController = ScrollController();

  List<String> _paragraphs = [];
  Directory? _booksDir;
  File? _indexFile;
  List<BookEntry> _books = [];

  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    _initStorage();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      // Scrolling down - hide FAB
      if (_isFabVisible) {
        setState(() {
          _isFabVisible = false;
        });
      }
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      // Scrolling up - show FAB
      if (!_isFabVisible) {
        setState(() {
          _isFabVisible = true;
        });
      }
    }
  }

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
    if (lines.isEmpty) return;

    String displayName = lines.first;
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

    _books.add(BookEntry(hash, displayName));
  }

  Future<void> _deleteFile(int index) async {
    if (index < 0 || index >= _books.length) {
      return;
    }
    final be = _books.removeAt(index);
    final file = File(join(_booksDir!.path, '${be.hash}.txt'));
    try {
      await file.delete();
    } catch (e) {
      // AlertDialog()
      return;
    }

    await _saveBookEntriesFile();
    setState(() {});
  }

  Future<void> _saveBookEntriesFile() async {
    if (_indexFile == null) return;
    final txt = _books.map((be) => '${be.hash}:${be.name}').join("\n");
    await _indexFile!.writeAsString(txt, flush: true, mode: FileMode.write);
  }

  Future<void> _openBook(BookEntry entry) async {
    final file = File(join(_booksDir!.path, '${entry.hash}.txt'));
    if (!await file.exists()) return;

    final content = await file.readAsString();
    setState(() {
      _paragraphs = _splitLines(content);
    });
  }

  int _textFiledSize = 2;
  final int _maxTextFiledSize = 14;

  @override
  Widget build(BuildContext context) {
    final textStyleBodyMedium = Theme.of(context).textTheme.bodyMedium;

    return Scaffold(
      appBar: AppBar(title: const Text('القارئ')),
      drawer: buildDrawer(context),
      body: SafeArea(
        child: Column(
          textDirection: TextDirection.rtl,
          children: [
            if (_paragraphs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _controller,
                      maxLines: _textFiledSize,
                      textDirection: TextDirection.rtl,
                      style: textStyleBodyMedium,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'اكتب هنا…',
                        hintTextDirection: TextDirection.rtl,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 4,
                        children: [
                          IconButton(
                            icon: Icon(Icons.expand),
                            iconSize: mediumFontSize * 2,
                            onPressed: () => setState(() {
                              if (_textFiledSize == _maxTextFiledSize) {
                                _textFiledSize = 2;
                              } else {
                                _textFiledSize = _maxTextFiledSize;
                              }
                            }),
                          ),
                          IconButton(
                            iconSize: mediumFontSize * 2,
                            onPressed: () async {
                              final txt = await getClipboardText();
                              if (txt != null) {
                                _controller.clear();
                                _controller.text = txt;
                              }
                            },
                            icon: Icon(Icons.paste),
                          ),
                          IconButton(
                            icon: Icon(Icons.clear),
                            iconSize: mediumFontSize * 2,
                            onPressed: () async {
                              if (_controller.text.isEmpty) return;

                              final res = await showConfirmDialog(
                                context,
                                message: 'Do you want to clear the texts?',
                              );
                              if (res != null && res) _controller.clear();
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.arrow_circle_right),
                            iconSize: mediumFontSize * 2,
                            onPressed: _showText,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            if (_paragraphs.isEmpty && _books.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _books.length,
                  itemBuilder: (context, index) {
                    return Ink(
                      decoration: index.isOdd
                          ? BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withAlpha(30),
                              // borderRadius: BorderRadius.circular(12), // Optional
                            )
                          : null,
                      child: InkWell(
                        onTap: () {
                          _openBook(_books[index]);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  final res = await showConfirmDialog(
                                    context,
                                    message:
                                        'Do you really want to delete: ${_books[index].name}',
                                  );
                                  if (res != null && res == true) {
                                    _deleteFile(index);
                                  }
                                },
                              ),

                              const SizedBox(width: 8),

                              Expanded(
                                child: Text(
                                  _books[index].name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            if (_paragraphs.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ).copyWith(bottom: 128),
                  itemCount: _paragraphs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ClickableParagraph(
                        text: _paragraphs[index],
                        textStyleBodyMedium: textStyleBodyMedium,
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

      floatingActionButton: _paragraphs.isNotEmpty
          ? AnimatedSlide(
              duration: Duration(milliseconds: 300),
              offset: _isFabVisible ? Offset.zero : Offset(0, 2),
              child: AnimatedOpacity(
                duration: Duration(milliseconds: 300),
                opacity: _isFabVisible ? 1.0 : 0.0,
                child: FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _paragraphs = [];
                    });
                  },
                  child: Icon(Icons.arrow_back),
                ),
              ),
            )
          : null,
    );
  }
}

class ClickableParagraph extends StatelessWidget {
  final String text;
  final void Function(String word) onWordTap;
  final TextStyle? textStyleBodyMedium;
  final TextAlign textAlign;

  const ClickableParagraph({
    super.key,
    required this.textStyleBodyMedium,
    required this.text,
    required this.onWordTap,
    this.textAlign = TextAlign.justify,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: textAlign,
      text: TextSpan(style: textStyleBodyMedium, children: _buildSpans()),
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
