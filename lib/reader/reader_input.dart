import 'dart:convert';
import 'dart:io';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/reader/reader.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:ara_dict/sv.dart';
import 'package:ara_dict/utils.dart';
import 'package:crypto/crypto.dart'; // for hashing
import 'package:ara_dict/wigds.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class BookEntry {
  final String hash;
  final String name;
  BookEntry(this.hash, this.name);
}

class _ReaderInputPageData {
  static bool isInited = false;
  static Directory? booksDir;
  static File? indexFile;
  static File? tmpIndexFile;
  static List<BookEntry> books = [];

  static Future<void> init(VoidCallback callback) async {
    if (isInited) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      booksDir = Directory(join(dir.path, 'books'));
      if (!await booksDir!.exists()) {
        await booksDir!.create();
      }
      indexFile = File(join(booksDir!.path, 'books.txt'));
      tmpIndexFile = File(join(booksDir!.path, 'books_tmp.txt'));
      isInited = true;
    } catch (e) {
      debugPrint('err while initing booksdir: $e');
      isInited = false;
      return;
    }

    if (!await indexFile!.exists()) return;
    final lines = await indexFile!.readAsLines();
    books = lines
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

    if (books.isNotEmpty) callback();
  }
}

class ReaderInputPage extends StatefulWidget {
  const ReaderInputPage({super.key});

  @override
  State<ReaderInputPage> createState() => _ReaderInputPageState();
}

