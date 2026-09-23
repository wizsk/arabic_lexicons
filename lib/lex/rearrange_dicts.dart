import 'dart:io';

import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/main_widgets.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:arabic_lexicons/utils/toast_snack.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// TODO: we can remove dicts but in the current lextion data the selectedDict will be whatever we don't care for now.
Future<void> showDictReorderScreen(
  BuildContext context, {
  required VoidCallback? after,
}) async {
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => DictReorderSheet()),
  );
  after?.call();
}

class DictReorderSheet extends StatefulWidget {
  const DictReorderSheet({super.key});

  @override
  State<DictReorderSheet> createState() => _DictReorderSheetState();
}

class _DictReorderSheetState extends State<DictReorderSheet> {
  late List<Dict> _dicts; // active, ordered
  List<Dict> _removed = []; // hidden, available to re-add
  bool _showRemoved = false;

  @override
  void initState() {
    super.initState();
    _dicts = List<Dict>.from(allDictsOrd);
    for (final d in allDicts) {
      if (_dicts.contains(d)) continue;
      _removed.add(d);
    }
  }

  Future<void> _setShowEnglishNames(BuildContext context) async {
    if (!L.isAr) {
      final res = await showConfirmDialog(
        context,
        'Show More Arabic',
        message: 'Do you want more Arabic to be used through out the app?',
        constraints: true,
      );
      if (res != true) return;
    }

    await appConf.saveUseMoreArabicToggle();
    setState(() {});
  }

  void _resetOrder() {
    setState(() {
      _dicts = List<Dict>.from(allDicts);
      _removed = [];
      _showRemoved = false;
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _dicts.removeAt(oldIndex);
      _dicts.insert(newIndex, item);
    });
  }

  void _removeDict(int index) {
    if (_dicts.length <= 1) {
      MsgSv.showSnackbarMsg('Keep at least one dictionary');
      return;
    }
    setState(() {
      final item = _dicts.removeAt(index);
      _removed.add(item);
    });
  }

  void _restoreDict(int index) {
    setState(() {
      final item = _removed.removeAt(index);
      _dicts.add(item);
      if (_removed.isEmpty) _showRemoved = false;
    });
  }

  Widget _mainDictsRearrange(ThemeData theme) {
    final scheme = theme.colorScheme;
    final th = theme.textTheme;

    final titleStyle = th.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
      fontFamily: L.arFontIf,
    );

