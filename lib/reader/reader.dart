import 'package:ara_dict/data.dart';
import 'package:ara_dict/etc.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:ara_dict/reader/reader_widgets.dart';
import 'package:ara_dict/main_widgets.dart';
import 'package:flutter/material.dart';

class ReaderPage extends StatefulWidget {
  final List<List<WordEntry>> paras;

  const ReaderPage({super.key, required this.paras});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late final List<List<WordEntry>> _paras;
  late String _title;

  ReaderPageSettings _rs = ReaderPageSettings(
    isQasidah: false,
    isRmTashkil: false,
    isOpenLexiconDirecly: appSettingsNotifier.readerIsOpenLexiconDirecly,
    textAlign: appSettingsNotifier.readerRightAligned
        ? TextAlign.right
        : TextAlign.justify,
  );

  @override
  void initState() {
    super.initState();
    _paras = widget.paras;
    _title = readerAppbarTitle(_paras, false);
  }

  void _settingsDrawer() async {
    final res = await showReaderModeSettings(context, _rs.copyWith(), _paras);
    if (res == null || _rs.isEqual(res)) {
      return;
    }

    if (_rs.isOpenLexiconDirecly != res.isOpenLexiconDirecly) {
      await appSettingsNotifier.saveReaderIsOpenLexiconDirecly(
        res.isOpenLexiconDirecly,
      );
    }

    if (_rs.textAlign != res.textAlign) {
      await appSettingsNotifier.saveReaderRightAligned(
        res.textAlign == TextAlign.right,
      );
    }

    if (_rs.isRmTashkil != res.isRmTashkil) {
      _title = readerAppbarTitle(_paras, res.isRmTashkil);
    }

    _rs = res;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final arabicFontStyle = appSettingsNotifier.getArabicTextStyle(context);
    final highWordStyle = arabicFontStyle.copyWith(color: cs.error);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _exitReaderPage(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _title,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontFamily: arabicFontStyle.fontFamily),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: _settingsDrawer,
              tooltip: 'Reader Mode settings',
            ),
            IconButton(
              icon: Icon(Icons.exit_to_app_outlined),
              tooltip: 'Exit Reader',
              onPressed: () => _exitReaderPage(context),
            ),
          ],
        ),
        drawer: buildDrawer(context),
        body: SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ).copyWith(bottom: 128),
            itemCount: _paras.length,
            itemBuilder: (context, index) {
              final textAlign = _rs.isQasidah ? TextAlign.right : _rs.textAlign;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ClickableParagraph(
                  peraIndex: index,
                  rs: _rs,
                  pera: _paras[index],
                  textStyleBodyMedium: arabicFontStyle,
                  highTextStyleBodyMedium: highWordStyle,
                  textAlign: textAlign,
                  onChange: () => setState(() {}),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

void openReaderPage(BuildContext context, List<List<WordEntry>> paras) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      settings: const RouteSettings(name: Routes.readerPage),
      builder: (_) => ReaderPage(paras: paras),
    ),
  );
}

void _exitReaderPage(BuildContext context) async {
  if (!context.mounted) return;
  if (await showConfirmDialog(
        context,
        'Exit Reader',
        message: 'Go to reader input page?',
      ) ??
      false) {
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, Routes.readerInput);
  }
}
