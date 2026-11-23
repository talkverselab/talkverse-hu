import 'package:flutter_test/flutter_test.dart';
import 'package:hungarian_universe/data/entitlement.dart';
import 'package:hungarian_universe/data/purchase.dart';
import 'package:hungarian_universe/screens/sense_course_screen.dart';
import 'package:hungarian_universe/services/curriculum_service.dart';
import 'package:hungarian_universe/services/dialogue_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 이용권 잠금 경계(PAYWALL_SPEC 11-23): 1단계 열림 · 2단계 잠김 · 이용권 있으면 열림.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final svc = CurriculumService.instance;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await DialogueService.instance.ensureLoaded();
  });
  tearDown(() {
    svc.stagesForTest = null;
    Purchase.owned.value = const {};
  });

  test('커리큘럼: 1단계 열림 · 2단계 잠김(JSON free) · 이용권 있으면 열림', () {
    svc.stagesForTest = [
      {'n': 1, 'free': true, 'dialogueIds': <String>[]},
      {'n': 2, 'free': false, 'dialogueIds': <String>[]},
      {'n': 3, 'dialogueIds': <String>[]}, // free 없음 → 첫 단계만 무료
    ];
    expect(svc.stageFree('1'), isTrue);
    expect(svc.stageFree('2'), isFalse);
    expect(svc.stageFree('3'), isFalse);
    expect(Entitlement.premium, isFalse);
    expect(CurriculumService.locked(svc.stageFree('1')), isFalse);
    expect(CurriculumService.locked(svc.stageFree('2')), isTrue);
    Purchase.owned.value = {'lang_hu_1y': DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch};
    expect(Entitlement.premium, isTrue);
    expect(CurriculumService.locked(svc.stageFree('2')), isFalse);
  });

  test('종합 이용권(all_*)도 열고, 기한 지난 구독은 못 염', () {
    Purchase.owned.value = {'all_life': 0};
    expect(Entitlement.premium, isTrue);
    Purchase.owned.value = {'lang_hu_1m': DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch};
    expect(Entitlement.premium, isFalse);
    Purchase.owned.value = {'lang_pl_life': 0}; // 다른 언어 이용권은 안 열림
    expect(Entitlement.premium, isFalse);
  });

  test('회화: R1 편 열림 · R2 편 잠김', () {
    final r1 = DialogueService.instance.list(region: 'R1').first;
    final r2 = DialogueService.instance.list(region: 'R2').first;
    expect(CurriculumService.locked(CurriculumService.dialogueFree(r1)), isFalse);
    expect(CurriculumService.locked(CurriculumService.dialogueFree(r2)), isTrue);
    expect(CurriculumService.locked(CurriculumService.dialogueFree(r2), premium: true), isFalse);
  });

  test('언어감각: 1급 열림 · 2급 잠김(freeSenseLevels 1)', () {
    final d = {
      'levels': [
        {'id': 'L1', 'lessons': [{'id': 'L1-1', 'sentences': ['a']}]},
        {'id': 'L2', 'lessons': [{'id': 'L2-1', 'sentences': ['b']}]},
      ]
    };
    expect(svc.freeSenseLevels, 1);
    expect(SenseCourse.lockedAt(d, 0), isFalse);
    expect(SenseCourse.lockedAt(d, 1), isTrue);
    Purchase.owned.value = {'all_life': 0};
    expect(SenseCourse.lockedAt(d, 1), isFalse);
  });
}
