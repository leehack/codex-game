import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/connection.dart';
import '../game/protocol.dart';
import '../game/sound_controller.dart';
import 'retro_widgets.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({this.initialRoom, super.key});

  final String? initialRoom;

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  late final GameConnection _connection;
  late final TextEditingController _roomController;
  final _nameController = TextEditingController();
  final _sound = SoundController();
  int? _lastWindow;
  String? _lastPhase;
  String? _lastResultQuestion;

  @override
  void initState() {
    super.initState();
    _connection = GameConnection()..addListener(_playSoundForSnapshot);
    _roomController = TextEditingController(
      text: (widget.initialRoom ?? '').trim().toUpperCase(),
    );
  }

  @override
  void dispose() {
    _connection.removeListener(_playSoundForSnapshot);
    _connection.dispose();
    _roomController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _playSoundForSnapshot() {
    final snapshot = _connection.snapshot;
    if (snapshot == null) {
      return;
    }
    if (_lastPhase != snapshot.phase) {
      if (snapshot.phase == 'victory') {
        _sound.play(SoundCue.victory);
      } else if (snapshot.phase == 'defeat') {
        _sound.play(SoundCue.defeat);
      } else if (snapshot.phase == 'battle') {
        _sound.play(SoundCue.question);
      }
      _lastPhase = snapshot.phase;
    }
    if (snapshot.isBattle && _lastWindow != snapshot.window) {
      _sound.play(SoundCue.question);
      _lastWindow = snapshot.window;
    }
    final result = snapshot.lastResult;
    final player = _currentPlayer(snapshot);
    if (!snapshot.isFinished &&
        result != null &&
        _lastResultQuestion != result.questionId) {
      _sound.play(
        player?.lastCorrect == true ? SoundCue.correct : SoundCue.wrong,
      );
      _lastResultQuestion = result.questionId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _connection,
      builder: (context, _) {
        return Scaffold(
          body: ScanlineBackground(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: _connection.isJoined
                        ? _QuizDeck(connection: _connection, sound: _sound)
                        : _JoinForm(
                            connection: _connection,
                            roomController: _roomController,
                            nameController: _nameController,
                            sound: _sound,
                            onJoin: _join,
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _join() {
    HapticFeedback.selectionClick();
    _sound.play(SoundCue.click);
    _connection.joinPlayer(
      roomId: _roomController.text,
      nickname: _nameController.text,
    );
  }

  PlayerInfo? _currentPlayer(RoomSnapshot snapshot) {
    for (final player in snapshot.players) {
      if (player.id == _connection.playerId) {
        return player;
      }
    }
    return null;
  }
}

class _JoinForm extends StatelessWidget {
  const _JoinForm({
    required this.connection,
    required this.roomController,
    required this.nameController,
    required this.sound,
    required this.onJoin,
  });

  final GameConnection connection;
  final TextEditingController roomController;
  final TextEditingController nameController;
  final SoundController sound;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return RetroPanel(
      child: ListView(
        shrinkWrap: true,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'JOIN QUIZ RAID',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              SoundToggle(sound: sound),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Answer fast. Correct answers damage the boss and climb the leaderboard.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cream),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: roomController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 4,
            style: const TextStyle(fontWeight: FontWeight.w900, color: cream),
            decoration: const InputDecoration(
              labelText: 'Room code',
              counterText: '',
              prefixIcon: Icon(Icons.tag),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nameController,
            maxLength: 18,
            style: const TextStyle(fontWeight: FontWeight.w900, color: cream),
            decoration: const InputDecoration(
              labelText: 'Nickname',
              counterText: '',
              prefixIcon: Icon(Icons.person),
            ),
            onSubmitted: (_) => onJoin(),
          ),
          const SizedBox(height: 22),
          PixelButton(
            label: connection.status == ConnectionStatus.connecting
                ? 'CONNECTING'
                : 'JOIN RAID',
            icon: Icons.login,
            enabled: connection.status != ConnectionStatus.connecting,
            onPressed: onJoin,
          ),
          if (connection.error != null) ...[
            const SizedBox(height: 12),
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

class _QuizDeck extends StatelessWidget {
  const _QuizDeck({required this.connection, required this.sound});

  final GameConnection connection;
  final SoundController sound;

  @override
  Widget build(BuildContext context) {
    final snapshot = connection.snapshot;
    final player = snapshot == null ? null : _currentPlayer(snapshot);

    return RetroPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  player == null
                      ? 'COMMAND DECK'
                      : player.nickname.toUpperCase(),
                  style: Theme.of(context).textTheme.headlineSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SoundToggle(sound: sound),
            ],
          ),
          const SizedBox(height: 12),
          if (snapshot == null)
            const Expanded(
              child: Center(child: CircularProgressIndicator(color: brass)),
            )
          else ...[
            _PhoneStatus(snapshot: snapshot, player: player),
            const SizedBox(height: 14),
            Expanded(
              child: _Body(
                connection: connection,
                snapshot: snapshot,
                player: player,
                sound: sound,
              ),
            ),
          ],
          if (connection.error != null) ...[
            const SizedBox(height: 12),
            Text(
              connection.error!,
              style: const TextStyle(color: ember, fontWeight: FontWeight.w800),
            ),
          ],
        ],
      ),
    );
  }

  PlayerInfo? _currentPlayer(RoomSnapshot snapshot) {
    for (final player in snapshot.players) {
      if (player.id == connection.playerId) {
        return player;
      }
    }
    return null;
  }
}

class _PhoneStatus extends StatelessWidget {
  const _PhoneStatus({required this.snapshot, required this.player});

  final RoomSnapshot snapshot;
  final PlayerInfo? player;

  @override
  Widget build(BuildContext context) {
    final result = player?.lastCorrect;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ink,
        border: Border.all(color: cream.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    snapshot.phaseTitle,
                    style: const TextStyle(
                      color: brass,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                snapshot.isBattle
                    ? CountdownDial(
                        remainingMs: snapshot.windowEndsInMs,
                        totalMs: 18000,
                        size: 70,
                      )
                    : Text(
                        '${snapshot.playerCount} players',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
              ],
            ),
            const SizedBox(height: 12),
            HpBar(
              label: 'Quiz Boss',
              value: snapshot.bossHp,
              maxValue: snapshot.bossHpMax,
              color: ember,
              height: 12,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Score',
                    value: '${player?.score ?? 0}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStat(
                    label: 'Correct',
                    value: '${player?.correctAnswers ?? 0}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MiniStat(
                    label: 'Last',
                    value: result == null
                        ? '-'
                        : result
                        ? '+${player?.lastPoints ?? 0}'
                        : 'miss',
                    color: result == true
                        ? mint
                        : result == false
                        ? ember
                        : cream,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.connection,
    required this.snapshot,
    required this.player,
    required this.sound,
  });

  final GameConnection connection;
  final RoomSnapshot snapshot;
  final PlayerInfo? player;
  final SoundController sound;

  @override
  Widget build(BuildContext context) {
    if (snapshot.isBattle && snapshot.currentQuestion != null) {
      return _AnswerPanel(
        connection: connection,
        snapshot: snapshot,
        player: player,
        sound: sound,
      );
    }
    if (snapshot.isFinished) {
      return _FinalLeaderboard(
        snapshot: snapshot,
        playerId: connection.playerId,
      );
    }
    return Center(
      child: Text(
        'You are in. Watch the projector for the first question.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: cream),
      ),
    );
  }
}

class _AnswerPanel extends StatelessWidget {
  const _AnswerPanel({
    required this.connection,
    required this.snapshot,
    required this.player,
    required this.sound,
  });

  final GameConnection connection;
  final RoomSnapshot snapshot;
  final PlayerInfo? player;
  final SoundController sound;

  @override
  Widget build(BuildContext context) {
    final question = snapshot.currentQuestion!;
    final category = categoryById(question.categoryId, snapshot.categories);
    final answered =
        player?.answered == true ||
        connection.lastAnsweredWindow == snapshot.window;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CategoryBadge(category: category),
        const SizedBox(height: 12),
        Text(question.prompt, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        if (answered)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Answer locked. Watch the boss take damage.',
              style: TextStyle(color: brass, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: question.options.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              return AnswerChoiceTile(
                index: i,
                label: question.options[i],
                color: category.accent,
                disabled: answered,
                selected: player?.selectedOption == i,
                onTap: () {
                  HapticFeedback.heavyImpact();
                  sound.play(SoundCue.answer);
                  connection.sendAnswer(i);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class AnswerChoiceTile extends StatelessWidget {
  const AnswerChoiceTile({
    required this.index,
    required this.label,
    required this.color,
    required this.disabled,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final String label;
  final Color color;
  final bool disabled;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.36)
              : disabled
              ? panelLight
              : color.withValues(alpha: 0.18),
          border: Border.all(
            color: selected
                ? brass
                : disabled
                ? cream.withValues(alpha: 0.2)
                : color,
            width: selected ? 4 : 3,
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(color: cream),
                  ),
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index),
                        style: const TextStyle(
                          color: ink,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FinalLeaderboard extends StatelessWidget {
  const _FinalLeaderboard({required this.snapshot, required this.playerId});

  final RoomSnapshot snapshot;
  final String? playerId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text(
          snapshot.isVictory ? 'Boss defeated.' : 'Boss survived.',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: brass),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < snapshot.leaderboard.length; i++)
          _LeaderboardTile(
            rank: i + 1,
            entry: snapshot.leaderboard[i],
            highlighted: snapshot.leaderboard[i].id == playerId,
          ),
      ],
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({
    required this.rank,
    required this.entry,
    required this.highlighted,
  });

  final int rank;
  final LeaderboardEntry entry;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: highlighted ? brass.withValues(alpha: 0.18) : ink,
          border: Border.all(
            color: highlighted ? brass : cream.withValues(alpha: 0.18),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 42,
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    color: brass,
                    fontWeight: FontWeight.w900,
                  ),
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
                '${entry.correctAnswers}✓ ${entry.score}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    this.color = cream,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: panelLight,
        border: Border.all(color: cream.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SoundToggle extends StatefulWidget {
  const SoundToggle({required this.sound, super.key});

  final SoundController sound;

  @override
  State<SoundToggle> createState() => _SoundToggleState();
}

class _SoundToggleState extends State<SoundToggle> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: widget.sound.enabled ? 'Sound on' : 'Sound off',
      onPressed: () {
        setState(() {
          widget.sound.enabled = !widget.sound.enabled;
        });
        if (widget.sound.enabled) {
          widget.sound.play(SoundCue.click);
        }
      },
      icon: Icon(widget.sound.enabled ? Icons.volume_up : Icons.volume_off),
      color: brass,
    );
  }
}
