#!/bin/zsh
set -eu

WORKFLOW_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$(mktemp -d /private/tmp/meeting-note-search-list.XXXXXX)"
NOTES_DIR="$TEST_DIR/notes"
mkdir -p "$NOTES_DIR"

cat > "$NOTES_DIR/2026-06-11_产品例会.md" <<'EOF'
---
title: "产品例会"
---

# 产品例会

- 讨论产品规划
EOF
touch -t 202606110900 "$NOTES_DIR/2026-06-11_产品例会.md"

cat > "$NOTES_DIR/2026-06-12_周会.md" <<'EOF'
---
title: "周会"
---

# 周会

- 讨论产品发布计划
EOF
touch -t 202606120900 "$NOTES_DIR/2026-06-12_周会.md"

export MEETING_NOTES_DIR="$NOTES_DIR"

# 无 query：列出所有 .md，按修改时间由近到远（周会较新，排前）
all="$("$WORKFLOW_DIR/search-list.sh")"
echo "$all" | grep -q '产品例会'
echo "$all" | grep -q '周会'
first_all="$(echo "$all" | head -n 1)"
echo "$first_all" | grep -q '周会'

# 标题命中：文件名含"产品"
title_hit="$("$WORKFLOW_DIR/search-list.sh" 产品)"
echo "$title_hit" | grep -q '产品例会'

# 正文命中：文件名不含"发布"，正文含"发布"
body_hit="$("$WORKFLOW_DIR/search-list.sh" 发布)"
echo "$body_hit" | grep -q '周会'

# 标题命中排在正文命中前
ordered="$("$WORKFLOW_DIR/search-list.sh" 产品)"
first="$(echo "$ordered" | head -n 1)"
echo "$first" | grep -q '产品例会'
