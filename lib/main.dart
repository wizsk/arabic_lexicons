import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:salah_time/dict/arEn.dart';
import 'package:salah_time/db.dart';

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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
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

class DictEntry {
  final Dict d;
  final String ar;

  const DictEntry({required this.d, required this.ar});
}

enum Dict {
  arEn,
  hanswehr,
  laneLexicon,
  mujamulGhoni,
  mujamulShihah,
  lisanAlArab,
  mujamulMuashiroh,
  mujamulWasith,
  mujamulMuhith,
}

String getDictTableName(Dict d) {
  switch (d) {
    case Dict.arEn:
      return "arEn";
    case Dict.hanswehr:
      return "hanswehr";
    case Dict.laneLexicon:
      return "lanelexcon";
    case Dict.mujamulGhoni:
      return "mujamul_ghoni";
    case Dict.mujamulShihah:
      return "mujamul_shihah";
    case Dict.lisanAlArab:
      return "lisanularab";
    case Dict.mujamulMuashiroh:
      return "mujamul_muashiroh";
    case Dict.mujamulWasith:
      return "mujamul_wasith";
    case Dict.mujamulMuhith:
      return "mujamul_muhith";
  }
}

final List<DictEntry> _dictNames = [
  DictEntry(d: Dict.arEn, ar: "مباشر"),
  DictEntry(d: Dict.hanswehr, ar: "هانز"),
  DictEntry(d: Dict.laneLexicon, ar: "لين"),
  DictEntry(d: Dict.mujamulGhoni, ar: "الغني"),
  DictEntry(d: Dict.mujamulShihah, ar: "مختار"),
  DictEntry(d: Dict.lisanAlArab, ar: "لسان"),
  DictEntry(d: Dict.mujamulMuashiroh, ar: "المعاصرة"),
  DictEntry(d: Dict.mujamulWasith, ar: "الوسيط"),
  DictEntry(d: Dict.mujamulMuhith, ar: "المحيط"),
];

// final List<DictEntry> _dictNames = [
//   DictEntry(d: Dict.ArEn, ar: "مباشر"),
//   DictEntry(d: Dict.hanswehr, ar: "هانز"),
//   DictEntry(d: Dict.lanelexcon, ar: "لين"),
//   DictEntry(d: Dict.mujamul_ghoni, ar: "الغني"),
//   DictEntry(d: Dict.mujamul_shihah, ar: "مختار"),
//   DictEntry(d: Dict.lisanularab, ar: "لسان"),
//   DictEntry(d: Dict.mujamul_muashiroh, ar: "المعاصرة"),
//   DictEntry(d: Dict.mujamul_wasith, ar: "الوسيط"),
//   DictEntry(d: Dict.mujamul_muhith, ar: "المحيط"),
// ];

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

    _selectedDict = _dictNames.first.d;
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
      appBar: AppBar(title: const Text('بحث')),
      body: showRes(_selectedDict, _dbRes, _arEnRes),

      bottomNavigationBar: SafeArea(
        child: Padding(
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
                    children: _dictNames.reversed.map((entry) {
                      final en = entry.d;
                      final ar = entry.ar;

                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text(ar), // Arabic name
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
      ),
    );
  }
}

Widget showArEnRes(List<Entry>? entries) {
  if (entries == null || entries.isEmpty) {
    return const Center(child: Text('No results'));
  }

  return SingleChildScrollView(
    child: Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24.0,
          columns: const [
            DataColumn(label: Text('Word')),
            DataColumn(label: Text('Definition')),
            DataColumn(label: Text('Root')),
          ],
          rows: entries.map((e) {
            return DataRow(
              cells: [
                DataCell(Text(e.word)),
                DataCell(Text(e.def)),
                DataCell(Text(e.root)),
              ],
            );
          }).toList(),
        ),
      ),
    ),
  );
}

Widget showRes(
  Dict curDict,
  List<Map<String, dynamic>>? dbRes,
  List<Entry>? arEnRes,
) {
  switch (curDict) {
    case Dict.arEn:
      return showArEnRes(arEnRes);
    // case "":
    default:
  }

  var dir = TextDirection.rtl;
  var al = TextAlign.right;
  if (curDict == Dict.hanswehr || curDict == Dict.laneLexicon) {
    al = TextAlign.left;
    dir = TextDirection.ltr;
  }
  if (dbRes != null && dbRes.isNotEmpty) {
    return ListView.separated(
      itemCount: dbRes.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 24, thickness: 1),
      itemBuilder: (context, index) {
        final row = dbRes[index];
        // return RichText(text: TextSpan(text: row['meanings']));
        return ListTile(
          title: Text(row['word'] ?? '', textDirection: dir, textAlign: al),
          subtitle: meaningView(row['meanings'] ?? '', dir, al),
        );
      },
    );
  }
  return Center(child: Text("loading"));
}

Widget meaningView(String html, TextDirection dir, TextAlign al) {
  return Directionality(
    textDirection: TextDirection.rtl, // Arabic
    child: Html(
      data: html,
      style: {
        'body': Style(
          fontSize: FontSize(16),
          lineHeight: LineHeight.number(1.6),
          direction: dir,
          textAlign: al,
        ),
        'strong': Style(fontWeight: FontWeight.bold),
        'i': Style(fontStyle: FontStyle.italic),
      },
    ),
  );
}
