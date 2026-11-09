#!/bin/zsh
# 회화 Grok 재작성 회차(PC 크롬 9247, 전문가 모드). 방 하나에 N편 — 첫 메시지만 규칙 첨부, 이후 파일 이름 한 줄.
#   zsh tools/grok_rewrite_run.sh <편id>...      결과 data/review/grok/out/<id>.md, 로그 data/review/grok/run.log
cd "$(dirname "$0")/.."
export GROK_CDP_PORT=9247
chat=""
for id in "$@"; do
  out=data/review/grok/out/$id.md
  [[ -s $out || -e ${out%.md}.timeout ]] && { echo "skip $id"; continue; }
  if [[ -z $chat ]]; then
    print -r -- "첨부한 rewrite_grok_hu.md 가 이 방의 규칙이다. 앞으로는 파일 이름 한 줄만 보낸다. 첫 편: $id.txt" > /tmp/grok_hu_first.txt
    r=$(python3 tools/grok_text.py /tmp/grok_hu_first.txt $out tools/prompts/rewrite_grok_hu.md data/review/grok/src/$id.txt 2>&1)
  else
    r=$(python3 tools/grok_text.py -m "$id.txt" $out data/review/grok/src/$id.txt --chat "$chat" 2>&1)
  fi
  rc=$?
  echo "$(date +%H:%M) $id rc=$rc $(echo $r | grep -E "저장|LIMIT|전문가|TIMEOUT" | tr '\n' ' ')"
  [[ $rc -eq 3 ]] && { echo "LIMIT — 멈춤"; exit 3; }
  c=$(echo $r | grep '^CHAT ' | awk '{print $2}' | sed 's/?.*//'); [[ -n $c ]] && chat=$c
  sleep 20
done
echo "끝 $chat"
