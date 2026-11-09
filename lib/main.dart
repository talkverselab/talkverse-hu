import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme.dart';
import 'data/db/app_database.dart';
import 'data/db/seed_loader.dart';
import 'screens/main_screen.dart';
import 'screens/sync_screen.dart';
import 'services/content_sync.dart';
import 'services/ko_reading.dart';
import 'core/l10n.dart';
import 'data/account.dart';
import 'data/purchase.dart';
import 'services/achievement_service.dart';
import 'services/hu_suffix.dart';
import 'services/learner_prefs.dart';

late final AppDatabase appDb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  appDb = AppDatabase();
  await SeedLoader(appDb).seedIfNeeded();
  await KoReadingPrefs.load();
  await AppLangPrefs.load();
  await LearnerPrefs.load();
  await HuSuffixes.load();
  await AchievementService.instance.load();
  // Talkverse ID(선택) — 저장된 로그인을 띄우고 뒤에서 토큰 갱신(기다리지 않음). 평생 이용권 상품 등록.
  Account.load();
  // 가격표 = ~/talkverse/PRICING.md(사용자 확정 2026-11-09) — 앱 할인가(30%)·앱 정가.
  Purchase.configure('hu', const [
    Plan('lang_hu_1m', 1, 3900, listKrw: 5500),
    Plan('lang_hu_3m', 3, 9000, listKrw: 12900),
    Plan('lang_hu_1y', 12, 19900, listKrw: 28500),
    Plan('lang_hu_life', 0, 49000, listKrw: 69900),
    Plan('all_1y', 12, 79000, listKrw: 112900, bundle: true),
    Plan('all_life', 0, 329000, listKrw: 469000, bundle: true),
  ]);
  await _setOrientations(); // 폰은 세로 고정, 태블릿·폴드 펼침(짧은 변 600 이상)은 회전 허용
  // 그림(장면 컷·단어 그림) 기기 내려받기: 버전이 다르면 로딩 화면에서 받고 시작(사용자 지시 2026-11-04, 일본어앱과 같음)
  final needSync = await ContentSync.instance.init(large: _wide ?? false);
  runApp(HungarianUniverseApp(syncFirst: needSync));
}

bool? _wide;

/// 짧은 변 600 이상(아이패드·태블릿·폴드 펼침)이면 가로 회전 허용, 아니면 세로 고정(일본어앱 main.dart 와 같음).
/// 폴드를 접고 펼 때마다 builder 에서 다시 계산한다.
Future<void> _setOrientations([double? shortest]) async {
  shortest ??= () {
    final v = WidgetsBinding.instance.platformDispatcher.views.first;
    return v.physicalSize.shortestSide / v.devicePixelRatio;
  }();
  final wide = shortest >= 600;
  if (wide == _wide && shortest != 0) return;
  _wide = wide;
  await SystemChrome.setPreferredOrientations(wide ? DeviceOrientation.values : [DeviceOrientation.portraitUp]);
}

class HungarianUniverseApp extends StatelessWidget {
  final bool syncFirst;
  const HungarianUniverseApp({super.key, this.syncFirst = false});

  @override
  Widget build(BuildContext context) {
    // 표시 언어가 바뀌면 key 가 바뀌어 앱 전체가 새로 그려진다 (홈으로 돌아감).
    return ValueListenableBuilder<AppLang>(
      valueListenable: AppLangPrefs.lang,
      builder: (context, lang, _) => MaterialApp(
        key: ValueKey(lang),
        title: tr('헝가리어유니버스'),
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
        // 아이폰 Dynamic Type·갤럭시 글자 크기 설정이 커도 타일이 깨지지 않게 1.2배까지만
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          WidgetsBinding.instance.addPostFrameCallback((_) => _setOrientations(mq.size.shortestSide));
          return MediaQuery(
            data: mq.copyWith(
              textScaler: mq.textScaler.clamp(maxScaleFactor: 1.2),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: syncFirst ? const SyncScreen(next: MainScreen()) : const MainScreen(),
      ),
    );
  }
}
