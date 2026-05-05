# Codex vs Bugs

A crowd-controlled retro quiz RPG for a Codex community meetup.

The host projects a Flutter Web battle screen. Attendees scan a QR code, join from
phone browsers, enter a nickname, and answer boss quiz questions during timed
windows. Correct answers deal collaborative damage, while individual speed and
accuracy determine the final leaderboard. A local Dart websocket server owns
room state, so the live event does not depend on a database or AI API.

## Run Locally

```sh
flutter pub get
flutter build web
cd server
dart pub get
dart run bin/server.dart --web-dir ../build/web --port 8080
```

Open the host screen:

```txt
http://localhost:8080/host
```

To make the room reachable by phones outside the laptop network:

```sh
ngrok http 8080
```

Open the ngrok `/host` URL on the projector. Attendees scan the QR code shown on
that page.

## Host Online

Use a single always-on web service because rooms are stored in memory and the
same process serves both Flutter Web and `/ws`.

Recommended path: deploy the repository as a Docker web service on Render,
Railway, Fly.io, or Cloud Run. The root `Dockerfile` builds Flutter Web, compiles
the Dart server, and listens on `$PORT`.

For meetup reliability, run one instance unless you add shared room storage.
Multiple instances can split WebSocket clients across different in-memory rooms.

## Screens

- `/host`: projector lobby, QR code, category/count setup, quiz boss, leaderboard.
- `/join?room=CODE`: phone join form and answer deck.
- `/`: launcher for local testing.

## Quiz Categories

The built-in categories are Flutter, Codex, Dart, AI, Git, Web, Montreal, and
Debugging. Flutter and Codex are selected by default.

## Verify

```sh
flutter test
(cd server && dart test)
flutter build web
```
