import 'package:codex_game/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('launcher exposes host and join paths', (tester) async {
    await tester.pumpWidget(const CodexVsBugsApp());

    expect(find.text('CODEX VS BUGS'), findsOneWidget);
    expect(find.text('Host Projector'), findsOneWidget);
    expect(find.text('Join From Phone'), findsOneWidget);
  });
}
