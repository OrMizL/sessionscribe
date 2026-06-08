#!/bin/bash
# summarize-session.sh
# Fires on Stop at the end of the final turn. Reads all prompts and activity,
# calls Claude Haiku to generate a clean session summary, and saves it to
# ~/.sessionscribe/logs/ as a markdown file.

SESSION_DIR="/tmp/sessionscribe/${CLAUDE_SESSION_ID:-default}"
PROMPTS_FILE="$SESSION_DIR/prompts.log"
ACTIVITY_LOG="$SESSION_DIR/activity.log"
TURN_FILE="$SESSION_DIR/turn_count.txt"

# Only summarize at session end — check if this is the last Stop
# We summarize after at least 1 turn
TURN=$(cat "$TURN_FILE" 2>/dev/null || echo "0")
if [ "$TURN" -eq 0 ]; then
  exit 0
fi

# Skip if nothing was logged
if [ ! -s "$PROMPTS_FILE" ] && [ ! -s "$ACTIVITY_LOG" ]; then
  exit 0
fi

# Need API key
if [ -z "$ANTHROPIC_API_KEY" ]; then
  exit 0
fi

PROMPTS=$(cat "$PROMPTS_FILE" 2>/dev/null || echo "No prompts recorded.")
ACTIVITY=$(cat "$ACTIVITY_LOG" 2>/dev/null || echo "No file activity recorded.")
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
DATE_SLUG=$(date '+%Y-%m-%d_%H-%M-%S')

PAYLOAD=$(jq -n \
  --arg prompts "$PROMPTS" \
  --arg activity "$ACTIVITY" \
  --arg timestamp "$TIMESTAMP" \
  '{
    model: "claude-haiku-4-5-20251001",
    max_tokens: 800,
    system: "You generate concise session summaries for Claude Code sessions. Given a list of user prompts and file/command activity, produce a clean markdown summary. Format:\n\n## Session Summary — {date}\n\n**What was worked on:** one sentence overview\n\n**Requests:**\n- bullet list of what the user asked for, grouped logically\n\n**Changes made:**\n- bullet list of files modified or created\n- bullet list of notable commands run (skip trivial ones like ls, cat)\n\n**Notes:** any observations about the session worth remembering (e.g. incomplete tasks, decisions made, next steps implied)\n\nBe concise. Skip filler. No preamble.",
    messages: [
      {
        role: "user",
        content: ("Timestamp: " + $timestamp + "\n\nUser prompts:\n" + $prompts + "\n\nFile and command activity:\n" + $activity)
      }
    ]
  }')

RESPONSE=$(curl -s \
  -X POST \
  -H "Content-Type: application/json" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d "$PAYLOAD" \
  "https://api.anthropic.com/v1/messages" 2>/dev/null)

SUMMARY=$(echo "$RESPONSE" | jq -r '.content[0].text // empty' 2>/dev/null)

if [ -z "$SUMMARY" ]; then
  exit 0
fi

# Save to ~/.sessionscribe/logs/
LOG_DIR="$HOME/.sessionscribe/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/${DATE_SLUG}.md"

echo "$SUMMARY" > "$LOG_FILE"

# Also print to session so user sees it
echo ""
echo "─────────────────────────────────────"
echo "📝 SessionScribe — session summary saved"
echo "   $LOG_FILE"
echo "─────────────────────────────────────"
echo ""
echo "$SUMMARY"

# Clean up temp files for this session
rm -rf "$SESSION_DIR"

exit 0
