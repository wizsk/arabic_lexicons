import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ara_dict/alphabets.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/reader.dart';
import 'package:ara_dict/wigds.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

const _bookMarkFileName = 'arabic_lexicons_bookMarks.txt';

class BookMarks {
  static const int _maxBookMarkWrodSize = 10;
  static late final File _bookMarkFile;
  static late final File _bookMarkFileTmp;
  static final Set<String> _bookMarkedWords = {};

  static Future<void> load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _bookMarkFile = File(join(dir.path, _bookMarkFileName));
      _bookMarkFileTmp = File(
        join(dir.path, 'arabic_lexicons_bookMarks_tmp.txt'),
      );

      if (!await _bookMarkFile.exists()) return;
      for (var w in await _bookMarkFile.readAsLines()) {
        w = w.trim();
        if (w.isNotEmpty) _bookMarkedWords.add(w);
      }
    } catch (e) {}
  }

  static bool isSet(String? w) {
    return _bookMarkedWords.contains(w);
  }

  static bool get isEmpty {
    return _bookMarkedWords.isEmpty;
  }

  static bool get isNotEmpty {
    return _bookMarkedWords.isNotEmpty;
  }

  static int get length {
    return _bookMarkedWords.length;
  }

  static Set<String> get list {
    return _bookMarkedWords;
  }

  /// word must be cleaned
  static bool add(String w) {
    if (w.isEmpty || w.length > _maxBookMarkWrodSize) return false;
    if (!_bookMarkedWords.add(w)) return true;
    return _saveToFile();
  }

  /// word list must be cleaned
  static int addAll(List<String> wl) {
    int added = 0;
    for (final w in wl) {
      if (w.isEmpty || w.length > _maxBookMarkWrodSize) continue;
      if (_bookMarkedWords.add(w)) {
        added++;
      }
    }
    if (added > 0) _saveToFile();
    return added;
  }

  static bool rm(String w) {
    if (w.isEmpty) return false;
    if (!_bookMarkedWords.remove(w)) return true;
    return _saveToFile();
  }

  static bool rmAll() {
    if (_bookMarkedWords.isEmpty) return true;
    _bookMarkedWords.clear();
    return _saveToFile();
  }

  static bool _saveToFile() {
    if (_bookMarkedWords.isEmpty) {
      try {
        if (_bookMarkFile.existsSync()) _bookMarkFile.deleteSync();
      } catch (_) {
        return false;
      }
      return true;
    }

    final txt = _bookMarkedWords.join("\n");

    try {
      _bookMarkFileTmp.writeAsStringSync(txt);
    } catch (e) {
      return false;
    }

    try {
      _bookMarkFileTmp.renameSync(_bookMarkFile.path);
    } catch (e) {
      return false;
    }
    return true;
  }
}

class BookMarkPage extends StatefulWidget {
  const BookMarkPage({super.key});

  @override
  State<BookMarkPage> createState() => _BookMarkPageState();
}

class _BookMarkPageState extends State<BookMarkPage> {
  bool _isShowNewToOld = true;
  bool _isFabVisable = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection ==
            ScrollDirection.reverse &&
        _isFabVisable) {
      setState(() {
        _isFabVisable = false;
      });
    } else if (_scrollController.position.userScrollDirection ==
            ScrollDirection.forward &&
        !_isFabVisable) {
      setState(() {
        _isFabVisable = true;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arabicFontStyle = appSettingsNotifier.getArabicTextStyle(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          'BM${BookMarks.isEmpty ? "" : "s (${BookMarks.length.toString()})"}',
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep), // export
            tooltip: 'Delete all',
            onPressed: BookMarks.isEmpty
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Long press to delete')),
                    );
                  },
            onLongPress: BookMarks.isEmpty
                ? null
                : () async {
                    final res = await showConfirmDialog(
                      context,
                      'Delete All Bookmarks',
                      message:
                          'Are you sure you want to delete all bookmarked words?\nThis action cannot be undone.',
                    );
                    if (res ?? false) {
                      BookMarks.rmAll();
                      setState(() {});
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.upload_file), // export
            tooltip: 'Export List',
            onPressed: BookMarks.isEmpty
                ? null
                : () async {
                    try {
                      Uint8List fileBytes = Uint8List.fromList(
                        utf8.encode(BookMarks.list.join("\n")),
                      );

                      String? outputFile = await FilePicker.platform.saveFile(
                        dialogTitle: 'Export Bookmarks',
                        fileName: _bookMarkFileName,
                        bytes: fileBytes,
                        allowedExtensions: ['txt'],
                      );

                      if (outputFile != null) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Saved')));
                      } else {
                        throw "Filepicker canceled";
                      }
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Export failed: $e')),
                      );
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.download), // import
            tooltip: 'Import List',

            onPressed: () async {
              try {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['txt'],
                  withData: true,
                );

                if (result != null && result.files.single.bytes != null) {
                  final Uint8List fileBytes = result.files.single.bytes!;
                  final String content = utf8.decode(fileBytes);
                  final res = <String>[];
                  for (var w in content.split(RegExp(r'\r\n?|\n'))) {
                    w = cleanWord(w);
                    if (w.isEmpty) continue;
                    res.add(w);
                  }
                  final addedCound = BookMarks.addAll(res);
                  setState(() {});
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Added $addedCound word${addedCound > 1 ? "s" : ""} to bookmark',
                      ),
                    ),
                  );
                } else {
                  throw "Import canceled";
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
              }
            },
          ),
        ],
      ),
      drawer: buildDrawer(context),
      body: SafeArea(
        child: BookMarks.isEmpty
            ? Center(child: Text('Bookmark some words'))
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16).copyWith(bottom: 120),
                itemCount: BookMarks.length,
                itemBuilder: (context, index) {
                  if (_isShowNewToOld) {
                    index = BookMarks.length - 1 - index;
                  }
                  final word = BookMarks.list.elementAt(index);
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
                        openDict(context, word);
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
                                  'Delete Word',
                                  message:
                                      'Are you sure you want to delete $word?',
                                );
                                if (res ?? false) {
                                  BookMarks.rm(word);
                                }
                              },
                            ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: Text(
                                word,
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
                },
              ),
      ),

      floatingActionButton: AnimatedSlide(
        duration: Duration(milliseconds: 300),
        offset: _isFabVisable ? Offset.zero : Offset(0, 2),
        child: AnimatedOpacity(
          duration: Duration(milliseconds: 300),
          opacity: _isFabVisable ? 1.0 : 0.0,
          child: FloatingActionButton.small(
            child: const Icon(Icons.swap_vert),
            onPressed: () {
              _isShowNewToOld = !_isShowNewToOld;
              setState(() {});
            },
          ),
        ),
      ),
    );
  }
}
