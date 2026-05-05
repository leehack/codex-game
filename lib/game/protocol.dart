import 'package:flutter/material.dart';

const fallbackCategories = <QuizCategorySpec>[
  QuizCategorySpec(
    id: 'flutter',
    label: 'Flutter',
    accent: Color(0xFF55D6FF),
    questionCount: 4,
  ),
  QuizCategorySpec(
    id: 'codex',
    label: 'Codex',
    accent: Color(0xFFFFC857),
    questionCount: 4,
  ),
  QuizCategorySpec(
    id: 'dart',
    label: 'Dart',
    accent: Color(0xFF62FF9B),
    questionCount: 4,
  ),
  QuizCategorySpec(
    id: 'ai',
    label: 'AI',
    accent: Color(0xFFA36CFF),
    questionCount: 4,
  ),
  QuizCategorySpec(
    id: 'git',
    label: 'Git',
    accent: Color(0xFFFF8F3D),
    questionCount: 4,
  ),
  QuizCategorySpec(
    id: 'web',
    label: 'Web',
    accent: Color(0xFFFF4D6D),
    questionCount: 4,
  ),
  QuizCategorySpec(
    id: 'montreal',
    label: 'Montreal',
    accent: Color(0xFFF7F06D),
    questionCount: 4,
  ),
  QuizCategorySpec(
    id: 'debugging',
    label: 'Debugging',
    accent: Color(0xFFFFFFFF),
    questionCount: 4,
  ),
];

QuizCategorySpec categoryById(String id, [List<QuizCategorySpec>? categories]) {
  final source = categories == null || categories.isEmpty
      ? fallbackCategories
      : categories;
  return source.firstWhere(
    (category) => category.id == id,
    orElse: () => fallbackCategories.first,
  );
}

class QuizCategorySpec {
  const QuizCategorySpec({
    required this.id,
    required this.label,
    required this.accent,
    required this.questionCount,
  });

  factory QuizCategorySpec.fromJson(Map<String, dynamic> json) {
    return QuizCategorySpec(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      accent: _hexColor((json['accent'] ?? '#FFFFFF').toString()),
      questionCount: _asInt(json['questionCount']),
    );
  }

  final String id;
  final String label;
  final Color accent;
  final int questionCount;
}

class RoomSnapshot {
  const RoomSnapshot({
    required this.roomId,
    required this.phase,
    required this.window,
    required this.quizCount,
    required this.windowEndsInMs,
    required this.bossHp,
    required this.bossHpMax,
    required this.players,
    required this.leaderboard,
    required this.categories,
    required this.selectedCategories,
    required this.currentQuestion,
    required this.lastResult,
    required this.tallies,
    required this.feed,
  });

  factory RoomSnapshot.fromJson(Map<String, dynamic> json) {
    return RoomSnapshot(
      roomId: (json['roomId'] ?? '').toString(),
      phase: (json['phase'] ?? 'lobby').toString(),
      window: _asInt(json['window']),
      quizCount: _asInt(json['quizCount']),
      windowEndsInMs: _asInt(json['windowEndsInMs']),
      bossHp: _asInt(json['bossHp']),
      bossHpMax: _asInt(json['bossHpMax']),
      players: ((json['players'] as List?) ?? const [])
          .map(
            (value) =>
                PlayerInfo.fromJson(Map<String, dynamic>.from(value as Map)),
          )
          .toList(growable: false),
      leaderboard: ((json['leaderboard'] as List?) ?? const [])
          .map(
            (value) => LeaderboardEntry.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          )
          .toList(growable: false),
      categories: ((json['categories'] as List?) ?? const [])
          .map(
            (value) => QuizCategorySpec.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          )
          .toList(growable: false),
      selectedCategories: ((json['selectedCategories'] as List?) ?? const [])
          .map((value) => value.toString())
          .toSet(),
      currentQuestion: json['currentQuestion'] is Map
          ? QuizQuestionView.fromJson(
              Map<String, dynamic>.from(json['currentQuestion'] as Map),
            )
          : null,
      lastResult: json['lastResult'] is Map
          ? QuestionResult.fromJson(
              Map<String, dynamic>.from(json['lastResult'] as Map),
            )
          : null,
      tallies: _intMap(json['tallies']),
      feed: ((json['feed'] as List?) ?? const [])
          .map((value) => value.toString())
          .toList(growable: false),
    );
  }

