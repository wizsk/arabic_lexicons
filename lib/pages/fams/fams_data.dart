import 'package:arabic_lexicons/data.dart';
import 'package:arabic_lexicons/pages/help/help.dart';
import 'package:flutter/material.dart';

class VerbFamilyInfo {
  final String formName;
  final String pattern;
  final String rootExample;
  final String commonMeaning;
  final String transitivity;
  final String explanation;
  final String morphologyNote;
  final List<VerbExample> examples;

  const VerbFamilyInfo({
    required this.formName,
    required this.pattern,
    required this.rootExample,
    required this.commonMeaning,
    required this.transitivity,
    required this.explanation,
    required this.morphologyNote,
    required this.examples,
  });
}

class VerbExample {
  final String arabic;
  final String literal;
  final String highlightedPart;

  const VerbExample({
    required this.arabic,
    required this.literal,
    required this.highlightedPart,
  });
}

class GrammarExplanation {
  final String term;
  final String definition;

  const GrammarExplanation(this.term, this.definition);
}

const grammarTerms = [
  GrammarExplanation(
    "Transitive Verb",
    "A verb that takes a direct object. The action passes from the doer to a receiver (e.g., 'He wrote the letter').",
  ),
  GrammarExplanation(
    "Intransitive Verb",
    "A verb that does not take a direct object. The action stays with the subject (e.g., 'He sat').",
  ),
  GrammarExplanation(
    "Reflexive",
    "The subject performs the action on itself or for itself (e.g., 'He washed himself').",
  ),
  GrammarExplanation(
    "Causative",
    "The subject causes someone or something else to do the action or enter a state (e.g., 'to teach' = 'to cause to know').",
  ),
  GrammarExplanation(
    "Reciprocal",
    "Two or more subjects perform the action on each other (e.g., 'They cooperated with each other').",
  ),
  GrammarExplanation(
    "Conative",
    "The action is directed toward someone or someone is engaged with, often with an attempt or effort (e.g., 'He fought him'). Typical of Form III.",
  ),
  GrammarExplanation(
    "Intensive",
    "The action is done with greater force, frequency, or to many objects (e.g., 'to smash to pieces' vs. 'to break').",
  ),
  GrammarExplanation(
    "Requestive (Seeking)",
    "Asking for or seeking to obtain the root meaning (e.g., 'to ask forgiveness'). Typical of Form X.",
  ),
  GrammarExplanation(
    "Medio-passive",
    "The subject undergoes the action with no doer mentioned (e.g., 'The cup broke'). Typical of Form VII.",
  ),
  GrammarExplanation(
    "Root (Jidhr / جذر)",
    "The base sequence of consonants (usually three) that carries the core meaning of a word, before vowels or added letters.",
  ),
  GrammarExplanation(
    "Triliteral",
    "A root made of exactly three consonants. This is the foundation of most Arabic verbs.",
  ),
  GrammarExplanation(
    "Gemination (Shadda)",
    "Doubling of a consonant, written with a shadda (ّ). It marks the middle letter in Forms II and V, and the final letter in Form IX.",
  ),
  GrammarExplanation(
    "Affix (Prefix/Infix)",
    "Letters added to the root. A prefix comes before it (like 'ista-' in Form X); an infix is inserted inside it (like the 't' in Form VIII).",
  ),
  GrammarExplanation(
    "Hamzat al-Wasl (همزة الوصل)",
    "A 'connecting' hamza at the start of Forms VII–X. It is pronounced only when beginning speech and drops after another word. Form IV's hamza is different: it is always pronounced.",
  ),
  GrammarExplanation(
    "Estimative",
    "A mental action where the subject considers the object to have a quality (e.g., 'He considered it good'). Common in Form X.",
  ),
  GrammarExplanation(
    "Feigning",
    "Pretending to have a quality or state one does not have (e.g., 'He pretended to be ignorant'). Characteristic of Form VI.",
  ),
  GrammarExplanation(
    "Stative",
    "A verb describing a state or condition (such as a color or physical defect) rather than a dynamic action. Typical of Form IX.",
  ),
];