class _ReaderInputPageState extends State<ReaderInputPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ReaderInputPageData.init(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _resetReaderInputPage() {
    _controller.clear();
    _textFiledSize = _minTextFiledSize;
    _isTempMode = false;
  }

  void _showText(BuildContext context) {
    final text = _controller.text.trim();
    final paras = cleanReaderInputAndPrepare(text);
    if (!_isTempMode && paras.isNotEmpty) _saveBookTxt(paras);
    _resetReaderInputPage();
    _openReaderPage(context, paras);
  }

  String _hashText(String text) {
    final bytes = utf8.encode(text);
    return sha1.convert(bytes).toString(); // short but unique
  }

  Future<void> _saveBookTxt(List<List<WordEntry>> peras) async {
    if (!_ReaderInputPageData.isInited || peras.isEmpty) return;

    String displayName = peras.first.map((w) => w.ar).join(" ");
    if (displayName.length > 100) displayName = displayName.substring(0, 100);

    String content = peras.map((p) => p.map((w) => w.ar).join(" ")).join("\n");

    final hash = _hashText(content); // filename
    final exists = _ReaderInputPageData.books.any((b) => b.hash == hash);
    if (exists) {
      return;
    }

    final file = File(join(_ReaderInputPageData.booksDir!.path, '$hash.txt'));
    try {
      await file.writeAsString(content);
    } catch (_) {
      return;
    }

    _ReaderInputPageData.books.add(BookEntry(hash, displayName));
    await _saveBookEntriesFile();
  }

  Future<void> _deleteFile(int index) async {
    if (!_ReaderInputPageData.isInited) return;
    if (index < 0 || index >= _ReaderInputPageData.books.length) {
      return;
    }
    final be = _ReaderInputPageData.books.removeAt(index);
    final file = File(
      join(_ReaderInputPageData.booksDir!.path, '${be.hash}.txt'),
    );
    try {
      await file.delete();
    } catch (e) {
      return;
    }

    await _saveBookEntriesFile();
    setState(() {});
  }

  Future<void> _saveBookEntriesFile() async {
    if (!_ReaderInputPageData.isInited) return;

    final txt = _ReaderInputPageData.books
        .map((be) => '${be.hash}:${be.name}')
        .join("\n");
    await _ReaderInputPageData.tmpIndexFile!.writeAsString(txt);
    await _ReaderInputPageData.tmpIndexFile!.rename(
      _ReaderInputPageData.indexFile!.path,
    );
  }

  Future<void> _openBook(BuildContext context, BookEntry entry) async {
    if (!_ReaderInputPageData.isInited) return;

    final file = File(
      join(_ReaderInputPageData.booksDir!.path, '${entry.hash}.txt'),
    );
    if (!await file.exists()) return;

    final content = await file.readAsString();
    final paras = cleanReaderInputAndPrepare(content);

    if (context.mounted) {
      _openReaderPage(context, paras);
    }
  }

  void _openReaderPage(BuildContext context, List<List<WordEntry>> paras) {
    if (paras.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open book')));
    }
    openReaderPage(context, paras);
  }

  final int _minTextFiledSize = 4;
  final int _maxTextFiledSize = 18;
  int _textFiledSize = 4;
  bool _isTempMode = false;
  bool _isShowEntrieNewToOld = true;

  @override
  Widget build(BuildContext context) {
    final arabicFontStyle = appSettingsNotifier.getArabicTextStyle(context);
    final cs = Theme.of(context).colorScheme;
    final btnTheme = FilledButton.styleFrom(
      backgroundColor: cs.primary.withAlpha(30),
      foregroundColor: cs.primary,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          /*txt*/ 'القارئ',
          textDirection: TextDirection.rtl,
          style: TextStyle(fontFamily: arabicFontStyle.fontFamily),
        ),
      ),
      drawer: buildDrawer(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _controller,
                  maxLines: _textFiledSize,
                  textDirection: TextDirection.rtl,
                  style: arabicFontStyle,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'اكتب هنا…',
                    hintTextDirection: TextDirection.rtl,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(10),
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

                // SizedBox(height: 10),
                SizedBox(
                  width: 150,
                  child: FilledButton.icon(
                    label: Text('Go'),
                    icon: Icon(Icons.start),
                    iconAlignment: IconAlignment.end,
                    onPressed: () => _showText(context),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 6,
                    children: [
                      FilledButton(
                        style: btnTheme,
                        child: _textFiledSize == _minTextFiledSize
                            ? Text('Expand')
                            : Text('Collapse'),
                        // icon: Icon(Icons.expand),
                        // iconSize: mediumFontSize * 2,
                        onPressed: () => setState(() {
                          if (_textFiledSize == _maxTextFiledSize) {
                            _textFiledSize = _minTextFiledSize;
                          } else {
                            _textFiledSize = _maxTextFiledSize;
                          }
                        }),
                      ),
                      FilledButton(
                        style: btnTheme,
                        child: Text('Paste'),
                        onPressed: () async {
                          final txt = await getClipboardText();
                          if (txt != null) {
                            // _controller.clear();
                            _controller.text = _controller.text + txt;
                          }
                        },
                        // icon: Icon(Icons.paste),
                      ),
                      FilledButton(
                        style: btnTheme,
                        child: Text('Clear'),
                        onPressed: () async {
                          if (_controller.text.isEmpty) return;

                          final res = await showConfirmDialog(
                            context,
                            'Clear all text?',
                            // message: 'Do you want to clear the texts?',
                          );
                          if (res != null && res) _controller.clear();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 26),
            if (_ReaderInputPageData.books.isNotEmpty)
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
                    /* Txt */ 'قائمة النص ${_isShowEntrieNewToOld ? "(جديد إلى قديم)" : "(قديم إلى جديد)"} [${enToArNum(_ReaderInputPageData.books.length)}]',
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: arabicFontStyle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (_ReaderInputPageData.books.isNotEmpty) Divider(thickness: 0.5),
            if (_ReaderInputPageData.books.isNotEmpty)
              ...List.generate(_ReaderInputPageData.books.length, (index) {
                if (_isShowEntrieNewToOld) {
                  index = _ReaderInputPageData.books.length - 1 - index;
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
                      _openBook(context, _ReaderInputPageData.books[index]);
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
                                /*txt*/ 'حذف الكتاب',
                                message:
                                    /* txt */ 'هل تريد حذف ${_ReaderInputPageData.books[index].name}؟',
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
                              _ReaderInputPageData.books[index].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              style: arabicFontStyle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
