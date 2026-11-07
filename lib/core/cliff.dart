/// 헝가리어 절벽 구간 — 경계는 코드 이 한 곳에만 둔다(단어 화면·앱 소개가 같이 씀, 2026-11-07).
/// 형태소 토큰 누적 55/60/70/80% 에 처음 닿는 순위 = R1~R4 의 끝(`docs/DIALOGUE.md`). 80% 밖은 R5.
/// R5 는 1,500위에서 끊는다 — 헝가리어 절벽 단어표가 1,500개다(사용자 지시 2026-11-02, 일본어앱은 2,000).
class Cliff {
  Cliff._();
  static const ends = [105, 146, 306, 813];
  static const cap = 1500;
  static const capPct = 85.0;
  static const unit = 20; // 단원 하나의 단어 수

  static String regionOf(int rank) {
    for (var i = 0; i < ends.length; i++) {
      if (rank <= ends[i]) return 'R${i + 1}';
    }
    return 'R5';
  }
}
