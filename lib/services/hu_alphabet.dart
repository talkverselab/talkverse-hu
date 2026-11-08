import '../core/l10n.dart';

/// 헝가리어 알파벳 44자 — 발음 기초 메뉴(일본어앱 kana_phonetics.dart 자리, 2026-11-08).
/// 글자마다: 글자 이름(TTS) · IPA · 한글로 가까운 소리 · 예시 낱말 · 소리 나는 곳 · 한국어 화자에게 비슷한/다른 점.
class HuLetter {
  final String letter, name, ipa, kor, word, wordKo, place, sim, diff;
  final String group; // vowel · long · cons · digraph · foreign
  const HuLetter(this.letter, this.group, this.name, this.ipa, this.kor, this.word, this.wordKo, this.place, this.sim, this.diff);
  bool get isVowel => group == 'vowel' || group == 'long';
  /// 모음조화: 뒷모음(a o u) / 앞모음(e i ö ü). 자음은 null.
  bool? get back => isVowel ? 'aáoóuú'.contains(letter) : null;
}

const _bi = '두 입술', _ld = '윗니 + 아랫입술', _al = '혀끝 + 윗잇몸', _pa = '혀 가운데 + 센입천장', _ve = '혀뒤 + 여린입천장', _gl = '목청(성문)', _po = '혀끝 + 잇몸 뒤';