const verbFamilies = [
  VerbFamilyInfo(
    formName: "I",
    pattern: "فَعَلَ",
    rootExample: "ك ت ب",
    commonMeaning: "Basic root meaning.",
    transitivity: "Transitive or intransitive (depends on the verb)",
    explanation:
        "The base form. It carries the core meaning of the root. Whether it takes an object depends on the individual verb.",
    morphologyNote:
        "Bare triliteral root with no added letters. The past-tense vowel on the middle letter varies: فَعَلَ / فَعِلَ / فَعُلَ.",
    examples: [
      VerbExample(
        arabic: "كَتَبَ الرَّجُلُ الرِّسَالَةَ",
        literal: "The man wrote the letter",
        highlightedPart: "كَتَبَ",
      ),
      VerbExample(
        arabic: "جَلَسَ الطِّفْلُ عَلَى الكُرْسِيِّ",
        literal: "The child sat on the chair",
        highlightedPart: "جَلَسَ",
      ),
      VerbExample(
        arabic: "ذَهَبَ الطَّالِبُ إِلَى الْمَدْرَسَةِ",
        literal: "The student went to school",
        highlightedPart: "ذَهَبَ",
      ),
    ],
  ),

  VerbFamilyInfo(
    formName: "II",
    pattern: "فَعَّلَ",
    rootExample: "ع ل م",
    commonMeaning: "Causative or Intensive.",
    transitivity: "Usually transitive",
    explanation:
        "Often makes an intransitive verb transitive, or a transitive verb take a second object (Causative: عَلِمَ 'to know' → عَلَّمَ 'to teach'). It can also mean doing the action intensively, repeatedly, or to many objects (Intensive).",
    morphologyNote: "Gemination (shadda) on the middle root letter.",
    examples: [
      VerbExample(
        arabic: "عَلَّمَ المُدَرِّسُ الطُّلَّابَ",
        literal: "The teacher taught the students (caused them to know)",
        highlightedPart: "عَلَّمَ",
      ),
      VerbExample(
        arabic: "كَسَّرَ الزُّجَاجَ",
        literal: "He smashed the glass to pieces (Intensive of 'broke')",
        highlightedPart: "كَسَّرَ",
      ),
    ],
  ),

  VerbFamilyInfo(
    formName: "III",
    pattern: "فَاعَلَ",
    rootExample: "ق ت ل",
    commonMeaning: "Directed action / Interaction.",
    transitivity: "Usually transitive",
    explanation:
        "The action is directed toward another person, often meaning to attempt, engage in, or do something with or against someone. Frequently implies a two-sided interaction.",
    morphologyNote: "Long vowel Alif added after the first root letter.",
    examples: [
      VerbExample(
        arabic: "قَاتَلَ الجُنْدِيُّ العَدُوَّ",
        literal: "The soldier fought the enemy",
        highlightedPart: "قَاتَلَ",
      ),
      VerbExample(
        arabic: "شَارَكَ المُوَظَّفُ فِي الاِجْتِمَاعِ",
        literal: "The employee participated in the meeting",
        highlightedPart: "شَارَكَ",
      ),
      VerbExample(
        arabic: "سَاعَدَ المُعَلِّمُ الطَّالِبَ",
        literal: "The teacher helped the student",
        highlightedPart: "سَاعَدَ",
      ),
    ],
  ),

  VerbFamilyInfo(
    formName: "IV",
    pattern: "أَفْعَلَ",
    rootExample: "خ ر ج",
    commonMeaning: "Causative.",
    transitivity: "Usually transitive",
    explanation:
        "The standard causative form. It makes an intransitive verb transitive (خَرَجَ 'to go out' → أَخْرَجَ 'to take out'), or a transitive verb take a second object. Some Form IV verbs have no clear causative sense (e.g., أَرْسَلَ).",
    morphologyNote:
        "Prefixed Hamza (أَ), always pronounced, with a sukun on the first root letter.",
    examples: [
      VerbExample(
        arabic: "أَخْرَجَ المُعَلِّمُ الكِتَابَ",
        literal: "The teacher took out the book (caused it to go out)",
        highlightedPart: "أَخْرَجَ",
      ),
      VerbExample(
        arabic: "أَرْسَلَ اللهُ الرُّسُلَ",
        literal: "Allah sent the messengers",
        highlightedPart: "أَرْسَلَ",
      ),
      VerbExample(
        arabic: "أَكْرَمَ الْمُضِيفُ الضَّيْفَ",
        literal: "The host honored the guest",
        highlightedPart: "أَكْرَمَ",
      ),
    ],
  ),

  VerbFamilyInfo(
    formName: "V",
    pattern: "تَفَعَّلَ",
    rootExample: "ع ل م",
    commonMeaning: "Reflexive of II / Gradual or effortful action.",
    transitivity: "Mostly intransitive (some verbs take an object)",
    explanation:
        "Often the reflexive or result of Form II (عَلَّمَ 'to teach' → تَعَلَّمَ 'to learn'). It can also imply gradual or effortful action. Some verbs, like تَعَلَّمَ and تَذَكَّرَ, still take an object.",
    morphologyNote:
        "Prefix (تَ) plus the Form II stem, with gemination (shadda) on the middle root letter.",
    examples: [
      VerbExample(
        arabic: "تَعَلَّمَ الطَّالِبُ الدَّرْسَ",
        literal: "The student learned the lesson",
        highlightedPart: "تَعَلَّمَ",
      ),
      VerbExample(
        arabic: "تَكَلَّمَ الرَّجُلُ بِوُضُوحٍ",
        literal: "The man spoke clearly",
        highlightedPart: "تَكَلَّمَ",
      ),
      VerbExample(
        arabic: "تَذَكَّرَ الْمَوْعِدَ",
        literal: "He remembered the appointment",
        highlightedPart: "تَذَكَّرَ",
      ),
    ],
  ),

  VerbFamilyInfo(
    formName: "VI",
    pattern: "تَفَاعَلَ",
    rootExample: "ع و ن",
    commonMeaning: "Reciprocity / Feigning.",
    transitivity: "Mostly intransitive (some verbs take an object)",
    explanation:
        "Indicates a mutual action between two or more parties (the reciprocal of Form III). It can also mean pretending to have a state, such as تَجَاهَلَ 'to feign ignorance'.",
    morphologyNote: "Prefix (تَ) plus the long Alif of Form III.",
    examples: [
      VerbExample(
        arabic: "تَعَاوَنَ الفَرِيقُ",
        literal: "The team cooperated (with each other)",
        highlightedPart: "تَعَاوَنَ",
      ),
      VerbExample(
        arabic: "تَجَاهَلَ المُدِيرُ الْمُشْكِلَةَ",
        literal:
            "The manager pretended not to know about the problem (feigned ignorance)",
        highlightedPart: "تَجَاهَلَ",
      ),
      VerbExample(
        arabic: "تَنَافَسَ اللَّاعِبُونَ",
        literal: "The players competed (against each other)",
        highlightedPart: "تَنَافَسَ",
      ),
    ],
  ),

  VerbFamilyInfo(
    formName: "VII",
    pattern: "اِنْفَعَلَ",
    rootExample: "ك س ر",
    commonMeaning: "Medio-passive (the action happens to the subject).",
    transitivity: "Intransitive",
    explanation:
        "Always intransitive. It describes the subject undergoing the action of Form I, with no doer mentioned (كَسَرَ 'to break something' → اِنْكَسَرَ 'to get broken'). Rare with roots beginning with ر ل م و ن ي.",
    morphologyNote: "Prefix اِنْ (Hamzat al-Wasl + nun) added before the root.",
    examples: [
      VerbExample(
        arabic: "اِنْكَسَرَ الكُوبُ",
        literal: "The cup broke",
        highlightedPart: "اِنْكَسَرَ",
      ),
      VerbExample(
        arabic: "اِنْقَطَعَ الاِتِّصَالُ",
        literal: "The connection was cut off",
        highlightedPart: "اِنْقَطَعَ",
      ),
      VerbExample(
        arabic: "اِنْفَتَحَ الْبَابُ",
        literal: "The door opened",
        highlightedPart: "اِنْفَتَحَ",
      ),
    ],
  ),

  VerbFamilyInfo(
    formName: "VIII",
    pattern: "اِفْتَعَلَ",
    rootExample: "ج م ع",
    commonMeaning: "Reflexive / Doing for oneself / Mutual action.",
    transitivity: "Varies",
    explanation:
        "Often the reflexive of Form I, meaning to do the action for oneself or to oneself (اِشْتَرَى 'to buy for oneself'). It can also express mutual action (اِجْتَمَعَ 'to gather'), and many verbs simply have a lexical meaning.",
    morphologyNote:
        "Infix (ت) inserted after the first root letter, with a prefixed Hamzat al-Wasl. The ت may change next to certain letters (e.g., اِصْطَبَرَ, اِزْدَحَمَ). With roots starting with س, the form looks like Form X (e.g., اِسْتَمَعَ 'to listen').",
    examples: [
      VerbExample(
        arabic: "اِجْتَمَعَ الْمُوَظَّفُونَ",
        literal: "The employees gathered/met",
        highlightedPart: "اِجْتَمَعَ",
      ),
      VerbExample(
        arabic: "اِشْتَرَى الرَّجُلُ سَيَّارَةً",
        literal: "The man bought a car (for himself)",
        highlightedPart: "اِشْتَرَى",
      ),
      VerbExample(
        arabic: "اِنْتَظَرَ الطَّالِبُ الْحَافِلَةَ",
        literal: "The student waited for the bus",
        highlightedPart: "اِنْتَظَرَ",
      ),
    ],
  ),

  VerbFamilyInfo(
    formName: "IX",
    pattern: "اِفْعَلَّ",
    rootExample: "ح م ر",
    commonMeaning: "Becoming a color / Physical defect.",
    transitivity: "Intransitive",
    explanation:
        "Used almost exclusively for turning a color (اِحْمَرَّ 'to turn red') or acquiring a physical defect (اِعْوَجَّ 'to become crooked'). It is rare compared to other forms.",
    morphologyNote:
        "Prefix Hamzat al-Wasl plus gemination (shadda) on the final root letter.",
    examples: [
      VerbExample(
        arabic: "اِحْمَرَّ وَجْهُهُ خَجَلًا",
        literal: "His face turned red from shyness",
        highlightedPart: "اِحْمَرَّ",
      ),
      VerbExample(
        arabic: "اِصْفَرَّتْ أَوْرَاقُ الشَّجَرِ",
        literal: "The tree leaves turned yellow",
        highlightedPart: "اِصْفَرَّتْ",
      ),
      VerbExample(
        arabic: "اِسْوَدَّتِ السَّمَاءُ",
        literal: "The sky turned black",
        highlightedPart: "اِسْوَدَّتِ",
      ),
    ],
  ),

  VerbFamilyInfo(
    formName: "X",
    pattern: "اِسْتَفْعَلَ",
    rootExample: "غ ف ر",
    commonMeaning: "Requesting / Estimative.",
    transitivity: "Usually transitive",
    explanation:
        "Indicates asking for the root meaning (غَفَرَ 'to forgive' → اِسْتَغْفَرَ 'to ask forgiveness') or considering something to have a quality (Estimative). Many verbs have a lexical meaning, such as اِسْتَخْدَمَ 'to use'.",
    morphologyNote:
        "Prefix اِسْتَ (Hamzat al-Wasl + sin + ta) added before the root.",
    examples: [
      VerbExample(
        arabic: "اِسْتَغْفَرَ الْمُؤْمِنُ رَبَّهُ",
        literal: "The believer asked his Lord for forgiveness",
        highlightedPart: "اِسْتَغْفَرَ",
      ),
      VerbExample(
        arabic: "اِسْتَخْدَمَ النَّاسُ التِّكْنُولُوجِيَا",
        literal: "People used technology (lexical meaning: to employ)",
        highlightedPart: "اِسْتَخْدَمَ",
      ),
      VerbExample(
        arabic: "اِسْتَحْسَنَ المُدِيرُ الاِقْتِرَاحَ",
        literal: "The manager considered the proposal good (Estimative)",
        highlightedPart: "اِسْتَحْسَنَ",
      ),
    ],
  ),
];

