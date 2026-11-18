import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/cliff.dart';
import '../core/embed_env.dart';
import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/prefs.dart';
import '../core/theme.dart';
import '../services/tts_service.dart';

/// 단어 퀴즈 복습 — 일본어앱 「외국어 단어 퀴즈」(빌드 110, 2026-11-18 전달)를 헝가리어 단어 복습으로 옮김.
/// 두 꼴 — 표기(바르게 쓴 헝가리어 고르기)와 뜻 고르기, 보기 1~4, 10문제. 틀린 단어는 다음 복습에 먼저.
/// 표기 문제의 틀린 보기 = 헝가리어에서 실제로 자주 틀리는 곳: 장모음 부호(a↔á, o↔ó, ö↔ő …)와 겹자음(tt↔t, ll↔l …).
/// 3단계 = 절벽 단어 R1(핵심) → R1~R2(중급까지) → R1~R3(전체).
const int kGairaigoQuizSize = 10;
const String _kWrong = 'word_quiz_wrong';

class GQWord {
  final String ja, en, ko; // ja = 헝가리어(일본어앱 이름 그대로), en = 한글 독음
  const GQWord(this.ja, this.en, this.ko);
}

const _long = {'a': 'á', 'e': 'é', 'i': 'í', 'o': 'ó', 'u': 'ú', 'ö': 'ő', 'ü': 'ű'};
final Map<String, String> _swap = {for (final e in _long.entries) e.key: e.value, for (final e in _long.entries) e.value: e.key};
const _gem = 'bdfgjklmnprstvz';

/// 규칙을 어긴 꼴들(실제 단어와 겹치는 것은 뺀다) — 모음 길이를 바꾸고, 자음을 겹치거나 홑으로.
List<String> gairaigoMisspellings(String ja, Set<String> real) {
  final c = ja.split('');
  final out = <String>{};
  for (var i = 0; i < c.length; i++) {
    final lower = c[i].toLowerCase();
    final s = _swap[lower];
    if (s != null) out.add(([...c]..[i] = c[i] == lower ? s : s.toUpperCase()).join());
    if (i > 0 && _gem.contains(lower)) {
      if (i + 1 < c.length && c[i + 1] == c[i]) {
        out.add(([...c]..removeAt(i)).join());
      } else if (i + 1 < c.length && (i == 0 || c[i - 1] != c[i])) {
        out.add(([...c]..insert(i, c[i])).join());
      }
    }
  }
  return out.where((s) => s != ja && s.isNotEmpty && !real.contains(s)).toList();
}

/// 단계 고르기 → 퀴즈.
class WordQuizHomeScreen extends StatelessWidget {
  const WordQuizHomeScreen({super.key});

  static Future<List<GQWord>> words(int stage) async {
    final j = json.decode(await rootBundle.loadString(assetPath('assets/data/freq/cliff_words_hu.json'))) as Map<String, dynamic>;
    final keep = const [{'R1'}, {'R1', 'R2'}, {'R1', 'R2', 'R3'}][stage];
    return [
      for (final w in (j['words'] as List).cast<Map<String, dynamic>>())
        if (keep.contains(Cliff.regionOf(w['rank'] as int)) && '${w['ko']}'.isNotEmpty) GQWord('${w['word']}', '${w['rd'] ?? ''}', '${w['ko']}'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final stages = [(tr('핵심'), 'R1'), (tr('중급까지'), 'R1~R2'), (tr('전체'), 'R1~R3')];
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text(tr('단어 퀴즈'))),
      body: ListView(padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset(context)), children: [
        Text(tr('장모음 부호(á·é·ő·ű)와 겹자음(tt·ll)을 바르게 쓴 것, 그리고 뜻을 골라요. 10문제, 틀린 단어는 다음에 먼저 나와요.'),
            style: const TextStyle(fontSize: 13, color: AppColors.sumiLight, height: 1.45)),
        const SizedBox(height: 14),
        for (var k = 0; k < stages.length; k++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FilledButton(
              key: ValueKey('wq-stage-$k'),
              style: FilledButton.styleFrom(backgroundColor: k == 0 ? AppColors.beni : (k == 1 ? AppColors.beniLight : AppColors.kinDeep), minimumSize: const Size.fromHeight(52)),
              onPressed: () async {
                final ws = await words(k);
                if (!context.mounted) return;
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => GairaigoQuizScreen(words: ws)));
              },
              child: Text('${k + 1}${tr('단계')} · ${stages[k].$1} (${stages[k].$2})', style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
      ]),
    );
  }
}

class _Q {
  final GQWord w;
  final bool spelling; // true = 표기, false = 뜻
  final List<String> options;
  const _Q(this.w, this.spelling, this.options);
  String get answer => spelling ? w.ja : w.ko;
}

class GairaigoQuizScreen extends StatefulWidget {
  final List<GQWord> words;
  final int? seed;
  const GairaigoQuizScreen({super.key, required this.words, this.seed});
  @override
  State<GairaigoQuizScreen> createState() => _GairaigoQuizScreenState();
}

