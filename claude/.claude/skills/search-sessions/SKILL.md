---
name: search-sessions
description: Search across Claude Code session history. Use when you need to find past conversations, decisions, code snippets, or resume previous sessions. Triggers on "remember", "previous session", "we discussed", "last time", "find conversation", "session history".
---

# Search Sessions

Search across all past Claude Code session history using `search-sessions` CLI.

## Modes

- **Index search (default)**: Searches session metadata (summary, firstPrompt, projectPath, gitBranch). Near-instant (~18ms).
- **Deep search (`--deep`)**: Searches actual message text via ripgrep. Sub-second (~280ms).

## Usage

```bash
# Basic search
search-sessions "query terms"

# Full message content search
search-sessions "query" --deep

# Filter by project
search-sessions "query" --project myapp

# Filter by date
search-sessions "query" --since "yesterday"
search-sessions "query" --date "2026-03-28"

# Limit results
search-sessions "query" --limit 5
```

## When to Use

- User asks about a previous conversation or decision
- Need to find context from a past session
- Looking for code snippets or approaches discussed earlier
- User says "remember when we...", "last time we...", "find that session where..."

## Output

Results include session ID, project path, date, summary, and first prompt. Use the session ID with `claude --resume <id>` to resume.

## Strategy

1. Start with index search (fast, metadata only)
2. If no results, suggest `--deep` for full content search
3. If too many results, add `--project` or `--since` filters
