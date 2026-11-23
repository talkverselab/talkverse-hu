import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hungarian_universe/services/curriculum_service.dart';
import 'package:hungarian_universe/services/dialogue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 토크버스 커리큘럼 §12 — 단계(1~5)·단계별 편은 서버/묶음 JSON 에서(11-23 사용자 지시).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final svc = CurriculumService.instance;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await DialogueService.instance.ensureLoaded();
  });
  tearDown(() => svc.stagesForTest = null);

  test('묶음 JSON 의 편 id 가 앱 편과 모두 맞음(단계 1~3, 150편)', () {
    final m = json.decode(File('assets/curriculum_hu.json').readAsStringSync()) as Map<String, dynamic>;
    final ids = [for (final s in m['stages'] as List) ...(s['dialogueIds'] as List).cast<String>()];
    expect(ids.length, 150);
    expect(ids.where((id) => DialogueService.instance.byId(id) == null), isEmpty);
  });

  test('단계 목록 = 편 있는 단계만, 앱에 없는 편 id 는 건너뜀', () {
    final r1 = DialogueService.instance.list(region: 'R1').take(3).map((d) => d.id).toList();
    svc.stagesForTest = [
      {'n': 1, 'title': '1단계', 'dialogueIds': [...r1, 'no_such_episode']},
      {'n': 2, 'title': '2단계', 'dialogueIds': ['no_such_episode']},
      {'n': 3, 'title': '3단계', 'dialogueIds': <String>[]},
    ];
    expect(svc.stageMode, isTrue);
    expect(svc.levels, ['1']);
    expect(svc.levelList('1').map((d) => d.id), r1);
    expect(svc.levelTitle('1'), '1단계');
    expect(svc.nextLevel('1'), isNull);
    expect(svc.poolFor(svc.levelList('1').first).length, 3);
  });

  test('JSON 이 없으면 옛 동작(회화 레벨 R)', () {
    svc.stagesForTest = null;
    expect(svc.stageMode, isFalse);
    expect(svc.levels, ['R1', 'R2', 'R3']);
    expect(svc.nextLevel('R1'), 'R2');
  });

  test('저장: 단계 번호는 숫자로, 옛 R 값도 읽힘', () {
    final s = CurriculumState(level: '2');
    expect(s.toJson()['level'], 2);
    expect(CurriculumState.fromJson({'level': 3}).level, '3');
    expect(CurriculumState.fromJson({'level': 'R2'}).level, 'R2');
  });

  test('단계 JSON 의 pick·pass·daily 를 읽고, 없으면 기본값', () {
    svc.stagesForTest = [
      {'n': 1, 'dialogueIds': <String>[], 'pick': [4, 8], 'pass': 70, 'daily': {'light': 2, 'normal': 3, 'focus': 5}},
      {'n': 2, 'dialogueIds': <String>[]},
    ];
    expect(svc.pickFor('1'), [4, 8]);
    expect(svc.passFor('1'), 70);
    expect(svc.dailyFor('1'), {'light': 2, 'normal': 3, 'focus': 5});
    expect(svc.pickFor('2'), [3, 5, 10]);
    expect(svc.passFor('2'), 80);
    expect(svc.dailyFor('2'), {'light': 1, 'normal': 2, 'focus': 3});
    final st = CurriculumState(course: Course('c', ['a']));
    expect(st.recordExam(7, 10, {}, '2026-11-23', passPercent: 70), isTrue);
  });
}
