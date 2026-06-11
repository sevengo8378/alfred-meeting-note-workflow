#!/bin/zsh
set -eu

WORKFLOW_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$(mktemp -d /private/tmp/meeting-note-fzf-test.XXXXXX)"
FAKE_BIN="$TEST_DIR/bin"
mkdir -p "$FAKE_BIN"

cat > "$FAKE_BIN/fzf" <<'EOF'
#!/bin/zsh
cat > "$FZF_INPUT_CAPTURE"
printf '产品复盘会\n'
EOF
chmod +x "$FAKE_BIN/fzf"

export PATH="$FAKE_BIN:$PATH"
export MEETING_NOTES_DIR="$TEST_DIR/notes"
export MEETING_TITLE_HISTORY="$TEST_DIR/title_history"
export MEETING_NOTE_CONTENT=$'# 产品复盘会\n\n- 结论一\n- 待办二\n'
export MEETING_NOTE_NO_NOTIFY=1
export FZF_INPUT_CAPTURE="$TEST_DIR/fzf_input"

printf '产品复盘会\n' > "$MEETING_TITLE_HISTORY"
"$WORKFLOW_DIR/meeting-note-fzf.sh" > "$TEST_DIR/output"

DATE_STR="$(date +%F)"
EXPECTED_FILE="$TEST_DIR/notes/${DATE_STR}_产品复盘会.md"

test -f "$EXPECTED_FILE"
grep -q 'title: "产品复盘会"' "$EXPECTED_FILE"
grep -q -- '- 待办二' "$EXPECTED_FILE"
grep -q '产品复盘会' "$MEETING_TITLE_HISTORY"
grep -q '产品复盘会' "$FZF_INPUT_CAPTURE"
grep -q "已保存到" "$TEST_DIR/output"
grep -q "纪要内容" "$TEST_DIR/output"
grep -q -- '- 待办二' "$TEST_DIR/output"
