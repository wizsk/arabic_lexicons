import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/font_size.dart';
import 'package:arabic_lexicons/pages/settings/settings.dart';
import 'package:arabic_lexicons/pages/settings/theme_color_font.dart';
import 'package:arabic_lexicons/play_rate.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final th = theme.textTheme;
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: appConf.readerPadd(context),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 30),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            elevatedIcon(
                              cs,
                              Icons.menu_book_rounded,
                              diemtion: 110,
                              iconSize: 54,
                            ),

                            const SizedBox(height: 12),

                            Text(
                              'Welcome!',
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              'Thanks for installing the app.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              'We hope it helps you along your Arabic-learning journey',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),

                            // const SizedBox(height: 8),

                            // Text(
                            //   ' If you encounter any issues, please email us at: $emailAddr',
                            //   textAlign: TextAlign.center,
                            //   style: theme.textTheme.bodyLarge?.copyWith(
                            //     color: cs.onSurfaceVariant,
                            //   ),
                            // ),
                          ],
                        ),

                        const SizedBox(height: 34),
                        Center(
                          child: Text(
                            'Make the app yours',
                            textAlign: TextAlign.center,
                            style: th.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        SettingsSectionSurface(
                          children: themeColorFontSettings(context),
                        ),

                        const SizedBox(height: 16),

                        SettingsSectionSurface(
                          children: [
                            SwitchListTile(
                              secondary: const FilledIcon(Icons.translate),
                              title: Text('Use More Arabic'),
                              subtitle: Text(
                                'Display Various Things in Arabic',
                              ),
                              value: L.isAr,
                              onChanged: (value) {
                                appConf.saveUseMoreArabic(value).then((_) {
                                  if (context.mounted) setState(() {});
                                });
                              },
                            ),
                            ListTile(
                              leading: const FilledIcon(Icons.format_size),
                              title: Text(
                                'UI font size: ${L.fontSize?.toStringAsFixed(0) ?? 'System'}',
                              ),
                              subtitle: const Text(
                                'Set the font size for Arabic input fields and UI elements.',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                showUiFontSizeBottomSheet(context).then((_) {
                                  if (context.mounted) setState(() {});
                                });
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
                              secondary: const FilledIcon(Icons.fullscreen),
                              title: Text('Full screen mode'),
                              subtitle: Text(
                                'Hides status bar and navigation bar',
                              ),
                              value: appConf.fullScreen,
                              onChanged: (value) {
                                appConf.saveFullScreen(value);
                              },
                            ),
                          ],
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),

            // ─────────────────────────────────────────
            // Sticky bottom button
            // ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Container(
                width: double.infinity,
                height: 46,
                constraints: BoxConstraints(maxWidth: appConf.maxWidth),
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, Routes.dictionary);
                    appConf.saveFirstRun(false);
                  },
                  icon: Icon(Icons.check_rounded, color: cs.onPrimary),
                  label: Text(
                    'Done for now',
                    style: th.titleMedium?.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
