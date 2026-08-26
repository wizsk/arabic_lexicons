import 'dart:math' as math;

import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/datas/stories_txts.dart';
import 'package:arabic_lexicons/reader/reader_utils.dart';
import 'package:arabic_lexicons/reader/reader_widgets.dart';
import 'package:arabic_lexicons/reader/settings_class.dart';
import 'package:arabic_lexicons/stories.dart';
import 'package:arabic_lexicons/theme.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:flutter/material.dart';

EdgeInsets readerPadding(
  BuildContext context, {
  required double maxWidth,
  required double sidePadd,
}) {
  final padd = maxWidth < 0
      ? sidePadd
      : ((MediaQuery.of(context).size.width - maxWidth) / 2).clamp(
          sidePadd,
          double.infinity,
        );

  return EdgeInsets.fromLTRB(
    padd,
    scrollPadding.top,
    padd,
    scrollPadding.bottom,
  );
}

class ReaderAdjustData {
  double padding;
  double maxWidth;
  double fontSize;
  double fontHeight;
  String fontFam;

  ReaderAdjustData({
    required this.fontFam,
    required this.fontSize,
    required this.fontHeight,
    required this.padding,
    required this.maxWidth,
  });

  static ReaderAdjustData def() {
    return ReaderAdjustData(
      fontFam: defaultReaderArabicFont,
      fontHeight: defArabicFontHeihgt,
      fontSize: defaultReaderArabicFontSize,
      maxWidth: ReaderPageSettings.maxWidthDef,
      padding: ReaderPageSettings.paddingDef,
    );
  }

  static ReaderAdjustData fromConf(AppSettingsController c) {
    return ReaderAdjustData(
      padding: c.padding,
      maxWidth: c.maxWidth,
      fontFam: c.readerFont,
      fontSize: c.readerFontSize,
      fontHeight: c.readerFontHeight,
    );
  }

  static ReaderAdjustData fromReaderPageSettings(ReaderPageSettings s) {
    return ReaderAdjustData(
      padding: s.padding,
      maxWidth: s.maxWidth,
      fontFam: s.fontFam,
      fontSize: s.fontSize,
      fontHeight: s.fontHeight,
    );
  }

  bool isEq(ReaderAdjustData b) {
    return padding == b.padding &&
        maxWidth == b.maxWidth &&
        fontFam == b.fontFam &&
        fontHeight == b.fontHeight &&
        fontSize == b.fontSize;
  }

  ReaderAdjustData copyWith({
    double? padding,
    double? maxWidth,
    double? fontSize,
    double? fontHeight,
    String? fontFam,
  }) {
    return ReaderAdjustData(
      padding: padding ?? this.padding,
      maxWidth: maxWidth ?? this.maxWidth,
      fontFam: fontFam ?? this.fontFam,
      fontSize: fontSize ?? this.fontSize,
      fontHeight: fontHeight ?? this.fontHeight,
    );
  }

  ReaderAdjustData copy() {
    return ReaderAdjustData(
      padding: padding,
      maxWidth: maxWidth,
      fontFam: fontFam,
      fontSize: fontSize,
      fontHeight: fontHeight,
    );
  }
}

const double minReaderFontSize = 14.00;
const double maxReaderFontSize = 36.00;

class ReaderAdjustPage extends StatefulWidget {
  final ReaderAdjustData data;
  final List<String>? paras;

  const ReaderAdjustPage({super.key, required this.data, this.paras});

  static Future<ReaderAdjustData?> open(
    BuildContext context, {
    required ReaderAdjustData data,
    List<String>? paras,
  }) async {
    return Navigator.push<ReaderAdjustData?>(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderAdjustPage(data: data, paras: paras),
      ),
    );
  }

  @override
  State<ReaderAdjustPage> createState() => _ReaderAdjustPageState();
}

class _ReaderAdjustPageState extends State<ReaderAdjustPage> {
  late ReaderAdjustData _data;

  int _currentTab = 0;
  bool _hidden = false;

  bool _showingDemoTxt = true;
  late final bool _hasProvidedDemoTxt;

  late List<String> _paras;
  int _demoTxtIdx = 0;

  @override
  void initState() {
    super.initState();
    touggleFullScreen();

    _data = widget.data.copyWith();
    if (widget.paras != null && widget.paras!.isNotEmpty) {
      _paras = widget.paras!;
      _showingDemoTxt = false;
      _hasProvidedDemoTxt = true;
    } else {
      _paras = stories[_demoTxtIdx];
      _hasProvidedDemoTxt = false;
    }
  }

  @override
  void dispose() {
    snackClearForced();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    touggleFullScreen();
  }

  bool get _hasChanges => !widget.data.isEq(_data);

  void _save() {
    Navigator.of(context).pop(_data);
  }

