import 'dart:io';

import 'package:ara_dict/data.dart';
import 'package:ara_dict/reader.dart';
import 'package:ara_dict/wigds.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class BookMarks {
  static late final File _bookMarkFile;
  static late final File _bookMarkFileTmp;
  static final Set<String> _bookMarkedWords = {'عمل'};

  static Future<void> load() async {
    final dir = await getApplicationDocumentsDirectory();
    _bookMarkFile = File(join(dir.path, 'arabic_lexicons_bookMarks.txt'));
    _bookMarkFileTmp = File(
      join(dir.path, 'arabic_lexicons_bookMarks_tmp.txt'),
    );

    if (!await _bookMarkFile.exists()) return;
    for (var w in await _bookMarkFile.readAsLines()) {
      w = w.trim();
      if (w.isNotEmpty) _bookMarkedWords.add(w);
    }
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

  static bool add(String w) {
    if (w.isEmpty) return false;
    if (!_bookMarkedWords.add(w)) return true;
    return _saveToFile();
  }

  static bool rm(String w) {
    if (w.isEmpty) return false;
    if (!_bookMarkedWords.remove(w)) return true;
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

  @override
  Widget build(BuildContext context) {
    final arabicFontStyle = appSettingsNotifier.getArabicTextStyle(context);

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
        child: BookMarks.isEmpty
            ? Center(child: Text('Bookmark some words'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
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
                                  message: 'Do you want to delte: $word',
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
      floatingActionButton: FloatingActionButton.small(
        child: Transform.rotate(
          angle: _isShowNewToOld ? 3.16 : 0,
          child: const Icon(Icons.sort),
        ),
        onPressed: () {
          _isShowNewToOld = !_isShowNewToOld;
          setState(() {});
        },
      ),
    );
  }
}
