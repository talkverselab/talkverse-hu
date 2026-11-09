// 스토어 스크린샷 + 단독 앱 실행 확인(2026-11-09) — 헝가리어 고유 화면을 먼저(~/talkverse/STORE_DIFFERENTIATION.md).
// python3 tools/pane_shots.py <UDID> <폴더> integration_test/store_shots_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hungarian_universe/embed.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<void> wait(WidgetTester t, int ms) async {
    final end = DateTime.now().add(Duration(milliseconds: ms));
    while (DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 100));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester t, String name) async {
    await wait(t, 2000);
    // ignore: avoid_print
    print('SHOT:$name');
    await wait(t, 2500);
  }

  testWidgets('store shots', timeout: const Timeout(Duration(minutes: 10)), (t) async {
    await embedInit(standalone: true);
    await t.pumpWidget(embedApp());
    await wait(t, 3000);
    if (find.text('나중에').evaluate().isNotEmpty) await t.tap(find.text('나중에').first); // 그림 내려받기 화면이면 건너뛰기
    await wait(t, 2000);

    await t.tap(find.text('알파벳과 발음').first);
    await wait(t, 2500);
    await shot(t, '01_alphabet');
    await t.tap(find.text('gy').first);
    await wait(t, 2500);
    await shot(t, '02_letter_sheet');
    await t.tapAt(const Offset(20, 60));
    await wait(t, 1500);

    await t.tap(find.text('ö').first);
    await wait(t, 2500);
    await shot(t, '03_vowel_harmony');
    await t.tapAt(const Offset(20, 60));
    await wait(t, 1500);

    await t.scrollUntilVisible(find.text('Ragok').first, 200, scrollable: find.byType(Scrollable).first);
    await t.tap(find.text('Ragok').first);
    await wait(t, 2500);
    await shot(t, '04_suffix_map');

    await t.scrollUntilVisible(find.text('R1~R5').first, 200, scrollable: find.byType(Scrollable).first);
    await t.tap(find.text('R1~R5').first);
    await wait(t, 3000);
    await shot(t, '05_cliff_words');

    await t.scrollUntilVisible(find.text('Beszélgetés').first, -200, scrollable: find.byType(Scrollable).first);
    await t.tap(find.text('Beszélgetés').first);
    await wait(t, 2500);
    await shot(t, '06_dialogue_home');
    await wait(t, 500);
    expect(true, isTrue);
  });
}
