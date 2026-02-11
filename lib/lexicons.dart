import 'package:ara_dict/ar_en.dart';

import 'package:ara_dict/theme.dart';
import 'package:flutter/material.dart';

import 'package:ara_dict/sv.dart';
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

  void _onTextChanged(String value) async {
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
      // fontSize: 20,
      fontFamily: arabicFontStyle.fontFamily,
    );

    if (_selectedWord != null) {
      return Text.rich(
        TextSpan(
          // style: ,
          children: [
            TextSpan(text: _selectedDict.ar, style: fontStyle),
            TextSpan(
              text: ': $_selectedWord',
              style: TextStyle(fontFamily: arabicFontStyle.fontFamily),
            ),
          ],
        ),
      );
    }
    return Text.rich(TextSpan(text: _selectedDict.ar, style: fontStyle));
  }

  @override
  Widget build(BuildContext context) {
    final arTxtTheme = appSettingsNotifier.getArabicTextStyle(context);
    return Scaffold(
      appBar: AppBar(title: appBarTxt(), titleSpacing: 0.0),
      drawer: _showDrawer ? buildDrawer(context) : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: showRes(arTxtTheme, _selectedDict.d, _dbRes, _arEnRes),
            ),

            Divider(thickness: 0.5, height: 0),
            Padding(
              // padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 8,
                right: 2,
                left: 8,
              ),
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
                        prefixIcon: _controller.text.isEmpty
                            ? IconButton(
                                onPressed: () async {
                                  final txt = await getClipboardText();
                                  if (txt != null && txt.isNotEmpty) {
                                    _controller.clear();
                                    _controller.text = txt;
                                    _focusNode.unfocus();
                                    _onTextChanged(txt);
                                  }
                                },
                                icon: Icon(Icons.paste),
                              )
                            : IconButton(
                                onPressed: () {
                                  setState(() {
                                    _controller.clear();
                                    _selectedWord = null;
                                    _words = [];
                                    _dbRes = [];
                                    _arEnRes = null;
                                  });
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
                  IconButton(
                    icon: dictWordSelectModalOpenIcon,
                    iconSize: mediumFontSize * 1.5,
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
                      if (res != null) {
                        _selectDict(res.de);
                        if (res.word != null) _selectWord(res.word!);
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
