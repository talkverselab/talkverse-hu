import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:hungarian_universe/core/cliff.dart';
import 'package:hungarian_universe/screens/about_screen.dart';
import 'package:hungarian_universe/screens/alphabet_screen.dart';
import 'package:hungarian_universe/services/hu_alphabet.dart';
import 'package:hungarian_universe/screens/word_freq_screen.dart';
import 'package:hungarian_universe/services/dialogue_service.dart';
import 'package:hungarian_universe/widgets/suffix_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(rootBundle.clear); // 앞 시험의 가짜 시계에 묶인 캐시를 비운다

  test('절벽 구간 경계', () {
    expect([1, 105, 106, 146, 147, 306, 307, 813, 814, 1500].map(Cliff.regionOf).toList(),
        ['R1', 'R1', 'R2', 'R2', 'R3', 'R3', 'R4', 'R4', 'R5', 'R5']);
  });

  for (final size in const [Size(360, 740), Size(820, 1180)]) {
    testWidgets('절벽 단어 화면 $size', (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(const MaterialApp(home: WordFreqScreen()));
      for (var i = 0; i < 40 && find.text('1단원').evaluate().isEmpty; i++) {
        await t.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
        await t.pump();
      }
      expect(find.text('1단원'), findsOneWidget);
      expect(find.text('절벽구간 단어만'), findsOneWidget);
      expect(find.text('회화 단어 포함 (+14)'), findsOneWidget);
      await t.tap(find.text('회화 단어 포함 (+14)'));
      await t.pump();
      await t.dragUntilVisible(find.text('회화'), find.byType(ListView).first, const Offset(-200, 0));
      await t.pump();
      await t.tap(find.text('회화'));
      await t.pump();
      expect(find.text('szombat'), findsOneWidget);
    });

    testWidgets('앱 소개 $size', (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(const MaterialApp(home: AboutScreen()));
      await t.pump();
      expect(find.text('814-1500'), findsOneWidget);
      expect(find.text('누적 85.0%'), findsOneWidget);
    });
  }

  testWidgets('문장 낱말 탭 = 단어창', (t) async {
    await t.pumpWidget(const MaterialApp(
      home: Scaffold(body: SuffixText('Az állomásban', lemmas: [Lemma('állomásban', 'állomás', '')], style: TextStyle(fontSize: 18))),
    ));
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 500)));
    await t.pump();
    await t.tap(find.byType(GestureDetector).first);
    await t.pumpAndSettle();
    expect(find.text('역'), findsOneWidget); // 단어장 뜻
    expect(find.textContaining('접미사 -'), findsOneWidget); // 접미사 시트로 가는 버튼
  });

  test('알파벳 44자', () => expect(huLetters.length, 44));

  for (final size in const [Size(360, 740), Size(820, 1180)]) {
    testWidgets('알파벳과 발음 $size', (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(const MaterialApp(home: AlphabetScreen()));
      await t.pump();
      expect(find.text('gy'), findsOneWidget);
      await t.tap(find.text('gy'));
      await t.pump(const Duration(milliseconds: 500));
      await t.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('gyerek'), findsOneWidget);
      await t.pump(const Duration(seconds: 2));
    });
  }
}
