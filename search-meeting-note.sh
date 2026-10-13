#!/bin/zsh
set -eu

WORKFLOW_DIR="$(cd "$(dirname "$0")" && pwd)"
NOTES_DIR="${MEETING_NOTES_DIR:-$HOME/Documents/meeting_notes}"
INITIAL_QUERY="$*"

if [[ ! -d "$NOTES_DIR" ]]; then
  echo "会议纪要目录不存在：$NOTES_DIR" >&2
  exit 1
fi

list_script="$WORKFLOW_DIR/search-list.sh"

# 左侧只显示文件名，输入时由 search-list.sh 实时全文搜索（标题命中优先）；
# 右侧预览：有查询词时高亮显示匹配行，无查询词时显示正文。
selection="$(
  "$list_script" "$INITIAL_QUERY" \
    | fzf \
        --query "$INITIAL_QUERY" \
        --disabled \
        --delimiter '/' \
        --with-nth '-1' \
        --bind "change:reload:$list_script {q} || true" \
        --preview 'f={}; if [ -n {q} ]; then rg --pretty --smart-case -F -C 3 -- {q} "$f"; else sed "1,/^---$/d" "$f" | head -200; fi' \
        --preview-window 'right:60%:wrap'
)"

if [[ -z "$selection" ]]; then
  exit 0
fi

if [[ ! -f "$selection" ]]; then
  echo "无法定位纪要文件：$selection" >&2
  exit 1
fi

# 回车后打印正文（剥掉 front matter）
sed '1,/^---$/d' "$selection"
