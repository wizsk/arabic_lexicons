import 'dart:convert';
import 'dart:io';
import 'package:ara_dict/etc.dart';
import 'package:ara_dict/sv.dart';
import 'package:crypto/crypto.dart'; // for hashing
import 'package:ara_dict/theme.dart';
import 'package:ara_dict/wigds.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ara_dict/lexicons.dart';

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
  String? _title;
  late final Directory _booksDir;

  late final File _indexFile;
  late final File _tmpIndexFile;

  List<BookEntry> _books = [];

  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _initStorage();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection ==
            ScrollDirection.reverse &&
        _isFabVisible) {
      setState(() {
        _isFabVisible = false;
      });
    } else if (_scrollController.position.userScrollDirection ==
            ScrollDirection.forward &&
        !_isFabVisible) {
      setState(() {
        _isFabVisible = true;
      });
    }
  }

  void _showText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _paragraphs = _splitLines(text);
    final t = _paragraphs.first;
    _title = t.length > 50 ? t.substring(0, 50) : t;
    setState(() {});
    if (!_isTempMode) {
      _saveFile();
    } else {
      _controller.clear();
    }
    _textFiledSize = _minTextFiledSize;
    _isTempMode = false;
  }

  List<String> _splitLines(String text) {
    text = text.trim();
    if (text.isEmpty) return [];
    return text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split(RegExp(r'\n+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  Future<void> _initStorage() async {
    final dir = await getApplicationDocumentsDirectory();
    _booksDir = Directory(join(dir.path, 'books'));
    if (!await _booksDir.exists()) await _booksDir.create();

    _indexFile = File(join(_booksDir.path, 'books.txt'));
    _tmpIndexFile = File(join(_booksDir.path, 'books_tmp.txt'));
    await _loadBooks();
  }

  Future<void> _loadBooks() async {
    if (!await _indexFile.exists()) return;

    final lines = await _indexFile.readAsLines();
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
    _controller.clear();
    if (content.isEmpty) return;

    final lines = _splitLines(content);
    if (lines.isEmpty) return;

    String displayName = lines.first.split(RegExp(r' +')).join(" ");
    if (displayName.length > 100) displayName = displayName.substring(0, 100);

    final hash = _hashText(content); // filename
    final exists = _books.any((b) => b.hash == hash);
    if (exists) {
      return;
    }

    final file = File(join(_booksDir.path, '$hash.txt'));
    try {
      await file.writeAsString(content);
    } catch (_) {
      return;
    }

    _books.add(BookEntry(hash, displayName));
    await _saveBookEntriesFile();
  }

  Future<void> _deleteFile(int index) async {
    if (index < 0 || index >= _books.length) {
      return;
    }

    final be = _books.removeAt(index);
    final file = File(join(_booksDir.path, '${be.hash}.txt'));
    try {
      await file.delete();
    } catch (e) {
      return;
    }

    await _saveBookEntriesFile();
    setState(() {});
  }

  Future<void> _saveBookEntriesFile() async {
    final txt = _books.map((be) => '${be.hash}:${be.name}').join("\n");
    await _tmpIndexFile.writeAsString(txt);
    await _tmpIndexFile.rename(_indexFile.path);
  }

  Future<void> _openBook(BookEntry entry) async {
    final file = File(join(_booksDir.path, '${entry.hash}.txt'));
    if (!await file.exists()) return;

    final content = await file.readAsString();
    _paragraphs = _splitLines(content);
    final t = _paragraphs.first;
    _title = t.length > 50 ? t.substring(0, 50) : t;

    _isTempMode = false;
    _textFiledSize = _minTextFiledSize;
    _controller.clear();
    setState(() {});
  }

  final int _minTextFiledSize = 4;
  final int _maxTextFiledSize = 18;
  int _textFiledSize = 4;
  bool _isQasidah = false;
  bool _isTempMode = false;
  bool _isShowEntrieNewToOld = true;
  TextAlign _textAlign = TextAlign.justify;

  @override
  Widget build(BuildContext context) {
    final textStyleBodyMedium = Theme.of(context).textTheme.bodyMedium;

    return Scaffold(
      appBar: AppBar(
        title: _paragraphs.isEmpty ? const Text('القارئ') : Text(_title!),
      ),
      drawer: buildDrawer(context),
      body: SafeArea(
        child: _paragraphs.isEmpty
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Column(
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
                        padding: const EdgeInsets.all(8.0),
                        child: CompactCheckboxTile(
                          value: _isTempMode,
                          onChanged: (v) {
                            setState(() {
                              _isTempMode = v ?? false;
                            });
                          },
                          title: Text("Don't save"),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 4,
                          children: [
                            IconButton(
                              icon: Icon(Icons.expand),
                              iconSize: mediumFontSize * 2,
                              onPressed: () => setState(() {
                                if (_textFiledSize == _maxTextFiledSize) {
                                  _textFiledSize = _minTextFiledSize;
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
                              icon: Icon(Icons.check_circle),
                              iconSize: mediumFontSize * 2,
                              onPressed: _showText,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 26),
                  if (_books.isNotEmpty)
                    InkWell(
                      // borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        setState(() {
                          _isShowEntrieNewToOld = !_isShowEntrieNewToOld;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Text(
                          /* Txt */ 'قائمة النص ${_isShowEntrieNewToOld ? "(جديد إلى قديم)" : "(قديم إلى جديد)"} [${enToArNum(_books.length)}]',
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (_books.isNotEmpty) Divider(thickness: 0.5),
                  if (_books.isNotEmpty)
                    ...List.generate(_books.length, (index) {
                      if (_isShowEntrieNewToOld) {
                        index = _books.length - 1 - index;
                      }
                      return Ink(
                        decoration: index.isOdd
                            ? null
                            : BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withAlpha(30),
                              ),
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
                                      message: 'احذف: ${_books[index].name}',
                                      dir: TextDirection.rtl,
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
                    }),
                ],
              )
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ).copyWith(bottom: 128),
                itemCount: _paragraphs.length,
                itemBuilder: (context, index) {
                  final textAlign = _isQasidah ? TextAlign.right : _textAlign;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ClickableParagraph(
                      peraIndex: index,
                      isQasidah: _isQasidah,
                      text: _paragraphs[index],
                      textStyleBodyMedium: textStyleBodyMedium,
                      textAlign: textAlign,
                      onWordTap: (word) {
                        openDict(context, word);
                      },
                    ),
                  );
                },
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
                  onPressed: () async {
                    final res = await showReaderModeSettings(
                      context,
                      _isQasidah,
                      _textAlign,
                      _paragraphs,
                      () {
                        // final res = await showConfirmDialog(
                        //   context,
                        //   message: "Do you realy want to exit?",
                        // );
                        // if (res != null && res) {
                        // after if no longer in reader mode
                        _paragraphs = [];
                        _isQasidah = false;
                        _textAlign = TextAlign.justify;
                        setState(() {});
                        // }
                      },
                    );

                    if (res == null) return;
                    if (res.isQasidah != _isQasidah ||
                        res.textAlign != _textAlign) {
                      _isQasidah = res.isQasidah;
                      _textAlign = res.textAlign;
                      setState(() {});
                    }
                  },
                  child: Icon(Icons.settings),
                ),
              ),
            )
          : null,
    );
  }
}

class ClickableParagraph extends StatelessWidget {
  final String text;
  final int peraIndex;
  final bool isQasidah;
  final void Function(String word) onWordTap;
  final TextStyle? textStyleBodyMedium;
  final TextAlign textAlign;

  const ClickableParagraph({
    super.key,
    required this.text,
    required this.peraIndex,
    required this.isQasidah,
    required this.onWordTap,
    required this.textStyleBodyMedium,
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

    final words = text.split(RegExp(r'\s+'));
    if (words.isEmpty) return spans;

    if (isQasidah) {
      if (peraIndex % 2 == 0) {
        spans.add(
          TextSpan(
            text: '${enToArNum((peraIndex ~/ 2) + 1)}- ',
            style: textStyleBodyMedium!.copyWith(fontWeight: FontWeight.bold),
          ),
        );
      } else {
        spans.add(TextSpan(children: [WidgetSpan(child: SizedBox(width: 30))]));
      }
    } else {
      spans.add(TextSpan(children: [WidgetSpan(child: SizedBox(width: 20))]));
    }

    for (final word in words) {
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
      builder: (_) => SearchLexicons(showDrawer: false, initialText: word),
    ),
  );
}

String enToArNum(dynamic n) {
  return n.toString().replaceAllMapped(
    RegExp(r'[0-9]'),
    (m) => String.fromCharCode(0x0660 + int.parse(m.group(0)!)),
  );
}
