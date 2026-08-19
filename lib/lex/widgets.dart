import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/datas/word_store.dart';
import 'package:arabic_lexicons/lex/data.dart';
import 'package:arabic_lexicons/lex/isolate.dart';

import 'package:arabic_lexicons/main_widgets.dart';
import 'package:flutter/material.dart';

Widget lexAppBar(
  BuildContext context,
  SearchLexiconsDatas datas,
  VoidCallback onChange,
) {
  final dictName = L.p(
    TextSpan(text: datas.selectedDict.en),
    TextSpan(text: datas.selectedDict.ar, style: L.arStyle),
  );

  Widget title;
  if (datas.selectedWord.isNotEmpty) {
    title = Text.rich(
      TextSpan(
        // style: ,
        children: [
          dictName,
          TextSpan(
            text: ': ${datas.selectedWord.replaceAll('_', ' ')} ',
            style: L.arStyle,
          ),
          // if (bm) WidgetSpan(child: Icon(Icons.bookmark)),
        ],
      ),
      textDirection: L.dir,
    );
  } else {
    title = Text.rich(dictName);
  }

  final bm = WordStore.isBm(datas.selectedWord);
  final cs = Theme.of(context).colorScheme;

  final actions = <Widget>[
    IconButton(
      icon: datas.isShowingSugg
          ? const Icon(Icons.directions)
          : const Icon(Icons.auto_awesome),
      tooltip: 'Toggle search suggestions',
      onPressed: datas.selectedWord.isNotEmpty && Isolates.suggCanBeShown
          ? () async {
              final ss = datas.isShowingSugg;
              await datas.getAndShowResORSugg(
                context,
                forceSugg: !ss,
                forceRes: ss,
              );
            }
          : null,
    ),
    IconButton(
      icon: bm
          ? Icon(Icons.bookmark, color: cs.error)
          : Icon(Icons.bookmark_border),
      tooltip: bm ? 'Unbookmark' : 'BookMark',
      onPressed: datas.selectedWord.isEmpty || datas.isShowingSugg
          ? null
          : () async {
              if (bm) {
                final confirm = await showConfirmDialog(
                  context,
                  'Remove Bookmark',
                  message: 'Remove: ${datas.selectedWord}',
                  destructive: true,
                  confirmText: 'Remove',
                );
                if (confirm != true) return;
                WordStore.rmBM(datas.selectedWord);
              } else {
                WordStore.addBM(datas.selectedWord);
              }
              onChange();
            },
    ),
  ];

  final bg = datas.appbarReaderBg ? appConf.readerSurface(context) : null;

  return datas.isShowingSugg && datas.sugg.isNotEmpty
      ? AppBar(
          title: title,
          forceMaterialTransparency: true,
          // most likely unnessesary
          backgroundColor: appConf.readerSurface(context),
          actions: actions,
        )
      : Directionality(
          textDirection: TextDirection.ltr,
          child: SliverAppBar(
            title: title,
            backgroundColor: bg,
            titleSpacing: 0.0,
            floating: true,
            snap: appConf.hideAppbar,
            pinned: !appConf.hideAppbar,
            actions: actions,
          ),
        );
}

class WordDictPickerResult {
  final Dict? d;
  final String? word;
  final bool? openSettings;

  const WordDictPickerResult({this.d, this.word, this.openSettings});
}

