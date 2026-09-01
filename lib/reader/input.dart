import 'dart:convert';

import 'package:arabic_lexicons/alphabets.dart';
import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/datas/stories_txts.dart';
import 'package:arabic_lexicons/first_run.dart';
import 'package:arabic_lexicons/helper_widgets.dart';
import 'package:arabic_lexicons/main_widgets.dart';
import 'package:arabic_lexicons/multi_selection.dart';
import 'package:arabic_lexicons/reader/book_entries_data.dart';
import 'package:arabic_lexicons/reader/data.dart';
import 'package:arabic_lexicons/reader/reader.dart';
import 'package:arabic_lexicons/reader/reader_utils.dart';
import 'package:arabic_lexicons/stories.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ReaderInputPage extends StatefulWidget {
  const ReaderInputPage({super.key});

  @override
  State<ReaderInputPage> createState() => _ReaderInputPageState();
}

class _ReaderInputPageState extends State<ReaderInputPage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _isTempMode = false;
  bool _isQasidahMode = false;
  bool _isPinned = false;
  bool _isShowEntrieNewToOld = true;

  late final SelectionController<int> _selection;

  String _searchText = "";

  @override
  void initState() {
    super.initState();
    touggleFullScreen();

    _selection = SelectionController(() {
      if (mounted) setState(() {});
    });

    showFirstRunPopupPostFrame(context);

    ReaderInputPageData.init().then((_) {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final shown = await appConf.showChangeChangelog(context);

      if (shown || !mounted) return;
      appConf.playRating(context);
    });

    appConf.saveRoute(Routes.readerInput);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    touggleFullScreen();
  }

  void _sortBooks() {
    ReaderInputPageData.setBookUnord(
      match: _searchText,
      newToOld: _isShowEntrieNewToOld,
    );
  }

  void _sortBooksRebuild() {
    _sortBooks();
    if (mounted) setState(() {});
  }

  Future<void> _openDemoTxt(BuildContext context) async {
    final idx = await showStoryPicker(context);
    if (idx != null && idx >= 0 && idx < stories.length && context.mounted) {
      final s = stories[idx];
      _isTempMode = true;
      _isQasidahMode = s.isQasidah;
      _showText(context, initialTxt: s.txt.join('\n'));
    }
  }

  Future<void> _showText(BuildContext context, {String? initialTxt}) async {
    final text = initialTxt ?? _controller.text;
    final paras = cleanReaderInputAndPrepare(text);

    if (text.isEmpty || paras.isEmpty) {
      showSnackL(
        context,
        en: 'Insert some text first!',
        ar: 'أدخل نصًا أولًا!',
      );
      return;
    }

    String? bookHash;

    if (!_isTempMode) {
      bookHash = await ReaderInputPageData.saveBookEntryWithData(paras);
      if (bookHash.isEmpty) {
        if (context.mounted) {
          showSnackL(context, en: 'Could not save book', ar: 'تعذر حفظ الكتاب');
        }
        return;
      }
    }

    if (context.mounted) {
      _openReaderPage(
        context,
        paras: paras,
        bookHash: bookHash,
        isQasidah: _isQasidahMode,
      );
    }
  }

  Future<void> _deleteFile(BookEntry en) async {
    await ReaderInputPageData.delete(en.sha);
    _sortBooksRebuild();
  }

  Future<void> _openBook(BuildContext context, BookEntry entry) async {
    if (context.mounted) {
      _openReaderPage(context, bookHash: entry.sha);
    }
  }

  void _openReaderPage(
    BuildContext context, {
    PeraEntries? paras,
    String? bookHash,
    bool? isQasidah,
  }) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: Routes.readerPage),
        builder: (_) =>
            ReaderPage(paras: paras, bookHash: bookHash, isQasidah: isQasidah),
      ),
    );
  }

  Future<void> _deleteSelectedBooks(BuildContext context) async {
    if (!_selection.hasSelection) {
      showSnackL(
        context,
        en: 'Long press on a book to start selection',
        ar: 'اضغط مطولًا على كتاب لبدء التحديد',
      );
      return;
    }

    final confirm = await showConfirmDialog(
      context,
      'Delete ${_selection.count} book${_selection.count > 1 ? "s" : ""}',
      message: 'Delete selected books?\nThis action cannot be undone.',
      confirmText: 'Delete Selected',
      destructive: true,
    );

    if (confirm != true) return;

    VoidCallback? stopSpinner;
    if (context.mounted) {
      stopSpinner = showSpinningDialog(
        context,
        L.p('Deleting...', 'جارٍ الحذف...'),
        textDir: L.dir,
      );
    }

    int deleted = _selection.selected.length;
    int failed = 0;

    try {
      final List<String> booksTobeDeleted = [];
      for (final i in _selection.selected) {
        booksTobeDeleted.add(ReaderInputPageData.bookEnsUnord[i].sha);
      }

      for (final b in booksTobeDeleted) {
        await ReaderInputPageData.delete(b);
      }
    } finally {
      _selection.clear();
      stopSpinner?.call();
    }

    _sortBooksRebuild();
    if (context.mounted) {
      showSnackL(
        context,
        en: failed > 0
            ? 'Deleted: $deleted, Failed: $failed'
            : 'Deleted: $deleted',
        ar: failed > 0
            ? 'تم الحذف: ${enToArNum(deleted)}، فشل: ${enToArNum(failed)}'
            : 'تم الحذف: ${enToArNum(deleted)}',
      );
    }
  }

  Future<void> _deleteAllBooks(BuildContext context) async {
    if (ReaderInputPageData.bookEntries.isEmpty) return;

    final confirm = await showConfirmDialog(
      context,
      L.p('Delete All', 'حذف الكل'),
      message: L.p(
        'Delete all books?\nThis action cannot be undone.',
        'حذف جميع الكتب؟\nلا يمكن التراجع عن هذا الإجراء.',
      ),
      confirmText: L.p('Delete All', 'حذف الكل'),
      destructive: true,
      useLClass: true,
    );

    if (confirm != true) return;

    VoidCallback? stopSpinner;
    if (context.mounted) {
      stopSpinner = showSpinningDialog(
        context,
        L.p('Deleting...', 'جارٍ الحذف...'),
      );
    }

    int deleted = ReaderInputPageData.bookEntries.length;
    const int failed = 0;

    try {
      await ReaderInputPageData.deleteAll();
    } finally {
      stopSpinner?.call();
      _selection.clear();
    }

    if (context.mounted) {
      setState(() {});
      postFrame((_) {
        showSnackL(
          context,
          en: failed > 0
              ? 'Deleted: $deleted, Failed: $failed'
              : 'Deleted: $deleted',
          ar: failed > 0
              ? 'تم الحذف: ${enToArNum(deleted)}، فشل: ${enToArNum(failed)}'
              : 'تم الحذف: ${enToArNum(deleted)}',
        );
      });
    }
  }

  Future<void> _exportBooks(BuildContext context) async {
    if (!ReaderInputPageData.inited ||
        ReaderInputPageData.bookEntries.isEmpty) {
      if (context.mounted) {
        showSnackL(
          context,
          en: 'No books to export',
          ar: 'لا توجد كتب للتصدير',
        );
      }
      return;
    }

    final confirmed = await showConfirmDialog(
      context,
      L.p('Export', 'تصدير'),
      message: L.p(
        'The entered books will be saved as a zip file. You can import them later. '
            'After exporting, make sure it was saved properly.\n\n'
            'Do you want to export?',
        /* ar */ 'سيتم حفظ الكتب المدخلة كملف مضغوط.'
            /* ar */ 'يمكنك استيرادها لاحقًا. بعد التصدير، تأكد من أنه حُفظ بشكل صحيح.\n\n'
            /* ar */ 'هل تريد التصدير؟',
      ),
      confirmText: L.p('Export', 'تصدير'),
      constraints: true,
      useLClass: true,
    );

    if (confirmed != true) return;

    VoidCallback? stopSpinner;
    if (!context.mounted) return;
    stopSpinner = showSpinningDialog(
      context,
      L.p('Exporting...', 'جارٍ التصدير...'),
    );

    final fileName = 'Arabic_Lexicons_books-${formatDateTimeForFileName()}.zip';

    final zipFileOut = path.join(
      (await getTemporaryDirectory()).path,
      fileName,
    );

    final List<String> names = [ReaderInputPageData.booksIndexName];
    final List<String> sourcefiles = [
      await ReaderInputPageData.saveBookEntriesToTmpFile(),
    ];

    for (final b in ReaderInputPageData.bookEntries) {
      names.add('${b.sha}.txt');
      sourcefiles.add(ReaderInputPageData.bookTextDest(b.sha));
    }

    List<int> zippedData;
    try {
      (_, zippedData) = await zipFiles(names, sourcefiles, zipFileOut);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$e');
      }

      stopSpinner.call();
      if (context.mounted) {
        showSnackL(
          context,
          en: 'Could not zip',
          ar: 'تعذر إنشاء الملف المضغوط',
        );
      }
      return;
    }

    stopSpinner.call();
    if (context.mounted) {
      showBackupOptionsButtomSheet(
        context,
        fileName: fileName,
        title: L.p('Export Ready', 'جاهز للتصدير'),
        saveDialogTitle: L.p('Save books', 'حفظ الكتب'),
        useLclass: true,
        filePaht: zipFileOut,
        fileData: zippedData,
        allowedExt: ['zip'],
      );
    }
  }

  Future<void> _importBooks(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      'Import',
      message:
          'You can only import books that were exported from this app.\n\n'
          'If a book in the backup already exists, it will be skipped.\n\n'
          'Do you want to import the backup?',
      confirmText: 'Select File',
      constraints: true,
    );

    if (confirmed != true) return;

    VoidCallback? stopSpinner;
    if (context.mounted) {
      stopSpinner = showSpinningDialog(
        context,
        L.p('Importing...', 'جارٍ الاستيراد...'),
      );
    }

    try {
      final result = await FilePicker.pickFile(dialogTitle: 'Import Books');

      if (result == null) return;

      // final data = await result.readAsByteStream().toList();
      final data = await result.readAsByteStream().fold<List<int>>(<int>[], (
        prev,
        chunk,
      ) {
        prev.addAll(chunk);
        return prev;
      });

      final archiveData = ZipDecoder().decodeBytes(data);

      final idxFile = archiveData.files
          .where((a) => a.name == ReaderInputPageData.booksIndexName)
          .firstOrNull;

      if (idxFile == null) {
        throw Exception('Corrupted file');
      }

      final bytes = idxFile.readBytes();
      if (bytes == null) {
        throw Exception('Corrupted file');
      }

      final books = ReaderInputPageData.parseBooks(
        LineSplitter.split(utf8.decode(bytes, allowMalformed: true)),
      );

      int added = 0;
      int skipped = 0;

      for (final b in books) {
        final exists = ReaderInputPageData.bookEntries.indexWhere(
          (bb) => b.sha == bb.sha,
        );
        if (exists > -1) {
          skipped++;
          continue;
        }

        final fileEntry = archiveData.files
            .where((a) => a.name == '${b.sha}.txt')
            .firstOrNull;

        if (fileEntry == null) {
          skipped++;
          continue;
        }

        final fileBytes = fileEntry.readBytes();
        if (fileBytes == null) {
          skipped++;
          continue;
        }

        try {
          final data = utf8.decode(fileBytes, allowMalformed: false);
          if (data.isEmpty) throw Exception('empty');

          await ReaderInputPageData.add(b, data, replace: false);
          added++;
        } catch (_) {
          skipped++;
        }
      }

      _sortBooksRebuild();

      if (context.mounted) {
        showSnackL(
          context,
          en: 'Added: $added Skipped: $skipped',
          ar: 'تمت الإضافة: ${enToArNum(added)}، تم التخطي: ${enToArNum(skipped)}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('while reading zip: $e');
      }
      if (context.mounted) {
        showSnackL(context, en: 'Import failed', ar: 'فشل الاستيراد');
      }
    } finally {
      stopSpinner?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final th = theme.textTheme;
    final cs = theme.colorScheme;

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
        drawer: buildDrawer(context),
        body: GestureStack(
          child: Theme(
            data: Theme.of(context).copyWith(
              textTheme: Theme.of(
                context,
              ).textTheme.apply(fontFamily: L.arFontIf),
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: Directionality(
                textDirection: L.dir,
                child: CustomScrollView(
                  slivers: [
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: SliverAppBar(
                        floating: true,
                        snap: appConf.hideAppbar,
                        pinned: !appConf.hideAppbar,
                        title: _selection.appBarTitle(
                          L.p('Reader Input', 'مدخل القارئ'),
                          style: L.arStyleIf,
                        ),
                        actions: [
                          if (_selection.hasSelection)
                            ..._selection.genricAppBarActions(
                              context,
                              all: () => [
                                for (
                                  int i = 0;
                                  i < ReaderInputPageData.bookEntries.length;
                                  i++
                                )
                                  i,
                              ],
                              rm: null,
                            ),
                          // [
                          // IconButton(
                          //   tooltip: L.p('Select all', 'تحديد الكل'),
                          //   icon: const Icon(Icons.checklist),
                          //   onPressed: () => setState(() {
                          //     for (final b
                          //         in ReaderInputPageData.booksUnord) {
                          //       b.selected = true;
                          //     }
                          //   }),
                          // ),
                          // IconButton(
                          //   tooltip: L.p('Clear Selection', 'إلغاء التحديد'),
                          //   icon: const Icon(Icons.clear_all),
                          //   onPressed: () => setState(() {
                          //     _stopSelectionMode();
                          //   }),
                          // ),
                          // ],
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (value) async {
                              switch (value) {
                                case 'delete_selected':
                                  await _deleteSelectedBooks(context);
                                  break;
                                case 'delete_all':
                                  _selection.clear();
                                  await _deleteAllBooks(context);
                                  break;
                                case 'export':
                                  _selection.clear();
                                  await _exportBooks(context);
                                  break;
                                case 'import':
                                  _selection.clear();
                                  await _importBooks(context);
                                  break;

                                case 'open-demo':
                                  await _openDemoTxt(context);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'export',
                                child: Row(
                                  children: [
                                    const Icon(Icons.upload_file),
                                    const SizedBox(width: 10),
                                    Text(L.p('Export', 'تصدير')),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'import',
                                child: Row(
                                  children: [
                                    const Icon(Icons.download),
                                    const SizedBox(width: 10),
                                    Text(L.p('Import', 'استيراد')),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'delete_all',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete_sweep),
                                    const SizedBox(width: 10),
                                    Text(L.p('Delete All', 'حذف الكل')),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete_selected',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete),
                                    const SizedBox(width: 10),
                                    Text(L.p('Delete Selected', 'حذف المحدد')),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'open-demo',
                                child: Row(
                                  children: [
                                    const Icon(Icons.text_snippet_outlined),
                                    const SizedBox(width: 10),
                                    Text(L.p('Demo Text', 'نص تجريبي')),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SliverPadding(
                      padding: padd.copyWith(top: 16, bottom: 16),
                      sliver: SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: _controller,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.start,
                                maxLines: 4,
                                style: L.arStyleSized,
                                decoration: InputDecoration(
                                  hintText: L.p(
                                    'Paste text here…',
                                    'الصق النص هنا…',
                                  ),
                                  hintTextDirection: L.dir,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Wrap(
                                  spacing: 8,
                                  alignment: WrapAlignment.center,
                                  runAlignment: WrapAlignment.center,
                                  runSpacing: 6,
                                  children: [
                                    FilterChip(
                                      showCheckmark: false,
                                      avatar: const Icon(Icons.save, size: 18),
                                      label: Text(L.p('Save', 'حفظ')),
                                      selected: !_isTempMode,
                                      onSelected: (_) => setState(
                                        () => _isTempMode = !_isTempMode,
                                      ),
                                    ),
                                    FilterChip(
                                      showCheckmark: false,
                                      avatar: const Icon(
                                        Icons.music_note,
                                        size: 18,
                                      ),
                                      label: Text(L.p('Qasidah', 'قصيدة')),
                                      selected: _isQasidahMode,
                                      onSelected: (v) =>
                                          setState(() => _isQasidahMode = v),
                                    ),
                                    FilterChip(
                                      showCheckmark: false,
                                      avatar: const Icon(
                                        Icons.push_pin,
                                        size: 18,
                                      ),
                                      label: Text(L.p('Pin', 'تثبيت')),
                                      selected: !_isTempMode & _isPinned,
                                      onSelected: _isTempMode
                                          ? null
                                          : (v) =>
                                                setState(() => _isPinned = v),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 38,
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final txt = await getClipboardText();
                                        if (txt != null) {
                                          _controller.text =
                                              _controller.text + txt;
                                        }
                                      },
                                      icon: const Icon(Icons.paste),
                                      label: Text(L.p('Paste', 'لصق')),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    height: 38,
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        if (_controller.text.isEmpty) return;

                                        final res = await showConfirmDialog(
                                          context,
                                          L.p(
                                            'Clear all text?',
                                            'مسح كل النص؟',
                                          ),
                                          confirmText: L.p('Clear', 'مسح'),
                                          useLClass: true,
                                        );
                                        if (res == true) _controller.clear();
                                      },
                                      icon: const Icon(Icons.clear),
                                      label: Text(L.p('Clear', 'مسح')),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: 160,
                                height: 52,
                                child: FilledButton.icon(
                                  label: Text(
                                    L.p('Go', 'ابدأ'),
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  icon: const Icon(Icons.start),
                                  onPressed: () => _showText(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (ReaderInputPageData.bookEntries.isEmpty)
                      Directionality(
                        textDirection: L.dir,
                        child: SliverPadding(
                          padding: padd.copyWith(top: 10),
                          sliver: SliverToBoxAdapter(
                            child: Container(
                              padding: const EdgeInsets.all(18.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.00),
                                color: cs.surfaceContainer,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0,
                                    ),
                                    child: Text(
                                      L.p(
                                        'There are no book entries.\n'
                                            'Open demo text to check out the reader',
                                        'لا توجد كتب. افتح نصا تجريبيا لتجربة القارئ',
                                      ),
                                      style: th.bodyMedium
                                          ?.copyWith(color: cs.secondary)
                                          .arIf,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  SizedBox(
                                    height: 42,
                                    child: FilledButton.icon(
                                      icon: const Icon(
                                        Icons.text_snippet_outlined,
                                      ),
                                      label: Text(
                                        L.p(
                                          'Open Demo Text',
                                          'افتح نصا تجريبيا',
                                        ),
                                        style: L.arStyleIf,
                                      ),
                                      onPressed: () => _openDemoTxt(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    else ...[
                      SliverPadding(
                        padding: padd.copyWith(top: 10, bottom: 8),
                        sliver: SliverToBoxAdapter(
                          child: Directionality(
                            textDirection: L.dir,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  L.p(
                                    'Books [${ReaderInputPageData.bookEntries.length}]',
                                    'الكتب [${enToArNum(ReaderInputPageData.bookEntries.length)}]',
                                  ),
                                  style: th.titleLarge?.arIf?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                FilterChip(
                                  labelStyle: L.arStyleIf,
                                  avatar: const Icon(Icons.swap_vert, size: 18),
                                  label: Text(
                                    _isShowEntrieNewToOld
                                        ? L.p(
                                            'New to Old',
                                            'من الجديد إلى القديم',
                                          )
                                        : L.p(
                                            'Old to New',
                                            'من القديم إلى الجديد',
                                          ),
                                  ),
                                  selected: false,
                                  showCheckmark: false,
                                  onSelected: (_) {
                                    setState(() {
                                      _selection.clear(runAfterChange: false);
                                      _isShowEntrieNewToOld =
                                          !_isShowEntrieNewToOld;
                                      ReaderInputPageData.setBookUnord(
                                        match: _searchText,
                                        newToOld: _isShowEntrieNewToOld,
                                      );
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: SliverPadding(
                          padding: padd.copyWith(top: 0, bottom: 12),
                          sliver: SliverToBoxAdapter(
                            child: TextField(
                              controller: _searchController,
                              style: L.arStyleSized,
                              onChanged: (input) {
                                setState(() {});
                                final s = ArabicNormalizer.cleanLineForSearch(
                                  input,
                                );
                                if (s == _searchText) return;

                                _searchText = s;
                                ReaderInputPageData.setBookUnord(
                                  match: s,
                                  newToOld: _isShowEntrieNewToOld,
                                );
                                if (_selection.hasSelection) {
                                  _selection.clear(runAfterChange: false);
                                }
                                setState(() {});
                              },
                              decoration: InputDecoration(
                                suffixIcon: _searchController.text.isEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.help),
                                        onPressed: () {
                                          showCleanLineForSearchInfo(context);
                                        },
                                      )
                                    : IconButton(
                                        tooltip: L.p(
                                          'Clear search',
                                          'مسح البحث',
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          _searchText = "";
                                          ReaderInputPageData.setBookUnord(
                                            match: "",
                                            newToOld: _isShowEntrieNewToOld,
                                          );
                                          setState(() {});
                                        },
                                        icon: const Icon(Icons.clear),
                                      ),
                                hintText: L.p(
                                  'Search for a book…',
                                  'ابحث عن كتاب…',
                                ),
                                hintTextDirection: L.dir,
                              ),
                              textAlign: TextAlign.start,
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ),
                      ),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: SliverPadding(
                          padding: padd.copyWith(bottom: 30, top: 0),
                          sliver: ReaderInputPageData.bookEnsUnord.isEmpty
                              ? SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 24.0),
                                    child: Column(
                                      spacing: 4,
                                      children: [
                                        Text(
                                          L.p(
                                            'No matches for',
                                            /* ar */ 'لا توجد نتائج لـ',
                                          ),
                                          textDirection: L.dir,
                                          style: L.arStyleIf,
                                        ),
                                        Text(
                                          '"$_searchText"',
                                          textDirection: TextDirection.rtl,
                                          softWrap: true,
                                          style: L.arStyle,
                                        ),
                                      ],
                                      // textDirection: L.dir,
                                    ),
                                  ),
                                )
                              : SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final en = ReaderInputPageData
                                          .bookEnsUnord[index];
                                      final style = th.titleMedium!.ar;

                                      Widget txt;
                                      if (_searchText.isEmpty) {
                                        txt = Text(
                                          en.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textDirection: TextDirection.rtl,
                                          textAlign: TextAlign.right,
                                          style: style,
                                        );
                                      } else {
                                        final (:pre, :suf) = en.titleCl
                                            .splitOnce(_searchText);

                                        txt = Text.rich(
                                          TextSpan(
                                            children: [
                                              if (pre != null)
                                                TextSpan(text: pre),
                                              TextSpan(
                                                text: _searchText,
                                                style: TextStyle(
                                                  color: cs.error,
                                                  // fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (suf != null)
                                                TextSpan(text: suf),
                                            ],
                                            style: style,
                                          ),
                                        );
                                      }

                                      final selected =
                                          _selection.hasSelection &&
                                          _selection.isSelected(index);
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Material(
                                          color: selected
                                              ? cs.secondaryContainer
                                              : cs.surfaceContainerLow,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            side: BorderSide(
                                              color: cs.outlineVariant,
                                            ),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: ListTile(
                                            selected: selected,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                            title: txt,
                                            trailing: _selection.hasSelection
                                                ? Checkbox(
                                                    value: _selection
                                                        .isSelected(index),
                                                    onChanged: (v) => _selection
                                                        .toggle(index),
                                                  )
                                                : Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        tooltip: en.pinned
                                                            ? L.p(
                                                                'Unpin',
                                                                'إلغاء التثبيت',
                                                              )
                                                            : L.p(
                                                                'Pin',
                                                                'تثبيت',
                                                              ),
                                                        icon: Icon(
                                                          en.pinned
                                                              ? Icons.push_pin
                                                              : Icons
                                                                    .push_pin_outlined,
                                                        ),
                                                        style: IconButton.styleFrom(
                                                          backgroundColor:
                                                              en.pinned
                                                              ? cs.inversePrimary
                                                                    .withAlpha(
                                                                      80,
                                                                    )
                                                              : null,
                                                          foregroundColor:
                                                              en.pinned
                                                              ? cs.primary
                                                              : null,
                                                        ),
                                                        onPressed: () async {
                                                          if (en.pinned) {
                                                            final confirm = await showConfirmDialog(
                                                              context,
                                                              L.p(
                                                                'Unpin a book',
                                                                'إلغاء تثبيت كتاب',
                                                              ),
                                                              message: L.p(
                                                                'Unpin: ${en.title}',
                                                                'إلغاء التثبيت: ${en.title}',
                                                              ),
                                                              confirmText: L.p(
                                                                'Unpin',
                                                                'إلغاء التثبيت',
                                                              ),
                                                              destructive: true,
                                                              useLClass: true,
                                                              constraints:
                                                                  en
                                                                      .title
                                                                      .length >
                                                                  50,
                                                            );
                                                            if (confirm !=
                                                                true) {
                                                              return;
                                                            }
                                                          }

                                                          final pinned =
                                                              await _tglPinBookEntries(
                                                                en.sha,
                                                              ) ??
                                                              false;
                                                          if (context.mounted) {
                                                            final p = pinned
                                                                ? L.p(
                                                                    'Pinned',
                                                                    'تم التثبيت',
                                                                  )
                                                                : L.p(
                                                                    'Unpinned',
                                                                    'تم إلغاء التثبيت',
                                                                  );
                                                            showSnack(
                                                              context,
                                                              '$p: ${en.title}',
                                                              textStyle:
                                                                  L.arStyleIf,
                                                              textDir: L.dir,
                                                            );
                                                          }
                                                        },
                                                      ),
                                                      IconButton(
                                                        tooltip: L.p(
                                                          'Delete book',
                                                          'حذف الكتاب',
                                                        ),
                                                        icon: const Icon(
                                                          Icons.delete_outline,
                                                        ),
                                                        onPressed: () async {
                                                          final confirm =
                                                              await showConfirmDialog(
                                                                context,
                                                                L.p(
                                                                  'Delete a book',
                                                                  'حذف كتاب',
                                                                ),
                                                                message: L.p(
                                                                  'Delete: ${en.title}',
                                                                  'حذف: ${en.title}',
                                                                ),
                                                                confirmText: L
                                                                    .p(
                                                                      'Delete',
                                                                      'حذف',
                                                                    ),
                                                                destructive:
                                                                    true,
                                                                constraints:
                                                                    en
                                                                        .title
                                                                        .length >
                                                                    50,
                                                                useLClass: true,
                                                              );
                                                          if (confirm != true) {
                                                            return;
                                                          }

                                                          await _deleteFile(en);
                                                          if (context.mounted) {
                                                            showSnackL(
                                                              context,
                                                              en: 'Deleted: ${en.title}',
                                                              ar: 'تم الحذف: ${en.title}',
                                                            );
                                                          }
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                            onTap: () {
                                              if (_selection.hasSelection) {
                                                _selection.toggle(index);
                                                return;
                                              }
                                              _openBook(context, en);
                                            },
                                            onLongPress: () {
                                              if (_searchText.isEmpty) {
                                                _selection.toggle(index);
                                              }
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    childCount:
                                        ReaderInputPageData.bookEnsUnord.length,
                                  ),
                                ),
                        ),
                      ),
                      // const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _tglPinBookEntries(String hash) async {
    return await ReaderInputPageData.togglePinned(hash);
  }
}
