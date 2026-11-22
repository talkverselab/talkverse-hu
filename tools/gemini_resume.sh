#!/bin/zsh
# Gemini 검수를 한도가 풀릴 때마다 이어 돌린다(사용자 지시 2026-11-22 「완료되더라도 제미나이 검수는 제미나이 풀리면 계속 진행」).
#   nohup zsh tools/gemini_resume.sh >> data/review/gemini_run.log 2>&1 &
# 목록 data/review/gemini_todo.tsv(Grok 대사판 150편, tools/gemini_prompts_hu.py 로 만듦) · 결과 data/review/dialogues/<편id>_gemini.md
# 크롬 = M4 9226(베트남어 세션 Gemini 크롬 공용 — 구글 로그인은 그 프로필에 있음, 쿠키 복사 안 함). 쓸 때만 켜고 끝나면 끈다(크롬 규칙).
cd "$(dirname "$0")/.."
export GEMINI_CDP_PORT=9226
[[ -f /tmp/hu_gemini_resume.pid ]] && kill -0 $(cat /tmp/hu_gemini_resume.pid) 2>/dev/null && { echo "$(date +%H:%M) 이미 돌고 있음"; exit 0; }
echo $$ > /tmp/hu_gemini_resume.pid
left() { local n=0; while IFS=$'\t' read -r p d; do [[ -s $d ]] || ((n++)); done < data/review/gemini_todo.tsv; echo $n; }
[[ $(left) -eq 0 ]] && { echo "$(date +%H:%M) Gemini 검수 전부 끝"; rm -f /tmp/hu_gemini_resume.pid; exit 0; }
# 부하·스왑 확인(크롬 규칙 — 부하 20 이상 또는 스왑 4GB 이상이면 켜지 않음)
read l s <<< $(ssh macmini4 'sysctl -n vm.loadavg | awk "{print int(\$2)}"; sysctl vm.swapusage | sed -E "s/.*used = ([0-9.]+)M.*/\1/"' | tr '\n' ' ')
if (( l >= 20 || ${s%.*} >= 4096 )); then echo "$(date +%H:%M) M4 부하 $l · 스왑 ${s}M — 다음에"; rm -f /tmp/hu_gemini_resume.pid; exit 0; fi
# 9226 은 여섯 세션 공용(uk 11-22 23:1x 순서: kk → hi → fa → my → pl → hu, 한 번에 한 세션). 이미 켜져 있으면 남이 쓰는 중 → 이번 회차는 건너뜀(30분 뒤 예약이 다시).
if ssh macmini4 'curl -s -m 3 127.0.0.1:9226/json/version >/dev/null'; then
  echo "$(date +%H:%M) 9226 이 이미 켜져 있음(다른 세션 사용 중) — 건너뜀"; rm -f /tmp/hu_gemini_resume.pid; exit 0
fi
ssh macmini4 'nohup "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --remote-debugging-port=9226 --remote-debugging-address=127.0.0.1 --user-data-dir=/Users/talkverse/chrome-grok-vi --no-first-run https://gemini.google.com/app >/dev/null 2>&1 &'
started=1; sleep 25  # Gemini 화면이 다 뜰 때까지(10초는 NOBUTTON, 11-22 23:54)
curl -s -m 3 127.0.0.1:9226/json/version >/dev/null || ssh -fN -L 9226:127.0.0.1:9226 macmini4
# 뒤 순서(pl·hu)는 한 회차 20편까지(uk). 한도·모델 안내가 뜨면 보내지 않고 물러남.
MAX=${HU_GEMINI_MAX:-20}
todo=$(mktemp); while IFS=$'\t' read -r p d; do [[ -s $d ]] || print -r -- "$p	$d"; done < data/review/gemini_todo.tsv | head -$MAX > $todo
r=$(/usr/bin/python3 tools/gemini_pick.py); echo "$(date +%H:%M) $r"
if [[ $r == PICKED* ]]; then
  echo "$(date +%H:%M) Gemini 이번 회차 $(wc -l < $todo | tr -d ' ')편 — 전체 남은 $(left)"
  /usr/bin/python3 tools/gemini_batch.py $todo -j 1 --gap 60
else
  echo "$(date +%H:%M) 한도·모델 안내 — 물러남"
fi
echo "$(date +%H:%M) 회차 끝 — 남은 $(left)"
# 내가 켠 크롬만 끈다(다른 세션이 켜 둔 것은 그대로)
if (( started )); then
  /usr/bin/python3 -c "
import json,urllib.request,websocket
v=json.load(urllib.request.urlopen('http://127.0.0.1:9226/json/version'))
ws=websocket.create_connection(v['webSocketDebuggerUrl']); ws.send(json.dumps({'id':1,'method':'Browser.close'})); print('크롬 9226 끔')
" 2>/dev/null || ssh macmini4 "pkill -f 'remote-debugging-port=9226'"
fi
pkill -f "ssh -fN -L 9226:127.0.0.1:9226" 2>/dev/null
rm -f /tmp/hu_gemini_resume.pid