Future<WordDictPickerResult?> showWordPickerBottomSheet_(
  BuildContext context,
  SearchLexiconsDatas datas,
  TextStyle ts,
) {
  // ts = ts.copyWith(fontSize: 0.85 * (ts.fontSize ?? defaultArabicFontSize));
  final ts = L.arStyle;

  return showModalBottomSheet<WordDictPickerResult?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (context) {
      final sh = MediaQuery.of(context).size.height;
      final th = Theme.of(context).textTheme;
      final maxHeight = sh * 0.9;
      final minHeight = sh * 0.4;
      final cs = Theme.of(context).colorScheme;

      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
          minHeight: minHeight,
          minWidth: double.infinity,
        ),
        child: Material(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          color: cs.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Column(
              // textDirection: TextDirection.rtl,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withAlpha(70),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              // 'Switcher',
                              'Switch Lexicon or Word',
                              style: th.titleMedium?.copyWith(
                                color: cs.onSurface.withAlpha(200),
                              ),
                            ),
                            // const SizedBox(height: 2),
                            // Text(
                            //   'Change Lexicon or Word',
                            //   style: th.bodySmall?.copyWith(
                            //     color: cs.onSurfaceVariant,
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        label: Text('Rearragne'),
                        icon: const Icon(Icons.settings),
                        // label: Text('Reset'),
                        onPressed: () {
                          Navigator.pop(
                            context,
                            WordDictPickerResult(openSettings: true),
                          );
                          // setState(() {
                          //   _dicts = List.from(allDicts);
                          // });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 0),
                const SizedBox(height: 12),

                if (!datas.areWordsEmpty) ...[
                  Flexible(
                    // Scroll
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        textDirection: TextDirection.rtl,
                        spacing: 8,
                        runSpacing: 8,
                        children: datas.words.map((word) {
                          final s = datas.selectedWord == word;
                          var tw = word.replaceAll('_', ' ').trim();
                          if (tw.length > 30) {
                            tw = '${tw.substring(0, 30)}…';
                          }
                          return ChoiceChip(
                            showCheckmark: false,
                            label: Text(
                              tw,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                            ),
                            selected: s,
                            labelStyle: s
                                ? ts.copyWith(color: cs.onPrimary)
                                : ts,
                            selectedColor: cs.primary,
                            onSelected: (value) {
                              if (s) {
                                Navigator.pop(context);
                                return;
                              }
                              Navigator.pop(
                                context,
                                WordDictPickerResult(word: word),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  SizedBox(height: 16),
                  Divider(height: 0),
                  SizedBox(height: 12),
                ],

                Align(
                  alignment: L.alignment,
                  child: Wrap(
                    textDirection: L.dir,
                    spacing: 8,
                    runSpacing: 8,
                    children: allDictsOrd.map((dict) {
                      final s = datas.selectedDict == dict;
                      return ChoiceChip(
                        showCheckmark: false,
                        label: Text(L.p(dict.en, dict.ar)),
                        tooltip: dict.enLong,
                        selected: s,
                        labelStyle: s
                            ? L.arStyleOrNew.copyWith(
                                color: s ? cs.onPrimary : cs.onSurface,
                              )
                            : L.arStyleIf,
                        selectedColor: cs.primary,
                        onSelected: (value) {
                          if (s) {
                            Navigator.pop(context);
                            return;
                          }
                          Navigator.pop(context, WordDictPickerResult(d: dict));
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
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

class _WordDictPickerSheet extends StatelessWidget {
  final SearchLexiconsDatas datas;

  const _WordDictPickerSheet({required this.datas});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final th = theme.textTheme;

    // used for words
    final chipTextStyle = L.arStyleSized.copyWith(color: cs.onSurface);

    final chipTextStyleDict = L.isAr
        ? chipTextStyle
        : TextStyle(color: cs.onSurface);

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
          if (datas.words.length > 1) ...[
            _SectionCard(
              title: L.p('Words', 'الكلمات'),
              titleFontFam: L.arFontIf,
              child: Align(
                alignment: Alignment.topRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  textDirection: TextDirection.rtl,
                  children: datas.words.map((word) {
                    final selected = datas.selectedWord == word;

                    var label = word.replaceAll('_', ' ').trim();
                    if (label.length > 30) {
                      label = '${label.substring(0, 30)}…';
                    }

                    return ChoiceChip(
                      showCheckmark: false,
                      selected: selected,
                      label: Text(label, textDirection: TextDirection.rtl),
                      labelStyle: selected
                          ? chipTextStyle.copyWith(color: cs.onPrimary)
                          : chipTextStyle,
                      selectedColor: cs.primary,
                      backgroundColor: cs.surfaceContainerHighest,
                      side: BorderSide(
                        color: selected ? cs.primary : cs.outlineVariant,
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onSelected: (_) {
                        if (selected) {
                          Navigator.pop(context);
                          return;
                        }
                        Navigator.pop(
                          context,
                          WordDictPickerResult(word: word),
                        );
                      },
                    );
                  }).toList(),
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
                  final selected = datas.selectedDict == dict;

                  return ChoiceChip(
                    showCheckmark: false,
                    selected: selected,
                    label: Text(dict.name),
                    tooltip: dict.enLong,
                    labelStyle: selected
                        ? chipTextStyleDict.copyWith(color: cs.onPrimary)
                        : chipTextStyleDict,
                    selectedColor: cs.primary,
                    backgroundColor: cs.surfaceContainerHighest,
                    side: BorderSide(
                      color: selected ? cs.primary : cs.outlineVariant,
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onSelected: (_) {
                      if (selected) {
                        Navigator.pop(context);
                        return;
                      }
                      Navigator.pop(context, WordDictPickerResult(d: dict));
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
