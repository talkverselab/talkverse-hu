import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hungarian_universe/services/dialogue_service.dart';

void main() {
  testWidgets('회화 = 편 파일 R1~R3 150편(옛 L1 아님), 장면의 A 는 이름으로', (t) async {
    SharedPreferences.setMockInitialValues({});
    await t.runAsync(() => DialogueService.instance.ensureLoaded());
    final s = DialogueService.instance;
    expect(s.all.length, 150);
    expect(s.regions, ['R1', 'R2', 'R3']);
    expect(s.topicsOf('R1'), isNotEmpty);
    final d = s.all.firstWhere((d) => RegExp(r'(?<![A-Za-z])A [가-힣]').hasMatch(d.scene));
    expect(d.sceneShown.contains(RegExp(r'(?<![A-Za-z])A [가-힣]')), isFalse);
  });
}
