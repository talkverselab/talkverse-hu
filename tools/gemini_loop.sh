#!/bin/zsh
# Gemini 검수 목록을 끝까지(한도에 걸리면 10분씩 기다렸다 모델을 다시 골라 이어감). 이미 저장된 편은 건너뜀.
#   zsh tools/gemini_loop.sh <목록.tsv>   로그 data/review/gemini_run.log
cd "$(dirname "$0")/.."
export GEMINI_CDP_PORT=${GEMINI_CDP_PORT:-9226}
for round in {1..60}; do
  todo=$(mktemp); while IFS=$'\t' read -r p d; do [[ -s $d ]] || print -r -- "$p	$d"; done < $1 > $todo
  n=$(wc -l < $todo | tr -d ' '); echo "$(date +%H:%M) 남은 $n"
  [[ $n -eq 0 ]] && { echo "전부 끝"; exit 0; }
  r=$(/usr/bin/python3 tools/gemini_pick.py); echo "$(date +%H:%M) $r"
  if [[ $r == PICKED* ]]; then
    /usr/bin/python3 tools/gemini_batch.py $todo -j 1 --gap 60
    grep -q BLOCKED <(tail -3 data/review/gemini_run.log) && { echo "BLOCKED — 멈춤"; exit 5; }
  fi
  sleep 600
done
