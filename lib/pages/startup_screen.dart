import 'package:ara_dict/data.dart';
import 'package:ara_dict/datas/app_db.dart';
import 'package:ara_dict/lex/isolate.dart';
import 'package:ara_dict/lex/rearrange_dicts.dart';
import 'package:ara_dict/main_widgets.dart';
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
    try {
      await Future.wait([
        appConf.load(),
        setDictOrdFromFile(),
        AppDb.init(),
        Isolates.spawn(),
      ]);

      await Isolates.initArEn();
      Isolates.initSugg();

      appConf.notify();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, appConf.lastRoute);
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
