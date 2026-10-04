import 'dart:convert';
import 'dart:math';

class LocalWord {
  final String word;
  final int length;
  final int vowelCount;
  final int consonantCount;
  final bool hasRepeatedLetters;
  final int difficulty; // 1 to 5
  final String category;
  final String partOfSpeech;
  final String definition;
  final String exampleSentence;
  final String strikingClue;
  final List<String> synonyms;
  final String origin;
  final String usageContext;

  const LocalWord({
    required this.word,
    required this.length,
    required this.vowelCount,
    required this.consonantCount,
    required this.hasRepeatedLetters,
    required this.difficulty,
    required this.category,
    required this.partOfSpeech,
    required this.definition,
    required this.exampleSentence,
    required this.strikingClue,
    required this.synonyms,
    required this.origin,
    required this.usageContext,
  });

  Map<String, dynamic> toWordDna() {
    return {
      'length': length,
      'vowels': vowelCount,
      'consonants': consonantCount,
      'has_repeated_letters': hasRepeatedLetters,
      'category': category,
      'part_of_speech': partOfSpeech,
      'difficulty': difficulty,
    };
  }

  Map<String, dynamic> toKnowledgeCard(String status, int mistakes, int combo) {
    return {
      'word': word.toUpperCase(),
      'definition': definition,
      'pronunciation': "/'${word.toLowerCase()}/",
      'part_of_speech': partOfSpeech,
      'category': category,
      'origin': origin,
      'usage_context': usageContext,
      'example_sentence': exampleSentence.replaceAll('___', word.toUpperCase()),
      'synonyms': synonyms,
      'status': status,
      'mistakes': mistakes,
      'combo': combo,
      'etymology': "Derived from $origin, heavily utilized across modern $category discourse.",
    };
  }
}

