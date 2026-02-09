import 'package:ara_dict/data.dart';
import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Help')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text.rich(
            TextSpan(
              children: [
                // TextSpan(
                //   text: 'Welcome to the Help page!\n\n',
                //   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                // ),
                TextSpan(text: 'Dictionarly/Laxicon English names:\n'),
                ...dictNames.map((itm) {
                  return TextSpan(text: "  • ${itm.en} is ${itm.ar}\n");
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
