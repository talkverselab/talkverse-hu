#!/bin/zsh
# 리뷰 페이지 다시 만들기 — 음성이 있는 시험 편을 앞에, 그 뒤 전편. uk 세션이 게시한다.
cd "$(dirname "$0")/.."
T=(assets/data/dialogues/R1/survival/r1_survival_s1.json assets/data/dialogues/R1/love/r1_love_a1.json assets/data/dialogues/R1/life/r1_life_a1.json assets/data/dialogues/R2/friends/r2_friends_c1.json)
R=(assets/data/dialogues/R*/*/*.json)
python3 tools/review_html.py data/review/REVIEW_hu.html $T ${R:|T}
