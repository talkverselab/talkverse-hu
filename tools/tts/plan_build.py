#!/usr/bin/python3
"""감정 원고(data/tts/emotions/*.txt) → data/tts/plan/<편id>.json.
원고 한 줄 = 한 편:  r1_love_a1: cheerful / surprised+gentle / shy
턴은 ` / ` 로, 한 턴 안의 문장별 감정은 `+` 로 나눈다(하나만 쓰면 턴 전체). 같은 감정이 이어지면 한 조각으로 합치고, 세 글자 미만 조각은 다음 조각에 붙인다.
`--from-json` = 회화 파일의 emotion·segs 에서 바로 계획을 만든다(기본 경로 — 새 회화는 원고 턴 줄에 emotion= 을 적는다).
인물 목소리는 이름으로 정한다(CAST). 읽을 글에서 이모지·괄호 지문은 뺀다."""
import glob, json, os, re, sys
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
EP = {os.path.basename(p)[:-5]: p for p in glob.glob(f'{R}/assets/data/dialogues/R*/*/*.json')}
V = json.load(open(f'{R}/data/tts/voices.json', encoding='utf-8'))
CAST = {'Anna': 'anna', 'Réka': 'reka', 'Bence': 'bence', 'Dávid': 'david'}
OLD_F = re.compile(r'néni|nagymama|mama$', re.I)
OLD_M = re.compile(r'bácsi|nagypapa|papa$', re.I)
MID_F = re.compile(r'anyuk|anya|ügyintéző|tanárnő|nővér|asszony|főnöknő|pincérnő|igazgatónő|recepciós|virágos|pénztáros|eladó|asszisztens|kolléganő', re.I)
MID_M = re.compile(r'apuk|apj|apa|férfi|igazgató|főnök|orvos|ellenőr|pincér|gondnok|professzor|tanár|sofőr|kovács|teremőr|pincemester|portás|rendőr|futár|vevő|kolléga|dj|iroda', re.I)


def voice(name):
    if name in CAST:
        return CAST[name]
    for rx, v in ((OLD_F, 'woman_o'), (OLD_M, 'man_o'), (MID_F, 'woman_m'), (MID_M, 'man_m')):
        if rx.search(name):
            return v
    return 'woman_y' if name.endswith(('a', 'i', 'é')) or name.endswith('ófi') else 'man_y'


def clean(s):
    s = re.sub(r'\([^)]*\)', '', s).replace('…', ',').replace('...', ',')
    s = re.sub(r',\s*([,.!?])', r'\1', s).strip(' ,')
    s = re.sub(r'[\U0001F000-\U0001FAFF☀-➿️‍]', '', s)
    return re.sub(r'\s+', ' ', s).strip()


def sents(s):
    return [x for x in re.findall(r'.+?(?:[.!?…]+["”]?(?=\s|$)|$)', s) if x.strip()]


def segs_of(ss, em):
    """문장 목록 + 문장별 감정 → [[감정, 본문(, 읽을 글)]]. 같은 감정은 합치고 아주 짧은 조각은 다음에 붙인다."""
    segs = []
    for x, s in zip(em, ss):
        if segs and segs[-1][0] == x:
            segs[-1][1] += ' ' + s.strip()
        else:
            segs.append([x, s.strip()])
    i = 0
    while i < len(segs) - 1:
        if len(re.sub(r'[^A-Za-zÁÉÍÓÖŐÚÜŰáéíóöőúüű]', '', segs[i][1])) < 3:
            segs[i + 1][1] = segs[i][1] + ' ' + segs[i + 1][1]
            del segs[i]
        else:
            i += 1
    return [[x, s, clean(s)] if clean(s) != s else [x, s] for x, s in segs]


def from_json():
    """회화 파일의 emotion·segs → 감정 계획(사용자 지시 2026-11-07, 감정을 다시 손으로 적지 않는다). 감정이 빠진 턴이 있는 편은 건너뛰고 알린다."""
    n = 0
    for ep, f in sorted(EP.items()):
        d = json.load(open(f, encoding='utf-8'))
        P = {'ep': ep, 'cast': {k: voice(v) for k, v in d['speakers'].items() if k != 'A'}, 'turns': {}}
        miss = [t['num'] for t in d['turns'] if not t.get('emotion') and not t.get('segs')]
        if miss:
            print(ep, '감정 없는 턴', miss)
            continue
        for t in d['turns']:
            raw = t.get('segs') or [[t['emotion'], t['hu']]]
            P['turns'][str(t['num'])] = {'segs': [[x, s, clean(s)] if clean(s) != s else [x, s] for x, s in raw]}
        os.makedirs(f'{R}/data/tts/plan', exist_ok=True)
        json.dump(P, open(f'{R}/data/tts/plan/{ep}.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
        n += 1
    print(f'회화 파일에서 계획 {n}편 / 전체 {len(EP)}편')


def main():
    if '--from-json' in sys.argv:
        return from_json()
    bad = 0
    seen = set()
    for f in sorted(glob.glob(f'{R}/data/tts/emotions/*.txt')):
        for ln in open(f, encoding='utf-8'):
            ln = ln.strip()
            if not ln or ln.startswith('#'):
                continue
            ep, _, rest = ln.partition(':')
            ep = ep.strip()
            if ep not in EP:
                print('없는 편', ep); bad += 1; continue
            seen.add(ep)
            d = json.load(open(EP[ep], encoding='utf-8'))
            es = [x.strip() for x in rest.split('/')]
            if len(es) != len(d['turns']):
                print(ep, f'턴 {len(d["turns"])} / 감정 {len(es)}'); bad += 1; continue
            P = {'ep': ep, 'cast': {k: voice(v) for k, v in d['speakers'].items() if k != 'A'}, 'turns': {}}
            for t, e in zip(d['turns'], es):
                ss = sents(t['hu'])
                em = [x.strip() for x in e.split('+')]
                if len(em) == 1:
                    em = em * len(ss)
                if len(em) != len(ss):
                    print(ep, f'턴 {t["num"]} 문장 {len(ss)} / 감정 {len(em)}: {t["hu"]}'); bad += 1; em = (em + em[-1:] * len(ss))[:len(ss)]
                for x in em:
                    if x not in V['emotions']:
                        print(ep, '감정?', x); bad += 1
                out = segs_of(ss, em)
                P['turns'][str(t['num'])] = {'segs': out}
            os.makedirs(f'{R}/data/tts/plan', exist_ok=True)
            json.dump(P, open(f'{R}/data/tts/plan/{ep}.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=0)
    print(f'계획 {len(seen)}편 / 전체 {len(EP)}편, 문제 {bad}, 빠진 편 {sorted(set(EP) - seen)[:6]}')
    if '--cast' in sys.argv:
        for n in sorted({v for p in EP.values() for k, v in json.load(open(p, encoding="utf-8"))['speakers'].items() if k != 'A'}):
            print(n, voice(n))


if __name__ == '__main__':
    main()