class LocalWordBank {
  static final List<LocalWord> words = [
    // Level 1-20: Easy / Very Easy (Difficulty 1)
    const LocalWord(
      word: 'code',
      length: 4,
      vowelCount: 2,
      consonantCount: 2,
      hasRepeatedLetters: false,
      difficulty: 1,
      category: 'Technology',
      partOfSpeech: 'noun',
      definition: 'Program instructions written by a programmer.',
      exampleSentence: 'Engineers write clean ___ to build modern web applications.',
      strikingClue: 'Software developers write these text instructions to command a computer.',
      synonyms: ['script', 'program', 'instructions'],
      origin: 'Old French / Latin origin',
      usageContext: 'Commonly applied in Technology when developing software systems.',
    ),
    const LocalWord(
      word: 'data',
      length: 4,
      vowelCount: 2,
      consonantCount: 2,
      hasRepeatedLetters: true,
      difficulty: 1,
      category: 'Technology',
      partOfSpeech: 'noun',
      definition: 'Facts and statistics collected together for reference or analysis.',
      exampleSentence: 'The server processed gigabytes of user ___ securely.',
      strikingClue: 'Digital systems gather and process these raw information records.',
      synonyms: ['information', 'records', 'facts'],
      origin: 'Latin origin',
      usageContext: 'Used across all data science, storage, and networking layers.',
    ),
    const LocalWord(
      word: 'atom',
      length: 4,
      vowelCount: 2,
      consonantCount: 2,
      hasRepeatedLetters: false,
      difficulty: 1,
      category: 'Science',
      partOfSpeech: 'noun',
      definition: 'The basic unit of a chemical element.',
      exampleSentence: 'Protons and neutrons form the central nucleus of an ___.',
      strikingClue: 'This fundamental microscopic particle consists of a nucleus with orbiting electrons.',
      synonyms: ['particle', 'unit', 'element'],
      origin: 'Classical Greek origin',
      usageContext: 'Foundational concept in physics and chemistry.',
    ),
    const LocalWord(
      word: 'cell',
      length: 4,
      vowelCount: 1,
      consonantCount: 3,
      hasRepeatedLetters: true,
      difficulty: 1,
      category: 'Science',
      partOfSpeech: 'noun',
      definition: 'The smallest structural and functional unit of an organism.',
      exampleSentence: 'The microscopic biological ___ is the basic building block of life.',
      strikingClue: 'Biologists regard this membrane-bound structure as the foundation of living matter.',
      synonyms: ['unit', 'corpuscle'],
      origin: 'Latin origin',
      usageContext: 'Core biological unit across all organisms.',
    ),
    const LocalWord(
      word: 'leaf',
      length: 4,
      vowelCount: 2,
      consonantCount: 2,
      hasRepeatedLetters: false,
      difficulty: 1,
      category: 'Nature',
      partOfSpeech: 'noun',
      definition: 'A flattened structure of a higher plant, typically green.',
      exampleSentence: 'A green ___ absorbs sunlight to synthesize plant nutrients.',
      strikingClue: 'This flat green structure sprouts from branches to capture sunlight.',
      synonyms: ['blade', 'frond', 'foliage'],
      origin: 'Old English origin',
      usageContext: 'Commonly observed on trees, shrubs, and flowering flora.',
    ),
    const LocalWord(
      word: 'tree',
      length: 4,
      vowelCount: 2,
      consonantCount: 2,
      hasRepeatedLetters: true,
      difficulty: 1,
      category: 'Nature',
      partOfSpeech: 'noun',
      definition: 'A woody perennial plant having a single stem or trunk.',
      exampleSentence: 'The ancient oak ___ provided shade over the grassy meadow.',
      strikingClue: 'A tall perennial plant with wooden trunk and leafy canopy.',
      synonyms: ['sapling', 'timber'],
      origin: 'Old English origin',
      usageContext: 'Central component of terrestrial woodland ecology.',
    ),
    const LocalWord(
      word: 'lion',
      length: 4,
      vowelCount: 2,
      consonantCount: 2,
      hasRepeatedLetters: false,
      difficulty: 1,
      category: 'Animals',
      partOfSpeech: 'noun',
      definition: 'A large wild cat native to Africa and India.',
      exampleSentence: 'The male ___ let out a loud roar across the savanna.',
      strikingClue: 'This apex feline predator is famously nicknamed the king of the jungle.',
      synonyms: ['feline', 'predator'],
      origin: 'Classical Greek / Latin origin',
      usageContext: 'Savanna predator and keystone species.',
    ),
    const LocalWord(
      word: 'star',
      length: 4,
      vowelCount: 1,
      consonantCount: 3,
      hasRepeatedLetters: false,
      difficulty: 1,
      category: 'Space',
      partOfSpeech: 'noun',
      definition: 'A luminous sphere of plasma in the night sky.',
      exampleSentence: 'A bright evening ___ shone clearly above the horizon.',
      strikingClue: 'A massive burning ball of gas generating light via nuclear fusion.',
      synonyms: ['sun', 'luminary'],
      origin: 'Old English / Germanic origin',
      usageContext: 'Astrophysical body lighting the celestial cosmos.',
    ),
    const LocalWord(
      word: 'moon',
      length: 4,
      vowelCount: 2,
      consonantCount: 2,
      hasRepeatedLetters: true,
      difficulty: 1,
      category: 'Space',
      partOfSpeech: 'noun',
      definition: 'The natural satellite of the earth, visible by reflected sunlight.',
      exampleSentence: 'The full ___ illuminated the quiet countryside at midnight.',
      strikingClue: 'This natural rocky sphere orbits Earth and governs ocean tides.',
      synonyms: ['satellite', 'lunar body'],
      origin: 'Old English origin',
      usageContext: 'Earth orbit and gravitational tide cycles.',
    ),

    // Level 21-40: Moderate (Difficulty 2)
    const LocalWord(
      word: 'algorithm',
      length: 9,
      vowelCount: 3,
      consonantCount: 6,
      hasRepeatedLetters: false,
      difficulty: 2,
      category: 'Technology',
      partOfSpeech: 'noun',
      definition: 'A step-by-step set of rules followed in calculations.',
      exampleSentence: 'The computer executed an efficient ___ to sort millions of items.',
      strikingClue: 'This systematic computational procedure computes solutions methodically.',
      synonyms: ['procedure', 'formula', 'routine'],
      origin: 'Arabic / Latin origin',
      usageContext: 'Used everywhere in computer science and algorithmic engineering.',
    ),
    const LocalWord(
      word: 'hardware',
      length: 8,
      vowelCount: 3,
      consonantCount: 5,
      hasRepeatedLetters: true,
      difficulty: 2,
      category: 'Technology',
      partOfSpeech: 'noun',
      definition: 'The physical components of a computer system.',
      exampleSentence: 'Upgrading the graphics ___ improved rendering frame rates.',
      strikingClue: 'The tangible mechanical and electronic components of a machine.',
      synonyms: ['equipment', 'machinery', 'components'],
      origin: 'Middle English origin',
      usageContext: 'Physical microelectronics and computing hardware.',
    ),
    const LocalWord(
      word: 'electron',
      length: 8,
      vowelCount: 3,
      consonantCount: 5,
      hasRepeatedLetters: true,
      difficulty: 2,
      category: 'Science',
      partOfSpeech: 'noun',
      definition: 'A stable subatomic particle carrying negative electric charge.',
      exampleSentence: 'An ___ orbits the positive atomic nucleus in energy shells.',
      strikingClue: 'This negatively charged subatomic particle governs electricity and chemical bonding.',
      synonyms: ['lepton', 'particle'],
      origin: 'Greek origin',
      usageContext: 'Quantum physics, electronics, and molecular bonding.',
    ),
    const LocalWord(
      word: 'glacier',
      length: 7,
      vowelCount: 3,
      consonantCount: 4,
      hasRepeatedLetters: false,
      difficulty: 2,
      category: 'Nature',
      partOfSpeech: 'noun',
      definition: 'A slowly moving river of ice formed by snow accumulation.',
      exampleSentence: 'The massive alpine ___ carved a deep valley over millennia.',
      strikingClue: 'A colossal mass of dense ice creeping slowly downhill.',
      synonyms: ['ice sheet', 'icefield'],
      origin: 'French / Latin origin',
      usageContext: 'Polar geology and alpine landscape formation.',
    ),
    const LocalWord(
      word: 'astronomy',
      length: 9,
      vowelCount: 3,
      consonantCount: 6,
      hasRepeatedLetters: true,
      difficulty: 2,
      category: 'Space',
      partOfSpeech: 'noun',
      definition: 'The scientific study of celestial bodies and deep space.',
      exampleSentence: 'She studied ___ through a powerful mountain observatory telescope.',
      strikingClue: 'The scientific observation of stars, galaxies, and planetary orbits.',
      synonyms: ['stargazing', 'astrophysics'],
      origin: 'Classical Greek origin',
      usageContext: 'Observational astrophysics and cosmos discovery.',
    ),
    const LocalWord(
      word: 'chameleon',
      length: 9,
      vowelCount: 4,
      consonantCount: 5,
      hasRepeatedLetters: true,
      difficulty: 2,
      category: 'Animals',
      partOfSpeech: 'noun',
      definition: 'A specialized lizard capable of changing skin coloration.',
      exampleSentence: 'The small ___ blended seamlessly into the rainforest branch.',
      strikingClue: 'This lizard alters its skin pigmentation for camouflage and mood.',
      synonyms: ['lizard', 'adapter'],
      origin: 'Greek / Latin origin',
      usageContext: 'Tropical biology and adaptive animal coloration.',
    ),

    // Level 41-60: Challenging (Difficulty 3)
    const LocalWord(
      word: 'encryption',
      length: 10,
      vowelCount: 4,
      consonantCount: 6,
      hasRepeatedLetters: true,
      difficulty: 3,
      category: 'Technology',
      partOfSpeech: 'noun',
      definition: 'The mathematical scrambling of data to prevent unauthorized reading.',
      exampleSentence: 'End-to-end ___ secures message transmission between devices.',
      strikingClue: 'Cybersecurity uses this mathematical cipher to protect secrets.',
      synonyms: ['encoding', 'ciphering', 'protection'],
      origin: 'Greek / Modern English',
      usageContext: 'Cryptography, banking protocols, and data protection.',
    ),
    const LocalWord(
      word: 'bandwidth',
      length: 9,
      vowelCount: 2,
      consonantCount: 7,
      hasRepeatedLetters: true,
      difficulty: 3,
      category: 'Technology',
      partOfSpeech: 'noun',
      definition: 'The maximum data transfer capacity of a communications network.',
      exampleSentence: 'High fiber-optic ___ enables smooth real-time video streaming.',
      strikingClue: 'Network transmission capacity measured in megabits or gigabits per second.',
      synonyms: ['throughput', 'capacity'],
      origin: 'Modern Technical',
      usageContext: 'Telecommunications, routing, and fiber-optic networking.',
    ),
    const LocalWord(
      word: 'quantum',
      length: 7,
      vowelCount: 3,
      consonantCount: 4,
      hasRepeatedLetters: true,
      difficulty: 3,
      category: 'Science',
      partOfSpeech: 'noun',
      definition: 'A discrete minimum unit of energy in physical interactions.',
      exampleSentence: 'Physicists explored subatomic particle interactions using ___ mechanics.',
      strikingClue: 'This physics term describes the smallest discrete packets of subatomic energy.',
      synonyms: ['quanta', 'unit'],
      origin: 'Latin origin',
      usageContext: 'Subatomic physics and quantum computing.',
    ),
    const LocalWord(
      word: 'photosynthesis',
      length: 14,
      vowelCount: 5,
      consonantCount: 9,
      hasRepeatedLetters: true,
      difficulty: 3,
      category: 'Science',
      partOfSpeech: 'noun',
      definition: 'Process by which green plants convert light into chemical energy.',
      exampleSentence: 'Plants use sunlight to perform ___ and synthesize sugars.',
      strikingClue: 'Green foliage absorbs solar photons to create oxygen and glucose.',
      synonyms: ['energy synthesis', 'chlorophyll reaction'],
      origin: 'Greek origin',
      usageContext: 'Botany, planetary oxygen cycles, and biochemistry.',
    ),
    const LocalWord(
      word: 'astronaut',
      length: 9,
      vowelCount: 4,
      consonantCount: 5,
      hasRepeatedLetters: false,
      difficulty: 3,
      category: 'Space',
      partOfSpeech: 'noun',
      definition: 'A pilot or crew member trained for spaceflight beyond atmosphere.',
      exampleSentence: 'The ___ floated through the airlock to conduct a spacewalk.',
      strikingClue: 'A certified explorer who travels aboard orbital rockets.',
      synonyms: ['cosmonaut', 'spacefarer'],
      origin: 'Greek origin',
      usageContext: 'Manned space exploration and orbital spaceflight.',
    ),

    // Level 61-80: Advanced (Difficulty 4)
    const LocalWord(
      word: 'cybernetics',
      length: 11,
      vowelCount: 4,
      consonantCount: 7,
      hasRepeatedLetters: true,
      difficulty: 4,
      category: 'Technology',
      partOfSpeech: 'noun',
      definition: 'The science of automatic control systems in machines and organisms.',
      exampleSentence: 'Advanced ___ bridges human neural signals with robotic limbs.',
      strikingClue: 'The study of feedback control loops connecting biology with automated machines.',
      synonyms: ['bionics', 'automation', 'robotics'],
      origin: 'Greek origin',
      usageContext: 'Robotics, bioengineering, and machine intelligence.',
    ),
    const LocalWord(
      word: 'thermodynamics',
      length: 14,
      vowelCount: 4,
      consonantCount: 10,
      hasRepeatedLetters: true,
      difficulty: 4,
      category: 'Science',
      partOfSpeech: 'noun',
      definition: 'The physics of heat, work, energy transfer, and entropy.',
      exampleSentence: 'The second law of ___ establishes that total entropy never decreases.',
      strikingClue: 'This physics branch describes how thermal energy converts into mechanical work.',
      synonyms: ['heat physics', 'energy mechanics'],
      origin: 'Greek / Latin origin',
      usageContext: 'Mechanical engineering, chemical reactions, and propulsion.',
    ),
    const LocalWord(
      word: 'precipitation',
      length: 13,
      vowelCount: 6,
      consonantCount: 7,
      hasRepeatedLetters: true,
      difficulty: 4,
      category: 'Nature',
      partOfSpeech: 'noun',
      definition: 'Condensed moisture falling from atmosphere as rain, sleet, or snow.',
      exampleSentence: 'Heavy seasonal ___ replenished depleted reservoir levels.',
      strikingClue: 'Meteorological collective term for atmospheric rain, hail, or snow.',
      synonyms: ['rainfall', 'downpour', 'sleet'],
      origin: 'Latin origin',
      usageContext: 'Climatology, meteorology, and water resources.',
    ),
    const LocalWord(
      word: 'archaeologist',
      length: 13,
      vowelCount: 6,
      consonantCount: 7,
      hasRepeatedLetters: true,
      difficulty: 4,
      category: 'History',
      partOfSpeech: 'noun',
      definition: 'A scientist who unearths and studies historical human artifacts.',
      exampleSentence: 'The ___ unearthed ancient bronze coins at the excavation trench.',
      strikingClue: 'An investigator who digs up ancient ruins and historical relics.',
      synonyms: ['excavator', 'antiquarian'],
      origin: 'Greek / Latin origin',
      usageContext: 'Historical excavations and antiquity research.',
    ),

    // Level 81-100: Expert / Brutal (Difficulty 5)
    const LocalWord(
      word: 'cryptography',
      length: 12,
      vowelCount: 3,
      consonantCount: 9,
      hasRepeatedLetters: true,
      difficulty: 5,
      category: 'Technology',
      partOfSpeech: 'noun',
      definition: 'The art of writing and deciphering secret ciphers and codes.',
      exampleSentence: 'Public-key ___ provides the security backbone of digital commerce.',
      strikingClue: 'The mathematical science of protecting sensitive messages using ciphers.',
      synonyms: ['ciphers', 'secret writing', 'steganography'],
      origin: 'Classical Greek origin',
      usageContext: 'Cybersecurity, distributed ledgers, and national intelligence.',
    ),
    const LocalWord(
      word: 'crystallography',
      length: 15,
      vowelCount: 4,
      consonantCount: 11,
      hasRepeatedLetters: true,
      difficulty: 5,
      category: 'Science',
      partOfSpeech: 'noun',
      definition: 'The science of analyzing crystalline structure through X-ray diffraction.',
      exampleSentence: 'X-ray ___ enabled scientists to resolve the helical structure of DNA.',
      strikingClue: 'Diffracting X-rays through crystals to map 3D molecular structures.',
      synonyms: ['diffraction analysis', 'crystal physics'],
      origin: 'Greek origin',
      usageContext: 'Structural biology, materials chemistry, and pharmacology.',
    ),
    const LocalWord(
      word: 'electromagnetism',
      length: 16,
      vowelCount: 5,
      consonantCount: 11,
      hasRepeatedLetters: true,
      difficulty: 5,
      category: 'Science',
      partOfSpeech: 'noun',
      definition: 'The unified fundamental force governing electric and magnetic interactions.',
      exampleSentence: 'Maxwell unified light and charge into the classic equations of ___.',
      strikingClue: 'A fundamental universe force that unifies electric currents with magnetic fields.',
      synonyms: ['electrodynamics', 'field theory'],
      origin: 'Greek / Latin origin',
      usageContext: 'Quantum electrodynamics, electronics, and astrophysics.',
    ),
    const LocalWord(
      word: 'supercomputer',
      length: 13,
      vowelCount: 5,
      consonantCount: 8,
      hasRepeatedLetters: true,
      difficulty: 5,
      category: 'Technology',
      partOfSpeech: 'noun',
      definition: 'An extraordinarily powerful mainframe performing trillions of calculations.',
      exampleSentence: 'Researchers utilized a massive ___ to simulate planetary climate shifts.',
      strikingClue: 'A high-performance supercomputing cluster for extreme scientific workloads.',
      synonyms: ['mainframe', 'cluster node'],
      origin: 'Modern Technical',
      usageContext: 'Climate modeling, fluid dynamics, and nuclear simulation.',
    ),
  ];

