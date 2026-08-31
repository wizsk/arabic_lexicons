import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/pages/settings/settings.dart';
import 'package:arabic_lexicons/pages/width_padd.dart';
import 'package:arabic_lexicons/reader/reader_utils.dart';
import 'package:arabic_lexicons/theme.dart';
import 'package:flutter/material.dart';

/// Color Picker
const double themeColorOuter = 40;
const double themeColorInner = 30;
const double themeColorRingWidth = 3;
const double themeColorGap =
    (themeColorOuter - themeColorInner) / 1.8 -
    themeColorRingWidth; // padding between ring and fill

class _ThemeModeButton extends StatelessWidget {
  const _ThemeModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Tooltip(
      message: label,
      child: Material(
        color: selected ? cs.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 70,
            height: 70,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 5.0,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? cs.onPrimary : cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ThemeSwicher extends StatefulWidget {
  const ThemeSwicher({super.key});

  @override
  State<ThemeSwicher> createState() => _ThemeSwicherState();
}

class _ThemeSwicherState extends State<ThemeSwicher> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6.0,
        children: [
          _ThemeModeButton(
            icon: Icons.settings_suggest_rounded,
            label: 'System',
            selected: appConf.theme == ThemeMode.system,
            onTap: () async {
              await appConf.saveTheme(ThemeMode.system);
              if (context.mounted) setState(() {});
            },
          ),
          _ThemeModeButton(
            icon: Icons.light_mode_rounded,
            label: 'Light',
            selected: appConf.theme == ThemeMode.light,
            onTap: () async {
              await appConf.saveTheme(ThemeMode.light);
              if (context.mounted) setState(() {});
            },
          ),
          _ThemeModeButton(
            icon: Icons.dark_mode_rounded,
            label: 'Dark',
            selected: appConf.theme == ThemeMode.dark,
            onTap: () async {
              await appConf.saveTheme(ThemeMode.dark);
              if (context.mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }
}

List<Widget> themeColorFontSettings(BuildContext context) {
  return [
    Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 24),
        child: Column(
          // crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 20,
          children: [
            ThemeSwicher(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: uiSeedColors.map((c) {
                final selected = c == appConf.seedColor;
                return GestureDetector(
                  onTap: () => appConf.setSeedColor(c),
                  child: Container(
                    width: themeColorOuter,
                    height: themeColorOuter,
                    padding: const EdgeInsets.all(themeColorGap),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? c : Colors.transparent,
                        width: themeColorRingWidth,
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
        final res = await ReaderAdjustPage.open(context, data: old);
        if (res == null || old.isEq(res)) {
          return;
        }
        await appConf.setReaderAdjustments(res);
        if (context.mounted) {
          showSnack(context, 'Default reader style applied and saved');
        }
      },
    ),
  ];
}
