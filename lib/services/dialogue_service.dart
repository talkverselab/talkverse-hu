import 'dart:convert';
import '../core/embed_env.dart';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import '../core/prefs.dart';

import 'learner_prefs.dart';
import 'script_sync.dart';

/// 회화 리더(일본어앱 시안 02 「만화책 읽기형」)용 회화 모델 — 2026-11-02, 일본어앱 `dialogue_service.dart` 를 옮김.
///
/// 편 파일 `assets/data/dialogues/R1~R3/<주제>/<id>.json`(일상회화 150편, 2026-11-10)을 읽는다 — 원고는 서버 판이 있으면 그것([ScriptSync], 2026-11-18 일본어앱 빌드 113·114 와 같게).
/// 편 파일이 하나도 안 읽히면 옛 `L1.json`(5편 × 8턴)으로 돈다.
/// 칸: tl = 헝가리어(편 파일 `hu`, 옛 L1 `es`), gloss = 단어별 뜻(지금 없음), rd = 한글 독음, ko = 한국어, note = 핵심 표현 한 줄.
/// 문장 내용어 한 개: 표면형(문장 속)·기본형·읽기(한글 독음, 없으면 빈 값) — 일본어앱과 같은 모양(2026-11-04).
class Lemma {
  final String surface, base, reading;
  const Lemma(this.surface, this.base, this.reading);
}

class DialogueTurn {
  final int num;
  final String speaker; // A·B
  final String tl;
  final String gloss;
  final String rd;
  final String ko;
  final String note;
  final List<String> tags;
  final String? art; // 장면 그림 URL(나중에 채움)
  final List<Lemma> lemmas; // 문장 내용어 — 단어장 연결(tools/add_lemmas.py)
  const DialogueTurn({
    required this.num,
    required this.speaker,
    required this.tl,
    required this.gloss,
    required this.rd,
    required this.ko,
    required this.note,
    required this.tags,
    this.art,
    this.lemmas = const [],
  });

  factory DialogueTurn.fromL1(Map<String, dynamic> j) => DialogueTurn(
        num: j['num'] as int? ?? 0,
        speaker: j['speaker'] as String? ?? 'A',
        tl: (j['hu'] ?? j['es']) as String? ?? '',
        gloss: j['gloss'] as String? ?? '',
        rd: j['rd'] as String? ?? '',
        ko: j['ko'] as String? ?? '',
        note: j['note'] as String? ?? '',
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        art: j['art'] as String?,
        lemmas: [for (final l in (j['lemmas'] as List? ?? const [])) if (l is List && l.length >= 2) Lemma('${l[0]}', '${l[1]}', l.length > 2 ? '${l[2]}' : '')],
      );

  /// 그림 조회용 핵심 단어 후보: note 의 표제어(`vagyok = 나는 ~이다` → vagyok), gloss 가 생기면 그 표제어도.
  List<String> get pictureWords => [
        for (final m in RegExp(r"^\s*([^\s=]+(?: [^\s=]+)?)\s*=").allMatches(note)) m.group(1)!,
        for (final m in RegExp(r"([^\s=]+)=").allMatches(gloss)) m.group(1)!,
      ];
}

class Dialogue {
  final String id;
  final String region; // 지금은 옛 레벨 이름(L1) 그대로 — R 재태그는 회화 작업 때
  final String topic; // 주제
  final String title;
  final String emoji;
  final String scene;
  final Map<String, String> speakers;
  final Map<String, String> genders;
  final List<String> expressions;
  final List<DialogueTurn> turns;
  final String? art;
  const Dialogue({
    required this.id,
    required this.region,
    required this.topic,
    required this.title,
    required this.emoji,
    required this.scene,
    required this.speakers,
    required this.genders,
    required this.expressions,
    required this.turns,
    this.art,
  });

