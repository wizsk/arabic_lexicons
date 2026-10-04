import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arabic_lexicons/alphabets.dart';
import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/datas/word_store.dart';
import 'package:arabic_lexicons/helper_widgets.dart';
import 'package:arabic_lexicons/main_widgets.dart';
import 'package:arabic_lexicons/multi_selection.dart';
import 'package:arabic_lexicons/pages/utils.dart';
import 'package:arabic_lexicons/reader/reader_utils.dart';
import 'package:arabic_lexicons/reader/word_lists.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:arabic_lexicons/utils/toast_snack.dart';
import 'package:arabic_lexicons/word_list/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

enum WordListType { bookmarks, foreings }

class WordListPage extends StatefulWidget {
  final WordListType listType;

  const WordListPage({super.key, required this.listType});

  @override
  State<WordListPage> createState() => _WordListPageState();
}

class _WordListPageState extends State<WordListPage> {
  late final WordListType _listType;
  late final String _titleMain;
  List<String> _words = [];
  late final Future<void> Function(String) _add;
  late final Future<int> Function(Iterable<String>) _addMulti;
  late final Future<void> Function(String) _remove;
  late final Future<int> Function(Iterable<String>) _removeMuli;
  late final Future<void> Function() _clearAll;
  late final String _exportFileName;
  late final bool _hasDeleteInList;

  bool _isShowNewToOld = true;
  final ScrollController _scrollController = ScrollController();
  late final SelectionController<String> _selection;
  final _tc = TextEditingController();
  String _shearced = '';

  @override
  void initState() {
    super.initState();

    _listType = widget.listType;

    switch (_listType) {
      case WordListType.bookmarks:
        _titleMain = 'Bookmarks';
        _words = WordStore.bookmarkedWords;
        _add = WordStore.addBM;
        _addMulti = WordStore.addBMs;
        _remove = WordStore.rmBM;
        _removeMuli = WordStore.rmBMs;
        _clearAll = WordStore.clearBookmarks;
        _exportFileName = 'Arabic_Lexicons_Boookamrks.txt';
        _hasDeleteInList = false;
        break;

      case WordListType.foreings:
        _titleMain = 'Foreigns';
        _words = WordStore.foreignWords;
        _add = WordStore.addForeign;
        _addMulti = WordStore.addForeigns;
        _remove = WordStore.removeForeign;
        _removeMuli = WordStore.removeForeignMany;
        _clearAll = WordStore.clearForeign;
        _exportFileName = 'Arabic_Lexicons_Foreings.txt';
        _hasDeleteInList = true;
        break;
    }

    _selection = SelectionController(() {
      if (mounted) setState(() {});
    });

    touggleFullScreen();
  }

