import 'dart:convert';
import '../core/embed_env.dart';

import 'package:flutter/services.dart' show rootBundle;

/// 헝가리어 단어장 — 절벽 기본형 순위 단어(assets/data/vocab/lexicon_hu.json, 2026-11-04).
/// 문장 레마 칩이 기본형으로 찾아본다(일본어앱 WordService.byLemmas 자리). 없는 말은 칩이 회색.
class LexEntry {
  final String word, ko, rd, en, pos, level;
  final int rank;
  const LexEntry(this.word, this.ko, this.rd, this.en, this.pos, this.rank, this.level);
}

class LexiconService {
  LexiconService._();
  static final LexiconService instance = LexiconService._();

  Map<String, LexEntry>? _words;
  Future<void>? _loading;

  Future<void> _ensure() => _loading ??= () async {
        final out = <String, LexEntry>{};
        try {
          final j = json.decode(await rootBundle.loadString(assetPath('assets/data/vocab/lexicon_hu.json'))) as Map<String, dynamic>;
          for (final e in (j['words'] as Map<String, dynamic>).entries) {
            final m = e.value as Map<String, dynamic>;
            out[e.key] = LexEntry(e.key, '${m['ko'] ?? ''}', '${m['rd'] ?? ''}', '${m['en'] ?? ''}', '${m['pos'] ?? ''}', (m['rank'] as num?)?.toInt() ?? 0, '${m['lv'] ?? ''}');
          }
        } catch (_) {}
        _words = out;
      }();

  /// 기본형 → 단어장 항목(없는 말은 빠짐).
  Future<Map<String, LexEntry>> byLemmas(Iterable<String> bases) async {
    await _ensure();
    final w = _words ?? const {};
    return {for (final b in bases) if (w[b.toLowerCase()] != null) b: w[b.toLowerCase()]!};
  }
}
