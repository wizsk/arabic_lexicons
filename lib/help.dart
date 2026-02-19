import 'package:ara_dict/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ara_dict/data.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});
  static const buildUnix = int.fromEnvironment('BUILD_UNIX_TIME');
  static const appVersion = String.fromEnvironment('APP_VERSION');
  static const gitCommit = String.fromEnvironment('GIT_COMMIT');
  static const gitCommitMsg = String.fromEnvironment('GIT_COMMIT_MSG');

  @override
  Widget build(BuildContext context) {
    String buildTimeFormatted = '';

    if (buildUnix != 0) {
      DateTime buildTimeUtc = DateTime.fromMillisecondsSinceEpoch(
        buildUnix * 1000,
        isUtc: true,
      );
      DateTime buildTimeLocal = buildTimeUtc.toLocal();
      buildTimeFormatted = formatDateTime(context, buildTimeLocal);
    }

    return Scaffold(
      appBar: AppBar(title: Text('Help')),
      // drawer: buildDrawer(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8),
          child: Text.rich(
            style: TextStyle(
              fontSize: appSettingsNotifier
                  .getArabicTextStyle(context)
                  .fontSize,
            ),
            TextSpan(
              children: [
                // info
                TextSpan(
                  text: 'Info:\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      'This app is a collection of ${dictNames.length - 1} lexicons and 1 dictionary for ease of access.\n',
                ),
                TextSpan(text: '  • Search multiple word at the same time\n'),
                TextSpan(text: '  • Pase a full sentece and go through it\n'),
                TextSpan(
                  text:
                      '  • Change lexcion for going into depth of the meaning\n\n',
                ),

                TextSpan(
                  text: 'English names:\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...dictNames.map((itm) {
                  return TextSpan(text: "  • ${itm.en} is ${itm.ar}\n");
                }),

                // about dicts
                TextSpan(
                  text: "\nChanging Lexcion or Word:\n",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: 'Click on the '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Icon(dictWordSelectModalOpenIcon),
                ),
                TextSpan(
                  text:
                      ' icon to open lexicon and word selector. By default the lexicons are presented, and if thre are more than 1 word then they are shown on top.\n\n',
                ),

                // about text editing
                TextSpan(
                  text: "Auto select edited word:\n",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      'When typing the edited word will automatically selected. For example you have typed "Foo bar bazz", by default "bazz" will be selected as it\'s the last word, then if you edit "bar" to "baar", then "baar" will be selected.\n\n',
                ),

                const TextSpan(
                  text: 'For more info and updates:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: '\nGo to: '),
                TextSpan(
                  text: 'github.com/wizsk/arabic_lexicons/',
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      launchUrl(
                        Uri.parse('https://github.com/wizsk/arabic_lexicons/'),
                      );
                    },
                ),

                if (appVersion.isNotEmpty ||
                    buildTimeFormatted.isNotEmpty ||
                    gitCommit.isNotEmpty ||
                    gitCommitMsg.isNotEmpty)
                  const TextSpan(text: '\n'),

                if (appVersion.isNotEmpty) ...[
                  const TextSpan(
                    text: '\nApp version:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' $appVersion'),
                ],

                if (buildTimeFormatted.isNotEmpty) ...[
                  const TextSpan(
                    text: '\nBuild Time:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' $buildTimeFormatted'),
                ],

                if (buildTimeFormatted.isNotEmpty) ...[
                  const TextSpan(
                    text: '\nGit commit:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' $gitCommit'),
                ],

                if (buildTimeFormatted.isNotEmpty) ...[
                  const TextSpan(
                    text: '\nGit commit msg:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: ' $gitCommitMsg'),
                ],

                const TextSpan(
                  text: '\n\nMail: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: 'sakibul706@gmail.com',
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      launchUrl(Uri.parse('mailto:sakibul706@gmail.com'));
                    },
                ),

                const TextSpan(
                  text: '\nGitHub: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                TextSpan(
                  text: 'github.com/wizsk',
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      launchUrl(Uri.parse('https://github.com/wizsk'));
                    },
                ),

                TextSpan(text: "\n\n"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
