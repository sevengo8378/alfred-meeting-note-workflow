#!/bin/zsh
set -eu

WORKFLOW_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ "${1:-}" == "search" ]]; then
  shift
  exec "$WORKFLOW_DIR/search-meeting-note.sh" "$@"
fi

NOTES_DIR="${MEETING_NOTES_DIR:-$HOME/Documents/meeting_notes}"
TITLE_HISTORY="${MEETING_TITLE_HISTORY:-$NOTES_DIR/.title_history}"
AUTO_TITLE_LABEL="从 Markdown 自动识别标题"

mkdir -p "$NOTES_DIR"
touch "$TITLE_HISTORY"

choose_title_with_fzf() {
  {
    printf '%s\n' "$AUTO_TITLE_LABEL"
    grep -v '^[[:space:]]*$' "$TITLE_HISTORY" 2>/dev/null | awk '!seen[$0]++'
  } | fzf --print-query --prompt="会议主题 > " --height=40% --reverse | tail -n 1
}

choose_title_with_read() {
  printf '会议主题（留空则尝试从 Markdown 自动识别）：'
  read -r title
  printf '%s\n' "$title"
}

title=""
save_args=()
record_history=0

if [[ "$#" -gt 0 ]]; then
  save_args=("$@")
  title="${*:-}"
else
  if command -v fzf >/dev/null 2>&1; then
    title="$(choose_title_with_fzf || true)"
  else
    title="$(choose_title_with_read)"
  fi
  save_args=("$title")
  record_history=1
fi

if [[ "$title" == "$AUTO_TITLE_LABEL" ]]; then
  title=""
  save_args=()
fi

MEETING_NOTES_DIR="$NOTES_DIR" "$WORKFLOW_DIR/save_meeting_note.py" "${save_args[@]}"

if [[ "$record_history" -eq 1 && -n "$title" ]]; then
  printf '%s\n' "$title" >> "$TITLE_HISTORY"
fi