  /// 편 JSON 한 개 → Dialogue(맞춤 회화 서버 응답 등 — 일본어앱 `Dialogue.fromJson` 과 같은 이름, 2026-11-22). 칸은 [DialogueService] 가 편 파일을 읽는 것과 같다.
  factory Dialogue.fromJson(Map<String, dynamic> m) => Dialogue(
        id: '${m['id']}',
        region: m['region'] as String? ?? '',
        topic: m['island'] as String? ?? m['topic'] as String? ?? '',
        title: m['title'] as String? ?? '${m['id']}',
        emoji: m['emoji'] as String? ?? '💬',
        scene: m['scene'] as String? ?? '',
        speakers: ((m['speakers'] as Map?) ?? const {}).map((k, v) => MapEntry('$k', '$v')),
        genders: ((m['genders'] as Map?) ?? const {}).map((k, v) => MapEntry('$k', '$v')),
        expressions: ((m['expressions'] as List?) ?? const []).map((e) => '$e').toList(),
        turns: ((m['turns'] as List?) ?? const []).map((t) => DialogueTurn.fromL1(t as Map<String, dynamic>)).toList(),
      );

  /// 화면에 보일 장면 설명 — 원고의 「A」(학습자)를 이름(없으면 「나」)으로(일본어앱 빌드 111, 2026-11-18 전달).
  String get sceneShown => scene.replaceAllMapped(RegExp(r'(?<![A-Za-z])A(?![A-Za-z]) ?(?=[가-힣])'), (_) => speakerName('A'));

  /// 화자 표시 이름. `{name}` 자리는 학습자 이름(없으면 「나」).
  String speakerName(String sp) {
    final raw = speakers[sp] ?? sp;
    if (raw.contains('{name}')) return LearnerPrefs.name.value.isNotEmpty ? LearnerPrefs.name.value : '나';
    return raw.replaceAll(RegExp(r'[{}]'), '');
  }

  /// 목소리 성별 — 지금 회화는 화자 이름·성별이 정해진 이야기(A Minjun 남 · B Anna 여)라 데이터의 성별을 따른다.
  String voiceGender(String sp) => genders[sp] ?? LearnerPrefs.voiceGender(sp);
}

class DialogueService {
  DialogueService._();
  static final DialogueService instance = DialogueService._();

  static const topics = ['survival', 'friends', 'love', 'life', 'travel', 'culture', 'work', 'study'];
  static const topicKo = {
    'survival': '서바이벌',
    'friends': '친구',
    'love': '사랑',
    'life': '생활',
    'travel': '여행',
    'culture': '문화',
    'work': '일',
    'study': '학업',
  };
  static const topicEmoji = {
    'survival': '🆘',
    'friends': '🤝',
    'love': '💘',
    'life': '🏠',
    'travel': '✈️',
    'culture': '🎬',
    'work': '💼',
    'study': '🎓',
  };
  static const levels = ['R0', 'R1', 'R2', 'R3', 'R4', 'R5']; // 커리큘럼 레벨 순서(일본어앱과 같게)
  static const levelKo = {'L1': '이야기', 'R0': '왕초보', 'R1': '초보', 'R2': '중급', 'R3': '고급', 'R4': '최상급'};
  static const _prefLast = 'dialogue_last';

  final List<Dialogue> _all = [];
  Future<void>? _loading;
  String? _lastOpened;
  String? get lastOpenedId => _lastOpened;
  Future<void> setLastOpened(String id) async {
    _lastOpened = id;
    (await Prefs.getInstance()).setString(_prefLast, id);
  }

  /// 넓은 화면에서는 탭 두 개가 동시에 불러서 목록이 두 번 찰 수 있다 — 한 번만 읽도록 Future 를 나눠 쓴다.
  Future<void> ensureLoaded() => _loading ??= _load();

  /// 원고가 서버 판으로 바뀌어 다시 읽힐 때마다 오른다.
  final ValueNotifier<int> revision = ValueNotifier(0);

  Future<void> _load() async {
    _lastOpened = (await Prefs.getInstance()).getString(_prefLast);
    await _readAll();
    // 서버에 더 새 원고가 있으면 뒤에서 받아 다시 읽는다(없거나 실패하면 그대로)
    ScriptSync.instance.refresh().then((changed) async {
      if (!changed) return;
      await _readAll();
      revision.value++;
    });
  }