  List<String> _getDefWordList() {
    return switch (_listType) {
      WordListType.bookmarks => WordStore.bookmarkedWords,
      WordListType.foreings => WordStore.foreignWords,
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    touggleFullScreen();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String get _title =>
      '$_titleMain${_words.isEmpty ? "" : " (${_words.length})"}';

  List<String> _selectedWordsList() {
    return _selection.selected.toList();
  }

  void _onSearchChange(String s) {
    if (!context.mounted) return;
    setState(() {
      _shearced = ArabicNormalizer.keepOnlyAr(s);
      if (_shearced.isEmpty) {
        _words = _getDefWordList();
        return;
      }

      final l = <(int, String)>[];
      for (final w in _getDefWordList()) {
        final idx = w.indexOf(_shearced);
        if (idx != -1) l.add((idx, w));
      }
      l.sort((a, b) => b.$1.compareTo(a.$1));

      _words = l.map((e) => e.$2).toList(growable: false);
    });
  }

  Widget _buildWordListAppbarMenu(
    BuildContext context, {
    required VoidCallback stateChanged,
    required List<String> Function() getSelectedWords,
    required List<String> allWords,
    required Future<void> Function(String) add,
    required Future<int> Function(Iterable<String>) addMulti,
    required Future<void> Function(String) remove,
    required Future<int> Function(Iterable<String>) removeMuli,
    required Future<void> Function() clearAll,
    required String exportFileName,
  }) {
    Iterable<String>? getWords(bool all) {
      if (all) {
        if (allWords.isEmpty) {
          MsgSv.showToast('No words');
          return null;
        }
        return allWords;
      } else {
        final words = getSelectedWords();
        if (words.isEmpty) {
          showSnack(context, 'No words Selected. Long press to select.');
          return null;
        }
        return words;
      }
    }

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        switch (value) {
          case 'sort':
            setState(() {
              _isShowNewToOld = !_isShowNewToOld;
            });
            break;

          case 'share_all_anki':
          case 'share_selected_anki':
            final words = getWords(value == 'share_all_anki');
            if (words == null || words.isEmpty) return;
            stateChanged();

            final res = await showAnkiCardShareOptions(context);
            if (res == null || res.$1 != true) return;

            VoidCallback? stopSpinner;
            if (context.mounted) {
              stopSpinner = showSpinningDialog(context, 'Sharing...');
            }

            final (filePath, fileBytes) = await makeAnki(words, res.$2);

            stopSpinner?.call();

            if (!context.mounted) return;
            showBackupOptionsButtomSheet(
              context,
              title: 'Import into Anki',
              saveDialogTitle: 'Save anki notes',
              filePaht: filePath,
              fileName: ankiExportFileName,
              fileData: fileBytes,
              allowedExt: ['txt'],
              shareTxt: 'Share with anki',
            );

            break;

          case 'delete_selected':
            final words = getSelectedWords();
            if (words.isEmpty) {
              if (context.mounted) {
                showSnack(context, 'No words Selected. Long press to select.');
              }
              return;
            }

            final count = words.length;

            final confrim = await showConfirmDialog(
              context,
              'Delete $count word${count > 1 ? "s" : ""}',
              message:
                  'Are you sure you want to delete selected words?'
                  '\nThis action cannot be undone.',
              confirmText: 'Delete Selected',
              destructive: true,
              constraints: true,
            );

            if (confrim != true) return;

            final rmCount = words.length;
            VoidCallback? stopSpinner;
            if (context.mounted) {
              stopSpinner = showSpinningDialog(context, 'Deleting...');
            }
            await removeMuli(words);

            stopSpinner?.call();
            stateChanged();

            if (context.mounted) {
              showSnack(
                context,
                'Deleted $rmCount word${rmCount > 1 ? "s" : ""}',
              );
            }
            break;

          case 'delete_all':
            if (allWords.isEmpty) return;
            final confrim = await showConfirmDialog(
              context,
              'Delete All',
              message: 'Are you sure you want to delete all words?',
              confirmText: 'Delete All',
              destructive: true,
              constraints: true,
            );

            if (confrim != true) return;
            VoidCallback? stopSpinner;
            if (context.mounted) {
              stopSpinner = showSpinningDialog(context, 'Deleting...');
            }

            final rmCount = allWords.length;

            await clearAll();

            stopSpinner?.call();
            stateChanged();

            if (context.mounted) {
              showSnack(
                context,
                'Deleted $rmCount word${rmCount > 1 ? "s" : ""}',
              );
            }
            break;

          case 'export':
          case 'export_selected':
            Iterable<String> words;
            if (value == 'export') {
              if (allWords.isEmpty) {
                showSnack(context, 'No words');
                return;
              }
              words = allWords;
            } else {
              words = getSelectedWords();
              if (words.isEmpty) {
                showSnack(context, 'No words Selected. Long press to select.');
                return;
              }
            }

            stateChanged();

            VoidCallback? stopSpinner;
            if (context.mounted) {
              stopSpinner = showSpinningDialog(context, 'Exporting...');
            }
            try {
              Uint8List fileBytes = utf8.encode(words.join("\n"));
              final tmp = await getTemporaryDirectory();
              final filePath = path.join(tmp.path, exportFileName);
              File(filePath).writeAsBytes(fileBytes);

              stopSpinner?.call();

              if (!context.mounted) return;
              showBackupOptionsButtomSheet(
                context,
                title: 'Export Ready',
                saveDialogTitle: 'Export',
                filePaht: filePath,
                fileName: exportFileName,
                fileData: fileBytes,
                allowedExt: ['txt'],
              );
            } catch (e) {
              stopSpinner?.call();
              if (kDebugMode) debugPrint('Export err: $e');
              stopSpinner?.call();

              if (context.mounted) {
                showSnack(context, 'Export failed');
              }
            }
            break;

          case 'import':
            final confirmed = await showConfirmDialog(
              context,
              'Import',
              message:
                  'If a word in the backup already exists in your list, '
                  'it will be skipped.\n\n'
                  'Do you want to import?',
              confirmText: 'Select File',
              constraints: true,
            );
            if (confirmed != true) return;

            stateChanged();

            VoidCallback? stopSpinner;
            if (context.mounted) {
              stopSpinner = showSpinningDialog(context, 'Importing...');
            }

            try {
              final result = await FilePicker.pickFile(dialogTitle: 'Import');

              if (result == null) return;

              // final data = await result.readAsByteStream().toList();
              final data = await result.readAsByteStream().fold<List<int>>(
                <int>[],
                (prev, chunk) {
                  prev.addAll(chunk);
                  return prev;
                },
              );

              // final result = Uint8List.fromList(bytes);

              final content = utf8.decode(data);

              final res = <String>[];
              for (var w in LineSplitter.split(content)) {
                w = ArabicNormalizer.keepOnlyAr(w);
                if (w.isEmpty) continue;
                res.add(w);
              }

              final addedCount = await addMulti(res);

              stateChanged();

              if (context.mounted) {
                showSnack(
                  context,
                  'Added $addedCount word${addedCount > 1 ? "s" : ""}',
                );
              }
            } catch (e) {
              if (context.mounted) {
                showSnack(context, 'Import failed');
              }
              if (kDebugMode) debugPrint('Import failed: $e');
            } finally {
              stopSpinner?.call();
            }
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'sort',
          child: Row(
            children: [
              Icon(Icons.sort),
              SizedBox(width: 10),
              Text(_isShowNewToOld ? 'New to old' : 'Old to new'),
            ],
          ),
        ),
        const PopupMenuDivider(),

        const PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.upload_file),
              SizedBox(width: 10),
              Text('Export'),
            ],
          ),
        ),

        const PopupMenuItem(
          value: 'export_selected',
          child: Row(
            children: [
              Icon(Icons.outbox),
              SizedBox(width: 10),
              Text('Export Selected'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'import',
          child: Row(
            children: [
              Icon(Icons.file_download),
              SizedBox(width: 10),
              Text('Import'),
            ],
          ),
        ),

        const PopupMenuDivider(),

        const PopupMenuItem(
          value: 'share_all_anki',
          child: Row(
            children: [
              Icon(Icons.school), // 📚 better for Anki
              SizedBox(width: 10),
              Text('Anki (All)'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'share_selected_anki',
          child: Row(
            children: [
              Icon(Icons.auto_stories), // 📖 distinct from above
              SizedBox(width: 10),
              Text('Anki (Selected)'),
            ],
          ),
        ),

        const PopupMenuDivider(),

        const PopupMenuItem(
          value: 'delete_all',
          child: Row(
            children: [
              Icon(Icons.delete_sweep),
              SizedBox(width: 10),
              Text('Delete All'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete_selected',
          child: Row(
            children: [
              Icon(Icons.delete),
              SizedBox(width: 10),
              Text('Delete Selected'),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final padd = appConf.readerPadd(context);

    return PopScope(
      canPop: !_selection.hasSelection,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_selection.hasSelection) {
          _selection.clear();
          return;
        }
        Navigator.pop(context);
      },
      child: Scaffold(
        // appBar: AppBar(),
        // drawer: buildDrawer(context),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: GestureStack(
            child: Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: SliverAppBar(
                          floating: true,
                          snap: appConf.hideAppbar,
                          pinned: !appConf.hideAppbar,
                          title: _selection.appBarTitle(
                            _title,
                            // style: L.arStyleIf,
                          ),
                          actions: [
                            if (_selection.hasSelection)
                              ..._selection.genricAppBarActions(
                                context,
                                all: () => _words,
                                rm: null,
                              )
                            else if (_listType == WordListType.foreings)
                              IconButton(
                                icon: const Icon(Icons.info_outlined),
                                tooltip: 'Info',
                                onPressed: () => showLuwAllInfo(context),
                              ),
                            _buildWordListAppbarMenu(
                              context,
                              stateChanged: _selection.clear,
                              allWords: _words,
                              add: _add,
                              addMulti: _addMulti,
                              exportFileName: _exportFileName,
                              remove: _remove,
                              removeMuli: _removeMuli,
                              clearAll: _clearAll,
                              getSelectedWords: _selectedWordsList,
                            ),
                          ],
                        ),
                      ),
                      if (_words.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height * 0.3,
                            ),
                            child: Center(
                              child: Text(
                                _shearced.isEmpty ? 'No words' : 'No results',
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: padd,
                          sliver: SliverList.separated(
                            itemCount: _words.length,
                            separatorBuilder: (_, _) {
                              return const SizedBox(height: 4);
                            },
                            itemBuilder: (context, visualIndex) {
                              final index = _isShowNewToOld
                                  ? _words.length - 1 - visualIndex
                                  : visualIndex;

                              final word = _words[index];

                              return SelectableWordListTitle(
                                index: visualIndex,
                                length: _words.length,
                                wordMatch: _shearced,
                                word: word,
                                selection: _selection,
                                setState: setState,
                                remove: _hasDeleteInList
                                    ? () async => await _remove(word)
                                    : null,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsetsGeometry.symmetric(horizontal: padd.right),
                  child: const Divider(height: 0),
                ),
                SizedBox(width: 8),
                Padding(
                  padding: EdgeInsetsGeometry.symmetric(
                    horizontal: padd.right,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _tc,
                    // focusNode: _focusNode,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.start,
                    onChanged: _onSearchChange,
                    // style: arTxtTheme,
                    style: L.arStyleSized,
                    decoration: InputDecoration(
                      hintText: L.p('Search Words', 'ابحث'),
                      hintTextDirection: L.dir,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _tc.clear();
                            _shearced = '';
                          });
                        },
                        icon: Icon(Icons.clear),
                      ),
                    ),
                  ),
                ),
                if (appConf.fullScreen) const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