const huLetters = <HuLetter>[
  HuLetter('a', 'vowel', 'a', 'ɒ', '어', 'alma', '사과', '뒤 · 낮은 모음 · 입술 둥글게', 'ㅓ', '입술을 조금 둥글게 한 ㅓ. 「아」로 읽지 않는다 — Anna = 언너'),
  HuLetter('á', 'long', 'á', 'aː', '아', 'ágy', '침대', '가운데 · 낮은 모음 · 길게', 'ㅏ', '입을 크게 벌린 ㅏ를 길게. a 와는 다른 모음이라 뜻이 바뀐다(kar 팔 / kár 손해)'),
  HuLetter('b', 'cons', 'bé', 'b', 'ㅂ', 'bor', '와인', _bi, 'ㅂ', '첫소리부터 성대가 울리는 ㅂ(한국어 첫소리 ㅂ은 울리지 않는다)'),
  HuLetter('c', 'cons', 'cé', 't͡s', '츠', 'cica', '고양이', _al, '츠', '혀끝을 윗잇몸에 대고 「츠」. ㅊ보다 앞에서 난다'),
  HuLetter('cs', 'digraph', 'csé', 't͡ʃ', 'ㅊ', 'csak', '~만', _po, 'ㅊ', '한국어 ㅊ과 거의 같다. 입술을 조금 내민다'),
  HuLetter('d', 'cons', 'dé', 'd', 'ㄷ', 'dal', '노래', _al, 'ㄷ', '첫소리부터 울리는 ㄷ'),
  HuLetter('dz', 'digraph', 'dzé', 'd͡z', '즈', 'edz', '운동하다', _al, '즈', '울리는 「츠」. 드물게 나온다'),
  HuLetter('dzs', 'digraph', 'dzsé', 'd͡ʒ', 'ㅈ', 'dzsem', '잼', _po, 'ㅈ', '울리는 ㅈ. 주로 외래어'),
  HuLetter('e', 'vowel', 'e', 'ɛ', '에', 'egy', '하나', '앞 · 조금 낮은 모음', 'ㅐ', '입을 조금 더 벌린 ㅔ(ㅐ에 가깝다)'),
  HuLetter('é', 'long', 'é', 'eː', '에', 'év', '해(년)', '앞 · 조금 높은 모음 · 길게', 'ㅔ', 'ㅔ보다 입을 좁혀 ㅣ 쪽으로, 길게. e 와 다른 모음'),
  HuLetter('f', 'cons', 'ef', 'f', 'ㅍ', 'fa', '나무', _ld, 'ㅍ', '윗니를 아랫입술에 대고 바람만. 한국어 ㅍ(두 입술)과 다르다'),
  HuLetter('g', 'cons', 'gé', 'ɡ', 'ㄱ', 'gép', '기계', _ve, 'ㄱ', '첫소리부터 울리는 ㄱ'),
  HuLetter('gy', 'digraph', 'gyé', 'ɟ', '디/지', 'gyerek', '아이', _pa, '디·지 사이', '혀 가운데를 입천장에 붙인 「디」. g 와 y 를 따로 읽지 않는다'),
  HuLetter('h', 'cons', 'há', 'h', 'ㅎ', 'ház', '집', _gl, 'ㅎ', '한국어 ㅎ과 같다. 낱말 끝에서는 거의 안 들린다(méh)'),
  HuLetter('i', 'vowel', 'i', 'i', '이', 'itt', '여기', '앞 · 높은 모음', 'ㅣ', '한국어 ㅣ와 같다'),
  HuLetter('í', 'long', 'í', 'iː', '이', 'íz', '맛', '앞 · 높은 모음 · 길게', 'ㅣ', 'ㅣ를 길게'),
  HuLetter('j', 'cons', 'jé', 'j', '이(반모음)', 'jó', '좋은', _pa, 'ㅣ 반모음', '뒤 모음과 붙어 야·요·유가 된다(jó = 요). 영어 j 가 아니다'),
  HuLetter('k', 'cons', 'ká', 'k', 'ㄲ/ㅋ', 'kávé', '커피', _ve, 'ㄲ', '숨을 세게 내지 않는다 — ㅋ보다 ㄲ에 가깝다'),
  HuLetter('l', 'cons', 'el', 'l', 'ㄹ', 'lány', '소녀', _al, '받침 ㄹ', '혀끝을 잇몸에 붙인 채 내는 ㄹ(받침 ㄹ처럼). r 과 구별'),
  HuLetter('ly', 'digraph', 'ellipszilon', 'j', '이(반모음)', 'lyuk', '구멍', _pa, 'ㅣ 반모음', 'j 와 같은 소리. 옛 철자라 낱말마다 외운다'),
  HuLetter('m', 'cons', 'em', 'm', 'ㅁ', 'ma', '오늘', _bi, 'ㅁ', '한국어 ㅁ과 같다'),
  HuLetter('n', 'cons', 'en', 'n', 'ㄴ', 'nem', '아니', _al, 'ㄴ', '한국어 ㄴ과 같다'),
  HuLetter('ny', 'digraph', 'eny', 'ɲ', '니', 'nyár', '여름', _pa, '니', '「니」를 한 소리로 — nyár = 냐르. n 과 y 를 따로 읽지 않는다'),
  HuLetter('o', 'vowel', 'o', 'o', '오', 'orr', '코', '뒤 · 조금 높은 모음 · 입술 둥글게', 'ㅗ', '한국어 ㅗ와 거의 같다'),
  HuLetter('ó', 'long', 'ó', 'oː', '오', 'óra', '시계', '뒤 · 조금 높은 모음 · 길게', 'ㅗ', 'ㅗ를 길게'),
  HuLetter('ö', 'vowel', 'ö', 'ø', '외', 'öt', '다섯', '앞 · 조금 높은 모음 · 입술 둥글게', 'ㅚ', '입술을 ㅗ처럼 둥글게 한 채 ㅔ를 말한다(ㅚ를 한 소리로). 웨로 미끄러지지 않게'),
  HuLetter('ő', 'long', 'ő', 'øː', '외', 'ő', '그·그녀', '앞 · 조금 높은 모음 · 둥글게 · 길게', 'ㅚ', 'ö 를 길게'),
  HuLetter('p', 'cons', 'pé', 'p', 'ㅃ/ㅍ', 'pénz', '돈', _bi, 'ㅃ', '숨을 세게 내지 않는다 — ㅍ보다 ㅃ에 가깝다'),
  HuLetter('q', 'foreign', 'kú', 'k', 'ㅋ', 'Aquincum', '아퀸쿰(옛 도시)', _ve, 'ㅋ', '외래 이름에만 나온다'),
  HuLetter('r', 'cons', 'er', 'r', 'ㄹ(굴림)', 'rossz', '나쁜', _al, '굴리는 ㄹ', '혀끝을 여러 번 떠는 r. 한국어 ㄹ 한 번 튕기기보다 길다'),
  HuLetter('s', 'cons', 'es', 'ʃ', '시/슈', 'só', '소금', _po, '「시」의 ㅅ', '영어 sh 소리. 「스」가 아니다 — só = 쇼'),
  HuLetter('sz', 'digraph', 'esz', 's', 'ㅆ', 'szia', '안녕', _al, 'ㅆ', '한국어 ㅆ에 가깝다. 헝가리어에서는 sz 가 「스」, s 가 「시」 — 거꾸로라 자주 틀린다'),
  HuLetter('t', 'cons', 'té', 't', 'ㄸ/ㅌ', 'tea', '차', _al, 'ㄸ', '숨을 세게 내지 않는다 — ㅌ보다 ㄸ에 가깝다'),
  HuLetter('ty', 'digraph', 'tyé', 'c', '티', 'tyúk', '암탉', _pa, '티', '혀 가운데로 낸 「티」를 한 소리로 — tyúk = 튜크'),
  HuLetter('u', 'vowel', 'u', 'u', '우', 'utca', '거리', '뒤 · 높은 모음 · 입술 둥글게', 'ㅜ', '한국어 ㅜ와 같다'),
  HuLetter('ú', 'long', 'ú', 'uː', '우', 'út', '길', '뒤 · 높은 모음 · 길게', 'ㅜ', 'ㅜ를 길게'),
  HuLetter('ü', 'vowel', 'ü', 'y', '위', 'ül', '앉다', '앞 · 높은 모음 · 입술 둥글게', 'ㅟ', '입술을 ㅜ처럼 둥글게 한 채 ㅣ를 말한다(ㅟ를 한 소리로). 위→이로 미끄러지지 않게'),
  HuLetter('ű', 'long', 'ű', 'yː', '위', 'tűz', '불', '앞 · 높은 모음 · 둥글게 · 길게', 'ㅟ', 'ü 를 길게'),
  HuLetter('v', 'cons', 'vé', 'v', 'ㅂ(울림)', 'víz', '물', _ld, 'ㅂ 아님', '윗니를 아랫입술에 대고 울린다'),
  HuLetter('w', 'foreign', 'dupla vé', 'v', 'ㅂ(울림)', 'wifi', '와이파이', _ld, 'v 와 같다', '외래어에만. 「비피」처럼 v 로 읽는 사람이 많다'),
  HuLetter('x', 'foreign', 'iksz', 'ks', '크ㅅ', 'taxi', '택시', _ve, '크스', '외래어에만'),
  HuLetter('y', 'foreign', 'ipszilon', 'i', '이', 'hobby', '취미', '앞 · 높은 모음', 'ㅣ', '혼자서는 외래어·옛 성씨 끝에만(Nagy 의 gy 와는 다르다)'),
  HuLetter('z', 'cons', 'zé', 'z', 'ㅈ 아님', 'zene', '음악', _al, '울리는 ㅅ', '울리는 「스」(영어 zoo 의 z). 한국어 ㅈ으로 읽지 않는다'),
  HuLetter('zs', 'digraph', 'zsé', 'ʒ', '주', 'zsemle', '둥근 빵', _po, '울리는 「시」', '영어 measure 의 s. 울리는 s(헝가리어 s 소리)'),
];

