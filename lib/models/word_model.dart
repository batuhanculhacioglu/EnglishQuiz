class Word {
  String english;
  String turkish;
  String sampleEn;
  String sampleTr;
  double learningScore;
  bool isInLibrary;

  Word({
    required this.english,
    required this.turkish,
    required this.sampleEn,
    required this.sampleTr,
    this.learningScore = 0.0,
    this.isInLibrary = false,
  });

  Map<String, dynamic> toJson() => {
    'english': english,
    'turkish': turkish,
    'sampleEn': sampleEn,
    'sampleTr': sampleTr,
    'learningScore': learningScore,
    'isInLibrary': isInLibrary,
  };

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      english: json['english'],
      turkish: json['turkish'],
      sampleEn: json['sampleEn'] ?? "",
      sampleTr: json['sampleTr'] ?? "",
      learningScore: (json['learningScore'] as num?)?.toDouble() ?? 0.0,
      isInLibrary: json['isInLibrary'] ?? false,
    );
  }

  // --- EŞİTLİK KONTROLÜ (Aynı kelimenin tekrar sayılmaması için) ---
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Word &&
          runtimeType == other.runtimeType &&
          english.toLowerCase().trim() == other.english.toLowerCase().trim();

  @override
  int get hashCode => english.toLowerCase().trim().hashCode;

  // Helper getters
  bool get isNew => learningScore == 0;
  bool get isWeak => learningScore > 0 && learningScore < 40;
  bool get isDeveloping => learningScore >= 40 && learningScore < 85;
  bool get isLearned => learningScore >= 85;
}

class WordDataset {
  String name;
  List<Word> words;
  String difficulty;
  DateTime importedDate;

  WordDataset({
    required this.name,
    required this.words,
    this.difficulty = "Normal",
    DateTime? date,
  }) : importedDate = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'name': name,
    'difficulty': difficulty,
    'importedDate': importedDate.toIso8601String(),
    'words': words.map((w) => w.toJson()).toList(),
  };

  factory WordDataset.fromJson(Map<String, dynamic> json) {
    var list = json['words'] as List;
    List<Word> wordsList = list.map((i) => Word.fromJson(i)).toList();
    return WordDataset(
      name: json['name'],
      difficulty: json['difficulty'],
      date: DateTime.parse(json['importedDate']),
      words: wordsList,
    );
  }

  double get progressPercentage {
    if (words.isEmpty) return 0.0;
    double totalScore = words.fold(0.0, (sum, w) => sum + w.learningScore);
    return totalScore / words.length;
  }
}
