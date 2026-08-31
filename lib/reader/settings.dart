import 'dart:async';

import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/pages/settings/settings.dart';
import 'package:arabic_lexicons/pages/width_padd.dart';
import 'package:arabic_lexicons/reader/data.dart';
import 'package:arabic_lexicons/reader/reader_utils.dart';
import 'package:arabic_lexicons/reader/settings_class.dart';
import 'package:flutter/material.dart';

class ReaderModeSettingsSheet extends StatefulWidget {
  final ReaderPageSettings original;
  final PeraEntries paras;

  const ReaderModeSettingsSheet({
    super.key,
    required this.original,
    required this.paras,
  });

  static Future<void> show(
    BuildContext context, {
    required ReaderPageSettings settings,
    required PeraEntries paras,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ReaderModeSettingsSheet(original: settings, paras: paras),
      ),
    );
  }

  @override
  State<ReaderModeSettingsSheet> createState() =>
      _ReaderModeSettingsSheetState();
}

class _ReaderModeSettingsSheetState extends State<ReaderModeSettingsSheet> {
  late final ReaderPageSettings _rs;

  @override
  void initState() {
    super.initState();

    _rs = widget.original;
  }

  Future<void> _save() async {
    await _rs.saveToFile();
    if (context.mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Reader Settings')),
      body: SafeArea(
        child: ListView(
          padding: appConf.readerPadd(context),
          children: [
            // GLOBAL
            const SettingsSectionTitle(title: 'Global Settings'),
            SettingsSectionSurface(
              children: [
                SwitchListTile(
                  title: const Text('Open lexicon directly'),
                  subtitle: const Text('Skip bookmark popup'),
                  secondary: const FilledIcon(Icons.directions),
                  value: appConf.readerIsOpenLexiconDirecly,
                  onChanged: (v) async {
                    await appConf.saveReaderIsOpenLexiconDirecly(v);
                    setState(() {});

                    if (context.mounted) {
                      showSnack(
                        context,
                        "Bookmark popup ${v ? "won't" : 'will'} be shown",
                      );
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // CURRENT BOOK
            const SettingsSectionTitle(title: 'Current Book'),

            // READING STYLE
            SettingsSectionSurface(
              children: [
                SwitchListTile(
                  title: const Text('Qasidah mode'),
                  subtitle: const Text('Poem layout'),
                  secondary: const FilledIcon(Icons.notes),
                  value: _rs.isQasidah,
                  onChanged: (v) {
                    _rs.isQasidah = v;
                    _save();
                  },
                ),

                if (_rs.isQasidah) ...[
                  SwitchListTile(
                    title: const Text('Center bayt'),
                    subtitle: const Text('Align poem to the center'),
                    secondary: const FilledIcon(Icons.format_align_center),
                    value: _rs.isQasidahCentered,
                    onChanged: (v) {
                      _rs.isQasidahCentered = v;
                      _save();
                    },
                  ),

                  SwitchListTile(
                    title: const Text('Line numbers'),
                    subtitle: const Text('Show poem line numbers'),
                    secondary: const FilledIcon(Icons.list),
                    value: _rs.qasidahLineNum,
                    onChanged: (v) {
                      _rs.qasidahLineNum = v;
                      _save();
                    },
                  ),
                ] else ...[
                  SwitchListTile(
                    title: const Text('Right-aligned text'),
                    subtitle: const Text('Align text towards right'),
                    secondary: const FilledIcon(Icons.format_align_right),
                    value: _rs.textAlign == TextAlign.right,
                    onChanged: (v) {
                      setState(() {
                        _rs.textAlign = v ? TextAlign.right : TextAlign.justify;
                      });
                    },
                  ),
                ],

                SwitchListTile(
                  title: const Text('Resume reading'),
                  subtitle: const Text('Open from your last read paragraph'),
                  secondary: const FilledIcon(Icons.history),
                  value: _rs.saveLastPeraIdx && _rs.bookHash.isNotEmpty,
                  onChanged: _rs.bookHash.isNotEmpty
                      ? (v) {
                          _rs.saveLastPeraIdx = v;
                          _save();
                        }
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // APPEARANCE
            SettingsSectionSurface(
              children: [
                ListTile(
                  leading: const FilledIcon(Icons.auto_stories),
                  title: const Text('Reader Style'),
                  subtitle: const Text(
                    "Set reader style for current reader entry",
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final old = ReaderAdjustData.fromReaderPageSettings(_rs);

                    final parasInput = widget.paras
                        .map((e) => e.map((f) => f.ar).join(" "))
                        .toList(growable: false);

                    final res = await ReaderAdjustPage.open(
                      context,
                      data: old,
                      paras: parasInput,
                    );

                    if (res == null || old.isEq(res)) {
                      return;
                    }

                    _rs.applyRAD(res);
                    await _save();

                    if (context.mounted) {
                      showSnack(
                        context,
                        'New Reader style saved',
                        duration: Duration(seconds: 4),
                      );
                    }
                  },
                ),

                SwitchListTile(
                  title: const Text('Remove tashkil'),
                  subtitle: const Text('Remove Arabic harakat'),
                  secondary: const FilledIcon(Icons.do_not_disturb),
                  value: _rs.isRmTashkil,
                  onChanged: (v) {
                    _rs.isRmTashkil = v;
                    _save();
                  },
                ),

                SwitchListTile(
                  title: const Text('Colored bookmarks'),
                  subtitle: const Text('Highlight bookmarked words'),
                  secondary: const FilledIcon(Icons.bookmark),
                  value: _rs.isBmColored,
                  onChanged: (v) {
                    _rs.isBmColored = v;
                    _save();
                  },
                ),

                SwitchListTile(
                  title: const Text('Foreign'),
                  subtitle: const Text('Add looked up words to foreing'),
                  secondary: const FilledIcon(Icons.g_translate),
                  value: _rs.foreignAdd,
                  onChanged: (v) {
                    _rs.foreignAdd = v;
                    _save();
                  },
                ),
                SwitchListTile(
                  title: const Text('Colored Foreign'),
                  subtitle: const Text('Highlight foreign words'),
                  secondary: const FilledIcon(Icons.highlight),
                  value: _rs.foreignColored,
                  onChanged: (v) {
                    _rs.foreignColored = v;
                    _save();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
