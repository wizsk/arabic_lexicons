import 'package:ara_dict/conf.dart';
import 'package:ara_dict/data.dart';
import 'package:ara_dict/pages/fams/fams_data.dart';
import 'package:ara_dict/utils.dart';
import 'package:flutter/material.dart';

class ArabicFamilyList extends StatefulWidget {
  const ArabicFamilyList({super.key});

  @override
  State<ArabicFamilyList> createState() => _ArabicFamilyListState();
}

class _ArabicFamilyListState extends State<ArabicFamilyList> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    touggleFullScreen();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    touggleFullScreen();
  }

  void _showDetails(
    BuildContext context,
    // ArabicFamily family,
    VerbFamilyInfo verbInfo,
    TextStyle arTextStyle,
    TextStyle titleTextStyle,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return DraggableScrollableSheet(
          initialChildSize: 0.97,
          minChildSize: 0.45,
          maxChildSize: 1.0,
          expand: false,
          builder: (context, controller) => SingleChildScrollView(
            padding: scrollPaddingBottmSheet(context),
            controller: controller,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${verbInfo.formName} - ${verbInfo.pattern}',
                  style: titleTextStyle.copyWith(color: colorScheme.onSurface),
                ),
                const Divider(),
                _buildSection(
                  context,
                  "Common Meaning (Not Rule)",
                  verbInfo.commonMeaning,
                  arTextStyle,
                ),
                _buildSection(
                  context,
                  "Transitivity",
                  verbInfo.transitivity,
                  arTextStyle,
                ),
                _buildSection(
                  context,
                  "Explanation",
                  verbInfo.explanation,
                  arTextStyle,
                ),
                const SizedBox(height: 16),
                _buildSection(
                  context,
                  "Examples",
                  verbInfo.examples
                      .map((e) => "${e.arabic}\n${e.literal}")
                      .join("\n"),
                  arTextStyle,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showGrammerTerms(
    BuildContext context,
    TextStyle arTextStyle,
    TextStyle titleTextStyle,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return DraggableScrollableSheet(
          initialChildSize: 0.97,
          minChildSize: 0.45,
          maxChildSize: 1.0,
          expand: false,
          builder: (_, controller) => SingleChildScrollView(
            padding: scrollPaddingBottmSheet(context),
            controller: controller,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Grammar Glossary",
                  style: titleTextStyle.copyWith(color: colorScheme.onSurface),
                ),
                const Divider(),
                ...grammarTerms.map(
                  (e) => _buildSection(
                    context,
                    "${e.term}:",
                    e.definition,
                    arTextStyle,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    TextStyle arTextStyle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: arTextStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          Text(
            content,
            style: arTextStyle.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final arTextStyle = appConf.readerTS(context);

    final titleTextStyle = Theme.of(context).textTheme.titleMedium!.copyWith(
      fontSize: arTextStyle.fontSize,
      fontFamily: arTextStyle.fontFamily,
      fontWeight: FontWeight.bold,
    );

    final colorScheme = Theme.of(context).colorScheme;
    final cs = colorScheme;
    final txtSytle = L.arStyle.copyWith(fontWeight: FontWeight.w600);

    return Scaffold(
      // drawer: buildDrawer(context),
      body: GestureStack(
        child: CustomScrollView(
          slivers: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: SliverAppBar(
                floating: true,
                snap: appConf.hideAppbar,
                pinned: !appConf.hideAppbar,
                title: Text(
                  L.p('Verb Families', 'أوزان الأفعال'),
                  style: L.arStyleIf,
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.info_outline),
                    onPressed: () =>
                        _showGrammerTerms(context, arTextStyle, titleTextStyle),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: appConf.readerPadd(context),
              sliver: SliverList.separated(
                itemCount: verbFamilies.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final family = verbFamilies[index];
                  return Material(
                    color: cs.surfaceContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: cs.outlineVariant, width: 1),
                    ),
                    clipBehavior: Clip.antiAlias,

                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      title: Text(
                        '${family.formName} - ${family.pattern}',
                        style: txtSytle,
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 12),
                      onTap: () => _showDetails(
                        context,
                        family,
                        arTextStyle,
                        titleTextStyle,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
