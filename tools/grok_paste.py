"""Grok 대사 붙여 넣기(2026-11-22 사용자 지시 「그록을 무조건 거치도록」, uk 원칙 「클로드 초안 → 그록 대사 그대로 붙여넣기」).
data/review/grok/out/<id>.md 의 코드 블록(Grok 답 그대로)을 data/dialogue_src/<주제>.txt 의 그 편 자리에 바꿔 넣는다.
  python3 tools/grok_paste.py            검사만 — 붙일 수 있는 편 / 다시 받을 편(끊김·형식 오류) 목록
  python3 tools/grok_paste.py --apply    붙일 수 있는 편을 원고에 넣는다(그 뒤 hu_dialogue.py build · turn_lock.py · script_publish.py)
대사 줄은 고치지 않는다. 지우는 것은 Grok 이 메모 칸에 남긴 작성용 표시뿐(뜻 풀이는 남김).
턴 고정(turn_lock): 줄 수·화자 순서가 초안과 다르면 붙이지 않는다(끊긴 답도 여기서 걸림).
"""
import glob, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'data/dialogue_src')
OUT = os.path.join(ROOT, 'data/review/grok/out')
TURN = re.compile(r'^[A-D] \|')
# 메모 칸의 작성용 표시(uk 공지 2026-11-19 — de·ko·id 에서 나온 것)
MARK = re.compile(r'\s*[\(\[]?(새로\s*씀|새로\s*작성|작성|필수|punchline|kick\s*setup|setup|callback|심쿵|멘트\s*#?\d*)[\)\]]?\s*[:·,/-]?\s*', re.I)


def blocks(path):
    """원고 파일 → [(id, 시작 줄, 끝 줄(제외))]"""
    lines = open(path, encoding='utf-8').read().split('\n')
    out, cur = [], None
    for i, s in enumerate(lines):
        if s.startswith('==='):
            if cur:
                out.append((cur[0], cur[1], i))
            cur = (s[3:].strip(), i)
    if cur:
        out.append((cur[0], cur[1], len(lines)))
    return lines, out


def answer(eid):
    p = os.path.join(OUT, eid + '.md')
    if not os.path.exists(p) or os.path.getsize(p) == 0:
        return None
    t = open(p, encoding='utf-8').read()
    m = re.search(r'```[a-z]*\n(.*?)```', t, re.S)
    body = (m.group(1) if m else t).strip('\n')
    return [ln.rstrip() for ln in body.split('\n')]


def clean_note(n):
    # 뜻 풀이(X = 뜻)가 있는 메모는 그대로 — 「kötelező = 필수인」 같은 풀이를 표시로 잘못 지우지 않게
    if '=' in n or not MARK.search(n):
        return n
    return MARK.sub(' ', n).strip(' :·,/-')


def judge(src_lines, ans):
    """(문제 목록, 붙일 줄들, 지운 표시 수)"""
    if ans is None:
        return ['답 없음'], None, 0
    st = [l.strip() for l in src_lines if TURN.match(l.strip())]
    at = [l.strip() for l in ans if TURN.match(l.strip())]
    errs = []
    if not ans or not ans[0].startswith('===') or ans[0][3:].strip() != src_lines[0][3:].strip():
        errs.append('머리 줄 id 다름')
    if len(at) != len(st):
        errs.append(f'턴 수 {len(at)} ≠ 초안 {len(st)}(끊김?)')
    elif [a[0] for a in at] != [s[0] for s in st]:
        errs.append('화자 순서 다름')
    marks = 0
    fixed = []
    for l in ans:
        s = l.strip()
        if TURN.match(s):
            p = [x.strip() for x in s.split('|')]
            if len(p) != 5:
                errs.append(f'칸 수 {len(p)}: {s[:40]}')
                fixed.append(s)
                continue
            if not p[4].startswith('emotion='):
                errs.append(f'다섯째 칸이 emotion= 아님(칸 밀림?): {s[:40]}')
            if p[3].startswith('emotion='):
                errs.append(f'메모 칸에 emotion 값(칸 밀림): {s[:40]}')
            n2 = clean_note(p[3])
            if n2 != p[3]:
                marks += 1
                p[3] = n2
            fixed.append(' | '.join(p))
        else:
            fixed.append(s)
    return errs, fixed, marks


def main():
    apply = '--apply' in sys.argv
    ok, redo, marks = [], [], 0
    for f in sorted(glob.glob(os.path.join(SRC, '*.txt'))):
        lines, bl = blocks(f)
        new = list(lines)
        for eid, a, b in reversed(bl):
            src = [l for l in lines[a:b] if l.strip()]
            errs, fixed, m = judge(src, answer(eid))
            if errs:
                redo.append((eid, errs[0]))
                continue
            ok.append(eid)
            marks += m
            new[a:b] = fixed + ['']
        if apply:
            open(f, 'w', encoding='utf-8').write('\n'.join(new).rstrip('\n') + '\n')
    print(f'붙일 수 있음 {len(ok)}편 · 다시 받을 편 {len(redo)} · 지운 메모 표시 {marks}줄' + (' — 원고에 넣음' if apply else ' (검사만)'))
    for eid, e in sorted(redo):
        print(f'  ✗ {eid}: {e}')


if __name__ == '__main__':
    main()
