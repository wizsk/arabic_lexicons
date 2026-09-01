import 'package:arabic_lexicons/key_shortcuts.dart';
import 'package:arabic_lexicons/pages/width_padd.dart';
import 'package:arabic_lexicons/play_rate.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/pages/help/help_utils.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const buildUnix = int.fromEnvironment('BUILD_UNIX_TIME');
  static const appVersion = String.fromEnvironment('APP_VERSION');
  static const gitCommit = String.fromEnvironment('GIT_COMMIT');
  static const gitCommitMsg = String.fromEnvironment('GIT_COMMIT_MSG');

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final tt = textTheme;

    const spaceBetweenSections = SizedBox(height: 16);
    const spaceBetweenSubSections = SizedBox(height: 12);

    return Scaffold(
      body: GestureStack(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: appConf.hideAppbar,
              pinned: !appConf.hideAppbar,
              title: const Text('Help'),
            ),
            SliverPadding(
              padding: readerPadding(
                context,
                maxWidth: appConf.maxWidth,
                sidePadd: appConf.padding,
              ),
              sliver: SliverList.list(
                children: [
                  // _SectionCard(
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       Text(
                  //         'This page still needs work. For now, watch the app overview video:',
                  //         style: textTheme.titleMedium,
                  //       ),
                  //       const SizedBox(height: 12),
                  //       InkWell(
                  //         onTap: () => _openUrl(overViewURL),
                  //         child: Text(overViewURL, style: linkStyle),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // spaceBetweenSections,

                  // _SectionCard(
                  //   title: 'Info',
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       Text(
                  //         'This app contains ${Dict.values.length - 1} lexicons and 1 dictionary for quick access.',
                  //         style: textTheme.bodyLarge,
                  //       ),
                  //       const SizedBox(height: 12),
                  //       const _Bullet('Search multiple words at the same time'),
                  //       const _Bullet('Paste a full sentence and work through it'),
                  //       const _Bullet(
                  //         'Switch lexicons to go deeper into the meaning',
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  // spaceBetweenSections,
                  _Section(
                    title: 'Lexicons Screen',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SubSection(
                          subTitle: 'Changing lexicons or words',
                          bullets: [
                            BulletSpans(
                              TextSpan(
                                style: textTheme.bodyMedium,
                                children: [
                                  TextSpan(text: 'Tap the '),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Icon(
                                      dictWordSelectModalOpenIcon,
                                      size: 20,
                                    ),
                                  ),
                                  const TextSpan(
                                    text:
                                        ' icon to open the lexicon and word selector.',
                                  ),
                                ],
                              ),
                            ),
                            Bullet(
                              'Click on words in the search input to quickly swith to that word',
                            ),
                            Bullet(
                              'The last inserted word is automatically selected',
                            ),
                          ],
                        ),

                        spaceBetweenSubSections,
                        Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: const ExpansionTile(
                            title: _SubTilte(
                              'Details (tap a name for details)',
                            ),
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: EdgeInsets.zero,
                            backgroundColor: Colors.transparent,
                            dense: true,
                            children: [DictList()],
                          ),
                        ),
                      ],
                    ),
                  ),

                  spaceBetweenSections,
                  _Section(
                    title: 'Reader Screen',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SubSection(
                          subTitle: 'Purpose',
                          bullets: [
                            Bullet(
                              'Paste text here after copying it from a website (see below) or another source.',
                            ),
                            Bullet(
                              'While reading, tap any word to see its meaning.',
                            ),
                            Bullet(
                              'Looked-up words are highlighted in blue, if enabled, and saved in Foreign Words for easier review.',
                            ),
                            Bullet(
                              'Settings are saved separately for each book entry.',
                            ),
                            Bullet(
                              'In Qasidah (Poem) Mode, only the poem text should be provided so that bayts are numbered correctly.',
                            ),
                            Bullet(
                              'You can export inserted book entries and import them later. Import only works with books exported from this app.',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  spaceBetweenSections,
                  _Section(
                    title: 'Settings Screen',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SubSection(
                          subTitle: 'Defaults',
                          bullets: [
                            Bullet(
                              'Reader style is used in the Lexicons screen and as the default style for new book entries.',
                            ),
                            Bullet(
                              'Options such as opening lexicons directly and saving foreign words are used as defaults for new book entries.',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  spaceBetweenSections,
                  _Section(
                    title: 'Keyboard Shortcuts',
                    child: const ShortcutsHelpList(),
                  ),

                  spaceBetweenSections,
                  _Section(
                    // title: 'Feedback',
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.menu_book_rounded,
                              size: 38,
                              color: cs.onPrimaryContainer,
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            'Enjoying the app?',
                            textAlign: TextAlign.center,
                            style: tt.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),
                          Text(
                            'Your support means a lot. A quick rating helps us improve the app and keep building useful features for you.',
                            style: tt.bodyLarge?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            constraints: const BoxConstraints(maxWidth: 250),
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            width: double.infinity,
                            height: 52,
                            child: FilledButton.icon(
                              icon: Icon(Icons.star_rounded),
                              label: const Text("Sure, I'll rate it"),
                              onPressed: openRatingFlow,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  spaceBetweenSections,
                  _Section(
                    title: 'Contact',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        _LinkRow(
                          label: 'Mail',
                          value: 'sakibul706@gmail.com',
                          onTap: () => _openUrl('mailto:sakibul706@gmail.com'),
                        ),
                        _LinkRow(
                          label: 'Telegram',
                          value: '@sakib26',
                          onTap: () => _openUrl('https://t.me/sakib26'),
                        ),
                        _LinkRow(
                          label: 'Web',
                          value: 'wizsk.github.io',
                          onTap: () => _openUrl('https://wizsk.github.io/'),
                        ),
                        _LinkRow(
                          label: 'GitHub',
                          value: 'github.com/wizsk',
                          onTap: () => _openUrl('https://github.com/wizsk'),
                        ),
                      ],
                    ),
                  ),

                  spaceBetweenSections,
                  _Section(
                    title: 'Resources ',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SubSection(
                          subTitle: 'Free Arabic Ebooks',
                          bullets: [
                            _LinkRow(
                              label: null,
                              value: 'safahat.org',
                              onTap: () => _openUrl('https://www.safahat.org/'),
                            ),
                          ],
                        ),

                        spaceBetweenSubSections,
                        _SubSection(
                          subTitle: 'Book Recommendations',
                          bullets: [
                            _LinkRow(
                              label: null,
                              value: 'wizsk.github.io/book_recommendations',
                              onTap: () => _openUrl(
                                'https://wizsk.github.io/book_recommendations.html',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String? title;
  final Widget child;

  const _Section({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Center(
                child: Text(
                  title!,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

const _bullet = '•'; //•●

class BulletSpans extends BulletBase {
  final InlineSpan child;

  const BulletSpans(this.child, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_bullet  ', style: theme.textTheme.bodyLarge),
          Expanded(child: Text.rich(child, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

sealed class BulletBase extends StatelessWidget {
  const BulletBase({super.key});
}

class Bullet extends BulletBase {
  final String text;

  const Bullet(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_bullet  ', style: theme.textTheme.bodyLarge),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

class _LinkRow extends BulletBase {
  final String? label;
  final String value;
  final VoidCallback onTap;

  const _LinkRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (label != null) ...[
              Text(
                '$label:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
            ] else
              Text(
                '$_bullet  ',
                style: theme.textTheme.bodyMedium!.copyWith(color: cs.primary),
              ),

            Flexible(
              child: Text(
                value,
                style: theme.textTheme.bodyMedium!.copyWith(color: cs.primary),
              ),
            ),

            // const SizedBox(width: 4),
            // Icon(Icons.open_in_new, size: 14, color: cs.primary),
          ],
        ),
      ),
    );
  }
}

class _SubTilte extends StatelessWidget {
  final String subTitle;
  const _SubTilte(this.subTitle);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Text(
      subTitle,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _SubSection extends StatelessWidget {
  final String subTitle;
  final List<BulletBase> bullets;
  const _SubSection({required this.subTitle, required this.bullets});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 3,
      children: [_SubTilte(subTitle), const SizedBox(height: 3), ...bullets],
    );
  }
}
