import 'package:flutter/material.dart';

import 'core/embed_env.dart';
import 'core/l10n.dart';
import 'core/theme.dart';
import 'data/account.dart';
import 'data/db/app_database.dart';
import 'data/db/seed_loader.dart';
import 'data/purchase.dart';
import 'screens/main_screen.dart';
import 'screens/sync_screen.dart';
import 'services/achievement_service.dart';
import 'services/content_sync.dart';
import 'services/hu_suffix.dart';
import 'services/ko_reading.dart';
import 'services/learner_prefs.dart';

export 'core/embed_env.dart' show embedded;

/// 통합 앱(Talkverse) 연결점 — 2026-11-09 uk `~/talkverse/talkverse-app/EMBED_GUIDE.md`(일본어앱 lib/embed.dart 와 같은 구조).
/// 단독 앱 `main()` 도 이 두 함수를 쓴다: `await embedInit(standalone: true)` → `runApp(embedApp())`.
/// 통합 앱: `await embedInit()` → 이 언어 화면을 열 때 `embedApp(onSwitchLanguage: …)`.

late final AppDatabase appDb;
bool _inited = false;
bool _syncFirst = false;

/// 「다른 언어 배우기」 — 통합 앱이 넘긴 콜백(없으면 메뉴를 안 보인다).
VoidCallback? switchLanguage;

/// 초기화 전부(화면 방향·runApp 제외). 여러 번 불러도 한 번만 한다.
Future<void> embedInit({bool standalone = false}) async {
  if (_inited) return;
  _inited = true;
  embedded = !standalone;
  WidgetsFlutterBinding.ensureInitialized();
  appDb = AppDatabase();
  await SeedLoader(appDb).seedIfNeeded();
  await KoReadingPrefs.load();
  await AppLangPrefs.load();
  await LearnerPrefs.load();
  await HuSuffixes.load();
  await AchievementService.instance.load();
  // Talkverse ID(선택) — 저장된 로그인을 띄우고 뒤에서 토큰 갱신(기다리지 않음). 통합 앱이면 결제 스트림은 공용 결제가 넘겨준다.
  Account.load();
  Purchase.ownStream = standalone;
  // 가격표 = ~/talkverse/PRICING.md(사용자 확정 2026-11-09) — 앱 할인가(30%)·앱 정가.
  Purchase.configure('hu', const [
    Plan('lang_hu_1m', 1, 3900, listKrw: 5500),
    Plan('lang_hu_3m', 3, 9000, listKrw: 12900),
    Plan('lang_hu_1y', 12, 19900, listKrw: 28500),
    Plan('lang_hu_life', 0, 49000, listKrw: 69900),
    Plan('all_1y', 12, 79000, listKrw: 112900, bundle: true),
    Plan('all_life', 0, 329000, listKrw: 469000, bundle: true),
  ]);
  // 그림(장면 컷·단어 그림) 기기 내려받기: 버전이 다르면 로딩 화면에서 받고 시작(2026-11-04)
  final v = WidgetsBinding.instance.platformDispatcher.views.first;
  final wide = v.physicalSize.shortestSide / v.devicePixelRatio >= 600;
  _syncFirst = await ContentSync.instance.init(large: wide);
}

/// runApp 에 넘기는 위젯. [onSwitchLanguage] 가 있으면 프로필 설정 맨 위에 「다른 언어 배우기」.
/// [onOrientation] = 단독 앱이 화면 방향을 다시 계산할 때(통합 앱은 넘기지 않는다).
Widget embedApp({VoidCallback? onSwitchLanguage, void Function(double shortest)? onOrientation}) {
  switchLanguage = onSwitchLanguage;
  return HungarianUniverseApp(syncFirst: _syncFirst, onOrientation: onOrientation);
}

class HungarianUniverseApp extends StatelessWidget {
  final bool syncFirst;
  final void Function(double shortest)? onOrientation;
  const HungarianUniverseApp({super.key, this.syncFirst = false, this.onOrientation});

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
          if (onOrientation != null) WidgetsBinding.instance.addPostFrameCallback((_) => onOrientation!(mq.size.shortestSide));
          return MediaQuery(
            data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: 1.2)),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: syncFirst ? const SyncScreen(next: MainScreen()) : const MainScreen(),
      ),
    );
  }
}
