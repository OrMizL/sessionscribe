# SessionScribe

A Claude Code plugin that automatically generates a clean, human-readable summary of every session — what you asked for, what files changed, and what commands ran. Saved as markdown, permanently, so you never lose track of what happened.

## What it generates

At the end of each session, SessionScribe saves a markdown file to `~/.sessionscribe/logs/`:

```markdown
## Session Summary — 2026-06-08

**What was worked on:** Added authentication middleware and updated related route handlers.

**Requests:**
- Add JWT verification middleware to protected routes
- Update user profile endpoint to use new middleware
- Fix token expiry handling in auth utils

**Changes made:**
- src/middleware/auth.js (created)
- src/routes/user.js (modified)
- src/utils/token.js (modified)

**Notes:** Token refresh logic was left incomplete — user noted they'd handle this manually. Tests not updated yet.
```

## Requirements

- Claude Code (Pro plan or above)
- `jq` installed (`brew install jq` / `sudo apt install jq`)
- An `ANTHROPIC_API_KEY` set in your environment

Summaries use `claude-haiku` — cheapest model, fires once per session. Cost is negligible (fractions of a cent).

## Installation

### 1. Clone the repo

```bash
git clone https://github.com/OrMizL/sessionscribe
cd sessionscribe
chmod +x bin/*.sh
```

### 2. Add your Anthropic API key

SessionScribe needs your API key to generate summaries. Add it to `~/.profile` (not `.bashrc` — Claude Code runs non-interactive shells):

```bash
echo 'export ANTHROPIC_API_KEY=your-key-here' >> ~/.profile
source ~/.profile
```

Get your key at console.anthropic.com.

### 3. Wire up the hooks

Add the following to your `~/.claude/settings.json` under a `"hooks"` key. If you don't have a `settings.json` yet, create one at `~/.claude/settings.json`.

Replace `/path/to/sessionscribe` with the actual path where you cloned the repo (e.g. `/home/your-username/sessionscribe`):

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/sessionscribe/bin/capture-prompt.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/sessionscribe/bin/watch-tools.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "/path/to/sessionscribe/bin/summarize-session.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

### 4. Start a session

```bash
ANTHROPIC_API_KEY=your-key claude
```

> **Note:** Pass your API key explicitly when starting Claude Code. This ensures hook scripts can access it, since Claude Code runs hooks in non-interactive subshells.

Do some work, then `/exit`. Your summary will be saved automatically.

## Viewing your logs

```bash
# View the most recent summary
cat ~/.sessionscribe/logs/$(ls ~/.sessionscribe/logs/ | tail -1)

# List all session logs
ls ~/.sessionscribe/logs/

# Search across all logs
grep -r "auth" ~/.sessionscribe/logs/
```

### Optional: add a convenience alias

```bash
echo "alias scribe='cat \$(ls ~/.sessionscribe/logs/ | tail -1 | xargs -I{} echo ~/.sessionscribe/logs/{})'" >> ~/.profile
source ~/.profile
```

Then just run `scribe` after any session to see the latest summary.

## How it works

| Hook | What it does |
|------|-------------|
| `UserPromptSubmit` | Logs every prompt you send with its turn number |
| `PostToolUse` | Logs every file write, edit, and bash command |
| `Stop` | At session end, sends everything to Claude Haiku and generates a markdown summary |

## Known limitations

- Claude Code swallows hook terminal output, so the summary doesn't print inline — it saves to `~/.sessionscribe/logs/` only
- Hooks run in non-interactive subshells, so your API key must be in `~/.profile` or passed explicitly via `ANTHROPIC_API_KEY=your-key claude`

## License

MIT