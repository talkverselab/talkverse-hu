# 헝가리어 회화 초안 규칙 (Claude 초안, 2026-11-07)

공통 원칙 https://talkverse.uk/talkverse/dialogue-rules/ · 헝가리어 특이점 `docs/DIALOGUE.md` · 인물 `CHARACTERS.md`. 예시 = `data/dialogue_src/*.txt` 의 기존 편(이 수준·이 재미가 기준).

## 분량 — 150편, R1~R3
| 레벨 | 편 | 턴 | 낱말/턴 |
|---|---|---|---|
| R1 | survival s1~s3 + friends·love·life·travel·culture 각 14(a1~a5 short · b1~b5 long · c1~c4 chat) = 73 | 6~8 | 2~8(chat 1~6) |
| R2 | friends·love·life·travel·culture·work·study 각 6(b1~b4 long · c1~c2 chat) = 42 | 8~12 | ≤12 |
| R3 | 위 7주제 각 5(b1~b4 long · c1 chat) = 35 | 12~16 | ≤16 |

턴 1~2문장. id = `r<레벨>_<주제>_<a|b|c><번호>`. short = 2~5낱말 위주, long = 조금 긴 문장.

## 재미가 먼저
- 암기하고 싶은 한 줄. 편마다 웃음·놀람 킥 1회(본론 후반). 교과서체·번역투·설명 대사·다짐이나 감사로 끝내기 금지. 끝은 킥이나 여운.
- `twist` 턴 + 종류: **chaos(일이 걷잡을 수 없이 커짐) 묶음의 1/3 이상**, slip(말실수·오해), reveal(의외 사실), emotion(심쿵·감정), ignore(읽씹). 같은 수법 반복 금지.
- 연애·플러팅 편마다 심쿵 한 줄(마음을 들키는 말·말끝 흐리기·여운), 범위는 썸·플러팅까지. **여성이 먼저 다가가는 편을 더 많이.** 다른 주제에도 가끔.
- SNS·DM·채팅·데이팅앱 장면을 많이. 수위 12+: 성적 묘사·불법 권유·미성년 금지, 술·질투·말싸움은 드물게 `flags`(alcohol·jealousy·profanity_mild·romance).
- 헝가리 생활감: 트램·온천·페이퍼 쿠폰보다 실제 것 — 레테시, 랑고시, 굴라시, 뜨끈한 온천, 시장, 벼룩시장, 이름의 날(névnap), 파프리카, 추운 겨울, 긴 단어 농담, 접미사 실수. 실존 브랜드는 최소.

## 말
- **최우선: 헝가리 사람이 실제로 많이 쓰는 짧은 구어**를 편마다 2개 이상 — na · hát · szóval · persze · jaj · tessék · figyelj · várj · komolyan? · mi van? · nem baj · oké · mindegy · tényleg? · ugye · légyszi · köszi · bocsi · durva · ne már · na ne · jól van · rendben · hogyhogy? · mizu? · naná · aha · amúgy · egyébként · szerintem · sajnos · gyere · nézd · tudod · izé · igazából · mindjárt · egy pillanat · úristen · te jó ég · de jó · király · szuper. 레벨이 올라도 계속. `tools/hu_dialogue.py` 의 POOL 을 볼 것. `expressions` 는 대사에 그대로 있어야 한다.
- **문법이 맞아야 한다**: 정/부정 활용(látok/látom), 모음조화, 목적격 -t, 어순 초점, 명령형, -lak/-lek. 번역투 어순 금지.
- 말투: 낯선 어른·가게·관공서 = Ön/Maga 3인칭 동사(kér, tessék parancsolni 는 과함), 친구·연인 = te. 가까워지는 전환 장면(Tegeződjünk?)도. ko 도 같은 말투.
- 어휘: 쉬운 레벨일수록 절벽 단어표 안에서. `assets/data/freq/cliff_words_hu.json` 의 순위를 참고 — R1 은 대체로 앞쪽 단어, 벗어나는 말은 편당 몇 개까지만 note 에 뜻. 검사기의 △ 「단어표 밖」은 활용형 오판일 수 있으니 보고 판단.

## 인물 (A = 학습자 `{name}`, 국적·성별을 대사에 고정하지 말 것 — 성별 드러나는 말 금지, 나라는 `{country}`)
- Anna(대학생, 미술관·레테시, 다정, 스케치북) — love 의 주 상대. Réka(직설·장난, 자전거·벼룩시장) — friends. Bence(바리스타, 농담, 커피) — 카페·work. Dávid(룸메이트, 수영·축구·온천, 솔직) — life.
- 조연은 이름 대신 역할도 됨(Ellenőr, Eladó, Pincér, Orvos, Néni, Főnök, Tanár). `c:`·`d:` 로 셋째 인물 가능.
- 앞 편을 살리는 콜백 환영(같은 묶음 안).

## 원고 형식
`tools/hu_dialogue.py` 머리말 그대로. 턴 줄 = `A | 헝가리어 | 한국어 | note`, 채팅 편은 다섯째 칸 `at=21:03`(필요하면 `stamp=😂`). rd 는 쓰지 않는다(도구가 만든다). note = 그 턴의 핵심 하나 "X = 뜻". `|` 를 대사에 쓰지 말 것. 괄호 지문 최소.

## 감정 열(2026-11-07 사용자 지시 — 앞으로 쓰는 회화부터)
회화를 쓸 때 턴마다 감정도 같이 정한다. 값 16개: neutral polite stiff cheerful amused teasing excited surprised shout tsukkomi annoyed sad worried flustered shy gentle. neutral 만 쓰지 말 것. 원고 턴 줄 다섯째 칸에 `emotion=shy`(턴 안에서 바뀌면 문장별로 `emotion=surprised+gentle`). `tools/hu_dialogue.py build` 가 턴에 `emotion`·`segs` 를 넣고, `tools/tts/plan_build.py --from-json` 이 거기서 음성 감정 계획을 만든다. `tools/tts/make_jobs.py` 가 그 감정의 참고 음성으로 생성한다.

## 금지
출처·작품명·원문 인용 금지(전부 자체 작문). 저작권 있는 대사 흉내 금지.
