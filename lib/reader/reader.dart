import 'package:ara_dict/data.dart';
import 'package:ara_dict/etc.dart';
import 'package:ara_dict/reader/reader_utils.dart';
import 'package:ara_dict/reader/reader_widgets.dart';
import 'package:ara_dict/wigds.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void openReaderPage(BuildContext context, List<List<WordEntry>> paras) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      settings: const RouteSettings(name: Routes.readerPage),
      builder: (_) => ReaderPage(paras: paras),
    ),
  );
}

void _exitReaderPage(BuildContext context) =>
    Navigator.pushReplacementNamed(context, Routes.readerInput);

class ReaderPage extends StatefulWidget {
  final List<List<WordEntry>> paras;

  const ReaderPage({super.key, required this.paras});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isFabVisible = true;
  late final List<List<WordEntry>> _paras;
  late String _title;

  ReaderPageSettings _rs = ReaderPageSettings(
    isQasidah: false,
    isRmTashkil: false,
    isOpenLexiconDirecly: appSettingsNotifier.readerIsOpenLexiconDirecly,
    textAlign: TextAlign.justify,
  );

  @override
  void initState() {
    super.initState();
    _paras = widget.paras;
    _title = readerAppbarTitle(_paras, false);

    _scrollController.addListener(() {
      if (_scrollController.position.userScrollDirection ==
              ScrollDirection.reverse &&
          _isFabVisible) {
        setState(() {
          _isFabVisible = false;
        });
      } else if (_scrollController.position.userScrollDirection ==
              ScrollDirection.forward &&
          !_isFabVisible) {
        setState(() {
          _isFabVisible = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final arabicFontStyle = appSettingsNotifier.getArabicTextStyle(context);
    final highWordStyle = arabicFontStyle.copyWith(color: cs.error);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title,
          textDirection: TextDirection.rtl,
          style: TextStyle(fontFamily: arabicFontStyle.fontFamily),
        ),
        actions: [
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
          controller: _scrollController,
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

      floatingActionButton: AnimatedSlide(
        duration: Duration(milliseconds: 300),
        offset: _isFabVisible ? Offset.zero : Offset(0, 2),
        child: AnimatedOpacity(
          duration: Duration(milliseconds: 300),
          opacity: _isFabVisible ? 1.0 : 0.0,
          child: FloatingActionButton.small(
            onPressed: () async {
              final res = await showReaderModeSettings(
                context,
                _rs.copyWith(),
                _paras,
                () => _exitReaderPage(context),
              );

              if (res == null || _rs.isEqual(res)) {
                return;
              }

              if (_rs.isOpenLexiconDirecly != res.isOpenLexiconDirecly) {
                await appSettingsNotifier.saveReaderIsOpenLexiconDirecly(
                  res.isOpenLexiconDirecly,
                );
              }

              if (_rs.isRmTashkil != res.isRmTashkil) {
                _title = readerAppbarTitle(_paras, res.isRmTashkil);
              }

              _rs = res;
              setState(() {});
            },
            child: Icon(Icons.settings),
          ),
        ),
      ),
    );
  }
}
