#!/bin/zsh
# Gemini 검수를 한도가 풀릴 때마다 이어 돌린다(사용자 지시 2026-11-22 「완료되더라도 제미나이 검수는 제미나이 풀리면 계속 진행」).
#   nohup zsh tools/gemini_resume.sh >> data/review/gemini_run.log 2>&1 &
# 목록 data/review/gemini_todo.tsv(Grok 대사판 150편, tools/gemini_prompts_hu.py 로 만듦) · 결과 data/review/dialogues/<편id>_gemini.md
# 크롬 = uk 가 켜 둔 Gemini 크롬(GEMINI_CDP_PORT, 기본 9227 = 두 번째 계정 ~/chrome-gemini2 · 9226 = ~/chrome-grok-vi). 켜고 끄지 않음, 쿠키 복사 안 함.
cd "$(dirname "$0")/.."
export GEMINI_CDP_PORT=${GEMINI_CDP_PORT:-9227}  # 11-23 두 번째 Gemini 계정 M4 9227(~/chrome-gemini2) — uk 가 정한 포트로
[[ -f /tmp/hu_gemini_resume.pid ]] && kill -0 $(cat /tmp/hu_gemini_resume.pid) 2>/dev/null && { echo "$(date +%H:%M) 이미 돌고 있음"; exit 0; }
echo $$ > /tmp/hu_gemini_resume.pid
left() { local n=0; while IFS=$'\t' read -r p d; do [[ -s $d ]] || ((n++)); done < data/review/gemini_todo.tsv; echo $n; }
[[ $(left) -eq 0 ]] && { echo "$(date +%H:%M) Gemini 검수 전부 끝"; rm -f /tmp/hu_gemini_resume.pid; exit 0; }
# 부하·스왑 확인(크롬 규칙 — 부하 20 이상 또는 스왑 4GB 이상이면 켜지 않음)
read l s <<< $(ssh macmini4 'sysctl -n vm.loadavg | awk "{print int(\$2)}"; sysctl vm.swapusage | sed -E "s/.*used = ([0-9.]+)M.*/\1/"' | tr '\n' ' ')
if (( l >= 20 || ${s%.*} >= 4096 )); then echo "$(date +%H:%M) M4 부하 $l · 스왑 ${s}M — 다음에"; rm -f /tmp/hu_gemini_resume.pid; exit 0; fi
# uk 가 순서대로 넘긴다(11-23: pl → hu → vi). hu 는 uk 의 「hu Gemini 차례」를 받은 뒤에만 이 스크립트를 돌린다.
# 크롬을 켜고 끄지 않는다(로그인을 지키려고 — 탭만 닫음). 쿠키 복사 금지. 크롬이 꺼져 있으면 uk 에 알리고 멈춤.
started=0
if ! ssh macmini4 "curl -s -m 3 127.0.0.1:$GEMINI_CDP_PORT/json/version >/dev/null"; then
  echo "$(date +%H:%M) $GEMINI_CDP_PORT 꺼짐 — uk 에 알릴 것(hu 는 켜지 않음)"; rm -f /tmp/hu_gemini_resume.pid; exit 4
fi
curl -s -m 3 127.0.0.1:$GEMINI_CDP_PORT/json/version >/dev/null || ssh -fN -L $GEMINI_CDP_PORT:127.0.0.1:$GEMINI_CDP_PORT macmini4
# 뒤 순서(pl·hu)는 한 회차 20편까지(uk). 한도·모델 안내가 뜨면 보내지 않고 물러남.
MAX=${HU_GEMINI_MAX:-150}  # 차례가 오면 끝까지(이전 「회차 20편」은 순서 이전 규칙)
todo=$(mktemp); while IFS=$'\t' read -r p d; do [[ -s $d ]] || print -r -- "$p	$d"; done < data/review/gemini_todo.tsv | head -$MAX > $todo
# 로그아웃이면 물러남(11-23: 로그아웃이어도 gemini_pick 은 PICKED 를 낸다 — 「로그인」 단추 수로 확인)
lo=$(/usr/bin/python3 -c "
import sys,time; sys.path.insert(0,'/Users/talkverse/Hanja/tools'); import grok_cdp as g
g.BASE='http://127.0.0.1:'+__import__('os').environ['GEMINI_CDP_PORT']; c=g.CDP(g.tab('gemini.google.com')); time.sleep(3)
print(c.ev(\"[...document.querySelectorAll('a,button')].filter(b=>(b.innerText||'').trim()==='로그인').length\"))" 2>/dev/null)
if [[ "$lo" != "0" ]]; then r="LOGGEDOUT 로그인 단추 $lo"; else r=$(/usr/bin/python3 tools/gemini_pick.py); fi
echo "$(date +%H:%M) $r"
if [[ $r == PICKED* ]]; then
  echo "$(date +%H:%M) Gemini 이번 회차 $(wc -l < $todo | tr -d ' ')편 — 전체 남은 $(left)"
  /usr/bin/python3 tools/gemini_batch.py $todo -j 1 --gap 60
else
  echo "$(date +%H:%M) 한도·모델 안내 — 물러남"
fi
echo "$(date +%H:%M) 회차 끝 — 남은 $(left)"
# 크롬은 끄지 않는다(uk 가 켜 두고 관리 — 로그인 유지)
pkill -f "ssh -fN -L $GEMINI_CDP_PORT:127.0.0.1:$GEMINI_CDP_PORT" 2>/dev/null
rm -f /tmp/hu_gemini_resume.pid
