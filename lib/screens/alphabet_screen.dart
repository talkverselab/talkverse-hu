import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/hu_alphabet.dart';
import '../services/ko_reading.dart';
import '../widgets/letter_sound_sheet.dart';

/// 알파벳과 발음 — 헝가리어 44자 격자 + 묶음 칩 + 한글 소리 토글(일본어앱 kana_chart_screen.dart 자리, 2026-11-08).
/// 모음은 모음조화로 색을 나눈다(뒷모음 남색 · 앞모음 자두). 글자를 누르면 발음 시트.
class AlphabetScreen extends StatefulWidget {
  const AlphabetScreen({super.key});
  @override
  State<AlphabetScreen> createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen> {
  String _f = 'all';

  static Map<String, String> get _chips => {
        'all': trf('전체 {0}', [huLetters.length]),
        'vowel': tr('모음'),
        'long': tr('긴 모음'),
        'back': tr('뒷모음 a·o·u'),
        'front': tr('앞모음 e·i·ö·ü'),
        'cons': tr('자음'),
        'digraph': tr('두·세 글자'),
        'foreign': tr('외래 글자'),
      };

  bool _in(HuLetter l) => switch (_f) {
        'all' => true,
        'vowel' => l.isVowel,
        'back' => l.back == true,
        'front' => l.back == false,
        _ => l.group == _f,
      };

  static Color colorOf(HuLetter l) => switch (l.back) {
        true => AppColors.magyar,
        false => AppColors.beni,
        null => l.group == 'digraph' ? AppColors.sumi : (l.group == 'foreign' ? AppColors.muted : AppColors.sumiLight),
      };

  @override
  Widget build(BuildContext context) {
    final shown = huLetters.where(_in).toList();
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('알파벳과 발음'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(tr('44자 · 긴 모음 · 두 글자 소리 · 모음조화'), style: const TextStyle(color: AppColors.sumiLight, fontSize: 10)),
        ]),
        actions: const [KoReadingToggleAction()],
      ),
      body: Column(children: [
        Container(
          color: AppColors.washiDeep,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: SizedBox(
            height: 32,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final e in _chips.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(e.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    selected: _f == e.key,
                    onSelected: (_) => setState(() => _f = e.key),
                    selectedColor: AppColors.beni.withValues(alpha: 0.15),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ]),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) => GridView.builder(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 16 + bottomInset(context)),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: (c.maxWidth / 84).floor().clamp(4, 9), mainAxisSpacing: 8, crossAxisSpacing: 8),
              itemCount: shown.length,
              itemBuilder: (context, i) => _Cell(l: shown[i], color: colorOf(shown[i])),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8 + bottomInset(context)),
          child: Text(tr('모음조화: 낱말의 모음이 뒷모음(남색)이면 접미사도 뒷모음 꼴(-ban), 앞모음(자두)이면 앞모음 꼴(-ben).'),
              style: const TextStyle(fontSize: 11, color: AppColors.sumiLight, height: 1.4)),
        ),
      ]),
    );
  }
}

class _Cell extends StatelessWidget {
  final HuLetter l;
  final Color color;
  const _Cell({required this.l, required this.color});
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => showLetterSoundSheet(context, l, color),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.washi,
            border: Border.all(color: color.withValues(alpha: 0.6), width: l.group == 'long' ? 2 : 1),
            borderRadius: BorderRadius.circular(10),
            boxShadow: kCardShadow,
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            FittedBox(fit: BoxFit.scaleDown, child: Text(l.letter, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color))),
            KoReadingText(l.kor, style: const TextStyle(fontSize: 10.5, color: AppColors.sumiLight)),
            Text('[${l.ipa}]', style: const TextStyle(fontSize: 9.5, color: AppColors.muted)),
          ]),
        ),
      );
}
