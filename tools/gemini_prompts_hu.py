#!/usr/bin/env python3
"""편마다 Gemini 검수 프롬프트를 만들고 목록(<프롬프트>\t<저장>)을 쓴다. 이미 검수한 편은 뺀다.
  python3 tools/gemini_prompts_hu.py <프롬프트 폴더> <목록.tsv> [편id ...]"""
import glob, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from hu_dialogue import parse
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
T = open(os.path.join(ROOT, 'tools/prompts/review_gemini_hu.md'), encoding='utf-8').read().split('```')[1].strip('\n')
pdir, lst, only = sys.argv[1], sys.argv[2], set(sys.argv[3:])
os.makedirs(pdir, exist_ok=True)
DONE = os.path.join(ROOT, 'data/review/dialogues')
os.makedirs(DONE, exist_ok=True)
eps = [e for f in sorted(glob.glob(os.path.join(ROOT, 'data/dialogue_src/*.txt'))) for e in parse(f)]
if only: eps = sorted([e for e in eps if e['id'] in only], key=lambda e: sorted(only).index(e['id']) if False else e['id'])
rows = []
for e in eps:
    dst = os.path.join(DONE, e['id'] + '_gemini.md')
    if os.path.exists(dst): continue
    roles = 'A=학습자({name})' + ''.join(f', {k.upper()}={e[k]}' for k in 'bcd' if e.get(k))
    lines = '\n'.join(f"{i} {t['speaker']}: {t['hu']} / {t['ko']}" for i, t in enumerate(e['turns'], 1))
    p = T.format(id=e['id'], roles=roles, scene=e.get('scene', ''), register=e.get('register', ''), twist=e.get('twist', ''), lines=lines)
    pf = os.path.join(pdir, e['id'] + '.txt'); open(pf, 'w', encoding='utf-8').write(p + '\n')
    rows.append(f'{pf}\t{dst}')
open(lst, 'w', encoding='utf-8').write('\n'.join(rows) + '\n')
print(len(rows), '건')
