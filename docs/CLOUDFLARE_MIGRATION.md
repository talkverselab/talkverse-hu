# Supabase → Cloudflare 이관 — talkverse-hu

**Supabase 사용 없음 — 확인 2026-10-26.**

- 앱 코드(`lib/`)·스크립트(`tool/`·`tools/`)·웹(`web/`)·에셋에 Supabase 주소·키·SDK 가 없다. `pubspec.yaml` 에도 Supabase 패키지 없음.
  콘텐츠는 번들 에셋 + 기기 안 SQLite, 바깥 통신은 GitHub 릴리스(앱 업데이트)뿐.
- 공용 Supabase 프로젝트 SELECT 확인: 공용 `items` 표에 헝가리어 행 0, 헝가리어 전용 표 없음, 저장소 `tts` 버킷에 `hu/` 파일 없음.
- 로그인·구독 없음 → `talkverse-accounts` 연결은 로그인 기능을 넣을 때 th 설계 §2-8 을 따른다.
- 옮길 것·지울 것 없음. 대기 항목 없음.
