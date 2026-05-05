FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY server/pubspec.yaml server/pubspec.lock ./server/
RUN cd server && dart pub get

COPY . .
RUN flutter build web --release
RUN cd server && dart compile exe bin/server.dart -o /app/codex_game_server

FROM debian:bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=build /app/build/web /app/build/web
COPY --from=build /app/codex_game_server /app/codex_game_server

ENV PORT=8080
EXPOSE 8080

CMD ["/app/codex_game_server", "--web-dir", "/app/build/web"]
