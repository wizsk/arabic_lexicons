import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/datas/lex_entry_bookmark.dart';
import 'package:arabic_lexicons/lex/def_card.dart';
import 'package:arabic_lexicons/theme.dart';
import 'package:arabic_lexicons/utils/toast_snack.dart';
import 'package:arabic_lexicons/widgets/reader_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LexBnDefPage extends StatefulWidget {
  final LexEntryBmEnty en;
  final VoidCallback? onRemove;
  final VoidCallback? onAdd;

  const LexBnDefPage({super.key, required this.en, this.onRemove, this.onAdd});

  static Future<void> open(
    BuildContext context, {
    required LexEntryBmEnty en,
    VoidCallback? onAdd,
    VoidCallback? onRemove,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LexBnDefPage(en: en, onAdd: onAdd, onRemove: onRemove),
      ),
    );
  }

  @override
  State<LexBnDefPage> createState() => _LexBnDefPageState();
}

class _LexBnDefPageState extends State<LexBnDefPage> {
  @override
  Widget build(BuildContext context) {
    final e = widget.en;

    final padd = appConf.readerPadd(context, top: 8);
    final theme = Theme.of(context);

    final ts = appConf.readerTS(context);

    final (fontFam, fontHeight) = appConf.useHansLaneDefRDStyle
        ? (appConf.readerFont, appConf.readerFontHeight)
        : (fontAmiri, htmlFontHeight);

    final fontSize = appConf.readerFontSize;

    final child = widget.en.formatDef(
      context,
      ts: ts,
      hlFont: fontFam,
      hlFontSize: fontSize,
      hlFontHeight: fontHeight,
      hlhiColor: getBookmarkBg(context),
    );

    final isSaved = widget.en.isSaved;

    return ReaderThemed(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${widget.en.dict.name}: ${widget.en.word}',
            textDirection: L.dir,
            style: L.arStyle,
          ),

          actions: [
            if (!widget.en.dict.isArEn)
              IconButton(
                tooltip: "Save/Remove defintion",
                icon: Icon(
                  isSaved ? Icons.bookmark_remove : Icons.bookmark_add_outlined,
                ),
                color: isSaved ? theme.colorScheme.error : null,
                onPressed: () async {
                  final w = widget.en.word;
                  final d = widget.en.dict;
                  if (isSaved) {
                    final res = await showSavedDefRmConfirm(context, w, d);
                    if (res != true) return;

                    await widget.en.remove();
                    widget.onRemove?.call();

                    MsgSv.showSnackbarMsg("Definition removed: $w");
                  } else {
                    await widget.en.save();
                    widget.onAdd?.call();

                    MsgSv.showSnackbarMsg("Definition added: $w");
                  }
                  if (context.mounted) setState(() {});
                },
              ),

            IconButton(
              tooltip: "Copy Text",
              icon: Icon(Icons.copy_all),
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: e.r.cleanedTxt(e.dict)),
                );
                MsgSv.showSnackbarMsg("Text Copied!");
              },
            ),
          ],
        ),
        body: Directionality(
          textDirection: widget.en.dict.dir,
          child: SafeArea(
            child: ListView(
              padding: padd,
              children: [
                SelectionArea(
                  magnifierConfiguration: TextMagnifierConfiguration.disabled,
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
