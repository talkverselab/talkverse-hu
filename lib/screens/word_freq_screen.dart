import 'dart:convert';
import '../core/embed_env.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../core/cliff.dart';
import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/ko_reading.dart';
import '../services/tts_service.dart';
import '../widgets/word_art_thumb.dart';

/// 절벽 단어 — 빈도 1~1,500위를 절벽 구간(R1~R5)별 **20어 단원**으로, 단어는 **네모 타일**로(일본어앱 word_freq_screen.dart, 2026-11-07).
/// 「회화 단어 포함」이면 회화에 나오지만 1,500위 밖인 단어(assets/data/freq/conv_words_hu.json)가 「회화」 구간으로 뒤에 붙는다.
/// 표는 tools/build_freq_words.py 가 만든다. 접미사·어미 토큰(-ban/-ben 등)도 순위에 그대로 있다.
class WordFreqScreen extends StatefulWidget {
  const WordFreqScreen({super.key});

  @override
  State<WordFreqScreen> createState() => _WordFreqScreenState();
}

class _WordFreqScreenState extends State<WordFreqScreen> {
  List<WordEntry> _words = [];
  List<WordEntry> _conv = [];
  bool _loading = true;
  bool _withConv = false;
  String _filter = 'ALL';

  static Map<String, _Region> get _regions {
    const e = Cliff.ends;
    return {
      'ALL': _Region(tr('전체'), AppColors.sumi),
      'R1': _Region('R1 · 1-${e[0]}', AppColors.beni),
      'R2': _Region('R2 · ${e[0] + 1}-${e[1]}', AppColors.beniLight),
      'R3': _Region('R3 · ${e[1] + 1}-${e[2]}', AppColors.kinDeep),
      'R4': _Region('R4 · ${e[2] + 1}-${e[3]}', AppColors.matcha),
      'R5': _Region('R5 · ${e[3] + 1}-${Cliff.cap}', AppColors.muted),
      'C': _Region(tr('회화'), AppColors.ai),
    };
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<List<Map<String, dynamic>>> _read(String asset) async {
    final j = json.decode(await rootBundle.loadString(assetPath(asset))) as Map<String, dynamic>;
    return (j['words'] as List).cast<Map<String, dynamic>>();
  }

  Future<void> _load() async {
    final words = [
      for (final w in await _read('assets/data/freq/cliff_words_hu.json'))
        WordEntry(rank: w['rank'] as int, word: '${w['word']}', ko: '${w['ko']}', rd: '${w['rd']}', region: Cliff.regionOf(w['rank'] as int)),
    ];
    final conv = <WordEntry>[];
    try {
      var n = 0;
      for (final w in await _read('assets/data/freq/conv_words_hu.json')) {
        conv.add(WordEntry(rank: ++n, word: '${w['word']}', ko: '${w['ko']}', rd: '${w['rd']}', region: 'C'));
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _words = words;
      _conv = conv;
      _loading = false;
    });
  }

  List<WordEntry> get _pool => _withConv ? [..._words, ..._conv] : _words;

  @override
  Widget build(BuildContext context) {
    final regions = _regions;
    final pool = _pool;
    final filtered = _filter == 'ALL' ? pool : pool.where((w) => w.region == _filter).toList();
    final units = <List<WordEntry>>[];
    for (var i = 0; i < filtered.length; i += Cliff.unit) {
      units.add(filtered.sublist(i, (i + Cliff.unit).clamp(0, filtered.length)));
    }
    final chips = regions.entries.where((e) => e.key != 'C' || _withConv).toList();
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('절벽 단어'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(trf('회화 빈도 {0}위 · {1}어 단원 · 탭하면 발음', ['1,500', Cliff.unit]), style: const TextStyle(color: AppColors.sumiLight, fontSize: 10)),
        ]),
        actions: const [KoReadingToggleAction()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.beni))
          : Column(children: [
              Container(
                color: AppColors.washiDeep,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(children: [
                  Row(children: [
                    _ModeButton(
                      label: tr('절벽구간 단어만'),
                      selected: !_withConv,
                      onTap: () => setState(() {
                        _withConv = false;
                        if (_filter == 'C') _filter = 'ALL';
                      }),
                    ),
                    const SizedBox(width: 8),
                    _ModeButton(label: trf('회화 단어 포함 (+{0})', [_conv.length]), selected: _withConv, onTap: () => setState(() => _withConv = true)),
                  ]),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final e in chips)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _filter = e.key),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _filter == e.key ? e.value.color : AppColors.washi,
                                  border: Border.all(color: e.value.color, width: _filter == e.key ? 1.5 : 0.8),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(e.value.label, style: TextStyle(color: _filter == e.key ? AppColors.washi : e.value.color, fontWeight: FontWeight.w700, fontSize: 12)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ]),
              ),
              Expanded(
                child: LayoutBuilder(
                  // 칸 수는 실제 칸 너비로(아이패드 오른쪽 칸은 화면보다 좁다)
                  builder: (context, c) => ListView.builder(
                    padding: EdgeInsets.fromLTRB(12, 8, 12, 16 + bottomInset(context)),
                    itemCount: units.length,
                    itemBuilder: (context, i) => _UnitBlock(index: i + 1, words: units[i], regions: regions, cols: (c.maxWidth / 112).floor().clamp(3, 8)),
                  ),
                ),
              ),
            ]),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.sumi : AppColors.washi,
              border: Border.all(color: selected ? AppColors.sumi : AppColors.line),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(label, style: TextStyle(color: selected ? AppColors.washi : AppColors.sumi, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ),
      );
}

