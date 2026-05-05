import 'dart:io';

import 'package:server/game_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

Future<void> main(List<String> arguments) async {
  final port =
      _optionInt(arguments, '--port') ??
      int.tryParse(Platform.environment['PORT'] ?? '') ??
      8080;
  final webDir = _option(arguments, '--web-dir') ?? _defaultWebDir();

  final game = CodexGameServer()..startTicker();
  final staticHandler = createStaticHandler(
    webDir,
    defaultDocument: 'index.html',
  );

  final handler = const Pipeline().addMiddleware(logRequests()).addHandler((
    request,
  ) async {
    if (request.url.path == 'ws') {
      return game.wsHandler(request);
    }

    final response = await staticHandler(request);
    if (response.statusCode != 404) {
      return response;
    }

    final indexFile = File('$webDir/index.html');
    if (!indexFile.existsSync()) {
      return Response.notFound(
        'Flutter web build not found at $webDir. Run `flutter build web` first.',
      );
    }

    return Response.ok(
      indexFile.openRead(),
      headers: {'content-type': 'text/html; charset=utf-8'},
    );
  });

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);

  stdout.writeln(
    'Codex vs Bugs server running on http://localhost:${server.port}',
  );
  stdout.writeln('Host screen: http://localhost:${server.port}/host');
  stdout.writeln('Web root: $webDir');

  ProcessSignal.sigint.watch().listen((_) async {
    game.dispose();
    await server.close(force: true);
    exit(0);
  });
}

String _defaultWebDir() {
  if (Directory('build/web').existsSync()) {
    return 'build/web';
  }
  return '../build/web';
}

String? _option(List<String> arguments, String name) {
  for (var i = 0; i < arguments.length; i++) {
    final argument = arguments[i];
    if (argument == name && i + 1 < arguments.length) {
      return arguments[i + 1];
    }
    if (argument.startsWith('$name=')) {
      return argument.substring(name.length + 1);
    }
  }
  return null;
}

int? _optionInt(List<String> arguments, String name) {
  final value = _option(arguments, name);
  return value == null ? null : int.tryParse(value);
}
