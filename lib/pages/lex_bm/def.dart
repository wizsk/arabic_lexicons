import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/datas/lex_entry_bookmark.dart';
import 'package:arabic_lexicons/lex/res.dart';
import 'package:arabic_lexicons/theme.dart';
import 'package:flutter/material.dart';

class LexBnDefPage extends StatelessWidget {
  final LexEntryBmEnty en;
  final TextAlign align;
  final TextDirection dir;
  final Widget def;

  const LexBnDefPage({
    super.key,
    required this.en,
    required this.dir,
    required this.align,
    required this.def,
  });

  static Future<void> open(
    BuildContext context, {
    required LexEntryBmEnty en,
    required TextDirection dir,
    required TextAlign align,
    required Widget def,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LexBnDefPage(en: en, align: align, dir: dir, def: def),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padd = appConf.readerPadd(context);
    final theme = Theme.of(context);

    final ts = appConf.readerTS(context);

    final fontFam = appConf.useHansLaneDefRDStyle
        ? appConf.readerFont
        : fontAmiri;

    final fontSize = appConf.readerFontSize;
    final fontHeight = htmlFontHeight;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hiColor = isDark ? bookmarkWordBgDark : bookmarkWordBg;

    final def = en;
    final isEng = def.dict.isEng;

    final child = def.dict.isArEn
        ? Directionality(
            textDirection: TextDirection.ltr,
            child: Text(def.meanings, style: ts, textAlign: TextAlign.left),
          )
        : isEng
        ? engMeaningView(
            def.meanings,
            fontSize,
            fontHeight,
            fontFam,
            theme.colorScheme,
            false,
            hiColor,
          )
        : def.r.arMeaningView(context, ts: ts, hasRefs: def.dict.hasRefs);

    final dir = isEng ? TextDirection.ltr : TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${en.dict.name}: ${en.word}',
          textDirection: L.dir,
          style: L.arStyle,
        ),
      ),
      body: Directionality(
        textDirection: dir,
        child: SingleChildScrollView(
          padding: padd,
          child: Column(
            children: [
              const SizedBox(height: 12),
              SelectionArea(
                magnifierConfiguration: TextMagnifierConfiguration.disabled,
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
