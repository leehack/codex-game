import 'package:flutter/material.dart';

import 'ui/host_screen.dart';
import 'ui/join_screen.dart';
import 'ui/retro_widgets.dart';

void main() {
  runApp(const CodexVsBugsApp());
}

class CodexVsBugsApp extends StatelessWidget {
  const CodexVsBugsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Codex vs Bugs',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'monospace',
        scaffoldBackgroundColor: ink,
        colorScheme: const ColorScheme.dark(
          primary: brass,
          secondary: cyan,
          tertiary: mint,
          error: ember,
          surface: panel,
        ),
        textTheme: const TextTheme(
          displaySmall: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w900,
            color: cream,
            letterSpacing: 0,
          ),
          headlineSmall: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: cream,
            letterSpacing: 0,
          ),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: cream,
            letterSpacing: 0,
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: cream,
            letterSpacing: 0,
          ),
          bodyMedium: TextStyle(
            fontSize: 15,
            color: cream,
            height: 1.25,
            letterSpacing: 0,
          ),
          labelLarge: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: cream,
            letterSpacing: 0,
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: cream,
            letterSpacing: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: ink,
          labelStyle: TextStyle(color: cream.withValues(alpha: 0.7)),
          prefixIconColor: brass,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: cream.withValues(alpha: 0.22)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: brass, width: 2),
          ),
        ),
      ),
      home: const RouteGate(),
    );
  }
}

class RouteGate extends StatelessWidget {
  const RouteGate({super.key});

  @override
  Widget build(BuildContext context) {
    final uri = Uri.base;
    final path = uri.path.endsWith('/') && uri.path.length > 1
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;

    if (path == '/host') {
      return const HostScreen();
    }
    if (path == '/join') {
      return JoinScreen(initialRoom: uri.queryParameters['room']);
    }
    return const LauncherScreen();
  }
}

class LauncherScreen extends StatelessWidget {
  const LauncherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ScanlineBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'CODEX VS BUGS',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: brass,
                        fontSize: 54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'A crowd-controlled retro quiz raid for the Montreal meetup.',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: cyan),
                    ),
                    const SizedBox(height: 28),
                    RetroPanel(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final narrow = constraints.maxWidth < 620;
                          final host = _LauncherAction(
                            title: 'Host Projector',
                            body:
                                'Open the shared battle screen and generate a QR room.',
                            icon: Icons.cast,
                            color: brass,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const HostScreen(),
                              ),
                            ),
                          );
                          final join = _LauncherAction(
                            title: 'Join From Phone',
                            body:
                                'Enter a room code manually if the QR is not available.',
                            icon: Icons.phone_iphone,
                            color: cyan,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const JoinScreen(),
                              ),
                            ),
                          );
                          return narrow
                              ? Column(
                                  children: [
                                    host,
                                    const SizedBox(height: 14),
                                    join,
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(child: host),
                                    const SizedBox(width: 14),
                                    Expanded(child: join),
                                  ],
                                );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Run the server, open /host, choose categories, tunnel the port, and let attendees scan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cream.withValues(alpha: 0.76),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

class _LauncherAction extends StatelessWidget {
  const _LauncherAction({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ink,
          border: Border.all(color: color, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 34),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                body,
                style: TextStyle(
                  color: cream.withValues(alpha: 0.78),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
