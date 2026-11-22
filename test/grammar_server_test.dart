import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hungarian_universe/screens/grammar_lesson_screen.dart';
import 'package:hungarian_universe/screens/sense_course_screen.dart';
import 'package:hungarian_universe/services/script_sync.dart';

String sha(String s) => sha1.convert(utf8.encode(s)).toString().substring(0, 12);

/// 문법 스텝 1~10 — 틀은 앱, 내용은 서버 원고(사용자 지시 2026-11-23).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('grammar_sync'));
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  const l1 = 'grammar/lesson1.json', l2 = 'grammar/lesson2.json', l3 = 'grammar/lesson3.json', l16 = 'grammar/lesson16.json';
  final base = {
    'rev': 1,
    'files': {l1: 'bundled'},
  };
  final new2 = json.encode({
    'lesson': 2,
    'title': '서버에서 온 스텝 2',
    'patterns': [
      {'id': 'p1', 'label': 'x', 'examples': []}
    ],
  });
  final empty3 = json.encode({'lesson': 3, 'title': '빈 스텝', 'patterns': []});

  Future<String?> Function(String) server(Map<String, String> files) => (url) async {
        if (url.endsWith('/index.json')) {
          return json.encode({'rev': 2, 'files': files.map((k, v) => MapEntry(k, sha(v)))});
        }
        final path = url.split('?').first;
        for (final e in files.entries) {
          if (path.endsWith(e.key)) return e.value;
        }
        return null;
      };

  test('서버가 없으면 앱에 묶은 스텝(1)만', () async {
    final s = ScriptSync.forTest(dir: dir, fetch: (_) async => null, baseline: base);
    await s.refresh();
    final ls = await GrammarLesson.loadAll(sync: s);
    expect(ls.map((l) => l.number), [1]);
  });

  test('서버에만 있는 스텝은 나타나고, 내용이 빈 스텝은 숨긴다', () async {
    final bundled1 = File('assets/data/grammar/lesson1.json').readAsStringSync();
    final s = ScriptSync.forTest(dir: dir, fetch: server({l1: bundled1, l2: new2, l3: empty3, l16: new2.replaceFirst('"lesson":2', '"lesson":16')}), baseline: base);
    expect(await s.refresh(), isTrue);
    final ls = await GrammarLesson.loadAll(sync: s);
    expect(ls.map((l) => l.number), [1, 2, 16]); // 15 를 넘어도 서버 목록 그대로
    expect(ls[1].title, '서버에서 온 스텝 2');
  });

  test('서버 목록에서 뺀 스텝은 숨긴다', () async {
    final s = ScriptSync.forTest(dir: dir, fetch: server({l2: new2}), baseline: base);
    await s.refresh();
    final ls = await GrammarLesson.loadAll(sync: s);
    expect(ls.map((l) => l.number), [2]);
  });

  test('언어감각: 빈 회차·빈 급은 숨긴다(「준비 중」 없음)', () {
    final d = SenseCourse.prune({
      'levels': [
        {
          'id': 'L1',
          'lessons': [
            {'id': 'L1-1', 'sentences': ['a']},
            {'id': 'L1-2', 'video': ''},
          ]
        },
        {
          'id': 'L2',
          'lessons': [
            {'id': 'L2-1', 'sentences': []}
          ]
        },
        {
          'id': 'L3',
          'lessons': [
            {'id': 'L3-1', 'video': 'https://x/v.mp4'}
          ]
        },
      ]
    });
    expect([for (final lv in d['levels'] as List) lv['id']], ['L1', 'L3']);
    expect([for (final l in (d['levels'] as List).first['lessons'] as List) l['id']], ['L1-1']);
  });

  test('지금 앱에 묶은 언어감각은 10급 모두 내용 있음', () {
    final d = SenseCourse.prune(json.decode(File('assets/data/grammar/sense_course.json').readAsStringSync()) as Map<String, dynamic>);
    expect((d['levels'] as List).length, 10);
  });
}
