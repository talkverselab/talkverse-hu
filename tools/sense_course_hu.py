#!/usr/bin/env python3
"""언어감각 과정 원고(헝가리어) → assets/data/grammar/sense_course.json (일본어앱 빌드 96~112 꼴, 2026-11-18 전달).

급마다 외울 대화 1회(kind memorize, 10줄) + 참고 1회(kind ref). 문장은 자체 제작.
`{글자|번호}` = 어미·관사 자리 — 같은 번호는 헝가리어·한국어에서 같은 색. 한글 독음 rd 는 tools/rd_hu.py 로 만든다.
  python3 tools/sense_course_hu.py           # JSON 다시 만들기 → 바뀌었으면 tools/script_publish.py --publish
  python3 tools/sense_course_hu.py --export  # Grok 초안 data/review/grok/sense_src/<급>.txt 쓰기(tools/grok_sense_run.sh 가 보냄)
외울 대화 10줄은 Grok 대사(2026-11-22 사용자 지시 「그록을 무조건 거치도록」): data/review/grok/sense_out/<급>.md 가 있고
줄 수·표시 번호가 맞으면 아래 Claude 초안 대신 그 줄을 그대로 쓴다(독음만 다시 만든다). 참고(ref) 칸은 초안 그대로.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from rd_hu import rd  # noqa: E402

OUT = ROOT / 'assets/data/grammar/sense_course.json'
MARK = re.compile(r'\{([^|}]+)\|(\d+)\}')
NOTE = '일부러 규칙을 설명하지 않았어요. 대화를 통째로 외우면 색칠한 어미가 저절로 익어요.'


def plain(s):
    return MARK.sub(lambda m: m.group(1), s)


def S(who, hu, ko):
    return {'who': who, 'hu': hu, 'rd': rd(plain(hu)), 'ko': ko}


def P(head, tip, *pairs):
    return {'head': head, 'tip': tip, 'sentences': [{'hu': h, 'rd': rd(h), 'ko': k} for h, k in pairs]}


LEVELS = [
    ('L1', '안쪽 장소 — -ban · -ba · -ból', '어디에 · 어디로 · 어디에서 (안쪽)', [
        S('Anna', 'Hol vagy? Már a kávézó{ban|1} ülök.', '어디야? 난 벌써 카페{에|1} 앉아 있어.'),
        S('나', 'Bocsi, még a metró{ban|1} vagyok.', '미안, 아직 지하철{에|1} 있어.'),
        S('Anna', 'Ugye ide jössz, a sarki kávézó{ba|2}?', '여기 모퉁이 카페{로|2} 오는 거 맞지?'),
        S('나', 'Igen. Öt perc múlva kiszállok a metró{ból|3}.', '응. 5분 뒤에 지하철{에서|3} 내려.'),
        S('Anna', 'Van esernyő a táskád{ban|1}? Esik.', '가방{에|1} 우산 있어? 비 와.'),
        S('나', 'Nincs. Otthon hagytam, a szobám{ban|1}.', '없어. 집에, 내 방{에|1} 두고 왔어.'),
        S('Anna', 'Akkor fuss be az üzlet{be|2}, ott vehetsz egyet.', '그럼 가게{로|2} 뛰어 들어가, 거기서 하나 살 수 있어.'),
        S('나', 'Jó ötlet. Már bent vagyok a bolt{ban|1}.', '좋은 생각. 벌써 가게 안{에|1} 들어왔어.'),
        S('나', 'Kijöttem a bolt{ból|3} egy új esernyővel.', '새 우산 들고 가게{에서|3} 나왔어.'),
        S('Anna', 'Végre! Gyere be a kávézó{ba|2}, már kihűl a kávéd.', '드디어! 카페{로|2} 들어와, 네 커피 벌써 식는다.'),
    ], [
        '-ban·-ben — 「안에 있다」. 단어 모음이 a·o·u 쪽이면 -ban, e·i·ö·ü 쪽이면 -ben (모음조화).',
        '-ba·-be — 「안으로 간다」. 한국어는 「카페에 있어 / 카페에 가」 둘 다 「에」지만 헝가리어는 갈라요.',
        '-ból·-ből — 「안에서 밖으로」. 지하철에서 내리다 = metróból kiszáll.',
    ], [
        P('-ban / -ben  ~안에', '있는 곳(안쪽). 뒷모음(a·á·o·ó·u·ú) 단어는 -ban, 앞모음(e·é·i·í·ö·ő·ü·ű)은 -ben.',
          ('A könyv a táskában van.', '책은 가방 안에 있어요.'), ('A gyerekek a kertben játszanak.', '아이들이 정원에서 놀아요.')),
        P('-ba / -be  ~안으로', '들어가는 곳. 「어디로?」= Hová?',
          ('Bemegyek a boltba.', '가게에 들어가요.'), ('Tedd a tejet a hűtőbe!', '우유를 냉장고에 넣어!')),
        P('-ból / -ből  ~안에서 (밖으로) · ~로 만든', '나오는 곳. 재료에도 써요.',
          ('Most jöttem ki a moziból.', '방금 영화관에서 나왔어요.'), ('Ez a pohár üvegből van.', '이 컵은 유리로 돼 있어요.')),
    ]),
    ('L2', '겉면·사람 곁 — -on · -ra · -ról · -nál · -hoz · -tól', '위에 · 위로 · 위에서 · 사람 곁', [
        S('나', 'A kulcs az asztal{on|1} van?', '열쇠 책상 위{에|1} 있어?'),
        S('Bence', 'Nem, a polc{on|1}. Tedd az asztal{ra|2}, jó?', '아니, 선반 위{에|1}. 책상{에|2} 올려 둘래?'),
        S('나', 'Leveszem a polc{ról|3}... megvan!', '선반{에서|3} 내릴게... 찾았다!'),
        S('Bence', 'Ma este Anná{nál|4} vacsorázunk.', '오늘 저녁은 Anna {네서|4} 먹어.'),
        S('나', 'Anná{hoz|5}? Mikor indulunk?', 'Anna {네로|5}? 언제 출발해?'),
        S('Bence', 'Hétkor. Előtte elmegyek az orvos{hoz|5}.', '7시에. 그 전에 의사{한테|5} 다녀올게.'),
        S('나', 'Én addig a postá{ra|2} megyek.', '나는 그동안 우체국{에|2} 갈게.'),
        S('Bence', 'Az orvos{tól|6} egyenesen Anná{hoz|5} megyek.', '의사{한테서|6} 곧장 Anna {네로|5} 갈게.'),
        S('나', 'Rendben. Hallottál már Anna új lakásá{ról|3}?', '좋아. Anna 새 집{에 대해|3} 들었어?'),
        S('Bence', 'Igen, a tizedik emelet{en|1} van, csodás a kilátás.', '응, 10층{에|1} 있대. 전망이 끝내준대.'),
    ], [
        '헝가리어의 「에」는 세 묶음 — 안(-ban), 위·겉(-on), 사람·가게 곁(-nál). 셋 다 「있다 / 가다 / 오다」로 또 갈려요.',
        '-on 은 앞 소리에 맞춰 -n·-on·-en·-ön (asztalon, emeleten). 헝가리 도시도 대개 -on 쪽 (Budapesten).',
        '우체국·시장처럼 늘 -ra 를 쓰는 곳이 있어요 (postára, piacra) — 외워 두면 돼요.',
        '사람한테 갈 때 -hoz·-hez·-höz (세 가지), 사람한테서 -tól·-től.',
    ], [
        P('-n / -on / -en / -ön  ~위에 · 겉에', '붙어 있는 곳. 도시·층에도.',
          ('A kép a falon van.', '그림이 벽에 걸려 있어요.'), ('Budapesten lakom.', '부다페스트에 살아요.')),
        P('-ra / -re  ~위로 · ~에 (가다)', '올려놓는 곳, 가는 곳.',
          ('Felteszem a polcra.', '선반에 올려요.'), ('Holnap a piacra megyek.', '내일 시장에 가요.')),
        P('-ról / -ről  ~위에서 · ~에 대해', '떨어지는 곳, 이야기의 주제.',
          ('Leesett a pohár az asztalról.', '컵이 책상에서 떨어졌어요.'), ('Miről beszéltek?', '너희 뭐에 대해 얘기해?')),
        P('-nál · -hoz · -tól  사람 곁', '~네 집에서 / ~한테 / ~한테서.',
          ('Péternél alszom.', '페테르네 집에서 자요.'), ('Holnap megyek a fogorvoshoz.', '내일 치과에 가요.')),
    ]),
    ('L3', '목적어 -t 와 관사 a·az', '을/를 = -t', [
        S('점원', 'Jó napot! Mit kér?', '안녕하세요! 뭐 드릴까요?'),
        S('나', 'Egy kenyer{et|1} és két kifli{t|1} kérek.', '빵{을|1} 하나, 키플리{를|1} 두 개 주세요.'),
        S('점원', 'Kér almá{t|1} is? Ma nagyon édes.', '사과{도|1} 드릴까요? 오늘 아주 달아요.'),
        S('나', 'Igen, egy kiló{t|1}... vagyis fél kilót.', '네, 1킬로{를|1}... 아니 반 킬로요.'),
        S('점원', 'Tessék. Mást?', '여기요. 다른 건요?'),
        S('나', 'Van tej? Nem látom a tej{et|1}.', '우유 있어요? 우유{가|1} 안 보여요.'),
        S('점원', 'Ott van, a hűtő mellett.', '저기 냉장고 옆에 있어요.'),
        S('나', 'Megvan. Elfogadnak kártyá{t|1}?', '찾았어요. 카드{도|1} 받으세요?'),
        S('점원', 'Persze. Kér szatyr{ot|1}?', '그럼요. 봉투{를|1} 드릴까요?'),
        S('나', 'Nem kell, hoztam táská{t|1}. Köszönöm!', '괜찮아요, 가방{을|1} 가져왔어요. 감사합니다!'),
    ], [
        '목적어 끝에 -t. 한국어는 「을/를」을 자주 빼거나 「가·도」로 바꾸지만 헝가리어는 꼭 -t 를 붙여요 (우유가 안 보여요 = Nem látom a tejet).',
        '-t 앞에 모음이 끼거나 줄기가 바뀌어요: kenyér→kenyeret, szatyor→szatyrot. a·e 로 끝나면 길어져요: alma→almát.',
        '관사는 자음 앞 a, 모음 앞 az (a tej / az alma).',
    ], [
        P('-t  ~을/를', '모음으로 끝나면 바로 -t, 자음 뒤에는 -ot·-et·-öt·-at 이 붙기도.',
          ('Kávét kérek.', '커피 주세요.'), ('Látod a házat?', '그 집 보여?')),
        P('a / az  그 (정관사)', '자음 앞 a, 모음 앞 az. 「그」라고 옮기지 않아도 돼요.',
          ('A busz késik.', '버스가 늦어요.'), ('Az étterem zárva van.', '식당이 문을 닫았어요.')),
        P('egy  하나 · 어떤 (부정관사)', '「하나」이기도 하고 그냥 「어떤」이기도.',
          ('Egy kérdésem van.', '질문이 하나 있어요.'), ('Láttam egy jó filmet.', '좋은 영화를 하나 봤어.')),
    ]),
    ('L4', '정·부정 활용 — látok / látom', '「그것」을 알면 다른 어미', [
        S('Anna', 'Mit néz{el|1}?', '뭐{를|1} 봐?'),
        S('나', 'Egy régi filmet néz{ek|1}.', '옛날 영화{를|1} 하나 봐.'),
        S('Anna', 'Melyiket? Ismer{em|2}?', '어떤 거? 나도 {그거|2} 알아?'),
        S('나', 'Biztos ismer{ed|2}, apa kedvence.', '분명 {그거|2} 알 거야, 아빠가 제일 좋아하는 거.'),
        S('Anna', 'Ja, azt! Én is szeret{em|2}.', '아, {그거|2}! 나도 좋아해.'),
        S('나', 'Kérsz popcornt? Most csinál{ok|1} egy kicsit.', '팝콘 먹을래? 지금 {조금|1} 만들게.'),
        S('Anna', 'Kér{ek|1}! És hoz{ok|1} két kólát.', '{먹을래|1}! 콜라도 {두 개|1} 가져올게.'),
        S('나', 'A kólát a hűtőben talál{od|2}.', '{그 콜라|2}는 냉장고에 있어.'),
        S('Anna', 'Megvan. Elindít{od|2} a filmet?', '찾았어. {영화|2} 틀어 줄래?'),
        S('나', 'Elindít{om|2}. Csend legyen!', '{틀게|2}. 이제 조용!'),
    ], [
        '목적어가 「정해진 것」(a·az 이 붙은 것, 그것·이름)이면 정활용 -om·-od·-ja, 아니면(뭔가·하나·없음) 부정활용 -ok·-sz.',
        '한국어에는 없는 구분이라 처음엔 낯설어요. 빨강(아무거나)과 파랑(그것)을 견줘 보세요.',
    ], [
        P('부정활용  nézek · nézel · néz', '목적어가 없거나 「하나·뭔가·무엇」일 때.',
          ('Mit olvasol?', '뭐 읽어?'), ('Egy levelet írok.', '편지를 한 통 써.')),
        P('정활용  nézem · nézed · nézi', '목적어가 「그것」일 때 — a/az 이 붙은 말, 이름, azt.',
          ('Olvasod a levelet?', '그 편지 읽고 있어?'), ('Ismerem Pétert.', '페테르를 알아요.')),
        P('-lak / -lek  나 → 너', '「내가 너를」만 따로 있는 꼴.',
          ('Szeretlek.', '사랑해.'), ('Holnap felhívlak.', '내일 전화할게.')),
    ]),
    ('L5', '소유 — 내·네·그의를 끝에', 'családom = 내 가족', [
        S('나', 'Ez a család{om|1}.', '이건 {우리|1} 가족이야.'),
        S('Anna', 'Ki ez? A testvér{ed|2}?', '이 사람 누구야? {네|2} 형제야?'),
        S('나', 'Igen, a bátyá{m|1}. Ő Péter.', '응, {우리|1} 형. 페테르야.'),
        S('Anna', 'És ez az ő kutyá{ja|3}?', '그럼 이건 {그 사람|3} 강아지야?'),
        S('나', 'Nem, ez a mi kutyá{nk|4}, Bodri.', '아니, {우리 집|4} 개야. 보드리.'),
        S('Anna', 'Nekem nincs kutyá{m|1}, csak egy macská{m|1}.', '{난|1} 개는 없고 고양이만 한 마리 있어.'),
        S('나', 'Hogy hívják a macská{d|2}at?', '{네|2} 고양이 이름이 뭐야?'),
        S('Anna', 'Cirmi. A szüle{im|5} adták nekem.', '치르미. {우리|5} 부모님이 주셨어.'),
        S('나', 'Van fénykép{ed|2} róla?', '{너|2} 걔 사진 있어?'),
        S('Anna', 'Persze, a telefon{om|1}on van vagy száz.', '당연하지, {내|1} 폰에 백 장쯤 있어.'),
    ], [
        '헝가리어는 「내·네·그의」를 명사 끝에 붙여요 — családom 내 가족, testvéred 네 형제, kutyája 그의 개.',
        '「~가 있다」= Van + 소유 어미 (Van kutyám = 나는 개가 있어), 없으면 Nincs.',
        '소유 어미 뒤에 다른 어미가 또 붙어요: macskád + at → macskádat, telefonom + on → telefonomon.',
    ], [
        P('-m · -d · -a/-e  내 · 네 · 그의', '모음 뒤엔 바로, 자음 뒤엔 -om·-em·-öm 처럼 모음을 끼워요.',
          ('Hol a kulcsom?', '내 열쇠 어디 있지?'), ('Szép a lakásod.', '네 집 예쁘다.')),
        P('-nk · -tok · -uk  우리 · 너희 · 그들의', '여럿이 가진 것.',
          ('Ez a házunk.', '이게 우리 집이에요.'), ('Hol van az autótok?', '너희 차 어디 있어?')),
        P('Van … -m / Nincs … -m  가지고 있다 / 없다', '「갖다」 동사 대신 「있다」+소유 어미.',
          ('Van egy ötletem.', '나한테 생각이 하나 있어.'), ('Nincs időm.', '시간이 없어.')),
    ]),
    ('L6', '과거 — -t / -tt 하나로', '과거는 하나뿐', [
        S('나', 'Mit csinál{tál|1} hétvégén?', '주말에 뭐 {했어|1}?'),
        S('Bence', 'Szombaton kirándul{tam|1} a Mátrában.', '토요일엔 마트라 산에 하이킹 {갔어|1}.'),
        S('나', 'Egyedül men{tél|1}?', '혼자 {갔어|1}?'),
        S('Bence', 'Nem, a barátaimmal. Sokat nevet{tünk|1}.', '아니, 친구들이랑. 많이 {웃었어|1}.'),
        S('나', 'És vasárnap?', '일요일은?'),
        S('Bence', 'Vasárnap csak alud{tam|1} és főz{tem|1}.', '일요일엔 그냥 {잤고|1} 요리{했어|1}.'),
        S('나', 'Mit főz{tél|1}?', '뭘 요리{했어|1}?'),
        S('Bence', 'Gulyást. Most főz{tem|1} először egyedül.', '굴라시. 이번에 처음 혼자 {만들었어|1}.'),
        S('나', 'És sikerül{t|1}?', '그래서 잘 {됐어|1}?'),
        S('Bence', 'Majdnem. Kicsit sós lett, de mindet megett{ük|1}.', '거의. 좀 짰는데 다 {먹었어|1}.'),
    ], [
        '헝가리어 과거는 하나 — -t- 나 -tt- 를 넣고 그 뒤에 인칭 어미 (csináltam, nevettünk).',
        '-t 인지 -tt 인지는 끝소리에 따라: kirándult·aludt / nevetett·főzött. 외운 문장으로 감을 잡으세요.',
    ], [
        P('-t-  (자음 l·r·n·j 뒤 등)', '대개 짧은 -t-.',
          ('Tegnap moziba mentem.', '어제 영화관에 갔어요.'), ('Kértem egy kávét.', '커피 한 잔 시켰어요.')),
        P('-tt-  (-t 로 끝나는 동사·두 자음 뒤 등)', '모음을 끼운 -ott·-ett·-ött.',
          ('Sokat nevettünk.', '많이 웃었어요.'), ('Ki főzött ma?', '오늘 누가 요리했어?')),
        P('volt  있었다 · ~였다', 'van 의 과거.',
          ('Jó volt a koncert.', '콘서트 좋았어.'), ('Otthon voltam.', '집에 있었어요.')),
    ]),
    ('L7', '동사 접두사 — el- · be- · ki- · fel- · meg- · le-', '접두사가 뒤로 떨어질 때', [
        S('나', '{El|1}megyek a boltba, kérsz valamit?', '가게 {다녀|1}올게, 뭐 필요해?'),
        S('Anna', 'Igen! Vegyél tejet, és {be|2}dobnád a levelet a postaládába?', '응! 우유 사 오고, 편지 좀 우체통에 {넣어|2} 줄래?'),
        S('나', 'Persze. Hol van a levél?', '그래. 편지 어디 있어?'),
        S('Anna', 'Az asztalon. Ja, és {ki|3}vinnéd a szemetet is?', '책상 위에. 아, 쓰레기도 {내다|3} 버려 줄래?'),
        S('나', 'Jó, de akkor te {fel|4}mosod a konyhát.', '알았어, 그럼 넌 부엌 바닥을 {닦아|4}.'),
        S('Anna', 'Rendben, mindjárt {meg|5}csinálom.', '좋아, 금방 {해 놓을|5}게.'),
        S('나', 'Nem találom a kulcsot... ja, {meg|5}van!', '열쇠가 안 보이네... 아, {찾았다|5}!'),
        S('Anna', 'Ne felejtsd {el|1} a tejet!', '우유 {잊지|1} 마!'),
        S('나', 'Nem felejtem {el|1}. Fél óra múlva jövök.', '안 {잊어|1}. 30분 뒤에 올게.'),
        S('Anna', 'Ha {le|6}mész, nézd {meg|5} a postaládát is!', '{내려|6}가면 우편함도 {봐|5} 줘!'),
    ], [
        '접두사는 방향·끝맺음을 더해요: el- 떠나다, be- 안으로, ki- 밖으로, fel- 위로, le- 아래로, meg- 끝까지.',
        '부정(nem·ne)·명령·강조가 오면 접두사가 동사 뒤로 떨어져요: elfelejt → Ne felejtsd el! / megnéz → Nézd meg!',
    ], [
        P('el-  떠나 · 다 해 버리다', '멀어지는 쪽. 끝까지 해 버리는 느낌도.',
          ('Elmegyek.', '나 갈게.'), ('Elfelejtettem a nevét.', '이름을 잊어버렸어.')),
        P('be- / ki-  안으로 / 밖으로', '-ba·-ból 과 짝을 이뤄요.',
          ('Gyere be!', '들어와!'), ('Kimegyek a teraszra.', '테라스로 나갈게.')),
        P('meg-  끝까지 · 해냈다', '완료. 뜻을 「다」로 옮기면 쉬워요.',
          ('Megettem a levest.', '수프를 다 먹었어.'), ('Megírtad a házit?', '숙제 다 했어?')),
        P('떨어지는 자리', 'nem·ne, 명령, 초점(L8) 다음엔 「동사 + 접두사」.',
          ('Nem megyek el.', '안 갈래.'), ('Hívj fel holnap!', '내일 전화해!')),
    ]),
    ('L8', '어순·초점 — 강조는 동사 바로 앞', '누가 먹었어?', [
        S('나', '{Ki|1} ette meg a tortát?', '{누가|1} 케이크 먹었어?'),
        S('Bence', 'Nem {én|1} ettem meg! {Péter|1} ette meg.', '{내가|1} 먹은 거 아니야! {페테르가|1} 먹었어.'),
        S('나', 'Péter? Ő {tegnap|1} volt itt, nem ma.', '페테르? 걔는 {어제|1} 왔었지, 오늘이 아니라.'),
        S('Bence', 'Akkor {a kutya|1} ette meg.', '그럼 {개가|1} 먹었나 봐.'),
        S('나', 'A kutya {nem|2} eszik tortát.', '개는 케이크 {안|2} 먹어.'),
        S('Bence', 'Én csak {egy szeletet|1} ettem.', '나는 {한 조각만|1} 먹었어.'),
        S('나', 'Egy szeletet? Az egész torta eltűnt!', '한 조각? 케이크가 통째로 사라졌는데!'),
        S('Bence', 'Jó, jó... {kettőt|1} ettem.', '알았어, 알았어... {두 조각|1} 먹었어.'),
        S('나', 'És a maradékot?', '그럼 나머지는?'),
        S('Bence', 'A maradékot {nem én|1} ettem meg, hanem a bátyám.', '나머지는 {내가|1} 아니라 우리 형이 먹었어.'),
    ], [
        '헝가리어는 강조하고 싶은 말(새 정보·대답)을 동사 바로 앞에 둬요. 의문사(ki, mit, hol)도 그 자리.',
        '그 자리에 무엇이 오면 접두사가 동사 뒤로: Megette. → Péter ette meg.',
        '「A가 아니라 B」= nem A …, hanem B.',
    ], [
        P('초점 자리  [강조할 말] + 동사', '대답이 되는 말을 동사 앞에.',
          ('Holnap jövök.', '(오늘 말고) 내일 와요.'), ('Anna hívott, nem Péter.', '전화한 건 페테르가 아니라 안나야.')),
        P('의문사 + 동사 + 접두사', '의문사도 초점 자리라 접두사가 떨어져요.',
          ('Mikor jössz haza?', '언제 집에 와?'), ('Ki hívott fel?', '누가 전화했어?')),
        P('nem 의 자리', '부정하는 말 바로 앞. 동사를 부정하면 동사 앞.',
          ('Nem értem.', '이해가 안 돼요.'), ('Nem ma, hanem holnap.', '오늘이 아니라 내일.')),
    ]),
    ('L9', '가능·조건 — -hat/-het · -na/-ne', '~해도 돼 · ~할 텐데', [
        S('나', 'Bejö{het|1}ek?', '들어가도 {돼|1}?'),
        S('Anna', 'Persze. Leül{het|1}sz ide.', '그럼. 여기 앉아도 {돼|1}.'),
        S('나', 'Ha len{ne|2} időd, segíte{nél|2} nekem?', '시간 {있으면|2} 나 좀 도와{줄래|2}?'),
        S('Anna', 'Szívesen segíte{nék|2}, de most dolgozom.', '기꺼이 도와{주고 싶은데|2}, 지금 일하는 중이야.'),
        S('나', 'És holnap ráér{nél|2}?', '그럼 내일은 시간 {될까|2}?'),
        S('Anna', 'Holnap igen. Mit kell csinálni?', '내일은 돼. 뭘 해야 돼?'),
        S('나', 'Ki ké{ne|2} festeni a szobát.', '방을 칠해야 {할 텐데|2}.'),
        S('Anna', 'Hoz{hat|1}ok festéket is.', '페인트도 가져올 {수 있어|1}.'),
        S('나', 'Az nagyszerű len{ne|2}!', '그럼 정말 좋{겠다|2}!'),
        S('Anna', 'De a pizzát te fizeted, rendben?', '근데 피자는 네가 사는 거다, 알았지?'),
    ], [
        '-hat·-het = 「~해도 돼 / ~할 수 있어」 (허락·가능). Bejöhetek? 들어가도 돼요?',
        '-na·-ne = 「~할 텐데 / ~하겠다」 (조건·공손한 부탁). Ha … -na = 만약 ~라면.',
        'kéne = kellene(해야 할 텐데)의 입말.',
    ], [
        P('-hat / -het  ~해도 된다 · ~할 수 있다', '동사 줄기 뒤, 인칭 어미 앞.',
          ('Itt fizethetek kártyával?', '여기서 카드로 계산해도 돼요?'), ('Nem mehetsz el.', '너 가면 안 돼.')),
        P('-na / -ne  ~할 텐데', '바람·조건. 부탁을 부드럽게.',
          ('Innék egy kávét.', '커피 한 잔 마시고 싶다.'), ('Segítenél?', '도와줄래?')),
        P('Ha … -na  만약 ~라면', '두 쪽 다 -na/-ne.',
          ('Ha gazdag lennék, utaznék.', '부자라면 여행 다닐 텐데.'), ('Ha esne, otthon maradnánk.', '비가 오면 집에 있을 텐데.')),
    ]),
    ('L10', '존댓말 Ön · 부탁과 명령 -j', '손님에게 말하기', [
        S('직원', 'Jó napot kívánok! Miben segíthetek?', '안녕하세요! 무엇을 도와드릴까요?'),
        S('나', 'Jó napot! Szobát foglaltam Kim néven.', '안녕하세요! 김 이름으로 방을 예약했어요.'),
        S('직원', 'Igen, megvan. Kitölte{né|1} ezt a lapot?', '네, 확인됐습니다. 이 종이 좀 작성해 {주시겠어요|1}?'),
        S('나', 'Persze. Hol ír{jam|2} alá?', '물론이죠. 어디에 서명{할까요|2}?'),
        S('직원', 'Itt ír{ja|2} alá, kérem.', '여기에 서명해 {주세요|2}.'),
        S('직원', '{Ön|3} is kér reggelit?', '{손님|3}도 조식 드시겠어요?'),
        S('나', 'Igen, kérek. Hánykor van a reggeli?', '네, 주세요. 조식은 몇 시예요?'),
        S('직원', 'Héttől tízig. Pihen{jen|2} jól!', '7시부터 10시까지요. 푹 {쉬세요|2}!'),
        S('나', 'Köszönöm. Fel tud{ná|1} vinni a bőröndömet?', '감사합니다. 제 캐리어 좀 올려다 {주실 수 있어요|1}?'),
        S('직원', 'Természetesen. Köves{sen|2}, kérem!', '물론이죠. {따라오세요|2}!'),
    ], [
        '모르는 어른·손님에게는 Ön(당신)을 쓰고 동사는 3인칭(그·그녀) 꼴 — kér, írja, pihenjen. 친구에겐 te — kérsz, írd, pihenj.',
        '부탁을 부드럽게 할 땐 -ná·-né (Kitöltené? = 작성해 주시겠어요?).',
        '명령·「~할까요」는 -j 꼴 (írjam, pihenjen, kövessen).',
    ], [
        P('Ön + 3인칭  존댓말', '「당신」이지만 동사는 「그」와 같은 꼴.',
          ('Ön honnan jön?', '어디서 오셨어요?'), ('Mit parancsol?', '무엇을 드릴까요?')),
        P('-j  명령 · ~할까요', 'te: írj! / Ön: írjon! 정활용이면 írd! / írja!',
          ('Várjon egy percet!', '잠깐만 기다리세요!'), ('Mit csináljak?', '내가 뭘 할까?')),
        P('-ná / -né  공손한 부탁', '조건법 3인칭 = 손님에게 부탁하는 꼴.',
          ('Megmondaná, hány óra van?', '지금 몇 시인지 알려 주시겠어요?'), ('Becsukná az ablakot?', '창문 좀 닫아 주시겠어요?')),
    ]),
]


GSRC = ROOT / 'data/review/grok/sense_src'
GOUT = ROOT / 'data/review/grok/sense_out'
GLINE = re.compile(r'^\s*([^|]+?)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*$')


def export():
    GSRC.mkdir(parents=True, exist_ok=True)
    for lid, title, sub, lines, foot, points in LEVELS:
        body = [f'=== {lid}', f'title: {title}', f'sub: {sub}', 'target: ' + ' / '.join(foot), f'lines: {len(lines)}']
        body += [f"{x['who']} | {x['hu']} | {x['ko']}" for x in lines]
        (GSRC / f'{lid}.txt').write_text('\n'.join(body) + '\n', encoding='utf-8')
    print(f'{GSRC.relative_to(ROOT)} — {len(LEVELS)}급')


def grok_lines(lid, n):
    """Grok 답 → S 줄 목록(없거나 어긋나면 None, 이유 출력)"""
    p = GOUT / f'{lid}.md'
    if not p.exists():
        return None
    t = p.read_text(encoding='utf-8')
    m = re.search(r'```[a-z]*\n(.*?)```', t, re.S)
    rows = [GLINE.match(l) for l in (m.group(1) if m else t).split('\n')]
    rows = [r for r in rows if r and not r.group(1).startswith(('===', 'title', 'sub', 'target', 'lines'))]
    out = []
    for r in rows:
        who, hu, ko = r.groups()
        if {x.group(2) for x in MARK.finditer(hu)} != {x.group(2) for x in MARK.finditer(ko)}:
            print(f'  ✗ {lid}: Grok 줄 표시 번호 어긋남 — {hu}')
            return None
        out.append(S(who, hu, ko))
    if len(out) != n:
        print(f'  ✗ {lid}: Grok 줄 수 {len(out)} ≠ {n} — 초안 사용')
        return None
    return out


def main():
    if '--export' in sys.argv:
        return export()
    levels = []
    used = 0
    for lid, title, sub, lines, foot, points in LEVELS:
        g = grok_lines(lid, len(lines))
        if g:
            lines = g
            used += 1
        for s in lines:  # 양쪽 표시 번호가 맞는지
            a = {m.group(2) for m in MARK.finditer(s['hu'])}
            b = {m.group(2) for m in MARK.finditer(s['ko'])}
            if a != b:
                sys.exit(f'{lid}: 표시 번호가 다름 {a} / {b} — {s["hu"]}')
        levels.append({'id': lid, 'title': title, 'lessons': [
            {'id': f'{lid}-1', 'title': sub, 'kind': 'memorize', 'video': '', 'note': NOTE, 'sentences': lines, 'footnotes': foot},
            {'id': f'{lid}-ref', 'kind': 'ref', 'title': f'{title.split(" — ")[0]} 한눈에', 'points': points},
        ]})
    data = {'title': '언어감각 익히기', 'subtitle': 'L1 장소 어미부터 L10 존댓말까지 · 대화 통째로 외우기', 'levels': levels}
    OUT.write_text(json.dumps(data, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    print(f'Grok 대사 {used}/{len(LEVELS)}급')
    print(f'{OUT.relative_to(ROOT)} — 급 {len(levels)} · 외울 문장 {sum(len(l[3]) for l in LEVELS)} · 참고 문장 {sum(len(p["sentences"]) for l in LEVELS for p in l[5])}')


if __name__ == '__main__':
    main()
