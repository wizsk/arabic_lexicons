

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
    "A verb that requires a direct object. The action passes from the doer to a receiver (e.g., 'He wrote the letter').",
  ),
  GrammarExplanation(
    "Intransitive Verb",
    "A verb that does not take a direct object. The action remains with the subject (e.g., 'He sat').",
  ),
  GrammarExplanation(
    "Reflexive",
    "The subject performs the action on itself (e.g., 'He taught himself' or 'He washed himself').",
  ),
  GrammarExplanation(
    "Causative",
    "The subject causes someone or something else to perform the action or enter a state (e.g., 'To teach' is the causative of 'to know').",
  ),
  GrammarExplanation(
    "Reciprocal",
    "Two or more subjects perform the action on each other simultaneously (e.g., 'They cooperated').",
  ),
  GrammarExplanation(
    "Intensive",
    "The action is done with greater force, frequency, or violence (e.g., 'To smash' vs. 'To break').",
  ),
  GrammarExplanation(
    "Seeking Form",
    "Indicates asking for, seeking, or attempting to obtain the root meaning (Common in Form X).",
  ),
  // --- New Additions ---
  GrammarExplanation(
    "Root (Jizr)",
    "The base sequence of consonants (usually three) that carries the core lexical meaning of the word, before any vowels or affixes are added.",
  ),
  GrammarExplanation(
    "Triliteral",
    "A root consisting of exactly three consonants. This is the standard foundation for most Arabic verbs.",
  ),
  GrammarExplanation(
    "Gemination",
    "The doubling of a consonant, resulting in a stronger sound. In Arabic script, this is marked with a Shadda (ّ). Critical for Forms II and IX.",
  ),
  GrammarExplanation(
    "Affix (Prefix/Infix)",
    "Letters added to the root to change its meaning. A 'Prefix' is added to the front (like 'ista-' in Form X), and an 'Infix' is inserted inside the root (like the 't' in Form VIII).",
  ),
  GrammarExplanation(
    "Estimative",
    "A mental action where the subject deems or considers the object to have a certain quality (e.g., 'He considered it good'). Common in Form X.",
  ),
  GrammarExplanation(
    "Feigning",
    "Pretending to have a certain quality or state that one does not actually possess (e.g., 'Pretending to be sick'). A unique feature of Form VI.",
  ),
  GrammarExplanation(
    "Stative",
    "A verb that describes a state of being or a condition (like a color or physical trait) rather than a dynamic action. Common in Form IX.",
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
        "The base form. It carries the core lexical meaning. It can be transitive (needs an object) or intransitive depending strictly on the root.",
    morphologyNote: "Pure triliteral root without additional letters.",
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
    transitivity: "Transitive",
    explanation:
        "Often makes an intransitive root transitive (Causative). It can also indicate doing the action repeatedly or violently (Intensive).",
    morphologyNote: "Gemination (shadda) on the middle root letter (Ayin).",
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
    commonMeaning: "Interaction / Reciprocity.",
    transitivity: "Transitive",
    explanation:
        "Implies an action done towards another entity, often suggesting an attempt or interaction.",
    morphologyNote: "Alif added after the first root letter.",
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
        arabic: "سَافَرَ الرَّجُلُ",
        literal: "The man traveled (journeyed through space)",
        highlightedPart: "سَافَرَ",
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
        "The standard causative form. It makes an intransitive verb transitive, or a transitive verb doubly transitive.",
    morphologyNote: "Prefixed Hamza (أَ) before the root.",
    examples: [
      VerbExample(
        arabic: "أَخْرَجَ المُعَلِّمُ الكِتَابَ",
        literal: "The teacher brought out the book",
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
    commonMeaning: "Reflexive of II / Gradualness.",
    transitivity: "Intransitive",
    explanation:
        "Often the result of Form II. Can also imply gradualness or doing something with effort.",
    morphologyNote: "Prefix (تَ) plus the gemination of Form II.",
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
    transitivity: "Reciprocal / Intransitive",
    explanation:
        "Indicates mutual action between two or more parties. Crucially, it can also mean pretending or feigning a state (e.g., pretending to be sick).",
    morphologyNote: "Prefix (تَ) plus the Alif of Form III.",
    examples: [
      VerbExample(
        arabic: "تَعَاوَنَ الفَرِيقُ",
        literal: "The team cooperated (with each other)",
        highlightedPart: "تَعَاوَنَ",
      ),
      VerbExample(
        arabic: "تَجَاهَلَ المُدِيرُ الْمُشْكِلَةَ",
        literal: "The manager feigned ignorance of the problem",
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
    commonMeaning: "Passive / Reflexive.",
    transitivity: "Intransitive",
    explanation:
        "Strictly intransitive. It describes the state of having undergone the action. It is the reflexive/passive of Form I.",
    morphologyNote: "Prefix (اِنْ) added before the root.",
    examples: [
      VerbExample(
        arabic: "اِنْكَسَرَ الكُوبُ",
        literal: "The cup broke (shattered)",
        highlightedPart: "اِنْكَسَرَ",
      ),
      VerbExample(
        arabic: "اِنْقَطَعَ الاِتِّصَالُ",
        literal: "The connection was cut off",
        highlightedPart: "اِنْقَطَعَ",
      ),
      VerbExample(
        arabic: "اِنْفَجَرَ اللَّغَمُ",
        literal: "The mine exploded",
        highlightedPart: "اِنْفَجَرَ",
      ),
    ],
  ),

  VerbFamilyInfo(
    formName: "VIII",
    pattern: "اِفْتَعَلَ",
    rootExample: "ج م ع",
    commonMeaning: "Participating / Taking for oneself.",
    transitivity: "Varies",
    explanation:
        "Indicates doing the action for oneself, striving, or mutual participation. Often reflexive of Form I.",
    morphologyNote: "Infix (ت) inserted after the first root letter.",
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
        arabic: "اِسْتَمَعَ الطَّالِبُ",
        literal: "The student listened (intent to hear)",
        highlightedPart: "اِسْتَمَعَ",
      ),
    ],
  ),

  VerbFamilyInfo(
    formName: "IX",
    pattern: "اِفْعَلَّ",
    rootExample: "ح م ر",
    commonMeaning: "Colors / Physical Defects.",
    transitivity: "Intransitive",
    explanation:
        "Used almost exclusively for colors (turning a color) or physical defects (becoming twisted/crooked).",
    morphologyNote: "Gemination (shadda) on the final root letter.",
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
    ],
  ),

  VerbFamilyInfo(
    formName: "X",
    pattern: "اِسْتَفْعَلَ",
    rootExample: "غ ف ر",
    commonMeaning: "Requesting / Estimative.",
    transitivity: "Transitive",
    explanation:
        "Indicates asking for the action (Requesting) or considering something to have a certain quality (Estimative).",
    morphologyNote: "Prefix (اِسْتَ) added before the root.",
    examples: [
      VerbExample(
        arabic: "اِسْتَغْفَرَ الْمُؤْمِنُ رَبَّهُ",
        literal: "The believer sought forgiveness from his Lord",
        highlightedPart: "اِسْتَغْفَرَ",
      ),
      VerbExample(
        arabic: "اِسْتَخْدَمَ النَّاسُ التِّكْنُولُوجِيَا",
        literal: "People utilized/used technology (sought service from it)",
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
