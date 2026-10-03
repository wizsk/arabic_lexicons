import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/main_widgets.dart';
import 'package:arabic_lexicons/reader/find_word.dart';
import 'package:arabic_lexicons/review/list.dart';
import 'package:arabic_lexicons/review/models.dart';
import 'package:arabic_lexicons/review/order.dart';
import 'package:arabic_lexicons/review/provider.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:flutter/material.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  RevOrdData _ord = RevOrdData.def;

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

    touggleFullScreen();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    touggleFullScreen();
  }

  Future<void> _openDict() async {
    await openDict(context, _word ?? '');
    // TODO: look into it. should we load or not
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final res = await _repo.next(_ord);

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
      builder: (_) => DaysDialog(initial: _intervals?.last ?? 0),
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

  @override
  Widget build(BuildContext context) {
    // final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final surfaceColor = appConf.readerSurface(context);

    return Scaffold(
      backgroundColor: surfaceColor,
      drawer: buildDrawer(context),
      appBar: AppBar(
        backgroundColor: surfaceColor,
        title: const Text('Review'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Search all book entries for matching words',
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
            tooltip: 'Open reviewd word list',
            icon: Icon(Icons.list),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RevWordListPage(rr: _repo)),
              );
              _load();
            },
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
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _word == null ? null : _openDict,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              _word ?? 'لا موجود',
                              textAlign: TextAlign.center,
                              style: tt.displaySmall?.copyWith(
                                fontFamily: L.arFont,
                                // TODO: Fix color
                                // color: cs.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (_word != null) ...[
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(82, 48),
                      ),
                      icon: const Icon(Icons.sort_rounded),
                      label: Text(_ord.label),
                      onPressed: () async {
                        final res = await showRevOrdSheet(context, _ord);
                        if (res == null || res == _ord) return;
                        _ord = res;
                        _load();
                        _ord.save();
                      },
                    ),

                    const SizedBox(height: 18),
                    const Divider(height: 0),
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
                              minimumSize: const Size(72, 48),
                            ),
                            onPressed: () => _showAfter(-1),
                            child: const Text('${repeatDurMin}m'),
                          ),
                        ),
                        if (_intervals != null)
                          for (final d in _intervals!)
                            FilledButton(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(72, 48),
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
                      runSpacing: 12,
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
                        OutlinedButton.icon(
                          label: Text('Def'),
                          icon: Icon(Icons.search),
                          onPressed: _word == null ? null : _openDict,
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
