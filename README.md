# SessionScribe

A Claude Code plugin that automatically generates a clean, human-readable summary at the end of every session — what you asked for, what files changed, and what commands ran.

## Why

Long Claude Code sessions are hard to remember. SessionScribe gives you a permanent, readable record of every session: useful for async team handoffs, your own git commit messages, or just knowing what happened last Tuesday.

## What it generates

At the end of each session, SessionScribe saves a markdown file to `~/.sessionscribe/logs/` that looks like this:

```markdown
## Session Summary — 2026-06-08 14:32

**What was worked on:** Added authentication middleware and updated related route handlers.

**Requests:**
- Add JWT verification middleware to protected routes
- Update user profile endpoint to use new middleware
- Fix token expiry handling in auth utils

**Changes made:**
- src/middleware/auth.js (created)
- src/routes/user.js (modified)
- src/utils/token.js (modified)
- src/routes/index.js (modified)

**Notes:** Token refresh logic was left incomplete — user noted they'd handle this manually. Tests not updated yet.
```

## Requirements

- Claude Code (Pro plan or above)
- `jq` installed (`brew install jq` / `sudo apt install jq`)
- `ANTHROPIC_API_KEY` set in your environment

Summaries use `claude-haiku` — cheapest model, fires once per session. Cost is negligible.

## Installation

Add to `~/.claude/settings.json` under the `"hooks"` key (see hooks.json for the full config), or install via:

```bash
git clone https://github.com/OrMizL/sessionscribe
claude --plugin-dir ./sessionscribe
```

## Setup

```bash
# 1. Clone the repo
git clone https://github.com/OrMizL/sessionscribe
cd sessionscribe

# 2. Make scripts executable
chmod +x bin/*.sh

# 3. Add your API key if not already set
echo 'export ANTHROPIC_API_KEY=sk-ant-...' >> ~/.bashrc
source ~/.bashrc

# 4. Wire up the hooks in ~/.claude/settings.json
# Copy the contents of hooks.json into your existing hooks config
```

## Viewing your logs

```bash
# List all session logs
ls ~/.sessionscribe/logs/

# View the most recent
cat $(ls ~/.sessionscribe/logs/ | tail -1)

# Search across all logs
grep -r "auth" ~/.sessionscribe/logs/
```

## How it works

| Hook | What it does |
|------|-------------|
| `UserPromptSubmit` | Logs every prompt you send with its turn number |
| `PostToolUse` | Logs every file write, edit, and bash command |
| `Stop` | At session end, sends everything to Claude Haiku and generates a markdown summary |

## License

MIT
