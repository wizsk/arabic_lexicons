import 'dart:convert';
import 'dart:io';
import 'package:ara_dict/alphabets.dart';
import 'package:ara_dict/book_marks.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/etc.dart';

import 'package:ara_dict/sv.dart';
import 'package:crypto/crypto.dart'; // for hashing
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

  final _maxTitleLen = 40;

  List<List<WordEntry>> _paragraphs = [];
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

  void _resetReaderInputPage() {
    _controller.clear();
    _textFiledSize = _minTextFiledSize;
    _isTempMode = false;
  }

  void _showText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _paragraphs = _cleanInputAndPrepare(text);
    final t = _paragraphs.first.map((w) => w.ar).join(" ");
    _title = t.length > _maxTitleLen ? t.substring(0, _maxTitleLen) : t;
    setState(() {});

    if (!_isTempMode) _saveBookTxt(_paragraphs);
    _resetReaderInputPage();
  }

  List<List<WordEntry>> _cleanInputAndPrepare(String text) {
    text = text.trim();
    if (text.isEmpty) return [];

    List<List<WordEntry>> res = [];
    for (var l in LineSplitter.split(text)) {
      l = l.trim();
      if (l.isEmpty) continue;
      List<WordEntry> curr = [];
      for (var w in l.split(RegExp(r'\s'))) {
        curr.add(
          WordEntry(
            ar: w,
            cl: ArabicNormalizer.keepOnlyAr(w),
            nTk: ArabicNormalizer.rmTashkil(w),
          ),
        );
      }
      if (curr.isNotEmpty) res.add(curr);
    }
    return res;
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

  Future<void> _saveBookTxt(List<List<WordEntry>> peras) async {
    if (peras.isEmpty) return;

    String displayName = peras.first.map((w) => w.ar).join(" ");
    if (displayName.length > 100) displayName = displayName.substring(0, 100);

    String content = peras.map((p) => p.map((w) => w.ar).join(" ")).join("\n");

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
    _paragraphs = _cleanInputAndPrepare(content);

    if (_paragraphs.isEmpty) return;

    final t = _paragraphs.first.map((w) => w.ar).join(" ");
    _title = t.length > 50 ? t.substring(0, 50) : t;

    setState(() {});
    _resetReaderInputPage();
  }

  final int _minTextFiledSize = 4;
  final int _maxTextFiledSize = 18;
  int _textFiledSize = 4;
  bool _isTempMode = false;
  bool _isShowEntrieNewToOld = true;

  ReaderPageSettings _rs = ReaderPageSettings(
    isQasidah: false,
    isRmTashkil: false,
    isOpenLexiconDirecly: appSettingsNotifier.readerIsOpenLexiconDirecly,
    textAlign: TextAlign.justify,
  );

  @override
  Widget build(BuildContext context) {
    final arabicFontStyle = appSettingsNotifier.getArabicTextStyle(context);
    final cs = Theme.of(context).colorScheme;
    final btnTheme = FilledButton.styleFrom(
      backgroundColor: cs.primary.withAlpha(30),
      foregroundColor: cs.primary,
    );

    // final cs = Theme.of(context).colorScheme;
    final highWordStyle = arabicFontStyle.copyWith(color: cs.error);

    return Scaffold(
      appBar: AppBar(
        title: _paragraphs.isEmpty
            ? Text(
                /*txt*/ 'القارئ',
                textDirection: TextDirection.rtl,
                style: TextStyle(fontFamily: arabicFontStyle.fontFamily),
              )
            : Text(
                _title!,
                textDirection: TextDirection.rtl,
                style: TextStyle(fontFamily: arabicFontStyle.fontFamily),
              ),
      ),
      drawer: buildDrawer(context),
      body: SafeArea(
        child: _paragraphs.isEmpty
            ? ListView(
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
                          onPressed: _showText,
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
                          style: arabicFontStyle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
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
                                      /*txt*/ 'حذف الكتاب',
                                      message:
                                          /* txt */ 'هل تريد حذف ${_books[index].name}؟',
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
              )
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ).copyWith(bottom: 128),
                itemCount: _paragraphs.length,
                itemBuilder: (context, index) {
                  final textAlign = _rs.isQasidah
                      ? TextAlign.right
                      : _rs.textAlign;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ClickableParagraph(
                      peraIndex: index,
                      rs: _rs,
                      pera: _paragraphs[index],
                      textStyleBodyMedium: arabicFontStyle,
                      highTextStyleBodyMedium: highWordStyle,
                      textAlign: textAlign,
                      onChange: () => setState(() {}),
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
                child: FloatingActionButton.small(
                  onPressed: () async {
                    final res = await showReaderModeSettings(
                      context,
                      _rs.copyWith(),
                      _paragraphs,
                      () {
                        _paragraphs = [];
                        _rs.isQasidah = false;
                        _rs.isRmTashkil = false;
                        _rs.textAlign = TextAlign.justify;
                        setState(() {});
                      },
                    );

                    if (res == null || _rs.isEqual(res)) {
                      return;
                    }

                    if (_rs.isOpenLexiconDirecly != res.isOpenLexiconDirecly) {
                      await appSettingsNotifier.saveReaderIsOpenLexiconDirecly(
                        res.isOpenLexiconDirecly,
                      );
                    }

                    if (_rs.isRmTashkil != res.isRmTashkil &&
                        _paragraphs.isNotEmpty) {
                      final nt = res.isRmTashkil
                          ? _paragraphs.first.map((w) => w.nTk).join(" ")
                          : _paragraphs.first.map((w) => w.ar).join(" ");
                      _title = nt.length > _maxTitleLen
                          ? nt.substring(0, _maxTitleLen)
                          : nt;
                    }

                    _rs = res;
                    setState(() {});
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
  final List<WordEntry> pera;
  final int peraIndex;
  final ReaderPageSettings rs;
  final void Function() onChange;
  final TextStyle textStyleBodyMedium;
  final TextStyle highTextStyleBodyMedium;
  final TextAlign textAlign;

  const ClickableParagraph({
    super.key,
    required this.pera,
    required this.peraIndex,
    required this.rs,
    required this.onChange,
    required this.textStyleBodyMedium,
    required this.highTextStyleBodyMedium,
    this.textAlign = TextAlign.justify,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: textAlign,
      text: TextSpan(
        style: textStyleBodyMedium,
        children: _buildSpans(context),
      ),
    );
  }

  List<TextSpan> _buildSpans(BuildContext context) {
    final spans = <TextSpan>[];

    if (rs.isQasidah) {
      if (peraIndex % 2 == 0) {
        spans.add(
          TextSpan(
            text: '${enToArNum((peraIndex ~/ 2) + 1)}- ',
            style: textStyleBodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        );
      } else {
        spans.add(TextSpan(children: [WidgetSpan(child: SizedBox(width: 30))]));
      }
    } else {
      spans.add(TextSpan(children: [WidgetSpan(child: SizedBox(width: 20))]));
    }

    for (final word in pera) {
      final isBmk = BookMarks.isSet(word.cl);
      spans.add(
        TextSpan(
          text: rs.isRmTashkil ? '${word.nTk} ' : '${word.ar} ',
          recognizer: word.cl.isEmpty
              ? null
              : (TapGestureRecognizer()
                  ..onTap = rs.isOpenLexiconDirecly
                      ? () => openDict(context, word.cl).then((_) {
                          if (context.mounted) onChange();
                        })
                      : () => showWordReadeActionsDialog(
                          context,
                          word.cl,
                          isBmk,
                          () async {
                            if (isBmk) {
                              await BookMarks.rm(word.cl);
                            } else {
                              await BookMarks.add(word.cl);
                            }
                            if (context.mounted) onChange();
                          },
                          () {
                            openDict(context, word.cl).then((_) {
                              if (context.mounted) onChange();
                            });
                          },
                          textStyleBodyMedium,
                        )),
          style: isBmk ? highTextStyleBodyMedium : null,
        ),
      );
    }
    return spans;
  }
}

Future<void> openDict(BuildContext context, String word) async {
  await Navigator.push(
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

Future<void> showWordReadeActionsDialog(
  BuildContext context,
  String word,
  bool isBookmarked,
  VoidCallback onBookmark,
  VoidCallback onShowDefinition,
  TextStyle ts,
) {
  // final cs = Theme.of(context).colorScheme;

  return showDialog(
    context: context,
    builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Title
                Text(
                  word,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: ts.fontFamily,
                  ),
                ),

                const SizedBox(height: 24),

                /// Buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        ),
                        label: Text(
                          isBookmarked ? "Remove Bookmark" : "Add to Bookmark",
                        ),
                        style: isBookmarked
                            ? FilledButton.styleFrom(
                                backgroundColor: cs.error,
                                foregroundColor: cs.onError,
                              )
                            : null,
                        onPressed: () {
                          Navigator.pop(context);
                          onBookmark();
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.menu_book),
                        label: const Text("Show Definition"),
                        onPressed: () {
                          Navigator.pop(context);
                          onShowDefinition();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