  static LocalWord selectWord({
    String mode = 'classic',
    int level = 1,
    String category = 'General',
  }) {
    List<LocalWord> candidates = List.from(words);

    if (category.isNotEmpty && category != 'General') {
      final catMatches = candidates.where((w) => w.category.toLowerCase() == category.toLowerCase()).toList();
      if (catMatches.isNotEmpty) candidates = catMatches;
    }

    if (mode == 'classic') {
      int targetDiff = 1;
      if (level > 20) targetDiff = 2;
      if (level > 40) targetDiff = 3;
      if (level > 60) targetDiff = 4;
      if (level > 80) targetDiff = 5;

      final diffMatches = candidates.where((w) => w.difficulty == targetDiff).toList();
      if (diffMatches.isNotEmpty) {
        // Deterministic pseudo-random based on level
        final index = (level - 1) % diffMatches.length;
        return diffMatches[index];
      }
    } else if (mode == 'daily') {
      final dateStr = DateTime.now().toIso8601String().substring(0, 10);
      final hash = dateStr.codeUnits.fold(0, (prev, c) => prev + c);
      return candidates[hash % candidates.length];
    }

    final rand = Random();
    return candidates[rand.nextInt(candidates.length)];
  }

  static String getTierLabel(int level) {
    if (level <= 20) return "Very Easy";
    if (level <= 40) return "Easy";
    if (level <= 60) return "Moderate";
    if (level <= 80) return "Challenging";
    return "Expert";
  }
}
