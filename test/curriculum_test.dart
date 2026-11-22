import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hungarian_universe/screens/curriculum_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hungarian_universe/services/curriculum.dart';
import 'package:hungarian_universe/services/dialogue_service.dart';

Dialogue _d(String id, String topic, int n) => Dialogue(
      id: id,
      region: 'R1',
      topic: topic,
      title: id,
      emoji: '💬',
      scene: '',
      speakers: const {'A': 'A', 'B': 'B'},
      genders: const {},
      expressions: const [],
      turns: [
        for (var i = 1; i <= n; i++)
          DialogueTurn(num: i, speaker: i.isOdd ? 'A' : 'B', tl: '$id hu $i', gloss: '', rd: '', ko: '$id 뜻 $i', note: '', tags: const []),
      ],
    );

void main() {
  test('점수 80% 경계 — 소수점 버림', () {
    expect(scorePercent(8, 10), 80);
    expect(isPass(8, 10), isTrue);
    expect(scorePercent(79, 100), 79);
    expect(isPass(79, 100), isFalse);
    expect(scorePercent(23, 29), 79); // 79.3 → 79
    expect(isPass(23, 29), isFalse);
    expect(isPass(24, 30), isTrue);
    expect(scorePercent(0, 0), 0);
  });

  test('간격 반복 1·3·7일, 틀리면 1일로', () {
    final t = DateTime(2026, 11, 30);
    expect(nextReview(step: 0, correct: true, today: t), (1, '2026-12-03'));
    expect(nextReview(step: 1, correct: true, today: t), (2, '2026-12-07'));
    expect(nextReview(step: 2, correct: true, today: t), (2, '2026-12-07'));
    expect(nextReview(step: 2, correct: false, today: t), (0, '2026-12-01'));
  });

  test('시험 통과·불통과 기록과 하루 분량·연속 일수', () {
    final day1 = DateTime(2026, 11, 22, 9);
    final s = CurriculumState(level: 'R1', course: Course(id: 'c1', dialogueIds: ['a', 'b', 'c']));
    expect(s.newLeftToday(day1), 2);
    s.markPracticed('a', day1);
    s.markPracticed('b', day1);
    expect(s.newLeftToday(day1), 0);
    expect(s.doneToday(day1), isTrue);
    s.touchStreak(day1);
    expect(s.streakCount, 1);
    s.markPracticed('c', day1);
    expect(s.recordExam(7, 10, day1, failedDialogues: ['b']), isFalse);
    expect(s.course!.practiced, ['a', 'c']);
    expect(s.course!.examScores, [70]);
    s.markPracticed('b', day1);
    expect(s.recordExam(8, 10, day1), isTrue);
    expect(s.passedDialogues, ['a', 'b', 'c']);
    // 다음 날 복습이 남아 있으면 끝이 아니다
    final day2 = DateTime(2026, 11, 23, 9);
    s.enqueue('a#1', wrong: true, now: day1);
    expect(s.dueReviews(day2).length, 1);
    expect(s.doneToday(day2), isFalse);
    s.answerReview('a#1', correct: true, now: day2);
    expect(s.review.single.due, '2026-11-26');
    // JSON 왕복(curriculum_v1 형식)
    final back = CurriculumState.fromJson(s.toJson());
    expect(back.toJson(), s.toJson());
    expect(s.toJson().keys, containsAll(['level', 'dailyGoal', 'course', 'passedDialogues', 'review', 'streak']));
  });

  test('추천은 통과한 편을 빼고 주제가 겹치지 않게', () {
    final ds = [_d('f1', 'friends', 4), _d('f2', 'friends', 4), _d('l1', 'love', 4), _d('w1', 'work', 4)];
    final r = recommend(ds, passed: {'l1'}, chosen: {}, size: 3);
    expect(r, ['f1', 'w1', 'f2']);
    expect(levelCleared(ds, {'f1', 'f2', 'l1', 'w1'}), isTrue);
  });

  test('문제 수 — 편당 줄 수·최대 10, 시험 편당 최소 3·최대 30', () {
    final ds = [for (var i = 0; i < 10; i++) _d('d$i', 'life', 12)];
    final pool = [for (final d in ds) for (final t in d.turns) t.ko];
    final rnd = Random(1);
    expect(practiceQuestions(ds.first, pool, rnd).length, 10);
    expect(practiceQuestions(_d('s', 'life', 6), pool, rnd).length, 6);
    expect(examQuestions(ds, pool, rnd).length, 30);
    final ex3 = examQuestions(ds.take(3).toList(), pool, rnd);
    expect(ex3.length, 30);
    for (final d in ds.take(3)) {
      expect(ex3.where((q) => q.dialogueId == d.id).length, greaterThanOrEqualTo(3));
    }
    final q = ex3.first;
    expect(q.options.length, 4);
    expect(q.options, contains(q.answer));
  });

  testWidgets('화면: 레벨 고르기 → 추천 5편 → 코스 시작 → 편 연습 → 확인 문제', (t) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(400, 1600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(const MaterialApp(home: CurriculumScreen()));
    for (var i = 0; i < 60 && find.byKey(const ValueKey('cur-level-R1')).evaluate().isEmpty; i++) {
      await t.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await t.pump();
    }
    await t.tap(find.byKey(const ValueKey('cur-level-R1')));
    for (var i = 0; i < 20 && find.byKey(const ValueKey('cur-recommend')).evaluate().isEmpty; i++) {
      await t.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await t.pump();
    }
    expect(find.text('오늘: 복습 0 · 새 편 2'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('cur-recommend')));
    await t.pump();
    expect(find.text('코스 시작 (5/5)'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('cur-start')));
    for (var i = 0; i < 20 && find.byKey(const ValueKey('cur-exam')).evaluate().isEmpty; i++) {
      await t.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await t.pump();
    }
    expect(find.text('지금 코스 · 5편'), findsOneWidget);
    await t.tap(find.byType(ListTile).first);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('cur-to-quiz')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('cur-stem')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('cur-opt-0')));
    await t.pump();
    expect(find.byKey(const ValueKey('cur-next')), findsOneWidget);
  });
}