class _GairaigoQuizScreenState extends State<GairaigoQuizScreen> {
  late final _rnd = Random(widget.seed);
  List<_Q>? _qs;
  int _i = 0;
  String? _picked;
  int _right = 0;
  final List<GQWord> _missed = [];

  @override
  void initState() {
    super.initState();
    _build();
  }

  Future<void> _build() async {
    final p = await Prefs.getInstance();
    final wrong = (p.getStringList(_kWrong) ?? const []).toSet();
    final uniq = <String, GQWord>{for (final w in widget.words) w.ja: w}.values.toList()..shuffle(_rnd);
    uniq.sort((a, b) => (wrong.contains(b.ja) ? 1 : 0) - (wrong.contains(a.ja) ? 1 : 0));
    final picked = uniq.take(kGairaigoQuizSize).toList()..shuffle(_rnd);
    final real = {for (final w in widget.words) w.ja};
    final qs = <_Q>[];
    for (var k = 0; k < picked.length; k++) {
      final w = picked[k];
      final miss = (gairaigoMisspellings(w.ja, real)..shuffle(_rnd)).take(3).toList();
      if (k.isEven && miss.length == 3) {
        qs.add(_Q(w, true, [w.ja, ...miss]..shuffle(_rnd)));
      } else {
        final others = ({for (final o in uniq) if (o.ko != w.ko) o.ko}.toList()..shuffle(_rnd)).take(3);
        qs.add(_Q(w, false, [w.ko, ...others]..shuffle(_rnd)));
      }
    }
    if (mounted) setState(() => _qs = qs);
  }

  Future<void> _record(String ja, bool ok) async {
    final p = await Prefs.getInstance();
    final s = (p.getStringList(_kWrong) ?? const []).toSet();
    ok ? s.remove(ja) : s.add(ja);
    await p.setStringList(_kWrong, s.toList());
  }

  void _again() => setState(() {
        _qs = null;
        _i = 0;
        _picked = null;
        _right = 0;
        _missed.clear();
        _build();
      });

  @override
  Widget build(BuildContext context) {
    final qs = _qs;
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text(tr('퀴즈 복습'))),
      body: qs == null
          ? const Center(child: CircularProgressIndicator())
          : _i >= qs.length
              ? _summary(qs.length)
              : _question(qs[_i], qs.length),
    );
  }

  Widget _summary(int n) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎉', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 10),
            Text(trf('{0}문제 중 {1}개 맞힘', [n, _right]), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.sumi)),
            if (_missed.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(tr('틀린 단어 — 다음 복습에 먼저 나와요'), style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
              const SizedBox(height: 6),
              for (final w in _missed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${w.ja}  ${w.ko}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.sumi)),
                ),
            ],
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              OutlinedButton(key: const ValueKey('gq-again'), onPressed: _again, child: Text(tr('한 번 더'))),
              const SizedBox(width: 10),
              FilledButton(onPressed: () => Navigator.of(context).maybePop(), style: FilledButton.styleFrom(backgroundColor: AppColors.sumi), child: Text(tr('나가기'))),
            ]),
          ]),
        ),
      );

  Widget _question(_Q q, int n) {
    final w = q.w;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset(context)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('${tr(q.spelling ? '표기' : '뜻')} · ${_i + 1} / $n', style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
        const SizedBox(height: 14),
        Text(
          q.spelling ? w.ko : w.ja,
          key: const ValueKey('gq-stem'),
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.sumi, decoration: TextDecoration.underline, decorationColor: AppColors.sumiLight),
        ),
        const SizedBox(height: 8),
        Text(tr(q.spelling ? '헝가리어로 바르게 쓴 것을 고르세요.' : '뜻으로 맞는 것을 고르세요.'), style: const TextStyle(fontSize: 14, color: AppColors.sumi)),
        if (_picked != null && w.en.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(w.en, style: const TextStyle(fontSize: 13, color: AppColors.ai, fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: 14),
        for (var k = 0; k < q.options.length; k++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              key: ValueKey('gq-opt-$k'),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                backgroundColor: _picked == null ? null : (q.options[k] == q.answer ? const Color(0x3336A35B) : (q.options[k] == _picked ? const Color(0x33D83A3A) : null)),
                side: BorderSide(color: _picked != null && q.options[k] == q.answer ? AppColors.matcha : AppColors.line, width: 1.4),
              ),
              onPressed: _picked != null
                  ? null
                  : () {
                      final ok = q.options[k] == q.answer;
                      TtsService.instance.speak(w.ja);
                      _record(w.ja, ok);
                      setState(() {
                        _picked = q.options[k];
                        ok ? _right++ : _missed.add(w);
                      });
                    },
              child: Row(children: [
                SizedBox(width: 26, child: Text('${k + 1}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.sumiLight))),
                Expanded(child: Text(q.options[k], style: TextStyle(fontSize: q.spelling ? 20 : 16, fontWeight: FontWeight.w800, color: AppColors.sumi))),
              ]),
            ),
          ),
        if (_picked != null)
          FilledButton(
            key: const ValueKey('gq-next'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.sumi, minimumSize: const Size.fromHeight(48)),
            onPressed: () => setState(() {
              _i++;
              _picked = null;
            }),
            child: Text(tr('다음 →')),
          ),
      ]),
    );
  }
}
