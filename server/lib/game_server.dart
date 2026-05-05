import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const questionWindow = Duration(seconds: 18);
const roomIdleTimeoutDefault = Duration(minutes: 20);

const quizCategories = <QuizCategory>[
  QuizCategory(
    id: 'flutter',
    label: 'Flutter',
    accent: '#55D6FF',
    questions: [
      QuizQuestion(
        id: 'flutter_1',
        prompt:
            'Which widget lets Flutter efficiently build long scrolling lists on demand?',
        options: ['Column', 'ListView.builder', 'Wrap', 'Stack'],
        correctIndex: 1,
      ),
      QuizQuestion(
        id: 'flutter_2',
        prompt:
            'What method is called when a StatefulWidget creates its mutable state?',
        options: ['buildState', 'createState', 'initWidget', 'mountState'],
        correctIndex: 1,
      ),
      QuizQuestion(
        id: 'flutter_3',
        prompt: 'Which command creates an optimized web release build?',
        options: [
          'flutter run web',
          'flutter make web',
          'flutter build web',
          'dart build web',
        ],
        correctIndex: 2,
      ),
      QuizQuestion(
        id: 'flutter_4',
        prompt: 'What is Flutter’s rendering model built around?',
        options: ['HTML nodes', 'Native XML', 'A widget tree', 'SQL views'],
        correctIndex: 2,
      ),
    ],
  ),
  QuizCategory(
    id: 'codex',
    label: 'Codex',
    accent: '#FFC857',
    questions: [
      QuizQuestion(
        id: 'codex_1',
        prompt: 'What should Codex do before making a non-trivial code change?',
        options: [
          'Guess the file',
          'Inspect the codebase',
          'Rewrite everything',
          'Skip tests',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        id: 'codex_2',
        prompt:
            'For coding tasks, what is the strongest proof that a fix works?',
        options: [
          'A confident summary',
          'Passing relevant checks',
          'A longer diff',
          'A renamed branch',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        id: 'codex_3',
        prompt: 'What should an agent avoid doing to unrelated user changes?',
        options: [
          'Reading them',
          'Reverting them',
          'Respecting them',
          'Working around them',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        id: 'codex_4',
        prompt: 'When a repo has patterns already, Codex should usually...',
        options: [
          'Follow local style',
          'Invent a framework',
          'Delete tests',
          'Inline secrets',
        ],
        correctIndex: 0,
      ),
    ],
  ),
  QuizCategory(
    id: 'dart',
    label: 'Dart',
    accent: '#62FF9B',
    questions: [
      QuizQuestion(
        id: 'dart_1',
        prompt:
            'Which Dart keyword declares a value that cannot be reassigned?',
        options: ['let', 'final', 'mutable', 'var!'],
        correctIndex: 1,
      ),
      QuizQuestion(
        id: 'dart_2',
        prompt:
            'What is the return type of an async function that eventually returns an int?',
        options: ['int', 'Future<int>', 'Stream<int>', 'Async<int>'],
        correctIndex: 1,
      ),
      QuizQuestion(
        id: 'dart_3',
        prompt:
            'Which operator provides a fallback when the left side is null?',
        options: ['??', '?:', '&&', '=>'],
        correctIndex: 0,
      ),
      QuizQuestion(
        id: 'dart_4',
        prompt: 'What does `const` primarily require in Dart?',
        options: [
          'Runtime IO',
          'Compile-time value',
          'A mutable list',
          'A network call',
        ],
        correctIndex: 1,
      ),
    ],
  ),
  QuizCategory(
    id: 'ai',
    label: 'AI',
    accent: '#A36CFF',
    questions: [
      QuizQuestion(
        id: 'ai_1',
        prompt: 'What does “context window” describe for an LLM?',
        options: [
          'Screen size',
          'Available input/output tokens',
          'GPU fan speed',
          'Database rows',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        id: 'ai_2',
        prompt: 'What is a good way to reduce hallucination risk?',
        options: [
          'Ask for sources or checks',
          'Increase font size',
          'Remove constraints',
          'Ignore tests',
        ],
        correctIndex: 0,
      ),
      QuizQuestion(
        id: 'ai_3',
        prompt: 'A tool call is most useful when the model needs to...',
        options: [
          'Rhyme',
          'Access external state',
          'Use more adjectives',
          'Change its name',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        id: 'ai_4',
        prompt: 'What should prompts make clear for agents?',
        options: [
          'Intent and constraints',
          'Only vibes',
          'Secret keys',
          'Random deadlines',
        ],
        correctIndex: 0,
      ),
    ],
  ),
  QuizCategory(
    id: 'git',
    label: 'Git',
    accent: '#FF8F3D',
    questions: [
      QuizQuestion(
        id: 'git_1',
        prompt: 'Which command shows changed files in the working tree?',
        options: ['git show-tree', 'git status', 'git list', 'git files'],
        correctIndex: 1,
      ),
      QuizQuestion(
        id: 'git_2',
        prompt: 'What does a pull request usually request?',
        options: [
          'Code review and merge',
          'A new laptop',
          'DNS changes',
          'A terminal theme',
        ],
        correctIndex: 0,
      ),
      QuizQuestion(
        id: 'git_3',
        prompt: 'Which command records staged changes as a commit?',
        options: ['git save', 'git commit', 'git snapshot', 'git pack'],
        correctIndex: 1,
      ),
      QuizQuestion(
        id: 'git_4',
        prompt: 'What should you avoid before understanding a dirty worktree?',
        options: [
          'Running status',
          'Reading diffs',
          'Destructive resets',
          'Asking questions',
        ],
        correctIndex: 2,
      ),
    ],
  ),
  QuizCategory(
    id: 'web',
    label: 'Web',
    accent: '#FF4D6D',
    questions: [
      QuizQuestion(
        id: 'web_1',
        prompt:
            'Which protocol upgrades an HTTP connection for realtime bidirectional messages?',
        options: ['WebSocket', 'SMTP', 'RSS', 'PNG'],
        correctIndex: 0,
      ),
      QuizQuestion(
        id: 'web_2',
        prompt: 'What does a QR code in this game mainly carry?',
        options: [
          'The boss sprite',
          'The join URL',
          'A password hash',
          'The leaderboard only',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        id: 'web_3',
        prompt: 'Which browser API can synthesize simple tones?',
        options: [
          'Web Audio API',
          'Cookie API',
          'Clipboard API',
          'Paint Bucket API',
        ],
        correctIndex: 0,
      ),
      QuizQuestion(
        id: 'web_4',
        prompt: 'What does HTTPS add to HTTP?',
        options: [
          'Encryption in transit',
          'More pixels',
          'Dart syntax',
          'A database',
        ],
        correctIndex: 0,
      ),
    ],
  ),
  QuizCategory(
    id: 'montreal',
    label: 'Montreal',
    accent: '#F7F06D',
    questions: [
      QuizQuestion(
        id: 'mtl_1',
        prompt: 'Which mountain gives Montréal its name?',
        options: [
          'Mont Royal',
          'Mont Tremblant',
          'Mont Blanc',
          'Mont Mégantic',
        ],
        correctIndex: 0,
      ),
      QuizQuestion(
        id: 'mtl_2',
        prompt: 'Which metro line color serves Berri-UQAM to Lionel-Groulx?',
        options: ['Blue', 'Orange', 'Green', 'Yellow'],
        correctIndex: 2,
      ),
      QuizQuestion(
        id: 'mtl_3',
        prompt:
            'Which dish is strongly associated with Montréal late-night food?',
        options: [
          'Poutine',
          'Deep dish pizza',
          'Sushi burrito',
          'Clam chowder',
        ],
        correctIndex: 0,
      ),
      QuizQuestion(
        id: 'mtl_4',
        prompt: 'Which river borders Montréal to the south?',
        options: ['St. Lawrence', 'Hudson', 'Seine', 'Thames'],
        correctIndex: 0,
      ),
    ],
  ),
  QuizCategory(
    id: 'debugging',
    label: 'Debugging',
    accent: '#FFFFFF',
    questions: [
      QuizQuestion(
        id: 'debug_1',
        prompt: 'What is the first useful move when a bug is vague?',
        options: [
          'Reproduce it',
          'Rename files',
          'Delete logs',
          'Add animation',
        ],
        correctIndex: 0,
      ),
      QuizQuestion(
        id: 'debug_2',
        prompt: 'A failing test is useful because it gives you...',
        options: [
          'A random clue',
          'A reproducible signal',
          'A logo',
          'A color palette',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        id: 'debug_3',
        prompt: 'What should a minimal repro remove?',
        options: [
          'The bug',
          'Unrelated complexity',
          'All assertions',
          'The README',
        ],
        correctIndex: 1,
      ),
      QuizQuestion(
        id: 'debug_4',
        prompt: 'When a fix touches shared behavior, tests should usually...',
        options: [
          'Get broader',
          'Be deleted',
          'Only check spelling',
          'Move to Slack',
        ],
        correctIndex: 0,
      ),
    ],
  ),
];

class QuizCategory {
  const QuizCategory({
    required this.id,
    required this.label,
    required this.accent,
    required this.questions,
  });

  final String id;
  final String label;
  final String accent;
  final List<QuizQuestion> questions;
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });

  final String id;
  final String prompt;
  final List<String> options;
  final int correctIndex;
}

class CodexGameServer {
  CodexGameServer({
    Random? random,
    this.roomIdleTimeout = roomIdleTimeoutDefault,
  }) : _random = random ?? Random.secure();

  final Random _random;
  final Duration roomIdleTimeout;
  final Map<String, GameRoom> rooms = {};
  Timer? _timer;

  Handler get wsHandler => webSocketHandler(_handleSocket);

  void startTicker() {
    _timer ??= Timer.periodic(const Duration(milliseconds: 250), (_) => tick());
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  GameRoom createRoom({DateTime? now}) {
    final room = GameRoom(
      id: _roomId(),
      hostToken: _token(18),
      createdAt: now ?? DateTime.now(),
    );
    rooms[room.id] = room;
    room.addFeed('Room ${room.id} is online. Pick categories and scan in.');
    return room;
  }

  Player joinPlayer(GameRoom room, {required String nickname, DateTime? now}) {
    final cleanName = _cleanNickname(nickname);
    if (cleanName.isEmpty) {
      throw GameException('bad_name', 'Enter a nickname first.');
    }

    final player = Player(
      id: 'p_${_token(9)}',
      nickname: cleanName,
      joinedAt: now ?? DateTime.now(),
    );
    room.players[player.id] = player;
    room.addFeed('$cleanName joined the raid.');
    return player;
  }

  bool submitAnswer(
    GameRoom room, {
    required String playerId,
    required int optionIndex,
    DateTime? now,
  }) {
    if (room.phase != GamePhase.battle || room.currentQuestion == null) {
      return false;
    }
    if (optionIndex < 0 ||
        optionIndex >= room.currentQuestion!.options.length) {
      return false;
    }
    final player = room.players[playerId];
    if (player == null) {
      return false;
    }
    if (player.answerWindow == room.window) {
      return false;
    }

    final current = now ?? DateTime.now();
    player
      ..answerWindow = room.window
      ..selectedOption = optionIndex
      ..answeredAt = current
      ..lastSeen = current
      ..active = true;
    return true;
  }

  bool recordHeartbeat(
    GameRoom room, {
    required String playerId,
    DateTime? now,
  }) {
    final player = room.players[playerId];
    if (player == null) {
      return false;
    }
    player
      ..lastSeen = now ?? DateTime.now()
      ..active = true;
    room.updatedAt = now ?? DateTime.now();
    return true;
  }

  void startBattle(
    GameRoom room, {
    required List<String> categoryIds,
    required int quizCount,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final questions = _buildQuestionDeck(categoryIds, quizCount);
    if (questions.isEmpty) {
      throw GameException('no_questions', 'Select at least one quiz category.');
    }

    final activeCount = max(1, room.activePlayers.length);
    final count = quizCount.clamp(1, questions.length);
    room
      ..phase = GamePhase.battle
      ..window = 0
      ..quizCount = count
      ..questionDeck = questions.take(count).toList(growable: false)
      ..selectedCategoryIds = categoryIds.toSet()
      ..startedAt = current
      ..windowEndsAt = current.add(questionWindow)
      ..bossHpMax = activeCount * count * 70
      ..bossHp = activeCount * count * 70
      ..lastResult = null;

    for (final player in room.players.values) {
      player
        ..answerWindow = -1
        ..selectedOption = null
        ..answeredAt = null
        ..lastCorrect = null
        ..lastPoints = 0
        ..score = 0
        ..correctAnswers = 0
        ..active = true;
    }

    final categoryLabels = room.selectedCategoryIds
        .map((id) => categoryById(id)?.label ?? id)
        .join(', ');
    room.addFeed('Quiz raid started: $count questions from $categoryLabels.');
  }

  void resetRoom(GameRoom room) {
    room
      ..phase = GamePhase.lobby
      ..window = 0
      ..quizCount = 8
      ..selectedCategoryIds = {'flutter', 'codex'}
      ..questionDeck = const []
      ..startedAt = null
      ..windowEndsAt = null
      ..bossHpMax = 700
      ..bossHp = 700
      ..lastResult = null;
    for (final player in room.players.values) {
      player
        ..answerWindow = -1
        ..selectedOption = null
        ..answeredAt = null
        ..lastCorrect = null
        ..lastPoints = 0
        ..score = 0
        ..correctAnswers = 0
        ..active = true;
    }
    room.addFeed('The boss reset. Choose the next quiz raid.');
  }

  void tick({DateTime? now}) {
    final current = now ?? DateTime.now();
    final staleRooms = <String>[];

    for (final room in rooms.values) {
      _markInactivePlayers(room, current);
      if (room.phase == GamePhase.battle) {
        while (room.windowEndsAt != null &&
            !current.isBefore(room.windowEndsAt!) &&
            room.phase == GamePhase.battle) {
          resolveWindow(room, now: room.windowEndsAt!);
        }
      }

      if (room.clients.isEmpty &&
          current.difference(room.updatedAt) > roomIdleTimeout) {
        staleRooms.add(room.id);
      }
      _broadcastSnapshot(room);
    }

    for (final roomId in staleRooms) {
      rooms.remove(roomId);
    }
  }

  void resolveWindow(GameRoom room, {DateTime? now}) {
    if (room.phase != GamePhase.battle) {
      return;
    }
    final question = room.currentQuestion;
    if (question == null) {
      _finishBattle(room);
      return;
    }

    final current = now ?? DateTime.now();
    final activePlayers = room.activePlayers.toList(growable: false);
    final answered = activePlayers
        .where((player) => player.answerWindow == room.window)
        .toList(growable: false);
    final correct = answered
        .where((player) => player.selectedOption == question.correctIndex)
        .toList(growable: false);
    final damage = correct.length * 100;

    for (final player in answered) {
      final isCorrect = player.selectedOption == question.correctIndex;
      final speedBonus = isCorrect ? _speedBonus(room, player) : 0;
      final points = isCorrect ? 1000 + speedBonus : 75;
      player
        ..lastCorrect = isCorrect
        ..lastPoints = points
        ..score += points;
      if (isCorrect) {
        player.correctAnswers += 1;
      }
    }
    for (final player in activePlayers.where(
      (p) => p.answerWindow != room.window,
    )) {
      player
        ..lastCorrect = false
        ..lastPoints = 0;
    }

    room.bossHp = max(0, room.bossHp - damage);
    room.lastResult = QuestionResult(
      questionId: question.id,
      correctIndex: question.correctIndex,
      correctText: question.options[question.correctIndex],
      answeredCount: answered.length,
      correctCount: correct.length,
      damage: damage,
      tallies: room.currentTallies,
    );
    room.addFeed(
      'Q${room.window + 1}: ${correct.length}/${activePlayers.length} correct. $damage damage.',
    );

    final nextWindow = room.window + 1;
    if (nextWindow >= room.quizCount || room.bossHp <= 0) {
      _finishBattle(room);
      return;
    }

    room
      ..window = nextWindow
      ..windowEndsAt = current.add(questionWindow)
      ..updatedAt = current;
  }

  Map<String, dynamic> snapshot(GameRoom room, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final activePlayers = room.activePlayers.toList(growable: false);

    return {
      'type': 'room_snapshot',
      'roomId': room.id,
      'phase': room.phase.name,
      'window': room.window,
      'quizCount': room.quizCount,
      'windowEndsInMs': _remainingMs(room.windowEndsAt, current),
      'bossHp': room.bossHp,
      'bossHpMax': room.bossHpMax,
      'players': activePlayers
          .map((player) => player.toJson(room.window))
          .toList(growable: false),
      'leaderboard': room.leaderboard
          .map((player) => player.toLeaderboardJson())
          .toList(),
      'categories': quizCategories
          .map((category) => category.toJson())
          .toList(),
      'selectedCategories': room.selectedCategoryIds.toList(growable: false),
      'currentQuestion': room.currentQuestion?.toClientJson(),
      'lastResult': room.lastResult?.toJson(),
      'tallies': room.currentTallies,
      'feed': room.feed.toList(growable: false),
    };
  }

  void _handleSocket(WebSocketChannel channel, String? protocol) {
    final client = ClientConnection(channel);

    channel.stream.listen(
      (message) => _handleMessage(client, message),
      onDone: () => _removeClient(client),
      onError: (_) => _removeClient(client),
      cancelOnError: true,
    );
  }

  void _handleMessage(ClientConnection client, Object? rawMessage) {
    Map<String, dynamic> message;
    try {
      final decoded = jsonDecode(rawMessage as String);
      message = Map<String, dynamic>.from(decoded as Map);
    } on Object {
      _sendError(client, 'bad_json', 'Message was not valid JSON.');
      return;
    }

    final clientRoom = _clientRoom(client);
    final clientPlayerId = client.playerId;
    if (clientRoom != null && clientPlayerId != null) {
      recordHeartbeat(clientRoom, playerId: clientPlayerId);
    }

    final type = message['type'];
    switch (type) {
      case 'host_create':
        final room = createRoom();
        client
          ..roomId = room.id
          ..hostToken = room.hostToken
          ..role = ClientRole.host;
        room.clients.add(client);
        _send(client, {
          'type': 'room_created',
          'roomId': room.id,
          'hostToken': room.hostToken,
        });
        _send(client, snapshot(room));
      case 'host_command':
        _handleHostCommand(client, message);
      case 'player_join':
        _handlePlayerJoin(client, message);
      case 'player_answer':
        _handlePlayerAnswer(client, message);
      case 'ping':
        _send(client, {'type': 'pong'});
      default:
        _sendError(client, 'unknown_type', 'Unknown message type: $type.');
    }
  }

  void _handleHostCommand(
    ClientConnection client,
    Map<String, dynamic> message,
  ) {
    final room = _authorizedHostRoom(client, message);
    if (room == null) {
      return;
    }
    final command = message['command'];
    switch (command) {
      case 'start':
        final categoryIds = ((message['categoryIds'] as List?) ?? const [])
            .map((value) => value.toString())
            .where((id) => categoryById(id) != null)
            .toList(growable: false);
        final quizCount = _asInt(
          message['quizCount'],
          fallback: room.quizCount,
        );
        try {
          startBattle(
            room,
            categoryIds: categoryIds.isEmpty
                ? room.selectedCategoryIds.toList()
                : categoryIds,
            quizCount: quizCount,
          );
        } on GameException catch (error) {
          _sendError(client, error.code, error.message);
          return;
        }
      case 'reset':
        resetRoom(room);
      default:
        _sendError(client, 'bad_command', 'Unknown host command: $command.');
        return;
    }
    _broadcastSnapshot(room);
  }

  void _handlePlayerJoin(
    ClientConnection client,
    Map<String, dynamic> message,
  ) {
    final roomId = _roomInput(message['roomId']);
    final room = rooms[roomId];
    if (room == null) {
      _sendError(client, 'missing_room', 'Room $roomId does not exist.');
      return;
    }
    try {
      final player = joinPlayer(
        room,
        nickname: (message['nickname'] ?? '').toString(),
      );
      client
        ..roomId = room.id
        ..playerId = player.id
        ..role = ClientRole.player;
      room.clients.add(client);
      _send(client, {
        'type': 'player_joined',
        'roomId': room.id,
        'playerId': player.id,
      });
      _broadcastSnapshot(room);
    } on GameException catch (error) {
      _sendError(client, error.code, error.message);
    }
  }

  void _handlePlayerAnswer(
    ClientConnection client,
    Map<String, dynamic> message,
  ) {
    final room = _clientRoom(client);
    if (room == null || client.playerId == null) {
      _sendError(client, 'not_joined', 'Join a room before answering.');
      return;
    }
    final accepted = submitAnswer(
      room,
      playerId: client.playerId!,
      optionIndex: _asInt(message['optionIndex'], fallback: -1),
    );
    if (!accepted) {
      _sendError(client, 'answer_rejected', 'That answer is not available.');
      return;
    }
    _broadcastSnapshot(room);
  }

  void _finishBattle(GameRoom room) {
    room
      ..phase = room.bossHp <= 0 ? GamePhase.victory : GamePhase.defeat
      ..windowEndsAt = null
      ..updatedAt = DateTime.now();
    final winner = room.leaderboard.isEmpty ? null : room.leaderboard.first;
    final result = room.phase == GamePhase.victory
        ? 'Boss defeated'
        : 'Boss survived';
    room.addFeed(
      winner == null
          ? '$result. No leaderboard entries.'
          : '$result. MVP: ${winner.nickname} with ${winner.score} pts.',
    );
  }

  List<QuizQuestion> _buildQuestionDeck(
    List<String> categoryIds,
    int quizCount,
  ) {
    final selected = categoryIds
        .map(categoryById)
        .whereType<QuizCategory>()
        .toList(growable: false);
    final categories = selected.isEmpty
        ? quizCategories.where(
            (category) => category.id == 'flutter' || category.id == 'codex',
          )
        : selected;
    final questions = <QuizQuestion>[
      for (final category in categories) ...category.questions,
    ];
    questions.shuffle(_random);
    return questions
        .take(quizCount.clamp(1, questions.length))
        .toList(growable: false);
  }

  int _speedBonus(GameRoom room, Player player) {
    final answeredAt = player.answeredAt;
    final windowEndsAt = room.windowEndsAt;
    if (answeredAt == null || windowEndsAt == null) {
      return 0;
    }
    final remaining = windowEndsAt.difference(answeredAt).inMilliseconds;
    final ratio = (remaining / questionWindow.inMilliseconds).clamp(0.0, 1.0);
    return (ratio * 400).round();
  }

  GameRoom? _authorizedHostRoom(
    ClientConnection client,
    Map<String, dynamic> message,
  ) {
    final room = rooms[_roomInput(message['roomId'])] ?? _clientRoom(client);
    final token = (message['hostToken'] ?? '').toString();
    if (room == null || room.hostToken != token) {
      _sendError(client, 'not_host', 'Host token is invalid.');
      return null;
    }
    return room;
  }

  GameRoom? _clientRoom(ClientConnection client) {
    final roomId = client.roomId;
    return roomId == null ? null : rooms[roomId];
  }

  void _removeClient(ClientConnection client) {
    final room = _clientRoom(client);
    if (room == null) {
      return;
    }
    room.clients.remove(client);
    final playerId = client.playerId;
    if (playerId != null) {
      final player = room.players[playerId];
      if (player != null) {
        player.active = false;
        room.addFeed('${player.nickname} disconnected.');
      }
    }
    _broadcastSnapshot(room);
  }

  void _broadcastSnapshot(GameRoom room) {
    final data = snapshot(room);
    for (final client in room.clients.toList(growable: false)) {
      _send(client, data);
    }
  }

  void _send(ClientConnection client, Map<String, dynamic> message) {
    try {
      client.channel.sink.add(jsonEncode(message));
    } on Object {
      _removeClient(client);
    }
  }

  void _sendError(ClientConnection client, String code, String message) {
    _send(client, {'type': 'error', 'code': code, 'message': message});
  }

  void _markInactivePlayers(GameRoom room, DateTime now) {
    for (final player in room.players.values) {
      if (now.difference(player.lastSeen) > const Duration(seconds: 35)) {
        player.active = false;
      }
    }
  }

  String _roomId() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    String next() => String.fromCharCodes(
      List.generate(
        4,
        (_) => alphabet.codeUnitAt(_random.nextInt(alphabet.length)),
      ),
    );
    var id = next();
    while (rooms.containsKey(id)) {
      id = next();
    }
    return id;
  }

  String _token(int length) {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      List.generate(
        length,
        (_) => alphabet.codeUnitAt(_random.nextInt(alphabet.length)),
      ),
    );
  }

  String _cleanNickname(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    return String.fromCharCodes(normalized.runes.take(18));
  }

  String _roomInput(Object? value) => value.toString().trim().toUpperCase();

  int _remainingMs(DateTime? target, DateTime now) {
    if (target == null) {
      return 0;
    }
    return max(0, target.difference(now).inMilliseconds);
  }

  int _asInt(Object? value, {int fallback = 0}) {
    return value is num ? value.toInt() : fallback;
  }
}

class GameRoom {
  GameRoom({required this.id, required this.hostToken, required this.createdAt})
    : updatedAt = createdAt;

  final String id;
  final String hostToken;
  final DateTime createdAt;
  final Set<ClientConnection> clients = {};
  final Map<String, Player> players = {};
  final List<String> feed = [];

  DateTime updatedAt;
  GamePhase phase = GamePhase.lobby;
  DateTime? startedAt;
  DateTime? windowEndsAt;
  int window = 0;
  int quizCount = 8;
  int bossHpMax = 700;
  int bossHp = 700;
  Set<String> selectedCategoryIds = {'flutter', 'codex'};
  List<QuizQuestion> questionDeck = const [];
  QuestionResult? lastResult;

  Iterable<Player> get activePlayers =>
      players.values.where((player) => player.active);

  QuizQuestion? get currentQuestion {
    if (phase != GamePhase.battle ||
        window < 0 ||
        window >= questionDeck.length) {
      return null;
    }
    return questionDeck[window];
  }

  Map<String, int> get currentTallies {
    final tallies = <String, int>{};
    for (final player in activePlayers) {
      if (player.answerWindow != window || player.selectedOption == null) {
        continue;
      }
      final key = player.selectedOption!.toString();
      tallies[key] = (tallies[key] ?? 0) + 1;
    }
    return tallies;
  }

  List<Player> get leaderboard {
    final entries = players.values.toList(growable: false);
    entries.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      final correctCompare = b.correctAnswers.compareTo(a.correctAnswers);
      if (correctCompare != 0) {
        return correctCompare;
      }
      return a.nickname.compareTo(b.nickname);
    });
    return entries;
  }

  void addFeed(String message) {
    feed.insert(0, message);
    if (feed.length > 9) {
      feed.removeRange(9, feed.length);
    }
    updatedAt = DateTime.now();
  }
}

enum GamePhase { lobby, battle, victory, defeat }

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

  final String questionId;
  final int correctIndex;
  final String correctText;
  final int answeredCount;
  final int correctCount;
  final int damage;
  final Map<String, int> tallies;

  Map<String, dynamic> toJson() => {
    'questionId': questionId,
    'correctIndex': correctIndex,
    'correctText': correctText,
    'answeredCount': answeredCount,
    'correctCount': correctCount,
    'damage': damage,
    'tallies': tallies,
  };
}

class Player {
  Player({required this.id, required this.nickname, required this.joinedAt})
    : lastSeen = joinedAt;

  final String id;
  final String nickname;
  final DateTime joinedAt;
  DateTime lastSeen;
  bool active = true;
  int answerWindow = -1;
  int? selectedOption;
  DateTime? answeredAt;
  bool? lastCorrect;
  int lastPoints = 0;
  int score = 0;
  int correctAnswers = 0;

  Map<String, dynamic> toJson(int currentWindow) => {
    'id': id,
    'nickname': nickname,
    'answered': answerWindow == currentWindow,
    'selectedOption': answerWindow == currentWindow ? selectedOption : null,
    'lastCorrect': lastCorrect,
    'lastPoints': lastPoints,
    'score': score,
    'correctAnswers': correctAnswers,
  };

  Map<String, dynamic> toLeaderboardJson() => {
    'id': id,
    'nickname': nickname,
    'score': score,
    'correctAnswers': correctAnswers,
  };
}

enum ClientRole { spectator, host, player }

class ClientConnection {
  ClientConnection(this.channel);

  final WebSocketChannel channel;
  ClientRole role = ClientRole.spectator;
  String? roomId;
  String? hostToken;
  String? playerId;
}

class GameException implements Exception {
  GameException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'GameException($code, $message)';
}

QuizCategory? categoryById(String id) {
  for (final category in quizCategories) {
    if (category.id == id) {
      return category;
    }
  }
  return null;
}

extension on QuizCategory {
  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'accent': accent,
    'questionCount': questions.length,
  };
}

extension on QuizQuestion {
  Map<String, dynamic> toClientJson() => {
    'id': id,
    'categoryId': _categoryId,
    'prompt': prompt,
    'options': options,
  };

  String get _categoryId {
    for (final category in quizCategories) {
      if (category.questions.any((question) => question.id == id)) {
        return category.id;
      }
    }
    return 'quiz';
  }
}
