#!/bin/zsh
set -eu

# 用法：search-list.sh [query]
# 输出会议纪要文件路径（每行一个），供 fzf 使用：
#   - 无 query 时列出全部 .md 文件
#   - 有 query 时全文搜索，文件名命中（标题优先）的排在正文命中之前
#   - 同一优先级内按文件修改时间由近到远排序

NOTES_DIR="${MEETING_NOTES_DIR:-$HOME/Documents/meeting_notes}"
q="${1:-}"

if [[ ! -d "$NOTES_DIR" ]]; then
  exit 0
fi

rg -l --smart-case -F -- "$q" "$NOTES_DIR" -g '*.md' 2>/dev/null \
  | while IFS= read -r f; do
      mtime="$(stat -f '%m' "$f" 2>/dev/null || printf '0')"
      name="${f:t}"
      name="${name%.md}"
      if [[ -n "$q" && "$name" == *"$q"* ]]; then
        pri=0
      else
        pri=1
      fi
      printf '%s\t%s\t%s\n' "$pri" "$mtime" "$f"
    done \
  | sort -t $'\t' -k1,1n -k2,2nr \
  | cut -f3-
