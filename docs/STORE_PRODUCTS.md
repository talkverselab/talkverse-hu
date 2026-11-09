# 스토어 상품·차별화 — 헝가리어유니버스 (2026-11-09)

출시는 **Talkverse 통합 앱 하나**(com.talkverse.app)로 한다(uk 공지). 이 앱은 통합 앱 안의 헝가리어 패키지(`hungarian_universe`)이자 개발·시험용 단독 앱(Zealot·TestFlight)이다. 가격 = `~/talkverse/PRICING.md`(사용자 확정 2026-11-09)의 앱 정가 / 앱 할인가. **등록은 사용자가** App Store Connect·Google Play Console 에서 한다.

## 1. 상품

| 상품 ID | 이름(한국어 표시) | 종류 | 기간 | 앱 정가 | 스토어 판매가(할인가) |
|---|---|---|---|---|---|
| `lang_hu_1m` | 헝가리어 1개월 | 자동 갱신 구독 | 1개월 | 5,500 | **3,900** |
| `lang_hu_3m` | 헝가리어 3개월 | 자동 갱신 구독 | 3개월 | 12,900 | **9,000** |
| `lang_hu_1y` | 헝가리어 1년 | 자동 갱신 구독 | 1년 | 28,500 | **19,900** |
| `lang_hu_life` | 헝가리어 평생 이용권(서비스 운영 기간 동안) | 비소모성 | — | 69,900 | **49,000** |
| `all_1y` | 종합 패키지 1년 — 모든 언어 | 자동 갱신 구독 | 1년 | 112,900 | **79,000** |
| `all_life` | 종합 패키지 평생 — 모든 언어(서비스 운영 기간 동안) | 비소모성 | — | 469,000 | **329,000** |

- 결제 시트는 정가를 취소선으로, 스토어 가격을 크게(`lib/embed.dart` 의 `Purchase.configure`, `lib/screens/paywall_screen.dart`). 앱 안에서 사이트 가격을 안내하지 않는다.
- 옛 평생 상품 `com.talkverse.hungarianUniverse.lifetime`·`lang_hu` 는 판매 중지, 복원 때 `lang_hu_life` 로 인정.
- 통합 앱에서는 공용 결제가 스토어 스트림을 듣고 이 언어 상품을 `Purchase.onPurchaseUpdates` 로 넘긴다(EMBED_GUIDE 5단계).
- **아직 잠근 기능이 없다** — 유료 범위는 사용자 결정 대기. `docs/store/review_notes.md` 의 옛 「평생 이용권 1개」 문단은 유료 범위가 정해지면 이 표로 고친다.

## 2. 차별화(애플 지침 4.3 대비, `~/talkverse/STORE_DIFFERENTIATION.md`)

### 스토어 설명 첫 줄(안)
> 낱말 끝에 붙는 접미사 하나로 「집에서·집으로·집 안에」가 갈리는 말 — 헝가리어 접미사를 색으로 떼어 보여 주고, 모음조화(-ban/-ben)를 한국어 조사처럼 익힙니다.

### 헝가리어 전용 학습 도구(지금 앱에 있는 것만)
1. **접미사 자막·접미사 지도** — 회화 문장의 격 접미사를 색칠하고, 누르면 어간 + 접미사 = 한국어 뜻·모음조화 짝(● 뒷모음 / ○ 앞모음)·같은 접미사가 나온 문장. 격 접미사 25개를 지도로 모아 보고 「만난 접미사」를 성과에 센다.
2. **알파벳과 발음** — 44자(긴 모음 á é í ó ö ő ú ü ű, 두·세 글자 cs dz dzs gy ly ny sz ty zs), 모음조화 색(뒷모음·앞모음), 글자를 누르면 1초 뒤 예시 낱말 재생·IPA·소리 나는 곳·헝가리어 vs 한국어 모음 위치·한국어 화자 비교(s=「시」·sz=「스」 같은 함정).
3. **절벽 단어(형태소 단위)** — 기본형과 접미사·동사 어미를 따로 센 순위: 105개로 대사의 55%, 146개 60%, 306개 70%, 813개 80%, 1,500개 85.0%. 20어 단원 타일, 접미사 토큰도 순위에 그대로.
4. **회화 리더** — 낱말을 누르면 기본형 단어창, 길게 누르면 접미사 시트. 한글 독음은 기본 꺼짐.
5. 동사 활용 · 문법 강의·테스트 · 문장 말하기.

### 출시 전에 채울 것(지금은 없음 — 설명에 쓰지 않는다)
- 회화 150편(R1 73·R2 42·R3 35, 1,600턴)은 Claude 초안 — Grok 재작성(11-09 13:30 재개)·Gemini 검수·사용자 통과 뒤 앱 연결. 지금 앱 회화는 9월 초안 5편.
- 회화 음성: 시험 4편(R2 에만, D1 미등록) — 전편 2,707조각은 사용자 청취 뒤.
- 장면 컷 없음. 조음 위치 그림은 임시(출시 전 Grok 그림으로 교체).
- 「성·수」 메뉴는 준비중 화면 — 헝가리어엔 문법적 성이 없으니 출시 전에 빼거나 다른 화면으로(지침 2.1, 사용자 결정).

### 실측 숫자(출시 때 다시 확인)
- 절벽: R1 105 · R2 146 · R3 306 · R4 813 형태소(누적 55/60/70/80%), 1,500위 85.0%(영화·드라마 대사 자막 표본 약 400만 토큰).
- 회화: 앱 5편 / 초안 150편·1,600턴. 음성 줄: 시험 4편 72줄(앱 미연결).

### 심사 메모 문단(영문, 숫자는 출시 판 기준으로 채움)
> This app is one of a family of language-specific apps by Universal Talking Lab (Talkverse). Each app is built from scratch for one target language for Korean speakers and is NOT a re-skin: the Hungarian app has its own script & pronunciation module (44 letters including long vowels á é í ó ö ő ú ü ű and digraphs cs dz dzs gy ly ny sz ty zs, colour-coded by vowel harmony), its own grammar tools (case-suffix highlighting and a suffix map of 25 case endings with their front/back vowel-harmony pairs, verb conjugation), [N] original conversation episodes with recorded audio written for this language, and a vocabulary list measured from a Hungarian conversation corpus with suffixes counted separately (105 / 146 / 306 / 813 items cover 55 / 60 / 70 / 80 %). Content, curriculum and UI flows differ between apps; we keep them separate because learners search for and buy one language at a time.

### 스크린샷 순서(고유 화면 먼저)
1. 접미사 자막이 켜진 회화 + 접미사 시트(어간 + 접미사 = 뜻, 모음조화 짝)
2. 알파벳과 발음 — 모음조화 색 격자 + 발음 시트(IPA·한국어 비교)
3. 접미사 지도
4. 절벽 단어 — 105/146/306/813 표와 20어 단원 타일
5. 결제 시트(정가 취소선·할인가) — 마지막. 홈·프로필로 시작하지 않는다.
- 아이패드 시안 촬영: `python3 tools/pane_shots.py <UDID> <폴더> integration_test/store_shots_test.dart`(2026-11-09 판은 `data/review/store/`).
