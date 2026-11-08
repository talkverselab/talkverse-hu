import 'dart:async';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/hu_alphabet.dart';
import '../services/tts_service.dart';
import 'vowel_compare_chart.dart';

/// 글자 탭 → 발음 시트(일본어앱 kana_sound_sheet.dart 자리, 2026-11-08).
/// 열리면 1초 뒤 예시 낱말 자동 재생 · 다시 듣기 · 글자 이름 · IPA · 소리 나는 곳 · 모음 위치(헝가리어 vs 한국어) · 조음 위치 그림 · 한국어 화자 비교.
Future<void> showLetterSoundSheet(BuildContext context, HuLetter l, Color color) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.washi,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _Sheet(l: l, color: color),
    );

class _Sheet extends StatefulWidget {
  final HuLetter l;
  final Color color;
  const _Sheet({required this.l, required this.color});
  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  Timer? _auto;
  bool _chart = false;

  @override
  void initState() {
    super.initState();
    _auto = Timer(const Duration(seconds: 1), _word);
  }

  void _word() => TtsService.instance.speak(widget.l.word);

  @override
  void dispose() {
    _auto?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l, c = widget.color;
    final vc = vowelChartOf(l.letter);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scroll) => SafeArea(
        top: false,
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(20, 12, 20, 32 + bottomInset(context)),
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10)),
                child: Text('${l.letter.toUpperCase()}${l.letter.length == 1 ? ' ${l.letter}' : ''}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.washi)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${l.word} · ${l.wordKo}', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: c)),
                  const SizedBox(height: 4),
                  Text('IPA [${l.ipa}] · ${tr('한글')} ${l.kor}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.sumi)),
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: () => TtsService.instance.speak(l.name),
                    child: Text(trf('글자 이름: {0} 🔊', [l.name]), style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
                  ),
                ]),
              ),
              IconButton(iconSize: 44, color: c, tooltip: tr('다시 듣기'), icon: const Icon(Icons.play_circle_fill), onPressed: _word),
            ]),
            const SizedBox(height: 20),
            _box(tr('👄 소리 나는 곳 · 입 모양'), l.place, c),
            if (vc != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withValues(alpha: 0.35))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(tr('📍 모음 위치 — 헝가리어 vs 한국어'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c)),
                  const SizedBox(height: 10),
                  VowelCompareChart(data: vc),
                ]),
              ),
            ],
            if (!l.isVowel || l.letter == 'y') ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () => setState(() => _chart = !_chart),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Icon(_chart ? Icons.expand_less : Icons.expand_more, size: 18, color: c),
                    Text(tr('자음 조음 위치 그림 보기'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c)),
                  ]),
                ),
              ),
              if (_chart) ...[
                ClipRRect( // 임시 그림 — 출시 전에 Grok 그림으로 교체(사용자 지시 2026-11-08)
                  borderRadius: BorderRadius.circular(8),
                  child: Container(color: Colors.white, padding: const EdgeInsets.all(8), child: Image.asset('assets/images/ipa/places_of_articulation.png', fit: BoxFit.contain)),
                ),
              ],
            ],
            const SizedBox(height: 14),
            _box(tr('🇰🇷 한국어와 비교'), trf('비슷한 소리: {0}\n\n{1}', [l.sim, l.diff]), c),
          ],
        ),
      ),
    );
  }

  Widget _box(String title, String body, Color c) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withValues(alpha: 0.35))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 13.5, height: 1.55, color: AppColors.sumi)),
        ]),
      );
}
