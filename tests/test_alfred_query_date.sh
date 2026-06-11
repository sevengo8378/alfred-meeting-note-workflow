#!/bin/zsh
set -eu

WORKFLOW_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$(mktemp -d /private/tmp/meeting-note-alfred-date-test.XXXXXX)"
EXPECTED_FILE="$TEST_DIR/notes/2026-06-11_产品复盘会.md"

export MEETING_NOTES_DIR="$TEST_DIR/notes"
export MEETING_NOTE_CONTENT=$'# 产品复盘会\n\n- Alfred 日期参数\n'
export MEETING_NOTE_NO_NOTIFY=1

"$WORKFLOW_DIR/save_meeting_note.py" "--date 20260611 产品复盘会" > "$TEST_DIR/output"

test -f "$EXPECTED_FILE"
grep -q 'date: "2026-06-11"' "$EXPECTED_FILE"
grep -q -- '- Alfred 日期参数' "$EXPECTED_FILE"