  Widget _appbar() {
    return SliverAppBar(
      title: const Text('Reader Style'),
      centerTitle: false,
      floating: true,
      snap: appConf.hideAppbar,
      pinned: !appConf.hideAppbar,
      actions: [
        FilledButton.icon(
          onPressed: _hasChanges ? _save : null,
          label: const Text('Save'),
          icon: Icon(Icons.save),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            switch (value) {
              case 'reset':
                final old = _data.copy();
                final n = ReaderAdjustData.def();
                if (old.isEq(n)) {
                  showSnack(context, 'Already using the default style');
                  break;
                }

                setState(() {
                  _data = n;
                });

                showSnack(
                  context,
                  'Style reset',
                  forceCloseAfter: Duration(seconds: 6),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      if (!context.mounted) return;
                      setState(() {
                        _data = old;
                      });
                    },
                  ),
                );
                break;

              case 'visible':
                setState(() {
                  _hidden = !_hidden;
                });
                showSnack(
                  context,
                  'Pro tip: Tap the currently selected bottom icon to toggle its popup',
                  duration: const Duration(seconds: 5),
                  showCloseIcon: true,
                );
                break;

              case 'demo-txt':
                setState(() {
                  if (_showingDemoTxt) {
                    _paras = widget.paras ?? stories[_demoTxtIdx];
                    _showingDemoTxt = false;
                  } else {
                    _showingDemoTxt = true;
                    _paras = stories[_demoTxtIdx];
                  }
                });
                break;

              case 'demo-cng':
                final idx = await showStoryPicker(context);
                if (idx != null &&
                    idx >= 0 &&
                    idx < stories.length &&
                    context.mounted) {
                  setState(() {
                    _demoTxtIdx = idx;
                    _paras = stories[_demoTxtIdx];
                  });
                }
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'reset',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.restore),
                  const SizedBox(width: 10),
                  Text('Reset All'),
                ],
              ),
            ),
            // const PopupMenuDivider(height: 0,),
            PopupMenuItem(
              value: 'visible',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _hidden
                    ? const [
                        Icon(Icons.visibility_outlined),
                        SizedBox(width: 10),
                        Text('Show Popup'),
                      ]
                    : const [
                        Icon(Icons.visibility_off_outlined),
                        SizedBox(width: 10),
                        Text('Hide Popup'),
                      ],
              ),
            ),
            if (_hasProvidedDemoTxt)
              PopupMenuItem(
                value: 'demo-txt',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _showingDemoTxt
                      ? const [
                          Icon(Icons.menu_book_outlined),
                          SizedBox(width: 10),
                          Text('Reader Text'),
                        ]
                      : const [
                          Icon(Icons.play_circle_outline),
                          SizedBox(width: 10),
                          Text('Demo Text'),
                        ],
                ),
              ),
            if (_showingDemoTxt)
              PopupMenuItem(
                value: 'demo-cng',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.swap_horiz_outlined),
                    SizedBox(width: 10),
                    Text('Change Text'),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final th = theme.textTheme;

    final previewStyle = appConf
        .readerTS(context)
        .copyWith(
          fontFamily: _data.fontFam,
          fontSize: _data.fontSize,
          height: _data.fontHeight,
        );

    final titleStyle = th.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    );

    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (i) => setState(() {
          if (_currentTab == i && !_hidden) {
            _hidden = true;
            return;
          }
          _hidden = false;
          _currentTab = i;
        }),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.text_fields),
            label: 'Size',
          ),
          const NavigationDestination(
            icon: Icon(Icons.text_format_sharp),
            label: 'Height',
          ),
          const NavigationDestination(
            icon: Icon(Icons.font_download_outlined),
            label: 'Font',
          ),
          const NavigationDestination(
            icon: Icon(Icons.space_bar),
            label: 'Margin',
          ),
          NavigationDestination(
            icon: Transform.rotate(
              angle: 90 * math.pi / 180, // 90 degrees
              child: const Icon(Icons.expand),
            ),
            label: 'Width',
          ),
        ],
      ),
      body: Stack(
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: CustomScrollView(
              key: ValueKey((_showingDemoTxt, _demoTxtIdx)),
              slivers: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: _appbar(),
                ),
                SliverPadding(
                  padding: EdgeInsetsGeometry.only(bottom: 12),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        'Preview',
                        style: th.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                       ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: readerPadding(
                    context,
                    maxWidth: _data.maxWidth,
                    sidePadd: _data.padding,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      childCount: _paras.length,
                      (context, index) {
                        return Padding(
                          padding: paraSpaceInbetween(_data.fontSize),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                paraSpacerStart(_data.fontSize),
                                TextSpan(text: _paras[index]),
                              ],
                            ),
                            textAlign: TextAlign.justify,
                            textDirection: TextDirection.rtl,
                            style: previewStyle,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!_hidden)
            Align(
              alignment: AlignmentGeometry.bottomCenter,
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: switch (_currentTab) {
                      0 => _Changer(
                        key: const ValueKey('fontSize'),
                        title: 'Font size',
                        subTitle: 'Make the text smaller or larger.',
                        current: _data.fontSize,
                        minV: minReaderFontSize,
                        maxV: maxReaderFontSize,
                        def: defaultReaderArabicFontSize,
                        step: 1,
                        setVal: (v) => setState(() => _data.fontSize = v),
                      ),
                      1 => _Changer(
                        key: const ValueKey('fontHeight'),
                        title: 'Font height',
                        subTitle: 'Make the font height smaller or larger.',
                        valName: '%',
                        current: _data.fontHeight * 100,
                        minV: 40,
                        maxV: 400,
                        def: defArabicFontHeihgt * 100,
                        step: 20,
                        setVal: (v) =>
                            setState(() => _data.fontHeight = v / 100),
                      ),
                      2 => _FontPicker(
                        key: const ValueKey('font'),
                        fonts: arabicFonts,
                        selectedFont: _data.fontFam,
                        titleStyle: titleStyle,
                        onSelect: (font) =>
                            setState(() => _data.fontFam = font),
                      ),
                      3 => _Changer(
                        key: const ValueKey('padding'),
                        title: 'Side Margin',
                        subTitle:
                            'Minimum padding on small screens like phones',
                        current: _data.padding,
                        minV: 0,
                        maxV: 50,
                        def: ReaderPageSettings.paddingDef,
                        step: 5,
                        setVal: (v) => setState(() => _data.padding = v),
                      ),
                      4 => _Changer(
                        key: const ValueKey('width'),
                        title: 'Max Paragraph Width',
                        subTitle:
                            'Limits line length on wide screens like tablets',
                        current: _data.maxWidth,
                        minV: 400,
                        maxV: 1200,
                        def: ReaderPageSettings.maxWidthDef,
                        step: 20,
                        setVal: (v) => setState(() => _data.maxWidth = v),
                        touggleDisable: () {
                          setState(() {
                            if (_data.maxWidth > 0) {
                              _data.maxWidth = -1;
                            } else {
                              _data.maxWidth = ReaderPageSettings.maxWidthDef;
                            }
                          });
                        },
                        disabled: _data.maxWidth < 0,
                      ),
                      _ => const SizedBox.shrink(),
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FontPicker extends StatelessWidget {
  final List<String> fonts;
  final String selectedFont;
  final TextStyle? titleStyle;
  final ValueChanged<String> onSelect;

  const _FontPicker({
    super.key,
    required this.fonts,
    required this.selectedFont,
    required this.titleStyle,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Font family', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Pick a font for the reader.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...separatedList(
              items: fonts,
              separatorBuilder: (_) => const SizedBox(height: 10),
              itemBuilder: (font, _) {
                final isSelected = font == selectedFont;

                return Material(
                  color: isSelected ? cs.primaryContainer : cs.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: isSelected ? cs.primary : cs.outlineVariant,
                      width: isSelected ? 1.4 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    title: Text(
                      font,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: isSelected
                          ? titleStyle?.copyWith(color: cs.onPrimaryContainer)
                          : titleStyle,
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle, color: cs.primary)
                        : null,
                    onTap: () => onSelect(font),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Changer extends StatelessWidget {
  final String title;
  final String subTitle;
  final double current;
  final double minV;
  final double maxV;
  final double def;
  final int step;
  final void Function(double w) setVal;
  final VoidCallback? touggleDisable;
  final bool disabled;
  final String valName;

  const _Changer({
    super.key,
    required this.title,
    required this.subTitle,
    required this.current,
    required this.minV,
    required this.maxV,
    required this.def,
    required this.step,
    required this.setVal,
    this.touggleDisable,
    this.disabled = false,
    this.valName = 'px',
  });

  @override
  Widget build(BuildContext context) {
    final divs = ((maxV - minV) / step).round();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final th = theme.textTheme;

    final subTitleStyle = th.bodySmall?.copyWith(color: cs.onSurfaceVariant);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: th.titleMedium),
            if (subTitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(subTitle, style: subTitleStyle),
            ],
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    disabled ? "Disabled" : '${current.round()}$valName',
                    style: th.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      IconButton.filled(
                        icon: const Icon(Icons.remove),
                        onPressed: disabled || current <= minV
                            ? null
                            : () => setVal(current - step.toDouble()),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.restore),
                        onPressed: disabled || current == def
                            ? null
                            : () => setVal(def),
                      ),
                      if (touggleDisable != null)
                        IconButton.filledTonal(
                          tooltip: 'Disable/Enable',
                          icon: Icon(
                            disabled ? Icons.check_circle : Icons.block,
                          ),
                          onPressed: touggleDisable,
                        ),
                      IconButton.filled(
                        icon: const Icon(Icons.add),
                        onPressed: disabled || current >= maxV
                            ? null
                            : () => setVal(current + step.toDouble()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${minV.toInt()}px', style: subTitleStyle),
                  Text('${maxV.toInt()}px', style: subTitleStyle),
                ],
              ),
            ),
            Slider(
              value: disabled ? def : current,
              min: minV,
              max: maxV,
              divisions: divs,
              onChanged: disabled ? null : setVal,
            ),
          ],
        ),
      ),
    );
  }
}
