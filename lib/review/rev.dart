import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/review/list.dart';
import 'package:arabic_lexicons/review/provider.dart';
import 'package:arabic_lexicons/main_widgets.dart';
import 'package:arabic_lexicons/reader/find_word.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:arabic_lexicons/utils/toast_snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _customChoices = [1, 2, 3, 5, 7, 10, 14, 21, 30, 60, 90];

/// Persistence for flashcards. Table is created lazily.

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  RevOrder _ord = RevOrder.old;
  String? _word;
  List<int>? _intervals;
  bool _loading = true;
  late final ReviewRepo _repo;

  @override
  void initState() {
    super.initState();
    ReviewRepo.init().then((r) {
      _repo = r;
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final res = await _repo.next(_ord, _showNoDueWords);

    if (!mounted) return;
    setState(() {
      _word = res?.word;
      _intervals = res?.intervals;
      _loading = false;
    });
  }

  Future<void> _showAfter(int days) async {
    final w = _word;
    if (w == null) return;
    await _repo.showAfter(w, days);
    await _load();
  }

  Future<void> _customAfter() async {
    final days = await showDialog<int>(
      context: context,
      builder: (_) => const _CustomDaysDialog(),
    );
    if (days != null) await _showAfter(days);
  }

  Future<void> _dontShow() async {
    final w = _word;
    if (w == null) return;
    final ok = await showConfirmDialog(
      context,
      'Hide word?',
      message: 'Do you want to hide $w?',
      confirmText: 'Hide',
      fontFam: L.arFont,
    );
    if (ok == true) {
      await _repo.hide(w);
      await _load();
    }
  }

  Widget _ordLabel(RevOrder o) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(switch (o) {
        RevOrder.old => Icons.history_rounded,
        RevOrder.newest => Icons.update_rounded,
        RevOrder.rand => Icons.shuffle_rounded,
      }),
      const SizedBox(width: 8),
      Text(switch (o) {
        RevOrder.old => 'Oldest',
        RevOrder.newest => 'Newest',
        RevOrder.rand => 'Random',
      }),
    ],
  );

  bool _showNoDueWords = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: appConf.readerSurface(context),
      drawer: buildDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Review'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.image_search),
            onPressed: _word == null
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FindWordReaderPage(word: _word ?? ''),
                      ),
                    );
                    // TODO: look into it. should we load or not
                    _load();
                  },
          ),
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RevWordListPage(rr: _repo)),
              );
              _load();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Order',
            initialValue: _ord.name,
            onSelected: (o) {
              if (o == 'no-due-tgl') {
                _showNoDueWords = !_showNoDueWords;
              } else {
                _ord = RevOrder.values.firstWhere(
                  (e) => e.name == o,
                  orElse: () => _ord,
                );
              }
              // });
              _load();
            },
            itemBuilder: (_) => [
              for (final o in RevOrder.values)
                PopupMenuItem(value: o.name, child: _ordLabel(o)),

              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'no-due-tgl',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _showNoDueWords
                        ? Icon(Icons.check_box)
                        : Icon(Icons.check_box_outline_blank_outlined),
                    SizedBox(width: 6),
                    Text('Show only new'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: appConf.readerPadd(context).copyWith(bottom: 16),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            _word ?? 'لا موجود',
                            textAlign: TextAlign.center,
                            style: tt.displaySmall?.copyWith(
                              fontFamily: L.arFont,
                              color: _word == null
                                  ? cs.onSurfaceVariant
                                  : cs.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_word != null) ...[
                    const Divider(height: 0),
                    // const SizedBox(height: 16),
                    // Text(
                    //   'Show After',
                    //   style: tt.labelLarge?.copyWith(
                    //     color: cs.onSurfaceVariant,
                    //   ),
                    // ),

                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        Tooltip(
                          message: 'Repeat. Show again after 10m',
                          child: FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(82, 54),
                            ),
                            onPressed: () => _showAfter(-1),
                            child: const Text('${repeatDurMin}m'),
                          ),
                        ),
                        if (_intervals != null)
                          for (final d in _intervals!)
                            FilledButton(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(82, 54),
                              ),
                              onPressed: () => _showAfter(d),
                              child: Text(
                                '${d}d',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _customAfter,
                          icon: const Icon(Icons.edit_calendar, size: 18),
                          label: Text("Set"),
                        ),
                        OutlinedButton.icon(
                          onPressed: _dontShow,
                          // tooltip: 'Hide this word from review',
                          icon: const Icon(Icons.visibility_off_outlined),
                          label: Text('Hide'),
                        ),
                        FilledButton.tonalIcon(
                          label: Text('Lexicon'),
                          icon: Icon(Icons.search),
                          onPressed: _word == null
                              ? null
                              : () async {
                                  await openDict(context, _word ?? '');
                                  // TODO: look into it. should we load or not
                                  _load();
                                },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
    );
  }
}

class _CustomDaysDialog extends StatefulWidget {
  const _CustomDaysDialog();

  @override
  State<_CustomDaysDialog> createState() => _CustomDaysDialogState();
}

class _CustomDaysDialogState extends State<_CustomDaysDialog> {
  final _ctrl = TextEditingController();
  int _selected = _customChoices.first;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final txt = _ctrl.text.trim();
    final days = txt.isEmpty ? _selected : int.tryParse(txt);
    if (days == null || days < 0) {
      MsgSv.showToast("Invalid number of days: '$txt'");
      return;
    }
    Navigator.pop(context, days);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Show after'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            initialValue: _selected,
            decoration: const InputDecoration(
              labelText: 'Days',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final d in _customChoices)
                DropdownMenuItem(value: d, child: Text('$d')),
            ],
            onChanged: (v) => setState(() {
              _selected = v ?? _selected;
              _ctrl.clear();
            }),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Or enter days',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('OK')),
      ],
    );
  }
}
