import 'dart:async';

import 'package:ara_dict/data.dart';
import 'package:ara_dict/pages/settings.dart';
import 'package:ara_dict/pages/width_padd.dart';
import 'package:ara_dict/reader/data.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:ara_dict/reader/settings_class.dart';
import 'package:flutter/material.dart';

class ReaderModeSettingsSheet extends StatefulWidget {
  final ReaderPageSettings original;
  final PeraEntries paras;

  const ReaderModeSettingsSheet({
    super.key,
    required this.original,
    required this.paras,
  });

  static Future<ReaderSettingsRes?> show(
    BuildContext context, {
    required ReaderPageSettings settings,
    required PeraEntries paras,
  }) async {
    return Navigator.push(
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
  late ReaderPageSettings rs;

  @override
  void initState() {
    super.initState();
    rs = widget.original.copyWith();
  }

  bool get hasChanged => !widget.original.isEqual(rs);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Reader Settings')),
      body: SafeArea(
        child: ListView(
          padding: scrollPadding,
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
                  value: rs.isQasidah,
                  onChanged: (v) => setState(() => rs.isQasidah = v),
                ),

                if (rs.isQasidah) ...[
                  SwitchListTile(
                    title: const Text('Center bayt'),
                    subtitle: const Text('Align poem to the center'),
                    secondary: const FilledIcon(Icons.format_align_center),
                    value: rs.isQasidahCentered,
                    onChanged: (v) => setState(() => rs.isQasidahCentered = v),
                  ),

                  SwitchListTile(
                    title: const Text('Line numbers'),
                    subtitle: const Text('Show poem line numbers'),
                    secondary: const FilledIcon(Icons.list),
                    value: rs.qasidahLineNum,
                    onChanged: (v) => setState(() => rs.qasidahLineNum = v),
                  ),
                ] else ...[
                  SwitchListTile(
                    title: const Text('Right-aligned text'),
                    subtitle: const Text('Align text towards right'),
                    secondary: const FilledIcon(Icons.format_align_right),
                    value: rs.textAlign == TextAlign.right,
                    onChanged: (v) {
                      setState(() {
                        rs.textAlign = v ? TextAlign.right : TextAlign.justify;
                      });
                    },
                  ),
                ],

                SwitchListTile(
                  title: const Text('Resume reading'),
                  subtitle: const Text('Open from your last read paragraph'),
                  secondary: const FilledIcon(Icons.history),
                  value: rs.saveLastPeraIdx && rs.bookHash.isNotEmpty,
                  onChanged: rs.bookHash.isNotEmpty
                      ? (v) => setState(() => rs.saveLastPeraIdx = v)
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
                    final old = ReaderAdjustData.fromReaderPageSettings(rs);

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

                    setState(() => rs.applyRAD(res));

                    if (context.mounted) {
                      showSnack(
                        context,
                        'Save settings to apply reader style',
                        duration: Duration(seconds: 4),
                      );
                    }
                  },
                ),

                SwitchListTile(
                  title: const Text('Remove tashkil'),
                  subtitle: const Text('Remove Arabic harakat'),
                  secondary: const FilledIcon(Icons.do_not_disturb),
                  value: rs.isRmTashkil,
                  onChanged: (v) => setState(() => rs.isRmTashkil = v),
                ),

                SwitchListTile(
                  title: const Text('Colored bookmarks'),
                  subtitle: const Text('Highlight bookmarked words'),
                  secondary: const FilledIcon(Icons.bookmark),
                  value: rs.isBmColored,
                  onChanged: (v) => setState(() => rs.isBmColored = v),
                ),

                SwitchListTile(
                  title: const Text('Foreign'),
                  subtitle: const Text('Add looked up words to foreing'),
                  secondary: const FilledIcon(Icons.highlight),
                  value: rs.foreignAdd,
                  onChanged: (v) => setState(() => rs.foreignAdd = v),
                ),
                SwitchListTile(
                  title: const Text('Foreign Words'),
                  subtitle: const Text('Highlight looked-up words'),
                  secondary: const FilledIcon(Icons.highlight),
                  value: rs.foreignColored,
                  onChanged: (v) => setState(() => rs.foreignColored = v),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: hasChanged ? () => Navigator.of(context).pop(RPS(rs)) : null,

        backgroundColor: hasChanged ? null : cs.surfaceContainerHighest,
        foregroundColor: hasChanged
            ? null
            : cs.onSurface.withValues(alpha: 0.38),

        tooltip: 'Apply to current book',
        // icon: const Icon(Icons.save),
        label: const Text('Apply'),
        icon: const Icon(Icons.save),
      ),
    );
  }
}
