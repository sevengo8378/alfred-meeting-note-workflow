#!/bin/zsh
set -eu

WORKFLOW_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$(mktemp -d /private/tmp/meeting-note-search-print.XXXXXX)"
NOTES_DIR="$TEST_DIR/notes"
FAKE_BIN="$TEST_DIR/bin"
TARGET_FILE="$NOTES_DIR/2026-06-11_产品例会.md"
mkdir -p "$NOTES_DIR" "$FAKE_BIN"

cat > "$TARGET_FILE" <<'EOF'
---
date: "2026-06-11"
title: "产品例会"
source: "Tencent Meeting Yuanbao"
tags:
  - meeting
  - yuanbao
---

# 产品例会

- 讨论了 Q3 预算
- 决定推迟发布
EOF

cat > "$FAKE_BIN/rg" <<'EOF'
#!/bin/zsh
printf '%s\n' "$@" > "$RG_ARGS_CAPTURE"
printf '%s:1:---\n' "$TARGET_FILE"
EOF
chmod +x "$FAKE_BIN/rg"

cat > "$FAKE_BIN/fzf" <<'EOF'
#!/bin/zsh
printf '%s\n' "$@" > "$FZF_ARGS_CAPTURE"
printf '%s:1:---\n' "$TARGET_FILE"
EOF
chmod +x "$FAKE_BIN/fzf"

export PATH="$FAKE_BIN:$PATH"
export MEETING_NOTES_DIR="$NOTES_DIR"
export RG_ARGS_CAPTURE="$TEST_DIR/rg_args"
export FZF_ARGS_CAPTURE="$TEST_DIR/fzf_args"
export TARGET_FILE="$TARGET_FILE"

out="$("$WORKFLOW_DIR/search-meeting-note.sh")"

# 打印了正文
echo "$out" | grep -q -- '- 讨论了 Q3 预算'
echo "$out" | grep -q -- '- 决定推迟发布'
# 剥掉了 front matter
! echo "$out" | grep -q 'title:'
! echo "$out" | grep -q 'source:'
# rg 以全文方式列出 .md 文件
grep -q -- '-g' "$RG_ARGS_CAPTURE"
grep -q -- '--smart-case' "$RG_ARGS_CAPTURE"
grep -q "$NOTES_DIR" "$RG_ARGS_CAPTURE"
