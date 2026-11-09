import 'package:flutter/material.dart';

import '../core/pane.dart';
import '../core/theme.dart';
import '../services/ko_reading.dart';
import '../widgets/spanish_decor.dart';
import '../widgets/account_section.dart';
import '../widgets/learner_section.dart';
import '../core/l10n.dart';
import 'about_screen.dart';
import '../embed.dart' show switchLanguage;

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cal,
      appBar: AppBar(title: Text(tr('프로필 · 설정'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.rojoDeep, AppColors.rojo],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gualda, width: 1.5),
            ),
            child: Row(
              children: [
                const TileBadge(text: 'HU', size: 60, color: AppColors.magyar),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('학습자'),
                        style: TextStyle(
                          color: AppColors.cal,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        tr('1. nap · 입문 (A1)'),
                        style: TextStyle(
                          color: AppColors.gualdaBright,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SectionTitle(tr('학습자')),
          const SizedBox(height: 8),
          const LearnerSection(),
          const SizedBox(height: 16),
          _SectionTitle(tr('계정')),
          const SizedBox(height: 8),
          const AccountSection(),
          const SizedBox(height: 16),
          _SectionTitle(tr('설정')),
          const SizedBox(height: 8),
          ValueListenableBuilder<bool>(
            valueListenable: KoReadingPrefs.show,
            builder: (context, on, _) => _SettingsGroup(items: [
              // 통합 앱(Talkverse)에서만: 다른 언어 앱으로(2026-11-09)
              if (switchLanguage != null)
                _SettingItem(icon: Icons.swap_horiz, title: tr('다른 언어 배우기'), subtitle: tr('Talkverse 의 다른 언어로 이동'), onTap: switchLanguage!),
              _SettingItem(
                  icon: Icons.language,
                  title: tr('언어 / Language'),
                  subtitle: '${AppLangPrefs.lang.value.label}  →  ${AppLangPrefs.peekNext().label}',
                  onTap: AppLangPrefs.next),
              _SettingItem(
                  icon: Icons.subtitles_outlined,
                  title: tr('한글독음'),
                  subtitle: on ? tr('표시') : tr('미표시'),
                  onTap: () => KoReadingToggleAction.toggle(context)),
            ]),
          ),
          const SizedBox(height: 16),
          _SectionTitle(tr('정보')),
          const SizedBox(height: 8),
          _SettingsGroup(items: [
            _SettingItem(icon: Icons.menu_book_outlined, title: tr('앱 소개'), subtitle: tr('절벽구간 — 이 앱이 단어를 나누는 기준'), onTap: () => openPane(context, (_) => const AboutScreen())),
            _SettingItem(icon: Icons.info_outline, title: tr('앱 버전'), subtitle: '0.1.0 · alpha'),
            _SettingItem(icon: Icons.copyright, title: tr('저작권'), subtitle: tr('헝가리어유니버스 · 2026')),
            _SettingItem(icon: Icons.gavel_outlined, title: tr('라이선스'), subtitle: tr('사용한 그림·라이브러리'), onTap: () => showLicensePage(context: context, applicationName: tr('헝가리어유니버스'))),
          ]),
          const SizedBox(height: 20),
          const BandDivider(),
          const SizedBox(height: 12),
          const Center(child: SolMark(size: 28)),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Gyakorlat teszi a mestert', // 연습이 대가를 만든다
              style: TextStyle(
                color: AppColors.tintaLight,
                fontSize: 11,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 15,
        color: AppColors.tinta,
        letterSpacing: 2,
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingItem> items;
  const _SettingsGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    // ListTile 물결이 보이게 Material 로 감싼다(배경색 있는 DecoratedBox 안이면 디버그 경고).
    return Material(
      color: AppColors.cal,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.gualda.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ListTile(
              onTap: items[i].onTap,
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.rojo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.rojo, width: 0.8),
                ),
                child: Icon(items[i].icon, color: AppColors.rojo, size: 18),
              ),
              title: Text(items[i].title,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.tinta)),
              subtitle: Text(items[i].subtitle,
                  style: const TextStyle(color: AppColors.tintaLight, fontSize: 11)),
              trailing: const Icon(Icons.chevron_right, color: AppColors.rojo, size: 18),
            ),
            if (i < items.length - 1)
              Container(height: 0.5, color: AppColors.gualda.withValues(alpha: 0.3)),
          ],
        ],
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  _SettingItem({required this.icon, required this.title, required this.subtitle, this.onTap});
}
