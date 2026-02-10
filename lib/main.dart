import 'package:ara_dict/help.dart';
import 'package:ara_dict/reader.dart';
import 'package:ara_dict/sv.dart';
import 'package:ara_dict/theme.dart';
import 'package:ara_dict/txt.dart';
import 'package:ara_dict/wigds.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:ara_dict/etc.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/ar_en.dart';
import 'package:ara_dict/db.dart';
import 'package:ara_dict/res.dart';

final themeModeNotifier = ThemeController();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DbService.init();
  await ArEnDict.init();
  await themeModeNotifier.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Arabic Lexicons',

          theme: buildLightTheme(context),
          darkTheme: buildDarkTheme(context),
          themeMode: mode,
          initialRoute: Routes.dictionary,
          routes: {
            Routes.dictionary: (_) => const SearchWithSelection(),
            Routes.reader: (_) => const ReaderPage(),
            Routes.help: (_) => const HelpPage(),
          },
        );
      },
    );
  }
}

class SearchWithSelection extends StatefulWidget {
  final bool showDrawer;
  final String initialText;

  const SearchWithSelection({
    super.key,
    this.showDrawer = true,
    this.initialText = '',
  });

  @override
  State<SearchWithSelection> createState() => _SearchWithSelectionState();
}

class _SearchWithSelectionState extends State<SearchWithSelection> {
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
    final fontStyle = TextStyle(fontWeight: FontWeight.bold);

    if (_selectedWord != null) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(text: _selectedDict.ar, style: fontStyle),
            TextSpan(text: ': $_selectedWord'),
          ],
        ),
      );
    }
    return Text.rich(TextSpan(text: _selectedDict.ar, style: fontStyle));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: appBarTxt(), titleSpacing: 0.0),
      drawer: _showDrawer ? buildDrawer(context) : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: showRes(_selectedDict.d, _dbRes, _arEnRes)),

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
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'ابحث',
                        prefixIcon: _controller.text.isEmpty
                            ? IconButton(
                                onPressed: () async {
                                  final txt = await getClipboardText();
                                  if (txt != null) {
                                    _controller.clear();
                                    _controller.text = txt;
                                    _focusNode.unfocus();
                                    setState(() {});
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

class Routes {
  static const dictionary = '/dictionary';
  static const reader = '/reader';
  static const help = '/help';
}

class AppScaffold extends StatelessWidget {
  final Widget body;
  final Widget title;
  final List<Widget>? actions;

  const AppScaffold({
    super.key,
    required this.body,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: title, titleSpacing: 0.0),
      drawer: buildDrawer(context),
      body: body,
    );
  }
}