  final String roomId;
  final String phase;
  final int window;
  final int quizCount;
  final int windowEndsInMs;
  final int bossHp;
  final int bossHpMax;
  final List<PlayerInfo> players;
  final List<LeaderboardEntry> leaderboard;
  final List<QuizCategorySpec> categories;
  final Set<String> selectedCategories;
  final QuizQuestionView? currentQuestion;
  final QuestionResult? lastResult;
  final Map<String, int> tallies;
  final List<String> feed;

  bool get isLobby => phase == 'lobby';
  bool get isBattle => phase == 'battle';
  bool get isFinished => phase == 'victory' || phase == 'defeat';
  bool get isVictory => phase == 'victory';
  int get playerCount => players.length;
  int get answeredCount => players.where((player) => player.answered).length;
  int get currentQuestionNumber => isBattle ? window + 1 : window;
  int get totalTallies => tallies.values.fold(0, (sum, value) => sum + value);

  String get phaseTitle {
    return switch (phase) {
      'battle' => 'QUESTION ${window + 1}/$quizCount',
      'victory' => 'BOSS DEFEATED',
      'defeat' => 'BOSS SURVIVED',
      _ => 'LOBBY',
    };
  }
}

class QuizQuestionView {
  const QuizQuestionView({
    required this.id,
    required this.categoryId,
    required this.prompt,
    required this.options,
  });

  factory QuizQuestionView.fromJson(Map<String, dynamic> json) {
    return QuizQuestionView(
      id: (json['id'] ?? '').toString(),
      categoryId: (json['categoryId'] ?? '').toString(),
      prompt: (json['prompt'] ?? '').toString(),
      options: ((json['options'] as List?) ?? const [])
          .map((value) => value.toString())
          .toList(growable: false),
    );
  }

  final String id;
  final String categoryId;
  final String prompt;
  final List<String> options;
}

class QuestionResult {
  const QuestionResult({
    required this.questionId,
    required this.correctIndex,
    required this.correctText,
    required this.answeredCount,
    required this.correctCount,
    required this.damage,
    required this.tallies,
  });

  factory QuestionResult.fromJson(Map<String, dynamic> json) {
    return QuestionResult(
      questionId: (json['questionId'] ?? '').toString(),
      correctIndex: _asInt(json['correctIndex']),
      correctText: (json['correctText'] ?? '').toString(),
      answeredCount: _asInt(json['answeredCount']),
      correctCount: _asInt(json['correctCount']),
      damage: _asInt(json['damage']),
      tallies: _intMap(json['tallies']),
    );
  }

  final String questionId;
  final int correctIndex;
  final String correctText;
  final int answeredCount;
  final int correctCount;
  final int damage;
  final Map<String, int> tallies;
}

class PlayerInfo {
  const PlayerInfo({
    required this.id,
    required this.nickname,
    required this.answered,
    required this.selectedOption,
    required this.lastCorrect,
    required this.lastPoints,
    required this.score,
    required this.correctAnswers,
  });

  factory PlayerInfo.fromJson(Map<String, dynamic> json) {
    return PlayerInfo(
      id: (json['id'] ?? '').toString(),
      nickname: (json['nickname'] ?? '').toString(),
      answered: json['answered'] == true,
      selectedOption: json['selectedOption'] is num
          ? (json['selectedOption'] as num).toInt()
          : null,
      lastCorrect: json['lastCorrect'] is bool
          ? json['lastCorrect'] as bool
          : null,
      lastPoints: _asInt(json['lastPoints']),
      score: _asInt(json['score']),
      correctAnswers: _asInt(json['correctAnswers']),
    );
  }

  final String id;
  final String nickname;
  final bool answered;
  final int? selectedOption;
  final bool? lastCorrect;
  final int lastPoints;
  final int score;
  final int correctAnswers;
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.id,
    required this.nickname,
    required this.score,
    required this.correctAnswers,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: (json['id'] ?? '').toString(),
      nickname: (json['nickname'] ?? '').toString(),
      score: _asInt(json['score']),
      correctAnswers: _asInt(json['correctAnswers']),
    );
  }

  final String id;
  final String nickname;
  final int score;
  final int correctAnswers;
}

int _asInt(Object? value) => value is num ? value.toInt() : 0;

Map<String, int> _intMap(Object? value) {
  if (value is! Map) {
    return const {};
  }
  return Map<String, int>.fromEntries(
    value.entries.map(
      (entry) => MapEntry(entry.key.toString(), _asInt(entry.value)),
    ),
  );
}

Color _hexColor(String value) {
  final normalized = value.replaceFirst('#', '');
  final parsed = int.tryParse(normalized, radix: 16) ?? 0xFFFFFF;
  return Color(0xFF000000 | parsed);
}
