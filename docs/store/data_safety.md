# 데이터 안전 / 앱 개인정보 보호 답안 (2026-11-02 — 로그인·인앱 구입 포함)

> 한자 앱 `docs/store/data_safety.md` 를 헝가리어유니버스용으로 옮김.

근거(앱 사실): **Talkverse 계정 로그인은 선택**(구글·네이버·카카오·Apple, 이메일(데모) 로그인; 서버 auth.talkverse.uk = Cloudflare). 로그인하면 이메일·이름(제공자가 주는 범위)·계정 ID·세션 토큰을 서버에 저장. **인앱 구입** 1개(비소모성 평생 이용권) — 결제는 App Store/Google Play 가 처리, 앱·서버는 영수증(거래 번호·상품 ID)만 확인. 학습 기록·설정은 기기 안(SQLite·shared_preferences)에만. 광고·분석·크래시 SDK 없음. 마이크·음성 인식은 말하기 연습에서만(기기 음성 인식, 저장·전송 안 함). Android 는 앱 안 업데이트용 GitHub 릴리스 내려받기 있음(Play 판에서는 빼야 함 — `REQUEST_INSTALL_PACKAGES` 는 Play 정책 대상). 추적 없음.

## App Store — 앱 개인정보 보호(App Privacy)

| 질문 | 답 |
|---|---|
| 이 앱에서 데이터를 수집하나요? | **예** |
| 연락처 정보 → 이메일 주소 | 수집 · **앱 기능**(계정 로그인·구매 복원) · 사용자와 연결됨 · 추적 아님 |
| 연락처 정보 → 이름 | 수집(로그인 제공자가 넘기는 경우만, 선택) · 앱 기능 · 사용자와 연결됨 · 추적 아님 |
| 식별자 → 사용자 ID | 수집(Talkverse 계정 ID) · 앱 기능 · 사용자와 연결됨 · 추적 아님 |
| 구매 → 구매 내역 | 수집(이용권 복원·기기 간 공유) · 앱 기능 · 사용자와 연결됨 · 추적 아님 |
| 오디오 데이터 | **수집 안 함**(음성 인식은 기기 안에서 처리, 앱이 저장·전송하지 않음) |
| 사용 데이터·진단·위치·건강·금융·검색·기타 | **수집 안 함** |
| 추적(ATT) | **아니요** |
| 개인정보처리방침 URL | talkverse.uk 언어앱 방침 페이지(계정(선택)·결제 절 추가 요청) |

### Privacy Manifest(PrivacyInfo.xcprivacy)
- `NSPrivacyTracking` = false. `NSPrivacyCollectedDataTypes`: EmailAddress·Name·UserID·PurchaseHistory(linked=true, tracking=false, purposes=AppFunctionality).
- 필수 사유 API: UserDefaults(`CA92.1`, shared_preferences) — 플러그인 매니페스트에 없으면 Runner 에 추가.

## Google Play — 데이터 보안(Data safety)

| 질문 | 답 |
|---|---|
| 사용자 데이터를 수집하거나 공유하나요? | **예(수집)**, 공유 없음 |
| 수집 항목 | 개인 정보 → 이메일 주소·이름(선택, 계정 관리)·사용자 ID(계정 관리) / 금융 정보 → 구매 내역(앱 기능: 이용권 복원) |
| 필수 여부 | 모두 **선택** |
| 전송 중 암호화 | **예**(HTTPS) |
| 사용자가 데이터 삭제를 요청할 수 있나요? | **예** — 앱 안 "프로필 → 계정 → 계정 삭제" + https://talkverse.uk/account/delete |
| 광고 / 광고 ID | 아니요 / 아니요 |
| 앱 액세스 권한 | 모든 기능이 로그인 없이 사용 가능 — 심사용 데모 계정 review@talkverse.uk 를 안내에 적는다 |
| 디지털 구매 | **예** — 인앱 구입 |
