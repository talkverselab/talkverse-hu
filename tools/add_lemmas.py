"""회화 턴마다 내용어 레마 `lemmas: [[표면형, 기본형, 한글 독음]]` 를 붙인다(일본어앱 tools/add_lemmas.py 와 같은 자리, 2026-11-04).
기본형 = PyPI 헝가리어 기본형 변환기(simplemma). 기능어(관사·접속사·대명사·후치사·조사)는 뺀다.
독음은 앱 단어장(assets/data/vocab/lexicon_hu.json)에 있으면 그 값, 없으면 빈칸.
단어장에 없는 기본형은 빈도순으로 data/review/write/missing_lemmas.csv 에 — uk 세션이 단어·그림을 채운다.
사용: <venv>/bin/python tools/add_lemmas.py   (simplemma 가 깔린 파이썬)
주의: assets/data/dialogues/L1.json 은 _update_kit/build_content.py 로 다시 만들면 lemmas 가 사라진다 → 다시 만든 뒤 이 도구를 한 번 더.
"""
import collections, csv, json, os, re

import simplemma

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DLG = os.path.join(ROOT, 'assets/data/dialogues/L1.json')
LEX = os.path.join(ROOT, 'assets/data/vocab/lexicon_hu.json')
MISS = os.path.join(ROOT, 'data/review/write/missing_lemmas.csv')
WORD = re.compile(r"[A-Za-zÁÉÍÓÖŐÚÜŰáéíóöőúüű]+")
FUNC_POS = {'det', 'conj', 'pron', 'postp', 'particle', 'suffix', 'num'}
KEEP = {'igen', 'nincs', 'szia', 'persze'}  # 변환기가 잘못 자르는 잦은 말


def lemma(w):
    lw = w.lower()
    if lw in KEEP:
        return lw
    return simplemma.lemmatize(lw, lang='hu').lower()


def main():
    lex = json.load(open(LEX, encoding='utf-8'))['words']
    d = json.load(open(DLG, encoding='utf-8'))
    miss = collections.Counter()
    for ep in d.get('episodes', []):
        for t in ep.get('turns', []):
            out, seen = [], set()
            for i, w in enumerate(WORD.findall(t.get('es', ''))):
                if i > 0 and w[0].isupper():
                    continue  # 사람 이름 등
                b = lemma(w)
                e = lex.get(b)
                if (e and e.get('pos') in FUNC_POS) or len(b) < 2 or b in seen:
                    continue
                seen.add(b)
                out.append([w, b, (e or {}).get('rd', '')])
                if not e:
                    miss[b] += 1
            t['lemmas'] = out
    json.dump(d, open(DLG, 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    os.makedirs(os.path.dirname(MISS), exist_ok=True)
    with open(MISS, 'w', newline='', encoding='utf-8') as f:
        c = csv.writer(f)
        c.writerow(['lemma', 'count'])
        c.writerows(miss.most_common())
    n = sum(len(t['lemmas']) for ep in d['episodes'] for t in ep['turns'])
    print(f'레마 {n}개, 단어장에 없는 기본형 {len(miss)}종 → {os.path.relpath(MISS, ROOT)}')


if __name__ == '__main__':
    main()