  /// 앱 안 편 + 서버에서 받은 새 편 − 서버에서 뺀 편. 각 파일은 덮어쓴 판이 있으면 그것.
  Future<void> _readAll() async {
    final next = <Dialogue>[];
    try {
      final sync = ScriptSync.instance;
      await sync.init();
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final pat = RegExp(r'^assets/data/dialogues/R[0-4]/[^/]+/[^/]+\.json$');
      final rels = <String>{
        for (final p in manifest.listAssets().map(stripAssetPrefix).where(pat.hasMatch)) p.substring('assets/data/'.length),
        ...sync.added.where((p) => pat.hasMatch('assets/data/$p')),
      }..removeAll(sync.removed);
      for (final rel in rels) {
        try {
          final m = json.decode(await sync.load(rel)) as Map<String, dynamic>;
          final turns = ((m['turns'] as List?) ?? const []).map((t) => DialogueTurn.fromL1(t as Map<String, dynamic>)).toList();
          if (turns.isEmpty) continue;
          next.add(Dialogue(
            id: m['id'] as String,
            region: m['region'] as String? ?? rel.split('/')[1],
            topic: m['island'] as String? ?? rel.split('/')[2],
            title: m['title'] as String? ?? m['id'] as String,
            emoji: m['emoji'] as String? ?? '💬',
            scene: m['scene'] as String? ?? '',
            speakers: ((m['speakers'] as Map?) ?? const {}).map((k, v) => MapEntry('$k', '$v')),
            genders: ((m['genders'] as Map?) ?? const {}).map((k, v) => MapEntry('$k', '$v')),
            expressions: ((m['expressions'] as List?) ?? const []).map((e) => '$e').toList(),
            turns: turns,
          ));
        } catch (_) {}
      }
    } catch (_) {}
    next.sort((a, b) => a.id.compareTo(b.id));
    if (next.isEmpty) next.addAll(await _readL1());
    _all
      ..clear()
      ..addAll(next);
  }

  /// 옛 L1.json(편 파일이 없을 때만).
  Future<List<Dialogue>> _readL1() async {
    final out = <Dialogue>[];
    try {
      final j = json.decode(await rootBundle.loadString(assetPath('assets/data/dialogues/L1.json'))) as Map<String, dynamic>;
      final chars = (j['characters'] as Map<String, dynamic>? ?? const {});
      final names = chars.map((k, v) => MapEntry(k, ((v as Map)['name'] ?? k).toString()));
      final genders = chars.map((k, v) => MapEntry(k, ((v as Map)['gender'] ?? 'female').toString()));
      final level = j['level'] as String? ?? 'L1';
      for (final e in (j['episodes'] as List? ?? const [])) {
        final m = e as Map<String, dynamic>;
        final turns = ((m['turns'] as List?) ?? const []).map((t) => DialogueTurn.fromL1(t as Map<String, dynamic>)).toList();
        if (turns.isEmpty) continue;
        out.add(Dialogue(
          id: '${level}_${m['id']}',
          region: level,
          topic: 'love',
          title: m['title'] as String? ?? m['id'] as String,
          emoji: m['emoji'] as String? ?? '💬',
          scene: m['scenario'] as String? ?? '',
          speakers: names,
          genders: genders,
          expressions: const [],
          turns: turns,
        ));
      }
    } catch (_) {}
    return out;
  }

  Dialogue? byId(String id) => _all.where((d) => d.id == id).firstOrNull;
  List<Dialogue> get all => List.unmodifiable(_all);
  List<String> get regions => (_all.map((d) => d.region).toSet().toList())..sort();

  List<Dialogue> list({String? region, String? topic}) =>
      _all.where((d) => (region == null || d.region == region) && (topic == null || d.topic == topic)).toList();

  List<String> topicsOf(String region) {
    final has = _all.where((d) => d.region == region).map((d) => d.topic).toSet();
    return topics.where(has.contains).toList();
  }

  int count(String region) => _all.where((d) => d.region == region).length;
}
