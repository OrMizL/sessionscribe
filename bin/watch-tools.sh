#!/bin/bash
# watch-tools.sh
# Fires on PostToolUse. Logs every file write, edit, and bash command.

SESSION_DIR="/tmp/sessionscribe/${CLAUDE_SESSION_ID:-default}"
mkdir -p "$SESSION_DIR"

ACTIVITY_LOG="$SESSION_DIR/activity.log"
TURN_FILE="$SESSION_DIR/turn_count.txt"
TURN=$(cat "$TURN_FILE" 2>/dev/null || echo "?")

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

case "$TOOL" in
  Write|Edit|MultiEdit)
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
    if [ -n "$FILE_PATH" ]; then
      echo "[turn:$TURN] $TOOL $FILE_PATH" >> "$ACTIVITY_LOG"
    fi
    ;;
  Bash)
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
    if [ -n "$COMMAND" ]; then
      echo "[turn:$TURN] Bash: ${COMMAND:0:120}" >> "$ACTIVITY_LOG"
    fi
    ;;
esac

exit 0
