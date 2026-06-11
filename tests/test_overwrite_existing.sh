#!/bin/zsh
set -eu

WORKFLOW_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$(mktemp -d /private/tmp/meeting-note-overwrite-test.XXXXXX)"
DATE_STR="$(date +%F)"
EXPECTED_FILE="$TEST_DIR/notes/${DATE_STR}_产品复盘会.md"

mkdir -p "$TEST_DIR/notes"
printf '旧内容\n' > "$EXPECTED_FILE"

export MEETING_NOTES_DIR="$TEST_DIR/notes"
export MEETING_NOTE_CONTENT=$'# 产品复盘会\n\n- 新内容\n'
export MEETING_NOTE_NO_NOTIFY=1
export MEETING_NOTE_EXISTING=overwrite

"$WORKFLOW_DIR/save_meeting_note.py" 产品复盘会 > "$TEST_DIR/output"

test -f "$EXPECTED_FILE"
grep -q -- '- 新内容' "$EXPECTED_FILE"
! grep -q '旧内容' "$EXPECTED_FILE"
test ! -f "$TEST_DIR/notes/${DATE_STR}_产品复盘会-2.md"
grep -q "已保存到 $EXPECTED_FILE" "$TEST_DIR/output"
