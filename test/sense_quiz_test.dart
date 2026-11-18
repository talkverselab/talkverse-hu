import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hungarian_universe/screens/sense_course_screen.dart';
import 'package:hungarian_universe/screens/word_quiz_screen.dart';

void main() {
  test('표기 오답 = 장모음·겹자음만 바꾼 꼴, 실제 단어는 빼고', () {
    final m = gairaigoMisspellings('kenyér', {'kenyer'});
    expect(m, isNot(contains('kenyér')));
    expect(m, isNot(contains('kenyer')));
    expect(m, contains('kényér'));
    expect(gairaigoMisspellings('itt', {}), contains('it'));
  });

  test('언어감각 원고 — 10급, 급마다 외울 대화 10줄 + 참고, 표시 번호가 양쪽 같음', () {
    final d = json.decode(File('assets/data/grammar/sense_course.json').readAsStringSync()) as Map<String, dynamic>;
    final levels = (d['levels'] as List).cast<Map<String, dynamic>>();
    expect(levels.length, 10);
    final mark = RegExp(r'\{([^|}]+)\|(\d+)\}');
    for (final lv in levels) {
      final ls = (lv['lessons'] as List).cast<Map<String, dynamic>>();
      expect(ls.map((l) => l['kind']), ['memorize', 'ref']);
      final ss = (ls[0]['sentences'] as List).cast<Map<String, dynamic>>();
      expect(ss.length, 10);
      for (final s in ss) {
        expect({for (final m in mark.allMatches(s['hu'] as String)) m.group(2)}, {for (final m in mark.allMatches(s['ko'] as String)) m.group(2)});
        expect(plainMarked(s['hu'] as String).contains('{'), isFalse);
      }
    }
  });

  testWidgets('색 표시 — 같은 번호는 같은 색', (t) async {
    final a = markedSpans('a kávézó{ban|1}', const TextStyle()), b = markedSpans('카페{에|1}', const TextStyle());
    expect((a.last as TextSpan).style!.color, (b.last as TextSpan).style!.color);
  });
}
