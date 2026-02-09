import 'package:flutter/material.dart';

import 'package:ara_dict/alphabets.dart';
import 'package:ara_dict/etc.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/ar_en.dart';
import 'package:ara_dict/db.dart';
import 'package:ara_dict/res.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DbService.init();
  await ArEnDict.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Arabic Lexicons',
      theme: ThemeData(
        useMaterial3: true,
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: fontKitab,
          fontSizeFactor: 1.2,
          fontSizeDelta: 2.0,
          bodyColor: null,
          displayColor: null,
        ),

        scaffoldBackgroundColor: const Color(0xFFFFFAF3),
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ).copyWith(
            surface: const Color(0xFFFFFAF3),   // paper background
            onSurface: const Color(0xFF222223), // main text color
          ),
        // dividerColor: const Color(0xFFE6E1D8),
      ),
      home: SearchWithSelection(initialText: ''),
    );
  }
}

class SearchWithSelection extends StatefulWidget {
  final String initialText;

  const SearchWithSelection({super.key, this.initialText = ''});

  @override
  State<SearchWithSelection> createState() => _SearchWithSelectionState();
}

class _SearchWithSelectionState extends State<SearchWithSelection> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  late DictEntry _selectedDict;

  List<String> _words = [];
  String? _selectedWord;

  List<Map<String, dynamic>>? _dbRes;
  List<Entry>? _arEnRes;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.initialText);
    _onTextChanged(widget.initialText);

    _selectedDict = dictNames.first;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    // _dictScrollController.dispose();
    // _wordScrollController.dispose();
    DbService.close();
    super.dispose();
  }

  void _onTextChanged(String value) async {
    final parts = cleanQeury(value);

    setState(() {
      _words = parts;
      _selectedWord = parts.isNotEmpty ? parts.last : null;
      _arEnRes = null;
      _dbRes = [];
    });

    _loadWord();
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
    if (_selectedWord != null) {
      return Text("${_selectedDict.ar}: $_selectedWord");
    }
    return Text(_selectedDict.ar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: appBarTxt(), titleSpacing: 0.0),
      drawer: Drawer(child: Text("y")),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: showRes(_selectedDict.d, _dbRes, _arEnRes)),

            Divider(color: Colors.grey, thickness: 0.5),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      onChanged: _onTextChanged,
                      decoration: InputDecoration(
                        hintText: 'ابحث',
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: IconButton(
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
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black87),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        // filled: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.info),
                    onPressed: () async {
                      _focusNode.unfocus();
                      final res = await showWordPickerBottomSheet(
                        context,
                        dictNames,
                        _selectedDict,
                        _words,
                        _selectedWord,
                      );
                      if (res != null) {
                        _selectDict(res.de);
                        _selectWord(res.word!);
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
