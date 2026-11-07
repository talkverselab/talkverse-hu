"""절벽 단어표 → 앱 데이터(일본어앱 tools/freq/conv_words.py 자리, 2026-11-07).
입력 = 단어표 CSV(rank,word,reading,ko,en,pos,level,picturable — talkversehanja talkverse_art/words/hu.csv).
  python3 tools/build_freq_words.py <hu.csv>
  ① assets/data/vocab/lexicon_hu.json — 단어장(접미사 빼고 기본형 전부, 끝번호 3001~ 포함)
  ② assets/data/freq/cliff_words_hu.json — 절벽 단어 화면 1~1,500위(접미사·어미 토큰 포함)
  ③ (add_lemmas.py 뒤에 다시 돌릴 것) assets/data/freq/conv_words_hu.json — 회화 레마 중 1,500위 밖이면서 단어장에 있는 것(등장 횟수순)
구간 경계는 앱 lib/core/cliff.dart 한 곳에 둔다 — 여기엔 없다.
"""
import collections, csv, json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CAP = 1500
LEX = os.path.join(ROOT, 'assets/data/vocab/lexicon_hu.json')
TOP = os.path.join(ROOT, 'assets/data/freq/cliff_words_hu.json')
CONV = os.path.join(ROOT, 'assets/data/freq/conv_words_hu.json')
DLG = os.path.join(ROOT, 'assets/data/dialogues/L1.json')


def dump(path, obj):
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(obj, f, ensure_ascii=False, indent=0)
        f.write('\n')


def main():
    rows = list(csv.DictReader(open(sys.argv[1], encoding='utf-8')))
    meta = json.load(open(LEX, encoding='utf-8'))['_meta']
    words = {r['word'].lower(): {'ko': r['ko'], 'rd': r['reading'], 'en': r['en'], 'pos': r['pos'], 'rank': int(r['rank']), 'lv': r['level']}
             for r in rows if r['pos'] != 'suffix'}
    dump(LEX, {'_meta': meta, 'words': words})
    top = [{'rank': int(r['rank']), 'word': r['word'], 'ko': r['ko'], 'rd': r['reading'], 'pos': r['pos']} for r in rows if int(r['rank']) <= CAP]
    dump(TOP, {'_meta': '절벽 단어 1~1,500위 — 기본형 + 접미사·어미 토큰 · tools/build_freq_words.py', 'words': top})
    n = collections.Counter()
    for ep in json.load(open(DLG, encoding='utf-8')).get('episodes', []):
        for t in ep.get('turns', []):
            for l in t.get('lemmas', []):
                e = words.get(l[1])
                if e and e['rank'] > CAP:
                    n[l[1]] += 1
    orig = {r['word'].lower(): r['word'] for r in rows}  # 표기는 단어표 그대로(Korea·Budapest)
    conv = [{'word': orig[w], 'ko': words[w]['ko'], 'rd': words[w]['rd'], 'n': c} for w, c in n.most_common()]
    dump(CONV, {'_meta': '회화 레마 중 절벽 단어표(1,500위) 밖이면서 단어장에 있는 것 · tools/build_freq_words.py', 'words': conv})
    print(f'단어장 {len(words)} · 절벽 단어 {len(top)} · 회화 단어 {len(conv)}')


if __name__ == '__main__':
    main()
