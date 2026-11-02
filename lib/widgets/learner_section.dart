import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../services/learner_prefs.dart';

/// 학습자 프로필(일본어앱·인도네시아어앱 learner_prefs, 2026-11-02) — 이름 → 회화의 {name} 자리, 성별 → 학습자 목소리·장면 그림.
class LearnerSection extends StatelessWidget {
  const LearnerSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LearnerPrefs.name,
      builder: (context, name, _) => ValueListenableBuilder<String>(
        valueListenable: LearnerPrefs.gender,
        builder: (context, gender, _) => Material(
          color: AppColors.cal,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.gualda)),
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.badge_outlined, color: AppColors.rojo),
              title: Text(tr('이름')),
              subtitle: Text(name.isNotEmpty ? trf('{0} — 회화 속 「나」로 나와요', [name]) : tr('없음 — 회화에서 「○○」로 보여요'),
                  style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.edit_outlined, size: 18),
              onTap: () => _editName(context),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(gender == 'female' ? Icons.face_3 : Icons.face, color: AppColors.rojo),
              title: Text(tr('성별')),
              subtitle: Text(gender == 'female' ? tr('여성 — 탭하면 남성') : tr('남성 — 탭하면 여성'), style: const TextStyle(fontSize: 12)),
              onTap: () => LearnerPrefs.setGender(gender == 'female' ? 'male' : 'female'),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context) async {
    final c = TextEditingController(text: LearnerPrefs.name.value);
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('이름')),
        content: TextField(controller: c, autofocus: true, decoration: InputDecoration(hintText: tr('회화에서 불릴 이름'))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('취소'))),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text(tr('저장'))),
        ],
      ),
    );
    if (v != null) await LearnerPrefs.setName(v);
  }
}
