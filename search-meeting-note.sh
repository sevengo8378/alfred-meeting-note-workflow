#!/bin/zsh
set -eu

NOTES_DIR="${MEETING_NOTES_DIR:-$HOME/Documents/meeting_notes}"
INITIAL_QUERY="$*"

if [[ ! -d "$NOTES_DIR" ]]; then
  echo "会议纪要目录不存在：$NOTES_DIR" >&2
  exit 1
fi

# fzf 预览窗：从选中行（路径:行号:内容）取路径，剥掉 front matter 显示正文
fzf_preview='file="{1}"; if [ -f "$file" ]; then sed "1,/^---$/d" "$file" | head -200; fi'
fzf_args=(
  --ansi
  --query "$INITIAL_QUERY"
  --delimiter ':'
  --preview "$fzf_preview"
  --preview-window 'right:60%:wrap'
)

# 用 ripgrep 逐行列出目录下所有纪要（含标题和正文），交给 fzf 实时过滤；
# 未安装 rg 时降级为 grep。
if command -v rg >/dev/null 2>&1; then
  selection="$(rg --no-heading --line-number --color=always --smart-case '' "$NOTES_DIR" -g '*.md' | fzf "${fzf_args[@]}" || true)"
else
  selection="$(grep -rn --color=always '' "$NOTES_DIR" --include='*.md' | fzf "${fzf_args[@]}" || true)"
fi

if [[ -z "$selection" ]]; then
  exit 0
fi

file="${selection%%:*}"
if [[ ! -f "$file" ]]; then
  echo "无法定位纪要文件：$file" >&2
  exit 1
fi

# 回车后打印正文（剥掉 front matter）
sed '1,/^---$/d' "$file"
