import 'dart:math';

import 'package:server/game_server.dart';
import 'package:test/test.dart';

void main() {
  test('creates room and accepts one quiz answer per player per question', () {
    final server = CodexGameServer(random: Random(1));
    final room = server.createRoom(now: DateTime(2026));
    final player = server.joinPlayer(
      room,
      nickname: 'Ada Lovelace',
      now: DateTime(2026),
    );

    expect(
      server.submitAnswer(room, playerId: player.id, optionIndex: 0),
      isFalse,
    );

    server.startBattle(
      room,
      categoryIds: ['flutter', 'codex'],
      quizCount: 5,
      now: DateTime(2026),
    );

    expect(
      server.submitAnswer(room, playerId: player.id, optionIndex: 0),
      isTrue,
    );
    expect(
      server.submitAnswer(room, playerId: player.id, optionIndex: 1),
      isFalse,
    );

    final snapshot = server.snapshot(room, now: DateTime(2026));
    expect(snapshot['roomId'], room.id);
    expect(snapshot['phase'], 'battle');
    expect(snapshot['quizCount'], 5);
    expect(
      (snapshot['tallies'] as Map).values.fold(0, (a, b) => a + (b as int)),
      1,
    );
  });

  test('correct quiz answers damage boss and score leaderboard points', () {
    final server = CodexGameServer(random: Random(2));
    final room = server.createRoom(now: DateTime(2026));
    final first = server.joinPlayer(
      room,
      nickname: 'Grace',
      now: DateTime(2026),
    );
    final second = server.joinPlayer(
      room,
      nickname: 'Linus',
      now: DateTime(2026),
    );

    server.startBattle(
      room,
      categoryIds: ['flutter'],
      quizCount: 3,
      now: DateTime(2026),
    );
    final question = room.currentQuestion!;
    final startingBossHp = room.bossHp;

    server.submitAnswer(
      room,
      playerId: first.id,
      optionIndex: question.correctIndex,
      now: DateTime(2026).add(const Duration(seconds: 2)),
    );
    server.submitAnswer(
      room,
      playerId: second.id,
      optionIndex: (question.correctIndex + 1) % question.options.length,
      now: DateTime(2026).add(const Duration(seconds: 3)),
    );
    server.resolveWindow(room, now: DateTime(2026).add(questionWindow));

    expect(room.phase, GamePhase.battle);
    expect(room.window, 1);
    expect(room.bossHp, startingBossHp - 100);
    expect(first.correctAnswers, 1);
    expect(first.score, greaterThan(second.score));
    expect(room.leaderboard.first.id, first.id);
    expect(room.lastResult?.correctCount, 1);
  });

  test('heartbeat keeps waiting lobby players active', () {
    final server = CodexGameServer(random: Random(3));
    final room = server.createRoom(now: DateTime(2026));
    final player = server.joinPlayer(
      room,
      nickname: 'Grace',
      now: DateTime(2026),
    );

    server.tick(now: DateTime(2026).add(const Duration(seconds: 40)));
    expect(player.active, isFalse);

    final accepted = server.recordHeartbeat(
      room,
      playerId: player.id,
      now: DateTime(2026).add(const Duration(seconds: 41)),
    );
    server.tick(now: DateTime(2026).add(const Duration(seconds: 42)));

    expect(accepted, isTrue);
    expect(player.active, isTrue);
  });

  test('aggregates a 60 player quiz answer window', () {
    final server = CodexGameServer(random: Random(5));
    final room = server.createRoom(now: DateTime(2026));

    for (var i = 0; i < 60; i++) {
      final player = server.joinPlayer(
        room,
        nickname: 'Player $i',
        now: DateTime(2026),
      );
      expect(
        server.submitAnswer(room, playerId: player.id, optionIndex: 0),
        isFalse,
      );
    }

    server.startBattle(
      room,
      categoryIds: ['flutter', 'codex', 'dart', 'ai'],
      quizCount: 5,
      now: DateTime(2026),
    );
    final correct = room.currentQuestion!.correctIndex;
    for (final player in room.players.values) {
      expect(
        server.submitAnswer(room, playerId: player.id, optionIndex: correct),
        isTrue,
      );
    }

    expect(room.currentTallies.values.fold(0, (a, b) => a + b), 60);
    server.resolveWindow(room, now: DateTime(2026).add(questionWindow));
    expect(room.phase, GamePhase.battle);
    expect(room.bossHp, room.bossHpMax - 6000);
    expect(room.leaderboard.first.score, greaterThan(0));
  });

  test(
    'selected categories include flutter and codex in available catalog',
    () {
      expect(categoryById('flutter')?.label, 'Flutter');
      expect(categoryById('codex')?.label, 'Codex');
      expect(quizCategories.length, inInclusiveRange(5, 10));
    },
  );
}
