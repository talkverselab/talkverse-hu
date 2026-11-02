import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 헝가리어 격 접미사 — UX 시안 01(사용자 통과 2026-11-03)의 「접미사 색칠·분해 시트·접미사 지도」용 고정 표.
/// 회화 데이터는 바꾸지 않고, 문장의 낱말 끝을 이 표로 맞춰 「어간 | 접미사」로 나눈다(규칙 기반 — 틀릴 수 있는 짧은 낱말은 건너뜀).
/// 모음조화: back = 뒷모음 짝(a·á·o·ó·u·ú 낱말), front = 앞모음 짝(e·é·i·í·ö·ő·ü·ű 낱말).
class HuSuffix {
  final String form; // 붙은 모양 (예 ból)
  final String ko; // 한국어 조사·뜻
  final String group; // 접미사 지도 묶음
  final String back, front; // 모음조화 짝 (짝이 없으면 같은 값)
  const HuSuffix(this.form, this.ko, this.group, this.back, this.front);

  bool get isFront => form == front && front != back;
  bool get hasPair => back != front;
  String get pair => '-$back${hasPair ? ' / -$front' : ''}';
}

class HuSuffixes {
  HuSuffixes._();

  static const groups = ['장소 — 안', '장소 — 위', '장소 — 곁', '함께·대상', '그 밖'];

  static const list = <HuSuffix>[
    HuSuffix('ban', '~안에서(~에)', '장소 — 안', 'ban', 'ben'),
    HuSuffix('ben', '~안에서(~에)', '장소 — 안', 'ban', 'ben'),
    HuSuffix('ba', '~안으로(~로)', '장소 — 안', 'ba', 'be'),
    HuSuffix('be', '~안으로(~로)', '장소 — 안', 'ba', 'be'),
    HuSuffix('ból', '~안에서부터(~에서)', '장소 — 안', 'ból', 'ből'),
    HuSuffix('ből', '~안에서부터(~에서)', '장소 — 안', 'ból', 'ből'),
    HuSuffix('ra', '~위로(~에·~로)', '장소 — 위', 'ra', 're'),
    HuSuffix('re', '~위로(~에·~로)', '장소 — 위', 'ra', 're'),
    HuSuffix('ról', '~위에서부터·~에 대해', '장소 — 위', 'ról', 'ről'),
    HuSuffix('ről', '~위에서부터·~에 대해', '장소 — 위', 'ról', 'ről'),
    HuSuffix('nál', '~곁에서(~네 집에서)', '장소 — 곁', 'nál', 'nél'),
    HuSuffix('nél', '~곁에서(~네 집에서)', '장소 — 곁', 'nál', 'nél'),
    HuSuffix('hoz', '~쪽으로(~에게)', '장소 — 곁', 'hoz', 'hez'),
    HuSuffix('hez', '~쪽으로(~에게)', '장소 — 곁', 'hoz', 'hez'),
    HuSuffix('höz', '~쪽으로(~에게)', '장소 — 곁', 'hoz', 'höz'),
    HuSuffix('tól', '~에게서·~부터', '장소 — 곁', 'tól', 'től'),
    HuSuffix('től', '~에게서·~부터', '장소 — 곁', 'tól', 'től'),
    HuSuffix('val', '~와 함께·~로(도구)', '함께·대상', 'val', 'vel'),
    HuSuffix('vel', '~와 함께·~로(도구)', '함께·대상', 'val', 'vel'),
    HuSuffix('nak', '~에게·~의', '함께·대상', 'nak', 'nek'),
    HuSuffix('nek', '~에게·~의', '함께·대상', 'nak', 'nek'),
    HuSuffix('ig', '~까지', '그 밖', 'ig', 'ig'),
    HuSuffix('ért', '~를 위해·~를 가지러', '그 밖', 'ért', 'ért'),
    HuSuffix('ul', '~어로·~식으로', '그 밖', 'ul', 'ül'),
    HuSuffix('ül', '~어로·~식으로', '그 밖', 'ul', 'ül'),
  ];

  /// 접미사처럼 끝나지만 접미사가 아닌 낱말(어간이 짧거나 그 자체가 낱말).
  static const _skip = {
    'nem', 'igen', 'persze', 'merre', 'erre', 'arra', 'akkor', 'utána', 'ma', 'be', 'ért', 'ig', 'nekem', 'neked',
    'velem', 'veled', 'tőle', 'hozzá', 'bele', 'rá', 'szia', 'szombaton', 'ul', 'meg', 'még', 'de', 'te', 'és',
    // 동사 조건형 2인칭(-nál/-nél 로 끝나지만 접미사 아님)
    'szeretnél', 'lennél', 'mennél', 'kérnél', 'tudnál', 'akarnál', 'jönnél', 'látnál', 'csinálnál', 'innál', 'ennél',
  };

  /// 낱말 → (어간, 접미사). 못 찾으면 null. 어간은 3글자 이상, 가장 긴 접미사부터.
  static (String, HuSuffix)? split(String word) {
    final w = word.toLowerCase();
    if (_skip.contains(w)) return null;
    HuSuffix? best;
    for (final s in list) {
      if (w.length - s.form.length >= 3 && w.endsWith(s.form) && (best == null || s.form.length > best.form.length)) best = s;
    }
    if (best == null) return null;
    return (word.substring(0, word.length - best.form.length), best);
  }

  /// 자막 「접미사」 칩 — 켜면 문장의 접미사가 자두색(기본 켬). 리더·카드 모든 문장이 같이 바뀐다.
  static final ValueNotifier<bool> show = ValueNotifier(true);

  // 「만난 접미사」 — 시트를 열어 본 접미사 짝(back 기준) 모음. 성과 데스크 한 줄.
  static const _kSeen = 'hu_suffix_seen';
  static final ValueNotifier<Set<String>> seen = ValueNotifier(const {});
  static Future<void> load() async =>
      seen.value = {...?(await SharedPreferences.getInstance()).getStringList(_kSeen)};
  static Future<void> markSeen(HuSuffix s) async {
    if (seen.value.contains(s.back)) return;
    seen.value = {...seen.value, s.back};
    (await SharedPreferences.getInstance()).setStringList(_kSeen, seen.value.toList());
  }
}
