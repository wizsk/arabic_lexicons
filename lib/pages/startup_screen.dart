import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/datas/app_db.dart';
import 'package:arabic_lexicons/key_shortcuts.dart';
import 'package:arabic_lexicons/lex/dicts/db.dart';
import 'package:arabic_lexicons/lex/isolate.dart';
import 'package:arabic_lexicons/lex/rearrange_dicts.dart';
import 'package:arabic_lexicons/main_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    AppShortcut.assertUniqueKeys();

    try {
      // final s = Stopwatch()..start();
      await Future.wait([
        appConf.load(),
        setDictOrdFromFile(),
        DbService.init(copy: true),
        AppDb.init(),
      ]);

      Isolates.spawn().then((_) {
        Isolates.initArEn();
        Isolates.initSugg();
      });

      // s.stop();

      appConf.notify();

      // if (!mounted) return;
      // await showInfoDialog(
      //   context,
      //   'All took',
      //   message: '${s.elapsedMilliseconds}ms',
      // );

      if (!mounted) return;

      final r = appConf.firstRun ? Routes.welcome : appConf.lastRoute;
      Navigator.pushReplacementNamed(context, r);
    } catch (e) {
      if (mounted) {
        await showInfoDialog(
          context,
          'Fetal error',
          message: 'Could not read resources: $e',
          confirmText: 'Exit',
        );
      }
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // appBar: AppBar(title: Text("Loading...")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading resources...'),
          ],
        ),
      ),
    );
  }
}
