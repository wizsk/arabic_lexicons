import 'package:ara_dict/ar_en.dart';
import 'package:ara_dict/book_marks.dart';
import 'package:flutter/material.dart';
import 'package:ara_dict/txt.dart';
import 'package:ara_dict/wigds.dart';
import 'package:flutter/foundation.dart';
import 'package:ara_dict/etc.dart';
import 'package:ara_dict/res.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/db.dart';

class SearchLexicons extends StatefulWidget {
  final bool showDrawer;
  final String initialText;

  const SearchLexicons({
    super.key,
    this.showDrawer = true,
    this.initialText = '',
  });

  @override
  State<SearchLexicons> createState() => _SearchLexiconsState();
}

class _SearchLexiconsState extends State<SearchLexicons> {
  final int _maxTextSize = 500;
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  late DictEntry _selectedDict;
  late bool _showDrawer;

  List<String> _words = [];
  String? _selectedWord;

  List<Map<String, dynamic>>? _dbRes;
  List<Entry>? _arEnRes;

  @override
  void initState() {
    super.initState();

    _showDrawer = widget.showDrawer;
    _selectedDict = dictNames.first;

    _controller = TextEditingController(text: widget.initialText);
    if (widget.initialText.isNotEmpty) {
      _onTextChanged(widget.initialText);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    if (value.length > _maxTextSize) {
      value = value.length > _maxTextSize
          ? value.substring(0, _maxTextSize)
          : value;

      _controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Text too long, reduced to $_maxTextSize chars'),
          duration: Duration(seconds: 3),
        ),
      );
    }

    final (parts, currWord) = getNextWord(
      value,
      _controller.selection.base.offset,
    );

    if (!listEquals(_words, parts) || currWord != _selectedWord) {
      setState(() {
        _words = parts;
        _selectedWord = currWord;
        _arEnRes = null;
        _dbRes = [];
      });

      _loadWord();
    }
  }

  void _selectWord(String word) {
    if (word == _selectedWord) return;

    setState(() {
      _selectedWord = word;
      _dbRes = [];
      _arEnRes = null;
    });

    _loadWord();
  }

  void _selectDict(DictEntry de) {
    if (_selectedDict.d == de.d) {
      return;
    }
    setState(() {
      _selectedDict = de;
      _dbRes = [];
      _arEnRes = null;
    });

    _loadWord();
  }

  Future<void> _loadWord() async {
    if (_selectedWord == null || _selectedWord!.isEmpty) {
      _dbRes = null;
      _arEnRes = null;
      return;
    }

    switch (_selectedDict.d) {
      case Dict.arEn:
        _arEnRes = ArEnDict.findWord(_selectedWord);

      case Dict.hanswehr:
        _dbRes = await DbService.getByWordHans(_selectedWord);

      case Dict.laneLexicon:
        _dbRes = await DbService.getByWordLane(_selectedWord);

      case Dict.mujamulGhoni:
        _dbRes = await DbService.getByWordGoni(_selectedWord);

      case Dict.mujamulShihah:
      case Dict.lisanAlArab:
      case Dict.mujamulMuashiroh:
      case Dict.mujamulWasith:
      case Dict.mujamulMuhith:
        _dbRes = await DbService.getByWordWith3Rows(
          getDictTableName(_selectedDict.d),
          _selectedWord,
        );
    }

    setState(() {});
  }

  Widget appBarTxt() {
    final arabicFontStyle = appSettingsNotifier.getArabicTextStyle(context);
    final fontStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontFamily: arabicFontStyle.fontFamily,
    );

    if (_selectedWord != null) {
      return Text.rich(
        TextSpan(
          // style: ,
          children: [
            TextSpan(text: _selectedDict.ar, style: fontStyle),
            TextSpan(
              text: ': $_selectedWord ',
              style: TextStyle(fontFamily: arabicFontStyle.fontFamily),
            ),
            // if (bm) WidgetSpan(child: Icon(Icons.bookmark)),
          ],
        ),
        textDirection: TextDirection.rtl,
      );
    }
    return Text.rich(TextSpan(text: _selectedDict.ar, style: fontStyle));
  }

  @override
  Widget build(BuildContext context) {
    final arTxtTheme = appSettingsNotifier.getArabicTextStyle(context);
    final bm = BookMarks.isSet(_selectedWord);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: appBarTxt(),
        titleSpacing: 0.0,
        actions: [
          IconButton(
            icon: Icon(bm ? Icons.bookmark : Icons.bookmark_border),
            onPressed: _selectedWord == null
                ? null
                : () {
                    if (bm) {
                      BookMarks.rm(_selectedWord!);
                    } else {
                      BookMarks.add(_selectedWord!);
                    }
                    setState(() {});
                  },
          ),
        ],
      ),
      drawer: _showDrawer ? buildDrawer(context) : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: showRes(
                arTxtTheme,
                _selectedDict.d,
                _selectedWord,
                _dbRes,
                _arEnRes,
                cs,
              ),
            ),

            Divider(thickness: 0.5, height: 0),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      onChanged: _onTextChanged,
                      style: arTxtTheme,
                      decoration: InputDecoration(
                        hintText: 'ابحث',
                        prefixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _controller.clear();
                              _selectedWord = null;
                              _words = [];
                              _dbRes = [];
                              _arEnRes = null;
                            });
                            // this is when it's focued but keyboard is not oppended
                            _focusNode.requestFocus();
                          },

                          icon: Icon(Icons.clear),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 5),
                  IconButton.filledTonal(
                    icon: Icon(dictWordSelectModalOpenIcon),
                    onPressed: () async {
                      _focusNode.unfocus();
                      final res = await showWordPickerBottomSheet(
                        context,
                        dictNames,
                        _selectedDict,
                        _words,
                        _selectedWord,
                        arTxtTheme,
                      );

                      // the way it works only one can change if it changes the set state is called surely
                      // or we call manually to update bookmark info
                      if (res != null) {
                        if (res.de.d != _selectedDict.d) {
                          _selectDict(res.de);
                        } else if (res.word != _selectedWord) {
                          _selectWord(res.word!);
                        } else {
                          setState(() {});
                        }
                      } else {
                        setState(() {});
                      }
                    },
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