/// Sheet 1: all grammar terms.
Future<void> showGrammarTermsSheet(BuildContext context) {
  return _showScrollSheet(
    context,
    childrenBuilder: (context) {
      final text = Theme.of(context).textTheme;
      final scheme = Theme.of(context).colorScheme;
      return [
        Text('Grammar Terms', style: text.titleLarge),
        const SizedBox(height: 16),
        for (final term in grammarTerms) ...[
          Text(
            term.term,
            style: text.titleMedium?.copyWith(color: scheme.primary),
          ),
          const SizedBox(height: 4),
          Text(term.definition, style: text.bodyLarge),
          const Divider(height: 28),
        ],
      ];
    },
  );
}

/// Sheet 2: one verb family at a time.
Future<void> showVerbFamilySheet(BuildContext context, VerbFamilyInfo family) {
  return _showScrollSheet(
    context,
    childrenBuilder: (context) {
      final text = Theme.of(context).textTheme;
      final scheme = Theme.of(context).colorScheme;
      return [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text('Form ${family.formName}', style: text.titleLarge),
            ),
            Text(
              family.pattern,
              textDirection: TextDirection.rtl,
              style: text.headlineMedium?.copyWith(color: scheme.primary),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 8),

        Bullet(family.commonMeaning),
        Bullet(family.transitivity),
        const SizedBox(height: 8),

        _LabeledText(
          label: 'Example root',
          value: family.rootExample,
          rtl: true,
        ),
        _LabeledText(label: 'Explanation', value: family.explanation),
        _LabeledText(label: 'Morphology', value: family.morphologyNote),
        const SizedBox(height: 8),

        Text(
          'Examples',
          style: text.titleLarge?.copyWith(color: scheme.primary),
        ),
        const SizedBox(height: 8),
        for (final example in family.examples) _ExampleCard(example: example),
      ];
    },
  );
}

