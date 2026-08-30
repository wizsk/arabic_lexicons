import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/lex/data.dart';
import 'package:arabic_lexicons/widgets/choise_chip.dart';
import 'package:arabic_lexicons/widgets/lex_word_confirm.dart';
import 'package:flutter/material.dart';

class WordDictPickerResult {
  final bool? openSettings;

  const WordDictPickerResult({this.openSettings});
}

Future<WordDictPickerResult?> showWordPickerBottomSheet(
  BuildContext context,
  SearchLexiconsDatas datas,
) {
  return showModalBottomSheet<WordDictPickerResult?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    constraints: BoxConstraints(
      // maxHeight: MediaQuery.of(context).size.height * 9.2,
      minHeight: 400,
      maxWidth: 600,
    ),
    builder: (context) {
      return _WordDictPickerSheet(datas: datas);
    },
  );
}

class _WordDictPickerSheet extends StatefulWidget {
  final SearchLexiconsDatas datas;

  const _WordDictPickerSheet({required this.datas});

  @override
  State<_WordDictPickerSheet> createState() => _WordDictPickerSheetState();
}

class _WordDictPickerSheetState extends State<_WordDictPickerSheet> {
  late final SearchLexiconsDatas _datas;

  @override
  void initState() {
    super.initState();
    _datas = widget.datas;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final th = theme.textTheme;

    return SingleChildScrollView(
      padding: scrollPaddingBottmSheet(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Directionality(
              textDirection: L.dir,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          L.p(
                            'Switch lexicon or word',
                            'تغيير المعجم أو الكلمة',
                          ),
                          style: th.titleMedium?.arIf?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          L.p(
                            'Pick a word or change the dictionary',
                            'اختر كلمة أو غيّر المعجم',
                          ),
                          style: th.bodySmall?.arIf?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton.outlined(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        WordDictPickerResult(openSettings: true),
                      );
                    },
                    icon: const Icon(Icons.tune),
                    // label: const Text('Rearrange'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Words section
          if (widget.datas.words.length > 1) ...[
            _SectionCard(
              title: L.p('Words', 'الكلمات'),
              titleFontFam: L.arFontIf,
              child: Align(
                alignment: Alignment.topRight,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Wrap(
                    textDirection: TextDirection.rtl,
                    spacing: 8,
                    runSpacing: 8,
                    // alignment: WrapAlignment.end,
                    // textDirection: TextDirection.ltr,
                    children: widget.datas.words.indexed.map((itm) {
                      final (index, word) = itm;

                      final selected = widget.datas.selectedWord == word;

                      var label = word.replaceAll('_', ' ').trim();
                      if (label.length > 30) {
                        label = '${label.substring(0, 30)}…';
                      }

                      return Selection(
                        label,
                        selected: selected,
                        onTab: () {
                          _datas.selectedWord = word;
                          Navigator.pop(context);
                        },
                        onDelete: !appConf.lexWordRmIcon
                            ? null
                            : () async {
                                if (appConf.lexWordDelConfirm) {
                                  final res = await showLexWordDelConfirm(
                                    context,
                                    label,
                                  );
                                  if (res != true) return;
                                }

                                // _datas.words.isEmpty will never be true because we won't even show
                                // word picker if there is less than 2 words!

                                _datas.words.removeAt(index);
                                if (selected) {
                                  final next = index == 0 ? 0 : index - 1;
                                  _datas.selectedWord = _datas.words[next];
                                }

                                if (context.mounted) {
                                  setState(() {});
                                }
                              },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Lexicons section
          _SectionCard(
            title: L.p('Lexicons', 'المعاجم'),
            titleFontFam: L.arFontIf,
            child: Align(
              alignment: L.p(
                AlignmentDirectional.centerStart,
                AlignmentDirectional.centerEnd,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                textDirection: L.dir,
                children: allDictsOrd.map((dict) {
                  final selected = widget.datas.selectedDict == dict;

                  return Selection(
                    dict.name,
                    isAr: L.isAr,
                    selected: selected,
                    tooltip: dict.enLong,
                    onTab: () {
                      _datas.selectedDict = dict;
                      Navigator.of(context).pop();
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final String? titleFontFam;

  const _SectionCard({
    required this.title,
    required this.child,
    this.titleFontFam,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final th = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              title,
              style: th.labelLarge?.copyWith(
                fontFamily: titleFontFam,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