/// 한 단원 = 20어. 머리줄(단원 번호·순위 범위·구간) + 네모 타일 격자.
class _UnitBlock extends StatelessWidget {
  final int index, cols;
  final List<WordEntry> words;
  final Map<String, _Region> regions;
  const _UnitBlock({required this.index, required this.cols, required this.words, required this.regions});

  @override
  Widget build(BuildContext context) {
    final first = words.first;
    final last = words.last;
    final conv = first.region == 'C';
    final color = regions[first.region]?.color ?? AppColors.sumi;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 6),
          child: Row(children: [
            Text(trf('{0}단원', [index]), style: const TextStyle(color: AppColors.sumi, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Text(conv ? trf('회화 {0}-{1}', [first.rank, last.rank]) : '#${first.rank}-${last.rank}', style: const TextStyle(color: AppColors.sumiLight, fontSize: 11)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
              child: Text(conv ? tr('회화') : first.region, style: const TextStyle(color: AppColors.washi, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 6, crossAxisSpacing: 6),
          itemCount: words.length,
          itemBuilder: (context, i) => _WordTile(w: words[i], color: color),
        ),
      ]),
    );
  }
}

/// 네모 타일 — 순위·독음 · 그림(있으면) · 단어 · 뜻. 탭하면 발음(접미사 토큰은 소리 없음).
class _WordTile extends StatelessWidget {
  final WordEntry w;
  final Color color;
  const _WordTile({required this.w, required this.color});

  @override
  Widget build(BuildContext context) {
    final conv = w.region == 'C';
    final suffix = w.word.startsWith('-');
    return InkWell(
      onTap: suffix ? null : () => TtsService.instance.speak(w.word),
      child: Container(
        decoration: BoxDecoration(color: AppColors.washi, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(8), boxShadow: kCardShadow),
        padding: const EdgeInsets.all(6),
        child: LayoutBuilder(builder: (context, c) {
          final art = (c.maxHeight * 0.34).clamp(24.0, 72.0);
          return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(children: [
              Text(conv ? tr('회화') : '#${w.rank}', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w800)),
              const SizedBox(width: 4),
              if (w.rd.isNotEmpty)
                Expanded(child: KoReadingText(w.rd, textAlign: TextAlign.right, style: const TextStyle(fontSize: 9, color: AppColors.sumiLight))),
            ]),
            const SizedBox(height: 2),
            if (suffix)
              SizedBox(height: art, child: const Center(child: Icon(Icons.link, size: 20, color: AppColors.beni)))
            else
              WordArtThumb(word: w.word, rank: conv ? null : w.rank, size: art),
            const SizedBox(height: 4),
            FittedBox(fit: BoxFit.scaleDown, child: Text(w.word, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: suffix ? AppColors.beni : AppColors.sumi))),
            if (w.ko.isNotEmpty) Text(w.ko, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.sumiLight)),
          ]);
        }),
      ),
    );
  }
}

class WordEntry {
  final int rank;
  final String word, ko, rd;
  final String region; // R1~R5 · C(회화 단어)
  const WordEntry({required this.rank, required this.word, required this.ko, required this.rd, required this.region});
}

class _Region {
  final String label;
  final Color color;
  const _Region(this.label, this.color);
}
