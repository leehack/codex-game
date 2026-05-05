import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'protocol.dart';

enum ConnectionStatus { idle, connecting, connected, offline }

class GameConnection extends ChangeNotifier {
  GameConnection({Uri? socketUri})
    : _socketUri = socketUri ?? _defaultSocketUri();

  final Uri _socketUri;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _heartbeat;

  ConnectionStatus status = ConnectionStatus.idle;
  RoomSnapshot? snapshot;
  String? roomId;
  String? hostToken;
  String? playerId;
  String? error;
  int? lastAnsweredWindow;

  bool get isHost => hostToken != null;
  bool get isJoined => playerId != null;
  bool get isConnected => status == ConnectionStatus.connected;

  String? get joinUrl {
    final id = roomId;
    if (id == null || id.isEmpty) {
      return null;
    }
    return '${Uri.base.scheme}://${Uri.base.authority}/join?room=$id';
  }

  Future<void> createHost() async {
    await _connect();
    _send({'type': 'host_create'});
  }

  Future<void> joinPlayer({
    required String roomId,
    required String nickname,
  }) async {
    await _connect();
    _send({
      'type': 'player_join',
      'roomId': roomId.trim().toUpperCase(),
      'nickname': nickname.trim(),
    });
  }

  void startBattle({required int quizCount, required Set<String> categoryIds}) {
    _hostCommand('start', {
      'quizCount': quizCount,
      'categoryIds': categoryIds.toList(growable: false),
    });
  }

  void resetRoom() {
    _hostCommand('reset');
  }

  void sendAnswer(int optionIndex) {
    final currentWindow = snapshot?.window;
    if (currentWindow != null && lastAnsweredWindow == currentWindow) {
      return;
    }
    lastAnsweredWindow = currentWindow;
    _send({'type': 'player_answer', 'optionIndex': optionIndex});
    notifyListeners();
  }

  void clearError() {
    error = null;
    notifyListeners();
  }

  Future<void> _connect() async {
    if (_channel != null) {
      return;
    }
    status = ConnectionStatus.connecting;
    error = null;
    notifyListeners();

    try {
      final channel = WebSocketChannel.connect(_socketUri);
      _channel = channel;
      _subscription = channel.stream.listen(
        _handleMessage,
        onDone: _handleDisconnect,
        onError: (Object err) => _handleDisconnect(err.toString()),
        cancelOnError: true,
      );
      status = ConnectionStatus.connected;
      _startHeartbeat();
      notifyListeners();
    } on Object catch (err) {
      status = ConnectionStatus.offline;
      error = 'Could not connect to $_socketUri: $err';
      notifyListeners();
    }
  }

  void _hostCommand(String command, [Map<String, dynamic> extra = const {}]) {
    final id = roomId;
    final token = hostToken;
    if (id == null || token == null) {
      return;
    }
    _send({
      'type': 'host_command',
      'roomId': id,
      'hostToken': token,
      'command': command,
      ...extra,
    });
  }

  void _send(Map<String, dynamic> message) {
    try {
      _channel?.sink.add(jsonEncode(message));
    } on Object catch (err) {
      status = ConnectionStatus.offline;
      error = 'Connection failed: $err';
      notifyListeners();
    }
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_channel == null) {
        return;
      }
      _send({
        'type': 'ping',
        if (roomId != null) 'roomId': roomId,
        if (playerId != null) 'playerId': playerId,
      });
    });
  }

  void _handleMessage(Object? raw) {
    final text = raw is List<int> ? utf8.decode(raw) : raw.toString();
    final decoded = jsonDecode(text);
    if (decoded is! Map) {
      return;
    }
    final message = Map<String, dynamic>.from(decoded);
    switch (message['type']) {
      case 'room_created':
        roomId = (message['roomId'] ?? '').toString();
        hostToken = (message['hostToken'] ?? '').toString();
        error = null;
      case 'player_joined':
        roomId = (message['roomId'] ?? '').toString();
        playerId = (message['playerId'] ?? '').toString();
        error = null;
      case 'room_snapshot':
        final next = RoomSnapshot.fromJson(message);
        if (snapshot != null && snapshot!.window != next.window) {
          lastAnsweredWindow = null;
        }
        snapshot = next;
        roomId = next.roomId;
        error = null;
      case 'error':
        error = (message['message'] ?? 'Something went wrong.').toString();
        if ((message['code'] ?? '') == 'answer_rejected') {
          lastAnsweredWindow = null;
        }
    }
    notifyListeners();
  }

  void _handleDisconnect([String? message]) {
    _heartbeat?.cancel();
    _heartbeat = null;
    _channel = null;
    status = ConnectionStatus.offline;
    error = message ?? 'Disconnected from game server.';
    notifyListeners();
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  static Uri _defaultSocketUri() {
    final scheme = Uri.base.scheme == 'https' ? 'wss' : 'ws';
    return Uri.parse('$scheme://${Uri.base.authority}/ws');
  }
}