HuLetter? huLetterOf(String l) {
  for (final x in huLetters) {
    if (x.letter == l) return x;
  }
  return null;
}

/// 모음 위치 — 0~1(가로 = 앞→뒤, 세로 = 높음→낮음).
class VowelPoint {
  final double x, y;
  final String ipa, label;
  const VowelPoint(this.x, this.y, this.ipa, this.label);
}

class VowelChartData {
  final VowelPoint hu;
  final List<VowelPoint> ko;
  final String note;
  const VowelChartData({required this.hu, required this.ko, required this.note});
}

VowelChartData? vowelChartOf(String l) {
  const ka = VowelPoint(0.50, 1.00, 'a', 'ㅏ'), keo = VowelPoint(0.85, 0.62, 'ʌ', 'ㅓ'), ke = VowelPoint(0.08, 0.50, 'e', 'ㅔ'), ki = VowelPoint(0.0, 0.0, 'i', 'ㅣ');
  const ko = VowelPoint(1.0, 0.38, 'o', 'ㅗ'), ku = VowelPoint(1.0, 0.02, 'u', 'ㅜ'), koe = VowelPoint(0.10, 0.42, 'ø', 'ㅚ'), kwi = VowelPoint(0.03, 0.04, 'y', 'ㅟ');
  switch (l) {
    case 'a':
      return VowelChartData(hu: const VowelPoint(0.95, 0.92, 'ɒ', 'a'), ko: const [keo, ka], note: tr('a 는 ㅏ보다 훨씬 뒤·아래, 입술을 둥글게 — 한국어 귀에는 ㅓ로 들린다.'));
    case 'á':
      return VowelChartData(hu: const VowelPoint(0.45, 1.0, 'aː', 'á'), ko: const [ka], note: tr('á 는 ㅏ와 같은 자리, 길게.'));
    case 'e':
      return VowelChartData(hu: const VowelPoint(0.14, 0.70, 'ɛ', 'e'), ko: const [ke], note: tr('e 는 ㅔ보다 입을 더 벌린다(ㅐ).'));
    case 'é':
      return VowelChartData(hu: const VowelPoint(0.04, 0.30, 'eː', 'é'), ko: const [ke, ki], note: tr('é 는 ㅔ와 ㅣ 사이, 길게.'));
    case 'i' || 'í' || 'y':
      return VowelChartData(hu: const VowelPoint(0.02, 0.02, 'i', 'i'), ko: const [ki], note: tr('i 는 ㅣ와 같다. í 는 길게.'));
    case 'o' || 'ó':
      return VowelChartData(hu: const VowelPoint(0.98, 0.34, 'o', 'o'), ko: const [ko], note: tr('o 는 ㅗ와 거의 같다. ó 는 길게.'));
    case 'ö' || 'ő':
      return VowelChartData(hu: const VowelPoint(0.12, 0.34, 'ø', 'ö'), ko: const [koe, ke], note: tr('ö 는 ㅔ 자리에서 입술만 둥글게 — ㅚ 한 소리. ő 는 길게.'));
    case 'u' || 'ú':
      return VowelChartData(hu: const VowelPoint(0.98, 0.04, 'u', 'u'), ko: const [ku], note: tr('u 는 ㅜ와 같다. ú 는 길게.'));
    case 'ü' || 'ű':
      return VowelChartData(hu: const VowelPoint(0.03, 0.06, 'y', 'ü'), ko: const [kwi, ki], note: tr('ü 는 ㅣ 자리에서 입술만 둥글게 — ㅟ 한 소리. ű 는 길게.'));
  }
  return null;
}
