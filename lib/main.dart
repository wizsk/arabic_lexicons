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
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: fontKitab,
          fontSizeFactor: 1.2,
          fontSizeDelta: 2.0,
          bodyColor: null,
          displayColor: null,
        ),

        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFFAF3),

        colorScheme: const ColorScheme.light(
          primary: Color(0xFF285A8C), // dark accent
          secondary: Color(0xFF3A6FA6), // lighter accent
          tertiary: Color(0xFF285A8C), // use same as primary for selected items

          surface: Color(0xFFFFFAF3), // paper background
          onSurface: Color(0xFF222223), // main text color

          surfaceContainerLowest: Color(0xFFFFFAF3),
          surfaceContainerLow: Color(0xFFF7F1E6),
          surfaceContainer: Color(0xFFF2ECDD),

          outline: Color(0xFFE6E1D8),
          error: Color(0xFFB84A4A),
        ),

        dividerColor: const Color(0xFFE6E1D8),

        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF285A8C),
          selectionColor: Color(0xFF3A6FA6),
          selectionHandleColor: Color(0xFF285A8C),
        ),
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

  // final ScrollController _wordScrollController = ScrollController();

  // final ScrollController _dictScrollController = ScrollController();
  // double _dictScrollOffset = 0;

  late Dict _selectedDict;

  List<String> _words = [];
  String? _selectedWord;

  List<Map<String, dynamic>>? _dbRes;
  List<Entry>? _arEnRes;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.initialText);
    _onTextChanged(widget.initialText);

    _selectedDict = dictNames.first.d;

    // _dictScrollController.addListener(() {
    //   _dictScrollOffset = _dictScrollController.offset;
    // });
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

    // // Auto-scroll to show last (rightmost) chip
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (_dictScrollController.offset != _dictScrollOffset) {
    //     _dictScrollController.jumpTo(_dictScrollOffset);
    //   }
    //   if (_wordScrollController.hasClients) {
    //     _wordScrollController.animateTo(
    //       _wordScrollController.position.maxScrollExtent,
    //       duration: const Duration(milliseconds: 250),
    //       curve: Curves.easeOut,
    //     );
    //   }
    // });

    _loadWord();
  }

  void _selectWord(String word) {
    setState(() {
      _selectedWord = word;
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

    switch (_selectedDict) {
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
          getDictTableName(_selectedDict),
          _selectedWord,
        );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: showRes(_selectedDict, _dbRes, _arEnRes)),

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
                        final en = res.dict;
                        if (_selectedDict != en) {
                          setState(() {
                            _selectedDict = en;
                            _dbRes = [];
                            _arEnRes = null;
                          });
                          _loadWord();
                        }
                        if (res.word != null && res.word != _selectedWord) {
                          _selectWord(res.word!);
                        }
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
