#!/bin/zsh
set -eu

WORKFLOW_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if grep -q 'output="$(MEETING_NOTES_DIR=.*save_meeting_note.py' "$WORKFLOW_DIR/meeting-note-fzf.sh"; then
  echo "meeting-note-fzf.sh captures save_meeting_note.py output, which hides interactive prompts."
  exit 1
fi

grep -q 'save_meeting_note.py" "${save_args\[@\]}"' "$WORKFLOW_DIR/meeting-note-fzf.sh"
