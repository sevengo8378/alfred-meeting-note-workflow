#!/bin/zsh
set -eu

WORKFLOW_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$(mktemp -d /private/tmp/meeting-note-search-dispatch.XXXXXX)"
NOTES_DIR="$TEST_DIR/notes"
FAKE_BIN="$TEST_DIR/bin"
TARGET_FILE="$NOTES_DIR/2026-06-11_产品例会.md"
mkdir -p "$NOTES_DIR" "$FAKE_BIN"

cat > "$TARGET_FILE" <<'EOF'
---
date: "2026-06-11"
title: "产品例会"
---

# 产品例会

- 讨论了 Q3 预算
EOF

cat > "$FAKE_BIN/rg" <<'EOF'
#!/bin/zsh
printf '%s:1:---\n' "$TARGET_FILE"
EOF
chmod +x "$FAKE_BIN/rg"

cat > "$FAKE_BIN/fzf" <<'EOF'
#!/bin/zsh
printf '%s:1:---\n' "$TARGET_FILE"
EOF
chmod +x "$FAKE_BIN/fzf"

export PATH="$FAKE_BIN:$PATH"
export MEETING_NOTES_DIR="$NOTES_DIR"
export TARGET_FILE="$TARGET_FILE"
export MEETING_NOTE_NO_NOTIFY=1
export MEETING_NOTE_CONTENT=$'# 无关内容\n'

before="$(ls "$NOTES_DIR")"
out="$("$WORKFLOW_DIR/meeting-note-fzf.sh" search)"

# 走了搜索：打印了已有纪要的正文
echo "$out" | grep -q -- '- 讨论了 Q3 预算'
# 未走保存：目录没有新增文件
after="$(ls "$NOTES_DIR")"
[[ "$before" == "$after" ]]
