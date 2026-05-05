import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../game/battle_scene.dart';
import '../game/connection.dart';
import '../game/protocol.dart';
import '../game/sound_controller.dart';
import 'retro_widgets.dart';

const _questionWindowMs = 18000;

class HostScreen extends StatefulWidget {
  const HostScreen({super.key});

  @override
  State<HostScreen> createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen> {
  late final GameConnection _connection;
  late final BattleSceneGame _battleGame;
  final SoundController _sound = SoundController();
  final Set<String> _selectedCategories = {'flutter', 'codex'};
  int _quizCount = 8;
  int? _lastWindow;
  String? _lastPhase;
  String? _lastResultQuestion;

  @override
  void initState() {
    super.initState();
    _connection = GameConnection()..addListener(_playSoundForSnapshot);
    _battleGame = BattleSceneGame();
    _connection.createHost();
  }

  @override
  void dispose() {
    _connection.removeListener(_playSoundForSnapshot);
    _connection.dispose();
    _battleGame.pauseEngine();
    super.dispose();
  }

  void _playSoundForSnapshot() {
    final snapshot = _connection.snapshot;
    if (snapshot == null) {
      return;
    }
    if (_lastPhase != snapshot.phase) {
      if (snapshot.phase == 'battle') {
        _sound.play(SoundCue.start);
      } else if (snapshot.phase == 'victory') {
        _sound.play(SoundCue.victory);
      } else if (snapshot.phase == 'defeat') {
        _sound.play(SoundCue.defeat);
      }
      _lastPhase = snapshot.phase;
    }
    if (snapshot.isBattle && _lastWindow != snapshot.window) {
      _sound.play(SoundCue.question);
      _lastWindow = snapshot.window;
    }
    final result = snapshot.lastResult;
    if (!snapshot.isFinished &&
        result != null &&
        _lastResultQuestion != result.questionId) {
      _sound.play(result.correctCount > 0 ? SoundCue.damage : SoundCue.wrong);
      _lastResultQuestion = result.questionId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _connection,
      builder: (context, _) {
        final snapshot = _connection.snapshot;
        _battleGame.snapshot = snapshot;
        return Scaffold(
          body: ScanlineBackground(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 980;
                    final stage = _BattleStage(
                      game: _battleGame,
                      snapshot: snapshot,
                      error: _connection.error,
                    );
                    final panel = _HostPanel(
                      connection: _connection,
                      snapshot: snapshot,
                      selectedCategories: _selectedCategories,
                      quizCount: _quizCount,
                      soundEnabled: _sound.enabled,
                      onSoundChanged: (value) => setState(() {
                        _sound.enabled = value;
                        if (value) {
                          _sound.play(SoundCue.click);
                        }
                      }),
                      onCategoryToggled: _toggleCategory,
                      onQuizCountChanged: (value) => setState(() {
                        _quizCount = value;
                      }),
                      onStart: _startBattle,
                    );
                    if (compact) {
                      return Column(
                        children: [
                          Expanded(flex: 6, child: stage),
                          const SizedBox(height: 14),
                          Expanded(flex: 6, child: panel),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 7, child: stage),
                        const SizedBox(width: 18),
                        SizedBox(width: 430, child: panel),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleCategory(String id) {
    setState(() {
      if (_selectedCategories.contains(id)) {
        if (_selectedCategories.length > 1) {
          _selectedCategories.remove(id);
        }
      } else {
        _selectedCategories.add(id);
      }
    });
    _sound.play(SoundCue.click);
  }

  void _startBattle() {
    _sound.play(SoundCue.start);
    _connection.startBattle(
      quizCount: _quizCount,
      categoryIds: _selectedCategories,
    );
  }
}

class _BattleStage extends StatelessWidget {
  const _BattleStage({
    required this.game,
    required this.snapshot,
    required this.error,
  });

  final BattleSceneGame game;
  final RoomSnapshot? snapshot;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return RetroPanel(
      padding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(game: game),
          Positioned(
            left: 18,
            right: 18,
            top: 18,
            child: _QuestionBanner(snapshot: snapshot),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: _BattleOverlay(snapshot: snapshot, error: error),
          ),
          if (snapshot?.isFinished == true)
            Positioned.fill(child: _EndOverlay(snapshot: snapshot!)),
        ],
      ),
    );
  }
}

class _QuestionBanner extends StatelessWidget {
  const _QuestionBanner({required this.snapshot});

  final RoomSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final question = snapshot?.currentQuestion;
    if (snapshot == null || question == null) {
      return RetroPanel(
        color: panelLight.withValues(alpha: 0.9),
        child: Text(
          snapshot?.isFinished == true
              ? 'Leaderboard locked. Reset for another raid.'
              : 'Scan the QR code, then answer boss questions from your phone.',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      );
    }
    final category = categoryById(question.categoryId, snapshot!.categories);
    return RetroPanel(
      color: panelLight.withValues(alpha: 0.94),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryBadge(category: category),
              const Spacer(),
              CountdownDial(
                remainingMs: snapshot!.windowEndsInMs,
                totalMs: _questionWindowMs,
                size: 96,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(question.prompt, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < question.options.length; i++)
                _OptionChip(
                  label:
                      '${String.fromCharCode(65 + i)}. ${question.options[i]}',
                  count: snapshot!.tallies[i.toString()] ?? 0,
                  accent: i == snapshot!.lastResult?.correctIndex
                      ? mint
                      : category.accent,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EndOverlay extends StatelessWidget {
  const _EndOverlay({required this.snapshot});

  final RoomSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final victory = snapshot.isVictory;
    final accent = victory ? mint : ember;
    final title = victory ? 'BOSS DEFEATED' : 'BOSS SURVIVED';
    final subtitle = victory
        ? 'The room patched the quiz boss together.'
        : 'The boss held on. Reset and run another raid.';
    final top = snapshot.leaderboard.isEmpty
        ? null
        : snapshot.leaderboard.first;

    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ink.withValues(alpha: 0.42),
          border: Border.all(color: accent, width: 6),
        ),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.84, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: RetroPanel(
                color: panel.withValues(alpha: 0.96),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 26,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      victory ? Icons.workspace_premium : Icons.warning_amber,
                      color: accent,
                      size: 68,
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(color: accent, fontSize: 64),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Final boss HP: ${snapshot.bossHp}/${snapshot.bossHpMax}',
                      style: const TextStyle(
                        color: brass,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (top != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'MVP: ${top.nickname}  ${top.correctAnswers} correct  ${top.score} pts',
                        style: const TextStyle(
                          color: cream,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.count,
    required this.accent,
  });

  final String label;
  final int count;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.82),
        border: Border.all(color: accent),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          '$label  [$count]',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _BattleOverlay extends StatelessWidget {
  const _BattleOverlay({required this.snapshot, required this.error});

  final RoomSnapshot? snapshot;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (snapshot == null) {
      return RetroPanel(
        color: panelLight.withValues(alpha: 0.94),
        child: Text(
          error ?? 'Opening room server link...',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
    }
    return RetroPanel(
      color: panelLight.withValues(alpha: 0.94),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HpBar(
            label: 'QUIZ BOSS',
            value: snapshot!.bossHp,
            maxValue: snapshot!.bossHpMax,
            color: ember,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatPill(label: 'ROUND', value: snapshot!.phaseTitle),
              const SizedBox(width: 10),
              _StatPill(
                label: 'ANSWERS',
                value: '${snapshot!.answeredCount}/${snapshot!.playerCount}',
              ),
              const SizedBox(width: 10),
              _StatPill(
                label: 'LAST HIT',
                value: '${snapshot!.lastResult?.damage ?? 0}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HostPanel extends StatelessWidget {
  const _HostPanel({
    required this.connection,
    required this.snapshot,
    required this.selectedCategories,
    required this.quizCount,
    required this.soundEnabled,
    required this.onSoundChanged,
    required this.onCategoryToggled,
    required this.onQuizCountChanged,
    required this.onStart,
  });

  final GameConnection connection;
  final RoomSnapshot? snapshot;
  final Set<String> selectedCategories;
  final int quizCount;
  final bool soundEnabled;
  final ValueChanged<bool> onSoundChanged;
  final ValueChanged<String> onCategoryToggled;
  final ValueChanged<int> onQuizCountChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final roomId = connection.roomId ?? snapshot?.roomId ?? '....';
    final joinUrl = connection.joinUrl;
    final categories = snapshot?.categories ?? fallbackCategories;
    return RetroPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'CODEX QUIZ RAID',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: soundEnabled ? 'Sound on' : 'Sound off',
                onPressed: () => onSoundChanged(!soundEnabled),
                icon: Icon(soundEnabled ? Icons.volume_up : Icons.volume_off),
                color: brass,
              ),
            ],
          ),
          Text(
            'Collaborative boss damage, individual leaderboard.',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: cyan),
          ),
          const SizedBox(height: 16),
          _RoomCode(roomId: roomId),
          const SizedBox(height: 14),
          if (joinUrl != null) _QrJoin(joinUrl: joinUrl),
          const SizedBox(height: 14),
          if (snapshot == null || snapshot!.isLobby)
            _QuizSetup(
              categories: categories,
              selectedCategories: selectedCategories,
              quizCount: quizCount,
              onCategoryToggled: onCategoryToggled,
              onQuizCountChanged: onQuizCountChanged,
            )
          else
            _Leaderboard(snapshot: snapshot!),
          const SizedBox(height: 14),
          _HostControls(
            connection: connection,
            snapshot: snapshot,
            onStart: onStart,
          ),
          const SizedBox(height: 14),
          Expanded(child: _EventFeed(feed: snapshot?.feed ?? const [])),
          if (connection.error != null) ...[
            const SizedBox(height: 10),
            Text(
              connection.error!,
              style: const TextStyle(color: ember, fontWeight: FontWeight.w800),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuizSetup extends StatelessWidget {
  const _QuizSetup({
    required this.categories,
    required this.selectedCategories,
    required this.quizCount,
    required this.onCategoryToggled,
    required this.onQuizCountChanged,
  });

  final List<QuizCategorySpec> categories;
  final Set<String> selectedCategories;
  final int quizCount;
  final ValueChanged<String> onCategoryToggled;
  final ValueChanged<int> onQuizCountChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.72),
        border: Border.all(color: cream.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('QUIZ COUNT', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final count in const [5, 8, 10, 12, 16])
                  ChoiceChip(
                    label: Text('$count'),
                    selected: quizCount == count,
                    onSelected: (_) => onQuizCountChanged(count),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text('CATEGORIES', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in categories)
                  CategoryBadge(
                    category: category,
                    selected: selectedCategories.contains(category.id),
                    onTap: () => onCategoryToggled(category.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Leaderboard extends StatelessWidget {
  const _Leaderboard({required this.snapshot});

  final RoomSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final entries = snapshot.leaderboard.take(6).toList(growable: false);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.72),
        border: Border.all(color: cream.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('LEADERBOARD', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              const Text('No answers yet.')
            else
              for (var i = 0; i < entries.length; i++)
                _LeaderboardRow(rank: i + 1, entry: entries[i]),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.rank, required this.entry});

  final int rank;
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#$rank',
              style: const TextStyle(color: brass, fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(
            child: Text(
              entry.nickname,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            '${entry.correctAnswers}✓  ${entry.score}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _RoomCode extends StatelessWidget {
  const _RoomCode({required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ink,
        border: Border.all(color: cream.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text('ROOM CODE', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 2),
            Text(
              roomId,
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(color: brass),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrJoin extends StatelessWidget {
  const _QrJoin({required this.joinUrl});

  final String joinUrl;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cream,
          border: Border.all(color: brass, width: 4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: QrImageView(
            data: joinUrl,
            version: QrVersions.auto,
            size: 190,
            backgroundColor: cream,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: ink),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _HostControls extends StatelessWidget {
  const _HostControls({
    required this.connection,
    required this.snapshot,
    required this.onStart,
  });

  final GameConnection connection;
  final RoomSnapshot? snapshot;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final canStart = snapshot != null && !snapshot!.isBattle;
    return Row(
      children: [
        Expanded(
          child: PixelButton(
            label: snapshot?.isFinished == true ? 'PLAY AGAIN' : 'START QUIZ',
            icon: Icons.play_arrow,
            enabled: canStart,
            onPressed: canStart ? onStart : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PixelButton(
            label: 'RESET',
            icon: Icons.restart_alt,
            color: cyan,
            onPressed: connection.resetRoom,
          ),
        ),
      ],
    );
  }
}

class _EventFeed extends StatelessWidget {
  const _EventFeed({required this.feed});

  final List<String> feed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.82),
        border: Border.all(color: cream.withValues(alpha: 0.18)),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: feed.isEmpty ? 1 : feed.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (feed.isEmpty) {
            return const Text('Waiting for contestants...');
          }
          return Text(
            '> ${feed[index]}',
            style: const TextStyle(fontWeight: FontWeight.w700, height: 1.25),
          );
        },
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ink,
          border: Border.all(color: cream.withValues(alpha: 0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: brass,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
