#!/bin/zsh
set -eu

WORKFLOW_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$(mktemp -d /private/tmp/meeting-note-merge-test.XXXXXX)"
DATE_STR="$(date +%F)"
EXPECTED_FILE="$TEST_DIR/notes/${DATE_STR}_产品复盘会.md"
FAKE_CLAUDE="$TEST_DIR/fake-claude"

mkdir -p "$TEST_DIR/notes"
cat > "$EXPECTED_FILE" <<'EOF'
---
date: "2026-06-12"
title: "产品复盘会"
source: "Tencent Meeting Yuanbao"
created_at: "2026-06-12 10:00:00"
tags:
  - meeting
  - yuanbao
---

# 产品复盘会

- 第一段已有内容
EOF

cat > "$FAKE_CLAUDE" <<'EOF'
#!/bin/zsh
cat > "$FAKE_CLAUDE_PROMPT_CAPTURE"
cat <<'MERGED'
# 产品复盘会

- 第一段已有内容
- 第二段新增内容
MERGED
EOF
chmod +x "$FAKE_CLAUDE"

export MEETING_NOTES_DIR="$TEST_DIR/notes"
export MEETING_NOTE_CONTENT=$'# 产品复盘会\n\n- 第二段新增内容\n'
export MEETING_NOTE_NO_NOTIFY=1
export MEETING_NOTE_EXISTING=merge
export MEETING_NOTE_MERGE_COMMAND="$FAKE_CLAUDE"
export FAKE_CLAUDE_PROMPT_CAPTURE="$TEST_DIR/claude_prompt"

"$WORKFLOW_DIR/save_meeting_note.py" 产品复盘会 > "$TEST_DIR/output"

test -f "$EXPECTED_FILE"
grep -q 'title: "产品复盘会"' "$EXPECTED_FILE"
grep -q -- '- 第一段已有内容' "$EXPECTED_FILE"
grep -q -- '- 第二段新增内容' "$EXPECTED_FILE"
grep -q '已有纪要' "$FAKE_CLAUDE_PROMPT_CAPTURE"
grep -q '新增纪要' "$FAKE_CLAUDE_PROMPT_CAPTURE"
test ! -f "$TEST_DIR/notes/${DATE_STR}_产品复盘会-2.md"
grep -q "已保存到 $EXPECTED_FILE" "$TEST_DIR/output"
