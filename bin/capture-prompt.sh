#!/bin/bash
# capture-prompt.sh
# Fires on UserPromptSubmit. Appends every user prompt to the session log.

SESSION_DIR="/tmp/sessionscribe/${CLAUDE_SESSION_ID:-default}"
mkdir -p "$SESSION_DIR"

PROMPTS_FILE="$SESSION_DIR/prompts.log"
TURN_FILE="$SESSION_DIR/turn_count.txt"

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null)

if [ -z "$PROMPT" ]; then
  exit 0
fi

TURN=0
if [ -f "$TURN_FILE" ]; then
  TURN=$(cat "$TURN_FILE")
fi
echo $((TURN + 1)) > "$TURN_FILE"

echo "[turn:$((TURN + 1))] $PROMPT" >> "$PROMPTS_FILE"

exit 0
