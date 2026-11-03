import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/dialogue_service.dart';
import '../services/lexicon_service.dart';
import '../services/tts_service.dart';

/// 문장의 내용어(레마) 칩 — 단어장에 있는 말은 누르면 단어 시트, 없는 말은 회색(일본어앱 lemma_chips.dart 를 옮김, 2026-11-04).
/// 같은 기본형은 한 번만. 단어장에 없는 레마 목록은 uk 세션이 채운다(data/review/write/missing_lemmas.csv).
class LemmaChips extends StatelessWidget {
  final DialogueTurn turn;
  final bool compact;
  const LemmaChips({super.key, required this.turn, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final lemmas = [for (final l in turn.lemmas) if (seen.add(l.base)) l];
    if (lemmas.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<Map<String, LexEntry>>(
      key: ValueKey('${turn.num}:${turn.tl}'),
      future: LexiconService.instance.byLemmas(lemmas.map((l) => l.base)),
      builder: (context, snap) {
        final found = snap.data ?? const {};
        return Wrap(spacing: 6, runSpacing: 6, children: [
          for (final l in lemmas)
            _Chip(
              label: l.base,
              gloss: found[l.base]?.ko,
              compact: compact,
              onTap: found[l.base] == null ? null : () => showLexSheet(context, found[l.base]!),
            ),
          if (snap.connectionState == ConnectionState.done && found.isEmpty)
            Padding(padding: const EdgeInsets.only(top: 2), child: Text(tr('단어장에 없는 말'), style: const TextStyle(fontSize: 10, color: AppColors.muted))),
        ]);
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String? gloss;
  final bool compact;
  final VoidCallback? onTap;
  const _Chip({required this.label, this.gloss, this.compact = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9, vertical: compact ? 3 : 4),
        decoration: BoxDecoration(
          color: on ? AppColors.washi : AppColors.washiDeep,
          border: Border.all(color: on ? AppColors.beni.withValues(alpha: 0.7) : AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(fontSize: compact ? 12 : 13.5, fontWeight: FontWeight.w800, color: on ? AppColors.sumi : AppColors.muted)),
          if (gloss != null && gloss!.isNotEmpty) ...[
            const SizedBox(width: 5),
            Flexible(
              child: Text(gloss!.split(RegExp(r'[,;·/(]')).first.trim(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: compact ? 10 : 11, color: AppColors.sumiLight)),
            ),
          ],
        ]),
      ),
    );
  }
}

/// 단어 시트 — 기본형·독음·뜻·품사·절벽 구간, 🔊.
Future<void> showLexSheet(BuildContext context, LexEntry e) => showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.washi,
      builder: (c) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 20 + bottomInset(c)),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text(e.word, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.sumi))),
              IconButton(onPressed: () => TtsService.instance.speak(e.word), icon: const Icon(Icons.volume_up, color: AppColors.beni)),
            ]),
            if (e.rd.isNotEmpty) Text(e.rd, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
            const SizedBox(height: 10),
            Text(e.ko, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.sumi, height: 1.4)),
            const SizedBox(height: 8),
            Text([if (e.pos.isNotEmpty) e.pos, if (e.level.isNotEmpty) trf('절벽 {0} · {1}위', [e.level, e.rank])].join(' · '),
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ),
      ),
    );
