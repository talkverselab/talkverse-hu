import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/hu_suffix.dart';

/// 헝가리어 문장 — 낱말 끝 격 접미사를 자두색으로 칠하고, 그 낱말을 누르면 접미사 시트(UX 시안 01, 2026-11-03).
/// [color] false 면 보통 글자(자막 「접미사」 칩을 끈 상태). [others] = 시트의 「같은 접미사가 나온 문장」 후보.
class SuffixText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final bool color;
  final List<String> others;
  const SuffixText(this.text, {super.key, required this.style, this.color = true, this.others = const []});

  @override
  State<SuffixText> createState() => _SuffixTextState();
}

class _SuffixTextState extends State<SuffixText> {
  final _taps = <TapGestureRecognizer>[];
  static final _word = RegExp(r"[A-Za-zÀ-ÿŐőŰű]+");

  void _clear() {
    for (final t in _taps) {
      t.dispose();
    }
    _taps.clear();
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: HuSuffixes.show,
        builder: (context, on, _) => _build(context, on && widget.color),
      );

  Widget _build(BuildContext context, bool on) {
    if (!on) return Text(widget.text, style: widget.style);
    _clear();
    final spans = <InlineSpan>[];
    var at = 0;
    for (final m in _word.allMatches(widget.text)) {
      if (m.start > at) spans.add(TextSpan(text: widget.text.substring(at, m.start)));
      final w = m.group(0)!;
      final hit = HuSuffixes.split(w);
      if (hit == null) {
        spans.add(TextSpan(text: w));
      } else {
        final tap = TapGestureRecognizer()..onTap = () => showSuffixSheet(context, hit.$1, hit.$2, others: widget.others);
        _taps.add(tap);
        spans.add(TextSpan(text: hit.$1, recognizer: tap));
        spans.add(TextSpan(text: w.substring(hit.$1.length), recognizer: tap, style: const TextStyle(color: AppColors.beni)));
      }
      at = m.end;
    }
    if (at < widget.text.length) spans.add(TextSpan(text: widget.text.substring(at)));
    return Text.rich(TextSpan(style: widget.style, children: spans));
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
