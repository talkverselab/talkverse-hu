"""회화 음성 공통(헝가리어): 감정 계획 + 편 JSON → 턴별 남성판·여성판(일본어앱 tools/tts/ttslib.py 와 같은 구조).
D1 audio_lines: text = 헝가리어 본문, reading = 빈 값, rd = 한글 독음, ko = 한국어 뜻. 모든 턴에 m·f 두 판.
헝가리어는 문법적 성이 없어 두 판은 이름 자리({name})에서만 갈린다."""
import glob, json, os, re, sys
R = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, f'{R}/tools')
from rd_hu import rd as _rd
V = json.load(open(f'{R}/data/tts/voices.json', encoding='utf-8'))
EP = {os.path.basename(p)[:-5]: p for p in glob.glob(f'{R}/assets/data/dialogues/R*/*/*.json')}
SIL = re.compile(r'[\s….,!?~♪]|\([^)]*\)|[\U0001F300-\U0001FAFF\u2600-\u27BF]')


def fills(P, g):
    out = {k: (x.get(g) or x) for k, x in V['fill'].items()}
    out.update(P.get('fill', {}))
    return out


def fill(s, F, key):
    for k, x in F.items():
        s = s.replace(k, x.get(key) or x['text'])
    return s


def turns(ep):
    """[{num, speaker, m:{voice,text,reading,rd,ko,segs:[(감정,읽기)]}, f:{…}, same:bool}] — 소리 없는 턴은 뺀다."""
    P = json.load(open(f'{R}/data/tts/plan/{ep}.json', encoding='utf-8')); d = json.load(open(EP[ep], encoding='utf-8'))
    out = []
    for t in d['turns']:
        T = P['turns'][str(t['num'])]; row = {'num': t['num'], 'speaker': t['speaker']}
        for g in 'mf':
            F = fills(P, g)
            segs = [(s[0], fill(s[-1], F, 'text').strip()) for s in T['segs']]
            segs = [s for s in segs if SIL.sub('', s[1])]
            text = fill(t['hu'], F, 'text')
            row[g] = {'voice': ('am' if g == 'm' else 'af') if t['speaker'] == 'A' else P['cast'][t['speaker']],
                      'text': text, 'reading': '', 'rd': _rd(text), 'ko': fill(t['ko'], F, 'ko'), 'segs': segs}
        if not row['m']['segs'] or not row['f']['segs']:
            continue
        row['same'] = row['m']['voice'] == row['f']['voice'] and row['m']['segs'] == row['f']['segs']
        out.append(row)
    return out


def seg_files(ep):
    """생성할 조각 [(파일이름, 목소리, 감정, 읽기)] — 두 판이 같으면 c 하나, 다르면 m·f."""
    out = []
    for r in turns(ep):
        for tag in (['c'] if r['same'] else ['m', 'f']):
            x = r['m' if tag == 'c' else tag]
            for i, (emo, text) in enumerate(x['segs']):
                out.append((f"{r['num']:02d}_{i}_{tag}.wav", x['voice'], emo, text))
    return out


def planned():
    return sorted(os.path.basename(p)[:-5] for p in glob.glob(f'{R}/data/tts/plan/*.json') if os.path.basename(p)[:-5] in EP)


VOX = '_vox'
OUT = 'hu'


def base(ep):
    return ep[:-len(VOX)] if ep.endswith(VOX) else ep


def job(ep, name, voice, emo, text, out=None):
    return {'out': out or f'{OUT}/{ep}/{name}', 'text': text, 'language': 'Hungarian', 'reference': f'out/ref_hu/{voice}_{emo}.wav'}
