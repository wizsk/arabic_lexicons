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
    "A verb that requires a direct object. The action passes to something.",
  ),
  GrammarExplanation(
    "Intransitive Verb",
    "A verb that does not take a direct object. The action remains with the subject.",
  ),
  GrammarExplanation("Reflexive", "The subject performs the action on itself."),
  GrammarExplanation(
    "Causative",
    "The subject causes someone else to perform the action.",
  ),
  GrammarExplanation(
    "Reciprocal",
    "Two or more subjects perform the action on each other.",
  ),
  GrammarExplanation("Intensive", "The action is strengthened or repeated."),
  GrammarExplanation(
    "Seeking Form",
    "Indicates seeking, requesting, or attempting to obtain something.",
  ),
];

const verbFamilies = [
  VerbFamilyInfo(
    formName: "I",
    pattern: "فَعَلَ",
    rootExample: "ك ت ب",
    commonMeaning: "Basic root meaning.",
    transitivity: "Both",
    explanation:
        "I carries the core lexical meaning of the root. It can be transitive or intransitive depending on the root.",
    morphologyNote: "Pure triliteral root without additional letters.",
    examples: [
      VerbExample(
        arabic: "كَتَبَ الرَّجُلُ الرِّسَالَةَ",
        literal: "The man wrote the letter",
        highlightedPart: "كَتَبَ",
      ),
      VerbExample(
        arabic: "جَلَسَ الطِّفْلُ",
        literal: "The child sat",
        highlightedPart: "جَلَسَ",
      ),
    ],
  ),

  VerbFamilyInfo(
    formName: "II",
    pattern: "فَعَّلَ",
    rootExample: "ع ل م",
    commonMeaning: "Intensive or causative.",
    transitivity: "Usually Transitive",
    explanation:
        "II strengthens or intensifies the root meaning. Often causative.",
    morphologyNote: "Gemination (shadda) on middle root letter.",
    examples: [
      VerbExample(
        arabic: "عَلَّمَ المُدَرِّسُ الطُّلَّابَ",
        literal: "The teacher taught the students",
        highlightedPart: "عَلَّمَ",
      ),
    ],
  ),

  VerbFamilyInfo(
    formName: "III",
    pattern: "فَاعَلَ",
    rootExample: "ق ت ل",
    commonMeaning: "Reciprocal interaction.",
    transitivity: "Transitive",
    explanation: "Implies participation between two parties.",
    morphologyNote: "Long vowel after first root letter.",
    examples: [
      VerbExample(
        arabic: "قَاتَلَ الجُنْدِيُّ العَدُوَّ",
        literal: "The soldier fought the enemy",
        highlightedPart: "قَاتَلَ",
      ),
    ],
  ),

  VerbFamilyInfo(
    formName: "IV",
    pattern: "أَفْعَلَ",
    rootExample: "خ ر ج",
    commonMeaning: "Causative.",
    transitivity: "Transitive",
    explanation:
        "Indicates causing someone or something to do the root action.",
    morphologyNote: "Prefix أَ added to triliteral root.",
    examples: [
      VerbExample(
        arabic: "أَخْرَجَ المُعَلِّمُ الطُّلَّابَ",
        literal: "The teacher made the students go out",
        highlightedPart: "أَخْرَجَ",
      ),
    ],
  ),

  VerbFamilyInfo(
    formName: "V",
    pattern: "تَفَعَّلَ",
    rootExample: "ع ل م",
    commonMeaning: "Reflexive of II.",
    transitivity: "Usually Intransitive",
    explanation: "Subject performs action upon itself.",
    morphologyNote: "Prefix تَ plus II structure.",
    examples: [
      VerbExample(
        arabic: "تَعَلَّمَ الطَّالِبُ",
        literal: "The student learned",
        highlightedPart: "تَعَلَّمَ",
      ),
    ],
  ),

  VerbFamilyInfo(
    formName: "VI",
    pattern: "تَفَاعَلَ",
    rootExample: "ع و ن",
    commonMeaning: "Mutual action.",
    transitivity: "Reciprocal",
    explanation: "Indicates mutual participation.",
    morphologyNote: "Prefix تَ plus III structure.",
    examples: [
      VerbExample(
        arabic: "تَعَاوَنَ الطُّلَّابُ",
        literal: "The students cooperated",
        highlightedPart: "تَعَاوَنَ",
      ),
    ],
  ),

  VerbFamilyInfo(
    formName: "VII",
    pattern: "اِنْفَعَلَ",
    rootExample: "ك س ر",
    commonMeaning: "Passive or reflexive.",
    transitivity: "Intransitive",
    explanation:
        "Often indicates passive meaning without explicit passive form.",
    morphologyNote: "Prefix اِنْ added before root.",
    examples: [
      VerbExample(
        arabic: "اِنْكَسَرَ الزُّجَاجُ",
        literal: "The glass broke",
        highlightedPart: "اِنْكَسَرَ",
      ),
    ],
  ),

  VerbFamilyInfo(
    formName: "VIII",
    pattern: "اِفْتَعَلَ",
    rootExample: "ج م ع",
    commonMeaning: "Internalized or effortful action.",
    transitivity: "Usually Transitive",
    explanation: "Often indicates exertion or deliberate action.",
    morphologyNote: "Infix ت after first root letter.",
    examples: [
      VerbExample(
        arabic: "اِجْتَمَعَ القَوْمُ",
        literal: "The people gathered",
        highlightedPart: "اِجْتَمَعَ",
      ),
    ],
  ),

  VerbFamilyInfo(
    formName: "IX",
    pattern: "اِفْعَلَّ",
    rootExample: "ح م ر",
    commonMeaning: "Colors or defects.",
    transitivity: "Intransitive",
    explanation: "Used primarily for colors and physical states.",
    morphologyNote: "Gemination on final root letter.",
    examples: [
      VerbExample(
        arabic: "اِحْمَرَّ الوَجْهُ",
        literal: "The face became red",
        highlightedPart: "اِحْمَرَّ",
      ),
    ],
  ),

  VerbFamilyInfo(
    formName: "X",
    pattern: "اِسْتَفْعَلَ",
    rootExample: "غ ف ر",
    commonMeaning: "Seeking or requesting.",
    transitivity: "Usually Transitive",
    explanation: "Indicates seeking or attempting to obtain the root meaning.",
    morphologyNote: "Prefix اِسْتَ added before triliteral root.",
    examples: [
      VerbExample(
        arabic: "اِسْتَغْفَرَ الرَّجُلُ رَبَّهُ",
        literal: "The man sought forgiveness from his Lord",
        highlightedPart: "اِسْتَغْفَرَ",
      ),
    ],
  ),
];

List<TextSpan> highlightArabic(
  BuildContext context,
  String text,
  String highlight,
) {
  final cs = Theme.of(context).colorScheme;
  final parts = text.split(highlight);

  if (parts.length < 2) {
    return [TextSpan(text: text)];
  }

  return [
    TextSpan(text: parts[0]),
    TextSpan(
      text: highlight,
      style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
    ),
    TextSpan(text: parts[1]),
  ];
}

class GrammarTermsSection extends StatelessWidget {
  const GrammarTermsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 8,
        // runSpacing: 8,
        children: [
          // Padding(
          //   padding: const EdgeInsets.all(20),
          //   child: Text('Grammar terms:'),
          // ),
          ActionChip(label: Text('Grammar terms:')),
          ...grammarTerms.map((term) {
            return ActionChip(
              label: Text(term.term),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // drag handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade500,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // Text('${words.length}'),
                        const SizedBox(height: 12),
                        Text(
                          term.term,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(term.definition),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
