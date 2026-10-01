import 'dart:async';

import 'package:arabic_lexicons/alphabets.dart';
import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/multi_selection.dart';
import 'package:arabic_lexicons/review/provider.dart';
import 'package:arabic_lexicons/main_widgets.dart';
import 'package:arabic_lexicons/utils/toast_snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RevWordListPage extends StatefulWidget {
  const RevWordListPage({super.key, required this.rr});
  final ReviewRepo rr;

  @override
  State<RevWordListPage> createState() => _RevWordListPageState();
}

class _RevWordListPageState extends State<RevWordListPage> {
  late final ReviewRepo _rr = widget.rr;
  final _search = TextEditingController();
  Timer? _debounce;
  List<RevItem> _items = [];
  bool _loading = true;
  bool _showOnlyHidden = false;

  late final _selection = SelectionController<String>(() {
    if (mounted) {
      setState(() {});
    }
  });

  @override
  void initState() {
    super.initState();

    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _addWordTc.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final r = await _rr.list(q: _search.text.trim(), hidden: _showOnlyHidden);
    if (!mounted) return;
    setState(() {
      _items = r;
      _loading = false;
    });
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), _load);
  }

  void _showActions(String word, RevItem i) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isDismissible: true,
      useSafeArea: true,
      constraints: maxUiWidth,
      builder: (ctx) => Padding(
        padding: scrollPaddingBottmSheet(context, sides: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              word,
              style: Theme.of(context).textTheme.headlineMedium?.ar,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.edit_calendar_outlined),
              title: const Text('Edit days'),
              onTap: () {
                Navigator.pop(ctx);
                _editDays(i);
              },
            ),
            ListTile(
              leading: Icon(
                i.hidden
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              title: Text(i.hidden ? 'Unhide' : 'Hide'),
              onTap: () {
                Navigator.pop(ctx);
                _toggleHidden(i);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(ctx);
                _delete(context, i);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _dueText(RevItem i) {
    final diff = Duration(
      milliseconds: i.due - DateTime.now().millisecondsSinceEpoch,
    );

    final String when;
    if (diff.isNegative || diff.inMinutes < 1) {
      when = 'Now';
    } else if (diff.inHours < 1) {
      when = '${diff.inMinutes}m';
    } else if (diff.inDays < 1) {
      final minutes = diff.inMinutes % 60;
      if (minutes > 0) {
        when = '${diff.inHours}h ${minutes}m';
      } else {
        when = '${diff.inHours}h';
      }
    } else {
      final h = diff.inHours % 24;
      if (h > 0) {
        when = '${diff.inDays}d ${h}h';
      } else {
        when = '${diff.inDays}d';
      }
    }

    return when;
    // return '$when · interval ${i.lastInterval}d';
  }

  Future<void> _editDays(RevItem i) async {
    final days = await showDialog<int>(
      context: context,
      builder: (_) => DaysDialog(initial: i.lastInterval),
    );
    if (days == null) return;
    await _rr.setDays(i.word, days);
    _load();
  }

  Future<void> _toggleHidden(RevItem i) async {
    await _rr.setHidden(i.word, !i.hidden);
    _load();
  }

  Future<bool> _delete(BuildContext ctx, RevItem i) async {
    final confirm = await showConfirmDialog(ctx, 'Delete word ${i.word}?');
    if (confirm != true) return false;

    await _rr.delete(i.word);
    await _load();
    if (!mounted) return true;
    MsgSv.showSnackbar(
      Text('Deleted ${i.word}'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () async {
          await _rr.put(i);
          _load();
        },
      ),
    );
    return true;
  }

  final _addWordTc = TextEditingController();

  Future<void> _add() async {
    _addWordTc.clear();

    final wordRaw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add word'),
        content: TextField(
          controller: _addWordTc,
          autofocus: true,
          textDirection: TextDirection.rtl,
          style: L.arStyleSized,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onSubmitted: (v) {
            Navigator.pop(ctx, v.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _addWordTc.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (wordRaw == null) return;
    final word = ArabicNormalizer.keepOnlyAr(wordRaw);

    if (word.isEmpty) return;
    final added = await _rr.add(word);

    if (!mounted) return;
    if (!added) {
      MsgSv.showToast('Already exists');
    } else {
      MsgSv.showToast('Word Added: $word');
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final padd = appConf.readerPadd(context);

    return Scaffold(
      appBar: AppBar(
        title: _selection.appBarTitle('Words (${_items.length})'),
        actions: _selection.hasSelection
            ? [
                ..._selection.genricAppBarActions(
                  context,
                  all: () => _items.map((e) => e.word),
                  rm: (x) async {
                    await _rr.rmAll(x);
                  },
                ),
                IconButton(
                  tooltip: _showOnlyHidden
                      ? 'Un-hide selected'
                      : 'Hide selected',
                  icon: Icon(
                    _showOnlyHidden ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () async {
                    final res = await showConfirmDialog(
                      context,
                      '${_showOnlyHidden ? 'Show' : 'Hide'} selected words?',
                    );

                    if (res != true) return;

                    for (final w in _selection.selected) {
                      _rr.setHidden(w, !_showOnlyHidden);
                    }
                    _load();
                    _selection.clear();
                  },
                ),
              ]
            : [
                IconButton(
                  tooltip: 'Add a new word',
                  onPressed: _add,
                  icon: const Icon(Icons.add),
                ),
                IconButton(
                  tooltip: 'Show only hidden touggle',
                  onPressed: () {
                    setState(() {
                      _showOnlyHidden = !_showOnlyHidden;
                    });
                    MsgSv.showToast(
                      _showOnlyHidden
                          ? 'Showing only hidden words'
                          : 'Showing non-hidden words',
                    );

                    _load();
                  },
                  icon: _showOnlyHidden
                      ? Icon(Icons.visibility_off)
                      : Icon(Icons.visibility),
                ),
              ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: padd.left,
                vertical: 14,
              ),
              child: TextField(
                // readOnly: _selection.hasSelection,
                controller: _search,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.start,
                style: L.arStyleSized,
                decoration: InputDecoration(
                  hintText: L.p('Search Words', 'ابحث'),
                  hintTextDirection: L.dir,
                  prefixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            if (_search.text.isEmpty) return;
                            setState(() {
                              _search.clear();
                            });
                            _load();
                            // this is when it's focued but keyboard is not oppended
                          },
                          icon: Icon(Icons.clear),
                        ),
                ),
                onChanged: (v) {
                  final c = ArabicNormalizer.keepOnlyAr(v);
                  setState(() {
                    if (c != v) _search.text = c;
                  });
                  _onSearch(v);
                },
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                  ? const Center(child: Text('No words'))
                  : Directionality(
                      textDirection: TextDirection.rtl,
                      child: ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          padd.right,
                          4,
                          padd.right,
                          scrollPadding.bottom,
                        ),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 2),
                        itemBuilder: (_, idx) {
                          final i = _items[idx];
                          final selected = _selection.isSelected(i.word);

                          final r = BorderRadius.vertical(
                            top: Radius.circular(idx == 0 ? 20 : 4),
                            bottom: Radius.circular(
                              idx == _items.length - 1 ? 20 : 4,
                            ),
                          );

                          final child = Material(
                            color: selected
                                ? cs.surfaceContainerHigh
                                : cs.surfaceContainerLow,
                            child: ListTile(
                              minVerticalPadding: 16,
                              selected: selected,
                              onLongPress: () {
                                _selection.toggle(i.word);
                              },
                              onTap: () {
                                if (_selection.hasSelection) {
                                  _selection.toggle(i.word);
                                  return;
                                }
                                _showActions(i.word, i);
                              },
                              title: Text(
                                i.word,
                                textDirection: TextDirection.rtl,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontFamily: L.arFont,
                                      color: i.hidden ? cs.outline : null,
                                    ),
                              ),
                              trailing: _selection.hasSelection
                                  ? Checkbox(
                                      onChanged: (_) {
                                        _selection.toggle(i.word);
                                      },
                                      value: selected,
                                    )
                                  : Text(
                                      i.hidden ? 'Hidden' : _dueText(i),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: i.hidden
                                                ? cs.outline
                                                : cs.onSurfaceVariant,
                                          ),
                                    ),
                            ),
                          );
                          return ClipRRect(
                            borderRadius: r,
                            child: _selection.hasSelection
                                ? child
                                : Dismissible(
                                    key: ValueKey(i.word),
                                    background: Container(
                                      color: cs.secondaryContainer,
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 24),
                                      child: Icon(
                                        i.hidden
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: cs.onSecondaryContainer,
                                      ),
                                    ),
                                    secondaryBackground: Container(
                                      color: cs.errorContainer,
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.only(left: 24),
                                      child: Icon(
                                        Icons.delete,
                                        color: cs.onErrorContainer,
                                      ),
                                    ),
                                    confirmDismiss: (dir) async {
                                      if (dir == DismissDirection.startToEnd) {
                                        await _toggleHidden(i);
                                        return true; // keep the row, just toggle
                                      }
                                      return _delete(context, i);
                                    },
                                    child: child,
                                  ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class DaysDialog extends StatefulWidget {
  final int initial;
  const DaysDialog({super.key, required this.initial});

  @override
  State<DaysDialog> createState() => _DaysDialogState();
}

class _DaysDialogState extends State<DaysDialog> {
  late final _ctrl = TextEditingController(
    text: widget.initial > 0 ? '${widget.initial}' : '',
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final d = int.tryParse(_ctrl.text.trim());
    if (d == null || d < 0) return;
    Navigator.pop(context, d);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Show again after (days)'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          suffixText: 'days',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
