import 'package:arabic_lexicons/conf.dart';
import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/pages/fams/fams_data.dart';
import 'package:arabic_lexicons/utils.dart';
import 'package:flutter/material.dart';

class ArabicFamilyList extends StatefulWidget {
  const ArabicFamilyList({super.key});

  @override
  State<ArabicFamilyList> createState() => _ArabicFamilyListState();
}

class _ArabicFamilyListState extends State<ArabicFamilyList> {
  @override
  void initState() {
    super.initState();
    touggleFullScreen();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    touggleFullScreen();
  }

  @override
  Widget build(BuildContext context) {
    final titleTextStyle = Theme.of(context).textTheme.titleMedium!.copyWith(
      fontSize: L.fontSize,
      fontWeight: FontWeight.bold,
    );

    final colorScheme = Theme.of(context).colorScheme;
    final cs = colorScheme;

    // final txtSytle = the.copyWith(
    //   color: cs.onSurfaceVariant,
    //   fontWeight: FontWeight.w600,
    // );

    return Scaffold(
      // drawer: buildDrawer(context),
      body: GestureStack(
        child: Directionality(
          textDirection: TextDirection.rtl,
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
                      onPressed: () => showGrammarTermsSheet(context),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: appConf.readerPadd(context),
                sliver: SliverList.separated(
                  itemCount: verbFamilies.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final family = verbFamilies[index];

                    const size = 40.00;
                    final child = ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.primary,
                        ),
                        padding: const EdgeInsets.all(8),
                        alignment: AlignmentGeometry.center,
                        child: Text(
                          family.formName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      title: Text(family.pattern, style: titleTextStyle),
                      trailing: Icon(Icons.arrow_forward_ios, size: 12),
                      onTap: () => showVerbFamilySheet(context, family),
                    );

                    return segmentedListItem(
                      bg: cs.surfaceContainer,
                      index: index,
                      length: verbFamilies.length,
                      item: child,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
