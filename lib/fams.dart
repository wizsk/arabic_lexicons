import 'package:ara_dict/data.dart';
import 'package:ara_dict/fams_data.dart';

import 'package:flutter/material.dart';

class ArabicFamilyList extends StatelessWidget {
  const ArabicFamilyList({super.key});

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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${verbInfo.formName} - ${verbInfo.pattern}',
                style: titleTextStyle.copyWith(color: colorScheme.onSurface),
              ),
              const Divider(),
              _buildSection(
                context,
                "Common Meaning",
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withAlpha(40),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
              // const SizedBox(height: 16),
            ],
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
    final arTextStyle = appSettingsNotifier.getArabicTextStyle(context);
    final titleTextStyle = Theme.of(context).textTheme.titleMedium!.copyWith(
      fontSize: arTextStyle.fontSize,
      fontFamily: arTextStyle.fontFamily,
      fontWeight: FontWeight.bold,
    );

    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text("Verb Families"),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () =>
                _showGrammerTerms(context, arTextStyle, titleTextStyle),
          ),
        ],
      ),
      // drawer: buildDrawer(context),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: verbFamilies.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final family = verbFamilies[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(15),
            ),
            color: colorScheme.surface,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              title: Text(
                '${family.formName} - ${family.pattern}',
                style: titleTextStyle.copyWith(
                  fontFamily: arTextStyle.fontFamily,
                ),
              ),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () =>
                  _showDetails(context, family, arTextStyle, titleTextStyle),
            ),
          );
        },
      ),
    );
  }
}
