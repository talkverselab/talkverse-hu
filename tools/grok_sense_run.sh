#!/bin/zsh
# 언어감각 외울 대화 Grok 작성(PC 크롬 9247, 빠른 모드, 사용자 지시 2026-11-22). 방 하나에 10급.
#   python3 tools/sense_course_hu.py --export && zsh tools/grok_sense_run.sh [L1 ...]
#   결과 data/review/grok/sense_out/<급>.md → python3 tools/sense_course_hu.py → script_publish.py --publish
cd "$(dirname "$0")/.."
export GROK_CDP_PORT=9247
mkdir -p data/review/grok/sense_out
ids=(${@:-L1 L2 L3 L4 L5 L6 L7 L8 L9 L10})
chat=""
for id in $ids; do
  out=data/review/grok/sense_out/$id.md
  [[ -s $out ]] && { echo "skip $id"; continue; }
  if [[ -z $chat ]]; then
    print -r -- "첨부한 sense_grok_hu.md 가 이 방의 규칙이다. 앞으로는 파일 이름 한 줄만 보낸다. 첫 급: $id.txt" > /tmp/grok_hu_sense_first.txt
    r=$(python3 tools/grok_text.py /tmp/grok_hu_sense_first.txt $out tools/prompts/sense_grok_hu.md data/review/grok/sense_src/$id.txt 2>&1)
  else
    r=$(python3 tools/grok_text.py -m "$id.txt" $out data/review/grok/sense_src/$id.txt --chat "$chat" 2>&1)
  fi
  rc=$?
  echo "$(date +%H:%M) sense $id rc=$rc $(echo $r | grep -E "저장|LIMIT|빠른|TIMEOUT" | tr '\n' ' ')"
  [[ $rc -eq 3 ]] && { echo "LIMIT — 멈춤"; exit 3; }
  c=$(echo $r | grep '^CHAT ' | awk '{print $2}' | sed 's/?.*//'); [[ -n $c ]] && chat=$c
  sleep 20
done
echo "끝 $chat"
