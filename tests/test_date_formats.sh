#!/bin/zsh
set -eu

WORKFLOW_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$(mktemp -d /private/tmp/meeting-note-date-formats-test.XXXXXX)"

export MEETING_NOTES_DIR="$TEST_DIR/notes"
export MEETING_NOTE_NO_NOTIFY=1

formats=("20260611" "2026-06-11" "2026/6/11" "2026.6.11" "2026年6月11日")
index=1
for note_date in "${formats[@]}"; do
  title="日期格式测试${index}"
  export MEETING_NOTE_CONTENT="# ${title}\n\n- 内容\n"
  "$WORKFLOW_DIR/save_meeting_note.py" --date "$note_date" "$title" > "$TEST_DIR/output-${index}"
  expected_file="$TEST_DIR/notes/2026-06-11_${title}.md"
  test -f "$expected_file"
  grep -q 'date: "2026-06-11"' "$expected_file"
  index=$((index + 1))
done
