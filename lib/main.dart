import 'package:flutter/material.dart';
import 'package:salah_time/data.dart';
import 'package:salah_time/arEn.dart';
import 'package:salah_time/db.dart';
import 'package:salah_time/res.dart';

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
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.yellow),
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
  final ScrollController _chipScrollController = ScrollController();

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
  }

  void _onTextChanged(String value) async {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    setState(() {
      _words = parts;
      _selectedWord = parts.isNotEmpty ? parts.last : null;
    });

    _loadWord();

    // Auto-scroll to show last (rightmost) chip
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chipScrollController.hasClients) {
        _chipScrollController.animateTo(
          0, // RTL: start = right
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _selectWord(String word) {
    setState(() {
      _selectedWord = word;
    });

    _loadWord();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chipScrollController.hasClients) {
        _chipScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
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
  void dispose() {
    _controller.dispose();
    _chipScrollController.dispose();
    DbService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('بحث')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: showRes(_selectedDict, _dbRes, _arEnRes)),

            Material(
              elevation: 10, // 👈 shadow strength
              shadowColor: Colors.black26,
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.withAlpha(25), width: 1),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_words.length > 1)
                    SizedBox(
                      height: 40,
                      child: SingleChildScrollView(
                        controller: _chipScrollController,
                        scrollDirection: Axis.horizontal,
                        reverse: true, // 🔴 critical for RTL
                        child: Row(
                          children: _words.reversed.map((word) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ChoiceChip(
                                showCheckmark: false,
                                label: Text(word),
                                selected: word == _selectedWord,
                                onSelected: (_) => _selectWord(word),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                  if (_words.length > 1) const SizedBox(height: 8),

                  SizedBox(
                    height: 40,
                    child: SingleChildScrollView(
                      controller: _chipScrollController,
                      scrollDirection: Axis.horizontal,
                      reverse: true, // 🔴 critical for RTL
                      child: Row(
                        children: dictNames.reversed.map((entry) {
                          final en = entry.d;
                          final ar = entry.ar;

                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: ChoiceChip(
                              label: Text(ar), // Arabic name
                              showCheckmark: false,
                              selected: en == _selectedDict,
                              onSelected: (_) {
                                if (_selectedDict != en) {
                                  setState(() {
                                    _selectedDict = en;
                                  });
                                  _loadWord();
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    onChanged: _onTextChanged,
                    decoration: InputDecoration(
                      hintText: 'اكتب كلمات مفصولة بمسافة',
                      prefixIcon: IconButton(
                        onPressed: () => setState(() {
                          _controller.clear();
                          _selectedWord = null;
                          _words = [];
                        }),
                        icon: Icon(Icons.clear),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
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
