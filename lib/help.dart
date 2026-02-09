import 'package:ara_dict/wigds.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ara_dict/data.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Help')),
      drawer: buildDrawer(context),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8),
        child: SingleChildScrollView(
          child: Text.rich(
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
                  child: dictWordSelectModalOpenIcon,
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

                const TextSpan(text: 'Mail: '),
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

                const TextSpan(text: '\nGitHub: '),

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
