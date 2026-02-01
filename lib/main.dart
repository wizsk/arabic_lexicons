import 'package:flutter/material.dart';
import 'package:salah_time/dict/parse.dart';

void main() {
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
  final String en;
  final String ar;

  const DictEntry({required this.en, required this.ar});
}

class _SearchWithSelectionState extends State<SearchWithSelection> {
  late final TextEditingController _controller;
  final ScrollController _chipScrollController = ScrollController();

  final List<DictEntry> _dictNames = [
    DictEntry(en: "arEn", ar: "مباشر"),
    DictEntry(en: "hanswehr", ar: "هانز"),
    DictEntry(en: "lanelexcon", ar: "لين"),
    DictEntry(en: "mujamul_ghoni", ar: "الغني"),
    DictEntry(en: "mujamul_shihah", ar: "مختار"),
    DictEntry(en: "lisanularab", ar: "لسان"),
    DictEntry(en: "mujamul_muashiroh", ar: "المعاصرة"),
    DictEntry(en: "mujamul_wasith", ar: "الوسيط"),
    DictEntry(en: "mujamul_muhith", ar: "المحيط"),
  ];

  late String _selectedDict;

  List<String> _words = [];
  String? _selectedWord;

  final arEnDict = Dictionary();

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.initialText);
    _onTextChanged(widget.initialText);

    _selectedDict = _dictNames.first.en;
  }

  void _onTextChanged(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    setState(() {
      _words = parts;
      _selectedWord = parts.isNotEmpty ? parts.last : null;
    });

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

  @override
  void dispose() {
    _controller.dispose();
    _chipScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بحث')),

      // body: Center(
      //   child: Text(
      //     _selectedWord == null
      //         ? 'لا توجد كلمة مختارة'
      //         : 'الكلمة المختارة: $_selectedWord',
      //     style: const TextStyle(fontSize: 20),
      //   ),
      // ),
      //
      body: showArEnRes(
        _selectedWord == null ? null : arEnDict.findWord(_selectedWord!),
      ),

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
                      final en = entry.en;
                      final ar = entry.ar;

                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text(ar), // Arabic name
                          selected: en == _selectedDict,
                          onSelected: (_) => setState(() {
                            _selectedDict = en;
                          }),
                        ),
                      );
                    }).toList(),
                    // children: _words.reversed.map((word) {
                    // }).toList(),
                  ),
                ),
              ),
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
