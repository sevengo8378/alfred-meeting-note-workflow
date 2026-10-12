#!/bin/zsh
set -eu

WORKFLOW_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$(mktemp -d /private/tmp/meeting-note-search-query.XXXXXX)"
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
printf '%s\n' "$@" > "$FZF_ARGS_CAPTURE"
printf '%s:1:---\n' "$TARGET_FILE"
EOF
chmod +x "$FAKE_BIN/fzf"

export PATH="$FAKE_BIN:$PATH"
export MEETING_NOTES_DIR="$NOTES_DIR"
export TARGET_FILE="$TARGET_FILE"
export FZF_ARGS_CAPTURE="$TEST_DIR/fzf_args"

"$WORKFLOW_DIR/search-meeting-note.sh" 复盘 > /dev/null

# 初始关键词作为 fzf 的 --query 传入
grep -q -- '--query' "$FZF_ARGS_CAPTURE"
grep -q '复盘' "$FZF_ARGS_CAPTURE"
