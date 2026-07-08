import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/lex/isolate.dart';
import 'package:ara_dict/lex/rearrange_dicts.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:ara_dict/pages/width_padd.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:ara_dict/theme.dart';
import 'package:ara_dict/utils.dart';
import 'package:ara_dict/widgets/change_logs_widget.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Color Picker
const double _outer = 40;
const double _inner = 30;
const double _ringWidth = 3;
const double _gap =
    (_outer - _inner) / 1.8 - _ringWidth; // padding between ring and fill

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isReseting = false;

  @override
  void initState() {
    super.initState();
    touggleFullScreen();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    touggleFullScreen();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = appConf;

    return Scaffold(
      body: GestureStack(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: appConf.hideAppbar,
              pinned: !appConf.hideAppbar,
              title: const Text('Settings'),
            ),
            SliverPadding(
              padding: appConf.readerPadd(context),
              sliver: SliverList.list(
                children: [
                  // const SizedBox(height: 12),
                  const SettingsSectionTitle(title: 'Appearance'),
                  SettingsSectionSurface(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 24,
                          ),
                          child: Column(
                            // crossAxisAlignment: CrossAxisAlignment.center,
                            spacing: 20,
                            children: [
                              SegmentedButton<ThemeMode>(
                                showSelectedIcon: false,
                                segments: const [
                                  ButtonSegment(
                                    value: ThemeMode.system,
                                    icon: Icon(Icons.settings_suggest),
                                    label: Text('System'),
                                    tooltip: 'System',
                                  ),
                                  ButtonSegment(
                                    value: ThemeMode.light,
                                    icon: Icon(Icons.light_mode),
                                    label: Text('Light'),
                                    tooltip: 'Light',
                                  ),
                                  ButtonSegment(
                                    value: ThemeMode.dark,
                                    icon: Icon(Icons.dark_mode),
                                    label: Text('Dark'),
                                    tooltip: 'Dark',
                                  ),
                                ],
                                selected: {notifier.theme},
                                onSelectionChanged: (selection) {
                                  final selectedMode = selection.first;
                                  notifier.saveTheme(selectedMode);
                                  // setState(() {}); // if using StatefulWidget
                                },
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: uiSeedColors.map((c) {
                                  final selected = c == appConf.seedColor;
                                  return GestureDetector(
                                    onTap: () => appConf.setSeedColor(c),
                                    child: Container(
                                      width: _outer,
                                      height: _outer,
                                      padding: const EdgeInsets.all(_gap),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: selected
                                              ? c
                                              : Colors.transparent,
                                          width: _ringWidth,
                                        ),
                                      ),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: c,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const FilledIcon(Icons.auto_stories),
                        title: const Text('Reader Style'),
                        subtitle: const Text(
                          "Set the default reader style for lexicons and new reader entries",
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final old = ReaderAdjustData.fromConf(appConf);
                          final res = await ReaderAdjustPage.open(
                            context,
                            data: old,
                          );
                          if (res == null || old.isEq(res)) {
                            return;
                          }
                          await appConf.setReaderAdjustments(res);
                          if (context.mounted) {
                            showSnack(
                              context,
                              'Default reader style applied and saved',
                            );
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const SettingsSectionTitle(title: 'System'),
                  SettingsSectionSurface(
                    children: [
                      SwitchListTile(
                        secondary: const FilledIcon(Icons.translate),
                        title: Text('Use More Arabic'),
                        subtitle: Text('Display Various Things in Arabic'),
                        value: L.isAr,
                        onChanged: (value) {
                          notifier.saveUseMoreArabic(value);
                          setState(() {});
                        },
                      ),

                      /// Keep Screen On
                      SwitchListTile(
                        secondary: FilledIcon(Icons.screen_lock_portrait),
                        title: const Text('Keep Screen On'),
                        subtitle: const Text(
                          // 'Prevents the screen from sleeping while using the app for $durationToScreenWake minutes',
                          'Keeps the screen on for $durationToScreenWake minutes',
                        ),
                        value: WakelockController.isEnabled,
                        onChanged: (value) async {
                          await WakelockController.saveWakeLock(value);
                          setState(() {});
                        },
                      ),

                      SwitchListTile(
                        secondary: const FilledIcon(Icons.vertical_distribute),
                        title: const Text('Auto-hide Interface'),
                        subtitle: const Text(
                          'Hide top-bar and bottom controls while scrolling',
                        ),
                        value: appConf.hideAppbar,
                        onChanged: (value) {
                          notifier.saveHideAppbar(value);
                        },
                      ),

                      SwitchListTile(
                        secondary: const FilledIcon(Icons.fullscreen),
                        title: Text('Full screen mode'),
                        subtitle: Text('Hides status bar and navigation bar'),
                        value: appConf.fullScreen,
                        onChanged: (value) {
                          notifier.saveFullScreen(value);
                        },
                      ),
                      SwitchListTile(
                        secondary: const FilledIcon(Icons.visibility_off),
                        title: Text('Hide status bar'),
                        subtitle: Text('Hides only the status bar'),
                        value: appConf.hideStatusbar,
                        onChanged: appConf.fullScreen
                            ? null
                            : (value) {
                                notifier.saveHideStatusBar(value);
                              },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const SettingsSectionTitle(title: 'Lexicon'),
                  SettingsSectionSurface(
                    children: [
                      ListTile(
                        leading: const FilledIcon(Icons.reorder),
                        title: Text('Reorder lexicons'),
                        subtitle: const Text(
                          'Change the Order of the Lexicons',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => showDictReorderSheet(context, after: null),
                      ),

                      /// Suggestions
                      SwitchListTile(
                        secondary: const FilledIcon(Icons.auto_awesome),
                        title: const Text('Search Suggestions'),
                        subtitle: const Text('Show suggestions while typing'),
                        value: appConf.showSearchSugg,
                        onChanged:
                            appConf.showSearchSugg && !Isolates.suggInited
                            ? null
                            : (value) async {
                                appConf.saveShowSearchSugg(value).then((_) {
                                  if (context.mounted) setState(() {});
                                });
                                setState(() {});
                              },
                      ),

                      SwitchListTile(
                        secondary: const FilledIcon(Icons.view_week_rounded),
                        title: const Text('Scrollable selectors'),
                        subtitle: const Text(
                          'Browse words and dictionaries without opening the picker',
                        ),
                        value: appConf.scrollLexSelection,
                        onChanged: (value) async {
                          await appConf.saveScrollLexSelection(value);
                          if (context.mounted) setState(() {});
                        },
                      ),
                      SwitchListTile(
                        secondary: const FilledIcon(Icons.horizontal_rule),
                        title: const Text('Auto-scroll to selection'),
                        subtitle: const Text(
                          'Automatically scroll to the selected word or dictionary',
                        ),
                        value: appConf.scrollLexSelectionAutoSc,
                        onChanged: appConf.scrollLexSelection
                            ? (value) async {
                                appConf.saveScrollLexSelectionAutoSc(value);
                                if (context.mounted) setState(() {});
                              }
                            : null,
                      ),

                      /// Direct Results
                      // SwitchListTile(
                      //   secondary: FilledIcon(Icons.directions),
                      //   title: const Text('Direct Results'),
                      //   subtitle: Text(
                      //     // 'Open results immediately while typing, if an exact match is found'
                      //     // ' (but always direct in ${Dict.arEn.name})',
                      //     'Open results immediately while typing if an exact match is found'
                      //     '(no suggestions shown ${Dict.arEn.name}, which always opens directly)',
                      //   ),
                      //   value: appConf.showResutlsDirecly,
                      //   onChanged: Isolates.suggCanBeShown
                      //       ? (value) {
                      //           notifier.saveShowResutlsDirecly(value);
                      //           setState(() {});
                      //         }
                      //       : null,
                      // ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const SettingsSectionTitle(title: 'Reader'),
                  SettingsSectionSurface(
                    children: [
                      SwitchListTile(
                        title: const Text('Open Lexicon Direcly'),
                        subtitle: const Text(
                          // 'Do not show popup of bookmakrs, bookmark it in the lexicon page',
                          'Skip bookmark popup',
                        ),
                        secondary: const FilledIcon(Icons.directions),
                        value: appConf.readerIsOpenLexiconDirecly,
                        onChanged: (v) async {
                          await appConf.saveReaderIsOpenLexiconDirecly(v);
                          setState(() {});
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Foreign Words'),
                        subtitle: const Text(
                          'Highlight looked-up words in new reader entries by default',
                        ),
                        secondary: const FilledIcon(Icons.highlight),
                        value: appConf.luwColored,
                        onChanged: (v) {
                          appConf.saveLuwColored(v).then((_) {
                            if (!context.mounted) return;
                            setState(() {});
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const SettingsSectionTitle(title: 'Reset settings'),
                  SettingsSectionSurface(
                    children: [
                      ListTile(
                        title: const Text('Reset Settings'),
                        subtitle: const Text('Revert all settings to default'),
                        leading: FilledIcon(
                          Icons.restore,
                          // iconColor: cs.onErrorContainer,
                          // bg: cs.errorContainer,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _isReseting
                            ? null
                            : () async {
                                if (_isReseting) return;

                                final ok = await showConfirmDialog(
                                  context,
                                  'Reset Settings',
                                  message:
                                      'All settings will be reset to default. Your data (eg. books and bookmarks) will remain unchanged.',
                                  destructive: true,
                                  confirmText: 'Reset',
                                  constraints: true,
                                );
                                if (ok != null && ok) {
                                  _isReseting = true;
                                  setState(() {});
                                  await notifier.reset();
                                  _isReseting = false;
                                  setState(() {});
                                }
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  const SettingsSectionTitle(title: 'App info'),
                  SettingsSectionSurface(
                    children: [
                      ListTile(
                        leading: const FilledIcon(Icons.info_outline),
                        title: Text('App Version'),
                        subtitle: Text(
                          BuildInfo.appVersion.isNotEmpty
                              ? 'v${BuildInfo.appVersion}${BuildInfo.isGPlayVersion ? ' Play Store' : ''}'
                              : 'N/A',
                        ),
                        trailing: Icon(Icons.chevron_right),
                        onTap: () {
                          launchUrl(Uri.parse(BuildInfo.repoLink));
                        },
                      ),
                      if (BuildInfo._gitCommit.isNotEmpty)
                        ListTile(
                          leading: const FilledIcon(Icons.question_answer),
                          title: Text('Git Commit'),
                          subtitle: Text(BuildInfo.gitCommit),
                          trailing: Icon(Icons.chevron_right),
                          onTap: () {
                            launchUrl(
                              Uri.parse(
                                '${BuildInfo.commitsLink}${BuildInfo._gitCommit}',
                              ),
                            );
                          },
                        ),
                      ListTile(
                        leading: const FilledIcon(Icons.update_outlined),
                        title: Text('Updates'),
                        subtitle: Text('Go to update page'),
                        trailing: Icon(Icons.chevron_right),
                        onTap: () {
                          launchUrl(
                            Uri.parse(
                              BuildInfo.isGPlayVersion
                                  ? 'https://play.google.com/store/apps/details?id=io.github.wizsk.arabic_lexicons'
                                  : BuildInfo.downloadUpdates,
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const FilledIcon(Icons.new_releases_rounded),
                        title: Text('Change Logs'),
                        subtitle: Text('Show change logs'),
                        trailing: Icon(Icons.chevron_right),
                        onTap: () {
                          showWhatsNewSheet(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

abstract final class BuildInfo {
  static const isGPlayVersion = bool.fromEnvironment(
    'GPLAY',
    defaultValue: false,
  );

  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '',
  );

  static const _gitCommit = String.fromEnvironment(
    'GIT_COMMIT',
    defaultValue: '',
  );

  // pretty
  static final gitCommit = _gitCommit.isNotEmpty
      ? _gitCommit.substring(0, 7)
      : '';

  static const String commitsLink =
      'https://github.com/wizsk/arabic_lexicons/commit/';

  static const String repoLink = 'https://github.com/wizsk/arabic_lexicons/';

  static const String downloadUpdates =
      'https://github.com/wizsk/arabic_lexicons/releases/latest';
}

enum FilledIconVariant { neutral, primary, secondary, error }

class FilledIcon extends StatelessWidget {
  final IconData icon;
  final FilledIconVariant variant;
  final double size;
  final bool outlined;

  const FilledIcon(
    this.icon, {
    super.key,
    this.variant = FilledIconVariant.secondary,
    this.size = 20,
    this.outlined = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (bg, fg) = switch (variant) {
      FilledIconVariant.primary => (cs.primaryContainer, cs.onPrimaryContainer),
      FilledIconVariant.secondary => (
        cs.secondaryContainer,
        cs.onSecondaryContainer,
      ),
      FilledIconVariant.error => (cs.errorContainer, cs.onErrorContainer),
      FilledIconVariant.neutral => (
        cs.surfaceContainerHighest,
        cs.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: outlined
            ? Border.all(color: cs.outlineVariant, width: 1)
            : null,
      ),
      child: Icon(icon, size: size, color: fg),
    );
  }
}

enum SettingsSectionSurfaceMode { normal, alert }

class SettingsSectionSurface extends StatelessWidget {
  final List<Widget> children;
  final SettingsSectionSurfaceMode mode;

  const SettingsSectionSurface({
    super.key,
    required this.children,
    this.mode = SettingsSectionSurfaceMode.normal,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = mode == SettingsSectionSurfaceMode.normal
        ? cs.surfaceContainer
        : cs.errorContainer;
    final tint = cs.surfaceTint;

    return Material(
      color: color,
      surfaceTintColor: tint,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _withDividers(children),
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> children) {
    if (children.isEmpty) return [];

    return List.generate(children.length * 2 - 1, (i) {
      if (i.isEven) return children[i ~/ 2];
      return const Divider(height: 0, thickness: 0.6);
    });
  }
}

class SettingsSectionTitle extends StatelessWidget {
  final String title;

  const SettingsSectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: textTheme.labelMedium?.copyWith(
          color: cs.onSurfaceVariant,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
