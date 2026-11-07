import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/dialogue_service.dart';
import '../services/hu_suffix.dart';
import '../services/lexicon_service.dart';
import 'lemma_chips.dart';

/// 헝가리어 문장 — 낱말 끝 격 접미사를 자두색으로 칠한다(UX 시안 01, 2026-11-03).
/// [lemmas] 를 주면 낱말을 레마 단위로: **탭 = 단어창**(단어장에 있는 말, 밑줄), **길게 = 접미사 시트**(일본어앱 레마 탭·길게 누르면 한자 시트 자리, 2026-11-07).
/// 단어장에 없는 낱말은 탭도 접미사 시트. [color] false 면 보통 글자(자막 「접미사」 칩을 끈 상태). [others] = 시트의 「같은 접미사가 나온 문장」 후보.
class SuffixText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final bool color;
  final List<String> others;
  final List<Lemma> lemmas;
  const SuffixText(this.text, {super.key, required this.style, this.color = true, this.others = const [], this.lemmas = const []});

  @override
  State<SuffixText> createState() => _SuffixTextState();
}

class _SuffixTextState extends State<SuffixText> {
  static final _word = RegExp(r"[A-Za-zÀ-ÿŐőŰű]+");
  Map<String, LexEntry> _lex = const {}; // 표면형(소문자) → 단어장 항목

  @override
  void initState() {
    super.initState();
    _loadLex();
  }

  @override
  void didUpdateWidget(SuffixText old) {
    super.didUpdateWidget(old);
    if (!identical(old.lemmas, widget.lemmas)) _loadLex();
  }

  Future<void> _loadLex() async {
    final lemmas = widget.lemmas;
    if (lemmas.isEmpty) {
      _lex = const {};
      return;
    }
    final found = await LexiconService.instance.byLemmas(lemmas.map((l) => l.base));
    if (!mounted || !identical(lemmas, widget.lemmas)) return;
    setState(() => _lex = {
          for (final l in lemmas)
            if (found[l.base] != null) l.surface.toLowerCase(): found[l.base]!,
        });
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: HuSuffixes.show,
        builder: (context, on, _) => _build(context, on && widget.color),
      );

  Widget _build(BuildContext context, bool on) {
    if (!on && _lex.isEmpty) return Text(widget.text, style: widget.style);
    final spans = <InlineSpan>[];
    var at = 0;
    for (final m in _word.allMatches(widget.text)) {
      if (m.start > at) spans.add(TextSpan(text: widget.text.substring(at, m.start)));
      final w = m.group(0)!;
      final hit = on ? HuSuffixes.split(w) : null;
      final entry = _lex[w.toLowerCase()];
      if (hit == null && entry == null) {
        spans.add(TextSpan(text: w));
      } else {
        spans.add(_tappable(context, w, hit, entry));
      }
      at = m.end;
    }
    if (at < widget.text.length) spans.add(TextSpan(text: widget.text.substring(at)));
    return Text.rich(TextSpan(style: widget.style, children: spans));
  }

  /// 탭과 길게 누르기를 함께 받으려고 낱말을 위젯으로 넣는다(TextSpan 은 인식기를 하나만 받는다).
  InlineSpan _tappable(BuildContext context, String w, (String, HuSuffix)? hit, LexEntry? entry) {
    void suffix() => showSuffixSheet(context, hit!.$1, hit.$2, others: widget.others);
    final style = entry == null
        ? widget.style
        : widget.style.copyWith(decoration: TextDecoration.underline, decorationColor: AppColors.magyar.withValues(alpha: 0.6), decorationThickness: 1.5);
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: entry == null ? suffix : () => showLexSheet(context, entry, suffix: hit == null ? null : '-${hit.$2.form}', onSuffix: hit == null ? null : suffix),
        onLongPress: hit == null ? null : suffix,
        child: Text.rich(TextSpan(style: style, children: [
          if (hit == null)
            TextSpan(text: w)
          else ...[
            TextSpan(text: hit.$1),
            TextSpan(text: w.substring(hit.$1.length), style: const TextStyle(color: AppColors.beni)),
          ],
        ])),
      ),
    );
  }
}

/// 접미사 시트 — 어간 + 접미사 = 한국어, 모음조화 짝(● 뒷모음 / ○ 앞모음), 같은 접미사가 나온 다른 문장.
Future<void> showSuffixSheet(BuildContext context, String stem, HuSuffix s, {List<String> others = const []}) {
  HuSuffixes.markSeen(s);
  final same = [
    for (final o in others)
      if (RegExp(r"[A-Za-zÀ-ÿŐőŰű]+").allMatches(o).any((m) {
        final h = HuSuffixes.split(m.group(0)!);
        return h != null && h.$2.back == s.back;
      }))
        o,
  ].take(3).toList();
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.washi,
    builder: (c) => SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 20 + bottomInset(c)),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(tr('접미사 시트'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.beni)),
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            _Part(label: tr('어간'), text: stem, color: AppColors.sumi),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('+', style: TextStyle(fontSize: 26, color: AppColors.muted))),
            _Part(label: tr('접미사'), text: '-${s.form}', color: AppColors.beni),
          ]),
          const SizedBox(height: 14),
          _Row(icon: Icons.translate, label: tr('뜻'), value: s.ko),
          _Row(icon: Icons.category_outlined, label: tr('묶음'), value: tr(s.group)),
          if (s.hasPair)
            _Row(
              icon: Icons.swap_horiz,
              label: tr('모음조화'),
              value: '-${s.back} ●  ↔  -${s.front} ○',
              note: s.isFront ? tr('앞모음(e·i·ö·ü) 낱말이라 ○ 쪽') : tr('뒷모음(a·o·u) 낱말이라 ● 쪽'),
            ),
          if (same.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(tr('같은 접미사가 나온 문장'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted)),
            const SizedBox(height: 4),
            for (final o in same) Padding(padding: const EdgeInsets.only(top: 4), child: SuffixText(o, style: const TextStyle(fontSize: 14, color: AppColors.sumi, fontWeight: FontWeight.w600))),
          ],
        ]),
      ),
    ),
  );
}

class _Part extends StatelessWidget {
  final String label, text;
  final Color color;
  const _Part({required this.label, required this.text, required this.color});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
        Text(text, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: color)),
      ]);
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final String? note;
  const _Row({required this.icon, required this.label, required this.value, this.note});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 10),
          SizedBox(width: 72, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600))),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: const TextStyle(fontSize: 15, color: AppColors.sumi, fontWeight: FontWeight.w700)),
              if (note != null) Text(note!, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ]),
          ),
        ]),
      );
}