    final subtitleStyle = th.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontFamily: L.isAr ? null : L.arFont,
    );
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      itemCount: _dicts.length,
      onReorderItem: _reorder,
      proxyDecorator: (child, index, animation) {
        return Material(
          color: Colors.transparent,
          elevation: 4,
          shadowColor: scheme.shadow,
          borderRadius: BorderRadius.circular(16),
          child: Directionality(textDirection: L.dir, child: child),
        );
      },
      itemBuilder: (context, index) {
        final dict = _dicts[index];
        final primaryText = L.pr(dict.ar, dict.en);
        final secondaryText = L.pr(dict.en, dict.ar);

        return Dismissible(
          key: ObjectKey(dict),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) async {
            _removeDict(index);
            return false; // we manage the list ourselves
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.remove_circle_outline,
              color: scheme.onErrorContainer,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.outlineVariant, width: 1),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: scheme.primary.withAlpha(220),
                  foregroundColor: scheme.onPrimary,
                  child: Text(
                    L.p('${index + 1}', enToArNum(index + 1)),
                    style: L.arStyleOrNew.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                title: Text(
                  primaryText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
                subtitle: Text(
                  secondaryText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: subtitleStyle,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6.0,
                  children: [
                    IconButton(
                      tooltip: L.p('Remove', 'إزالة'),
                      onPressed: () => _removeDict(index),
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: scheme.error,
                      ),
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final th = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          L.p('Lexicon order', 'ترتيب المعاجم'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: L.arStyleIf,
        ),

        actions: [
          IconButton(
            // visualDensity: VisualDensity.compact,
            tooltip: 'Toggle English/Arabic UI',
            onPressed: () => _setShowEnglishNames(context),
            icon: L.pr(
              Icon(Icons.language_rounded),
              Icon(Icons.translate_rounded),
            ),
          ),
          IconButton(
            // visualDensity: VisualDensity.compact,
            tooltip: 'Reset order',
            onPressed: _resetOrder,
            icon: const Icon(Icons.restore_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: maxUiWidth,
            child: Directionality(
              textDirection: L.dir,
              child: Column(
                children: [
                  Expanded(child: _mainDictsRearrange(theme)),

                  Divider(height: 1, color: scheme.outlineVariant),
                  if (_removed.isNotEmpty) ...[
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showRemoved = !_showRemoved;
                        });
                      },
                      child: Ink(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              L.p(
                                'Removed (${_removed.length})',
                                'المُزالة (${_removed.length})',
                              ),
                              style: th.labelLarge?.arIf?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),

                            if (_showRemoved)
                              Icon(Icons.keyboard_arrow_down)
                            else
                              Icon(Icons.keyboard_arrow_up),
                          ],
                        ),
                      ),
                    ),
                    if (_showRemoved)
                      Align(
                        alignment: L.alignment,
                        child: ConstrainedBox(
                          key: const PageStorageKey('removed-dicts-readd'),
                          constraints: const BoxConstraints(maxHeight: 120),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8.0,
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.start,
                              spacing: 6.0,
                              runSpacing: 6.0,
                              children: listBuilder(
                                items: _removed,
                                itemBuilder: (dict, index) {
                                  // final dict = _removed[index];
                                  final primaryText = L.pr(dict.ar, dict.en);

                                  return RawChip(
                                    label: Text(
                                      primaryText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: L.arStyleIf,
                                    ),
                                    onSelected: (_) => _restoreDict(index),
                                    avatar: Icon(
                                      Icons.add_circle_outline,
                                      // color: scheme.primary,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (_showRemoved) const SizedBox(height: 8),
                  ] else
                    const SizedBox(height: 8),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              textStyle: TextStyle(fontFamily: L.arFontIf),
                            ),
                            child: Text(L.p('Cancel', 'إلغاء')),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: () async {
                              allDictsOrd = _dicts;
                              // allDictsRemoved = _removed;
                              await saveDictOrd();
                              if (context.mounted) Navigator.pop(context);
                            },
                            icon: const Icon(Icons.check_rounded),
                            style: FilledButton.styleFrom(
                              textStyle: TextStyle(fontFamily: L.arFontIf),
                            ),
                            label: Text(L.p('Save order', 'حفظ الترتيب')),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<String> dictOrdFilePath() async {
  final d = await getApplicationDocumentsDirectory();
  final p = join(d.path, 'dict_ord.txt');
  return p;
}

// const _removedMarker = '---REMOVED---';

Future<void> saveDictOrd() async {
  final isDefault = _sameOrder(allDictsOrd, allDicts);

  try {
    final file = File(await dictOrdFilePath());
    if (isDefault) {
      await file.delete();
    } else {
      final lines = allDictsOrd.map((d) => d.table);
      await file.writeAsString(lines.join('\n'));
    }
  } catch (_) {}
}

bool _sameOrder(List<Dict> a, List<Dict> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

Future<void> setDictOrdFromFile() async {
  List<String> lines;
  try {
    final file = await dictOrdFilePath();
    lines = await File(file).readAsLines();

    final ordered = <Dict>{};

    for (var l in lines) {
      l = l.trim();
      if (l.isEmpty) continue;

      final idx = allDicts.indexWhere((d) => d.table == l);
      if (idx < 0) continue;

      ordered.add(allDicts[idx]);
    }

    // Any dict not mentioned at all (e.g. newly added in an app update)
    // shows up by default, appended to the active list.
    // for (final d in allDicts) {
    //   if (!ordered.contains(d) && !removed.contains(d)) {
    //     ordered.add(d);
    //   }
    // }

    allDictsOrd = List.from(ordered);
  } catch (_) {
    allDictsOrd = allDicts;
    // allDictsRemoved = [];
    return;
  }
}
