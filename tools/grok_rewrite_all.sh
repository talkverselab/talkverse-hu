#!/bin/zsh
# 남은 편을 3편씩 방을 새로 열어 차례로(한도 문구가 나오면 멈춤). 로그 data/review/grok/run.log
cd "$(dirname "$0")/.."
ids=($(ls data/review/grok/src | sed 's/.txt$//' | sort))
todo=(); for i in $ids; do [[ -s data/review/grok/out/$i.md ]] || todo+=$i; done
echo "남은 편 ${#todo}"
for ((k = 1; k <= ${#todo}; k += 3)); do
  zsh tools/grok_rewrite_run.sh ${todo[k,k+2]} || { echo "멈춤(한도 등)"; exit 3; }
done
echo "전부 끝"
