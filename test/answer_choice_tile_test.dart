import 'package:codex_game/ui/join_screen.dart';
import 'package:codex_game/ui/retro_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const longAnswer =
      'Use a scrollable answer list with wrapping text so every choice remains readable on compact phone browsers.';
  const options = [
    longAnswer,
    'A second intentionally wordy option that should wrap instead of being vertically clipped by its tile.',
    'A short option',
    'Another long answer label that can occupy multiple lines without causing render overflow warnings.',
  ];

  Future<void> pumpAnswerList(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: ink,
          body: SafeArea(
            child: SizedBox.expand(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return AnswerChoiceTile(
                    index: index,
                    label: options[index],
                    color: brass,
                    disabled: false,
                    selected: false,
                    onTap: () {},
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() async {
    await TestWidgetsFlutterBinding.ensureInitialized().setSurfaceSize(null);
  });

  for (final screen in <({String name, Size size})>[
    (name: 'iPhone 11 browser viewport', size: Size(414, 715)),
    (name: 'small phone viewport', size: Size(320, 568)),
    (name: 'wide phone viewport', size: Size(896, 414)),
  ]) {
    testWidgets('answer tile text remains readable on ${screen.name}', (
      tester,
    ) async {
      await pumpAnswerList(tester, screen.size);

      expect(tester.takeException(), isNull);
      expect(find.text(longAnswer), findsOneWidget);

      final text = tester.widget<Text>(find.text(longAnswer));
      expect(text.softWrap, isTrue);
      expect(text.maxLines, isNull);
      expect(text.overflow, isNull);

      final textSize = tester.getSize(find.text(longAnswer));
      final tileSize = tester.getSize(find.byType(AnswerChoiceTile).first);
      expect(textSize.height, greaterThan(22));
      expect(tileSize.height, greaterThanOrEqualTo(textSize.height + 28));
    });
  }
}
