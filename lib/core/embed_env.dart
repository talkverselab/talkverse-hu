import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 통합 앱(Talkverse, com.talkverse.app) 안에 패키지로 들어갔는지 — `embedInit()` 이 정한다(2026-11-09 uk `~/talkverse/talkverse-app/EMBED_GUIDE.md`, 일본어앱과 같은 구조).
/// 단독 앱(헝가리어유니버스)에서는 false 이고 모든 동작이 예전과 같다.
bool embedded = false;

/// 이 언어의 저장 이름 접두(설정 키·기기 폴더). 다른 언어 패키지와 겹치지 않게.
const storePrefix = 'hu_';
const _pkg = 'packages/hungarian_universe/';

/// 에셋 경로 — 패키지로 들어가면 Flutter 가 `packages/<패키지>/` 아래에 둔다.
String assetPath(String p) => embedded ? '$_pkg$p' : p;

/// AssetManifest 의 키 → 앱 안 상대 경로(`assets/...`).
String stripAssetPrefix(String p) => p.startsWith(_pkg) ? p.substring(_pkg.length) : p;

String? _dir;

/// 이 언어 전용 기기 저장 폴더(Application Support/hu). 단독 앱의 옛 위치(art)는 처음 한 번 옮긴다.
Future<String> dataDir() async {
  if (_dir != null) return _dir!;
  final base = (await getApplicationSupportDirectory()).path;
  final d = Directory('$base/hu');
  if (!d.existsSync()) d.createSync(recursive: true);
  if (!embedded) {
    for (final name in const ['art']) {
      final old = '$base/$name', now = '${d.path}/$name';
      try {
        if (FileSystemEntity.typeSync(old) != FileSystemEntityType.notFound && FileSystemEntity.typeSync(now) == FileSystemEntityType.notFound) {
          await (FileSystemEntity.isDirectorySync(old) ? Directory(old).rename(now) : File(old).rename(now));
        }
      } catch (_) {}
    }
  }
  return _dir = d.path;
}
