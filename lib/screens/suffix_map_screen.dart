import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/dialogue_service.dart';
import '../services/hu_suffix.dart';
import '../services/learner_prefs.dart';
import '../widgets/suffix_text.dart';

/// 접미사 지도 — 자주 나오는 격 접미사를 묶음(장소 안·위·곁 / 함께·대상 / 그 밖)으로 보여 주고,
/// 짝을 누르면 그 접미사가 나온 회화 문장(UX 시안 01, 2026-11-03). 회화 데이터는 읽기만 한다.
class SuffixMapScreen extends StatefulWidget {
  const SuffixMapScreen({super.key});
  @override
  State<SuffixMapScreen> createState() => _SuffixMapScreenState();
}

class _SuffixMapScreenState extends State<SuffixMapScreen> {
  List<String> _sentences = const [];

  @override
  void initState() {
    super.initState();
    DialogueService.instance.ensureLoaded().then((_) {
      if (!mounted) return;
      setState(() => _sentences = [for (final d in DialogueService.instance.all) for (final t in d.turns) LearnerPrefs.fill(t.tl)]);
    });
  }

  String _fronts(HuSuffix s) => {for (final x in HuSuffixes.list) if (x.back == s.back && x.front != x.back) '-${x.front}'}.join(' ');

  List<String> _using(HuSuffix s) => [
        for (final o in _sentences)
          if (RegExp(r"[A-Za-zÀ-ÿŐőŰű]+").allMatches(o).any((m) => HuSuffixes.split(m.group(0)!)?.$2.back == s.back)) o,
      ];

  @override
  Widget build(BuildContext context) {
    // 짝(back 기준) 하나씩만
    final pairs = <String, HuSuffix>{for (final s in HuSuffixes.list) s.back: s};
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text(tr('접미사 지도'))),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)),
        children: [
          Text(tr('헝가리어는 낱말 끝에 접미사를 붙여 뜻을 만든다 — 한국어 조사와 닮았다. ● 뒷모음 낱말 / ○ 앞모음 낱말에 붙는 짝.'),
              style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.5)),
          for (final g in HuSuffixes.groups) ...[
            const SizedBox(height: 16),
            Text(tr(g), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.sumi)),
            const SizedBox(height: 8),
            for (final s in pairs.values.where((p) => p.group == g)) _tile(s),
          ],
        ],
      ),
    );
  }

  Widget _tile(HuSuffix s) {
    final used = _using(s);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.line)),
        child: ListTile(
          leading: SizedBox(
            width: 124,
            // 앞모음 짝이 둘인 것(-hez / -höz)도 모두 보인다
            child: Text(s.hasPair ? '-${s.back} ●\n${_fronts(s)} ○' : '-${s.back}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.beni, height: 1.3)),
          ),
          title: Text(s.ko, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.sumi)),
          subtitle: Text(used.isEmpty ? tr('아직 회화에 없음') : trf('회화 문장 {0}개', [used.length]), style: const TextStyle(fontSize: 12)),
          trailing: used.isEmpty ? null : const Icon(Icons.chevron_right),
          onTap: used.isEmpty ? null : () => _showUses(s, used),
        ),
      ),
    );
  }

  void _showUses(HuSuffix s, List<String> used) {
    HuSuffixes.markSeen(s);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.washi,
      builder: (c) => SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(c).height * 0.6),
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.fromLTRB(24, 0, 24, 20 + bottomInset(c)),
            children: [
              Text('${s.pair} · ${s.ko}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.beni)),
              const SizedBox(height: 8),
              for (final o in used)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: SuffixText(o, others: used, style: const TextStyle(fontSize: 15, color: AppColors.sumi, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