// ---------------------------------------------------------------------------
// Shared sheet scaffold
// ---------------------------------------------------------------------------

Future<void> _showScrollSheet(
  BuildContext context, {
  required List<Widget> Function(BuildContext context) childrenBuilder,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final scheme = Theme.of(sheetContext).colorScheme;
      return DraggableScrollableSheet(
        expand: false,
        snap: true,
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 1.0,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: scrollPaddingBottmSheet(context, sides: 16),
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ...childrenBuilder(sheetContext),
            ],
          );
        },
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class _LabeledText extends StatelessWidget {
  final String label;
  final String value;
  final bool rtl;

  const _LabeledText({
    required this.label,
    required this.value,
    this.rtl = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.titleMedium?.copyWith(color: scheme.primary)),
          const Divider(height: 12),
          Text(
            value,
            style: rtl ? text.titleMedium : text.bodyLarge,
            textDirection: rtl ? TextDirection.rtl : null,
          ),
        ],
      ),
    );
  }
}

class _ExampleCard extends StatelessWidget {
  final VerbExample example;

  const _ExampleCard({required this.example});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final base = text.headlineSmall?.copyWith(
      color: scheme.onSurface,
      height: 1.8,
    );
    final highlight = base?.copyWith(
      color: scheme.primary,
      fontWeight: FontWeight.bold,
    );

    final index = example.arabic.indexOf(example.highlightedPart);
    final InlineSpan span;
    if (index < 0) {
      span = TextSpan(text: example.arabic, style: base);
    } else {
      final end = index + example.highlightedPart.length;
      span = TextSpan(
        style: base,
        children: [
          TextSpan(text: example.arabic.substring(0, index)),
          TextSpan(
            text: example.arabic.substring(index, end),
            style: highlight,
          ),
          TextSpan(text: example.arabic.substring(end)),
        ],
      );
    }

    return Card.filled(
      margin: const EdgeInsets.only(bottom: 8),
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text.rich(span, textDirection: TextDirection.rtl),
            const SizedBox(height: 8),
            Text(
              example.literal,
              style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
