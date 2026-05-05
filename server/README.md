# Codex vs Bugs Server

Local websocket and static-file server for the Flutter Web quiz game.

```sh
dart pub get
dart run bin/server.dart --web-dir ../build/web --port 8080
```

The server owns room state, question selection, answer windows, boss damage,
scoring, and leaderboard state in memory. It exposes:

- `GET /ws` for websocket host/player messages.
- Static Flutter Web files from `../build/web`.
- SPA fallback for `/host` and `/join?room=CODE`.
