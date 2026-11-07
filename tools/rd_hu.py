"""헝가리어 → 한글 독음(docs/DIALOGUE.md 표기표). 같은 낱말은 늘 같은 독음이 나온다.
  python3 tools/rd_hu.py "Köszönöm szépen!"
"""
import re, sys

CHO = 'ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ'
JUNG = 'ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ'
JONG = ' ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ'
VOW = {'a': 'ㅓ', 'á': 'ㅏ', 'e': 'ㅔ', 'é': 'ㅔ', 'i': 'ㅣ', 'í': 'ㅣ', 'o': 'ㅗ', 'ó': 'ㅗ', 'ö': 'ㅚ', 'ő': 'ㅚ', 'u': 'ㅜ', 'ú': 'ㅜ', 'ü': 'ㅟ', 'ű': 'ㅟ'}
GLIDE = {'ㅓ': 'ㅕ', 'ㅏ': 'ㅑ', 'ㅔ': 'ㅖ', 'ㅣ': 'ㅣ', 'ㅗ': 'ㅛ', 'ㅚ': 'ㅚ', 'ㅜ': 'ㅠ', 'ㅟ': 'ㅟ'}
# 자음 → (초성, 뒤 모음을 반모음화?)
ONSET = {'b': ('ㅂ', 0), 'c': ('ㅊ', 0), 'cs': ('ㅊ', 0), 'd': ('ㄷ', 0), 'dz': ('ㅈ', 0), 'dzs': ('ㅈ', 0), 'f': ('ㅍ', 0), 'g': ('ㄱ', 0), 'gy': ('ㅈ', 1),
         'h': ('ㅎ', 0), 'j': ('ㅇ', 1), 'k': ('ㅋ', 0), 'l': ('ㄹ', 0), 'ly': ('ㅇ', 1), 'm': ('ㅁ', 0), 'n': ('ㄴ', 0), 'ny': ('ㄴ', 1), 'p': ('ㅍ', 0), 'q': ('ㅋ', 0),
         'r': ('ㄹ', 0), 's': ('ㅅ', 1), 'sz': ('ㅆ', 0), 't': ('ㅌ', 0), 'ty': ('ㅌ', 1), 'v': ('ㅂ', 0), 'w': ('ㅂ', 0), 'z': ('ㅈ', 0), 'zs': ('ㅈ', 1)}
TENSE = {'k': 'ㄲ', 't': 'ㄸ', 'p': 'ㅃ', 'cs': 'ㅉ', 'c': 'ㅉ'}
CODA = {'k': 'ㄱ', 'g': 'ㄱ', 'n': 'ㄴ', 'm': 'ㅁ', 'l': 'ㄹ'}  # 받침으로 쓰는 것 — 나머지는 으/이 음절로 푼다
TAIL = {'b': '브', 'c': '츠', 'cs': '치', 'd': '드', 'dz': '즈', 'dzs': '지', 'f': '프', 'gy': '지', 'h': '흐', 'j': '이', 'ly': '이', 'ny': '니', 'p': '프', 'r': '르', 's': '시',
        'sz': '쓰', 't': '트', 'ty': '티', 'v': '브', 'w': '브', 'z': '즈', 'zs': '지', 'q': '크'}
UNIT = re.compile(r'dzs|ccs|ddz|ggy|lly|nny|ssz|tty|zzs|cs|dz|gy|ly|ny|sz|ty|zs|x|.', re.S)
DOUBLE = {'ccs': 'cs', 'ddz': 'dz', 'ggy': 'gy', 'lly': 'ly', 'nny': 'ny', 'ssz': 'sz', 'tty': 'ty', 'zzs': 'zs'}


def syl(c, v, t=' '):
    if v in ('ㅖ',) and c not in 'ㅇ':
        v = 'ㅔ'  # 녜·졔 → 네·제
    if c in 'ㅈㅊㅉ' and v in ('ㅑ',):
        v = 'ㅏ'
    return chr(0xAC00 + (CHO.index(c) * 21 + JUNG.index(v)) * 28 + JONG.index(t))


def add_coda(out, t):
    last = out[-1]
    i = ord(last) - 0xAC00
    if 0 <= i < 11172 and i % 28 == 0:
        out[-1] = chr(ord(last) + JONG.index(t))
        return True
    return False


def word(w):
    us = []
    for u in UNIT.findall(w.lower()):
        if u == 'x':
            us += ['k', 'sz']
        elif u == 'y':
            us.append('i')
        elif u in DOUBLE:
            us += [DOUBLE[u], DOUBLE[u]]
        else:
            us.append(u)
    out, i, n = [], 0, len(us)
    while i < n:
        u = us[i]
        if u in VOW:
            out.append(syl('ㅇ', VOW[u]))
            i += 1
            continue
        nxt = us[i + 1] if i + 1 < n else None
        if nxt == u and i + 2 < n and us[i + 2] in VOW:  # 겹자음 + 모음
            v = VOW[us[i + 2]]
            if u in TENSE:
                out.append(syl(TENSE[u], v))
            else:
                c, g = ONSET.get(u, ('ㅇ', 0))
                if u in CODA and out:
                    add_coda(out, CODA[u])
                elif u in ('s', 'sz') and out:
                    c = 'ㅆ'
                out.append(syl(c, GLIDE[v] if g else v))
            i += 3
            continue
        if nxt == u:  # 끝의 겹자음은 하나로
            i += 1
            continue
        if nxt in VOW:
            v = VOW[nxt]
            c, g = ONSET.get(u, ('ㅇ', 0))
            if u == 'l' and out and 0 <= ord(out[-1]) - 0xAC00 and (ord(out[-1]) - 0xAC00) % 28 == 0:
                add_coda(out, 'ㄹ')  # 모음 사이 l = ㄹㄹ(터눌록)
            if u == 'j' and v == 'ㅚ':
                v, g = 'ㅛ', 0  # jö → 요(jössz 요쓰)
            out.append(syl(c, GLIDE[v] if g else v))
            i += 2
            continue
        if u == 's' and nxt is not None:  # 자음 앞 s = 슈(Budapesten 부더페슈텐), 끝은 시
            out.append('슈')
            i += 1
            continue
        # 받침 또는 풀어 쓰기
        if u in CODA and out and add_coda(out, CODA[u]):
            i += 1
            continue
        out.append(TAIL.get(u, CODA.get(u) and {'k': '크', 'g': '그', 'n': '느', 'm': '므', 'l': '르'}[u] or ''))
        i += 1
    return ''.join(out)


WORD = re.compile(r"\{[a-z_]+\}|[A-Za-zÁÉÍÓÖŐÚÜŰáéíóöőúüű]+")


def rd(text):
    return WORD.sub(lambda m: m.group(0) if m.group(0).startswith('{') else word(m.group(0)), text)


if __name__ == '__main__':
    print(rd(' '.join(sys.argv[1:])))
