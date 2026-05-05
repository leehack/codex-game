import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:server/game_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  test('host and player can complete a websocket command flow', () async {
    final game = CodexGameServer(random: Random(4));
    final server = await shelf_io.serve(
      (Request request) => game.wsHandler(request),
      InternetAddress.loopbackIPv4,
      0,
    );
    addTearDown(() async {
      game.dispose();
      await server.close(force: true);
    });

    final uri = Uri.parse('ws://127.0.0.1:${server.port}/ws');
    final host = WebSocketChannel.connect(uri);
    final player = WebSocketChannel.connect(uri);
    addTearDown(() async {
      await host.sink.close();
      await player.sink.close();
    });

    final hostMessages = _messageQueue(host);
    final playerMessages = _messageQueue(player);
    addTearDown(hostMessages.cancel);
    addTearDown(playerMessages.cancel);

    host.sink.add(jsonEncode({'type': 'host_create'}));
    final created = await hostMessages.nextWhere('room_created');
    final roomId = created['roomId'] as String;
    final hostToken = created['hostToken'] as String;

    player.sink.add(
      jsonEncode({
        'type': 'player_join',
        'roomId': roomId,
        'nickname': 'Test Player',
      }),
    );
    final joined = await playerMessages.nextWhere('player_joined');
    final playerId = joined['playerId'] as String;
    expect(playerId, startsWith('p_'));

    host.sink.add(
      jsonEncode({
        'type': 'host_command',
        'roomId': roomId,
        'hostToken': hostToken,
        'command': 'start',
        'quizCount': 5,
        'categoryIds': ['flutter', 'codex'],
      }),
    );
    final battle = await playerMessages.nextWhere(
      'room_snapshot',
      where: (message) => message['phase'] == 'battle',
    );
    expect(battle['roomId'], roomId);

    final question = Map<String, dynamic>.from(
      battle['currentQuestion'] as Map,
    );
    final options = (question['options'] as List).cast<String>();
    expect(options, isNotEmpty);

    player.sink.add(jsonEncode({'type': 'player_answer', 'optionIndex': 0}));
    final acted = await playerMessages.nextWhere(
      'room_snapshot',
      where: (message) => ((message['tallies'] as Map?) ?? const {})['0'] == 1,
    );
    expect(acted['players'], isNotEmpty);
  });
}

_MessageQueue _messageQueue(WebSocketChannel channel) {
  final controller = StreamController<Map<String, dynamic>>();
  channel.stream.listen(
    (message) {
      controller.add(
        Map<String, dynamic>.from(jsonDecode(message as String) as Map),
      );
    },
    onError: controller.addError,
    onDone: controller.close,
  );
  return _MessageQueue(controller.stream);
}

class _MessageQueue {
  _MessageQueue(Stream<Map<String, dynamic>> stream) {
    _subscription = stream.listen(_messages.add, onError: _errors.add);
  }

  final _messages = <Map<String, dynamic>>[];
  final _errors = <Object>[];
  late final StreamSubscription<Map<String, dynamic>> _subscription;

  Future<Map<String, dynamic>> nextWhere(
    String type, {
    bool Function(Map<String, dynamic> message)? where,
  }) async {
    final deadline = DateTime.now().add(const Duration(seconds: 4));
    while (DateTime.now().isBefore(deadline)) {
      if (_errors.isNotEmpty) {
        throw _errors.first;
      }
      for (var i = 0; i < _messages.length; i++) {
        final message = _messages[i];
        if (message['type'] == type && (where == null || where(message))) {
          _messages.removeAt(i);
          return message;
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    throw TimeoutException('Timed out waiting for $type. Seen: $_messages');
  }

  Future<void> cancel() => _subscription.cancel();
}
