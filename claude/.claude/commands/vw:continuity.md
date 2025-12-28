---
description: Initialize or show the Continuity Ledger
argument-hint: [init|show]
allowed-tools: Read, Write
---

## Command: show (default)

Display full CONTINUITY.md contents. If not exists, suggest `init`.

## Command: init

### Step 1: Create CONTINUITY.md

Use AskUserQuestion to prompt for Goal, then create from template.

### Step 2: Add rule to project CLAUDE.md

**CRITICAL**: Append the Continuity Ledger execution rule to project CLAUDE.md.

Before appending, check if rule already exists:
- Search for "## Continuity Ledger" section
- If exists, skip appending

Rule to append (at END of file):

```markdown

## Continuity Ledger

CONTINUITY.md が存在する場合、毎ターン開始時に continuity-ledger スキルに従って：
1. Ledger を読み込み、現在の状態を把握する
2. 変更があれば CONTINUITY.md を更新する
3. Ledger Snapshot を返答の冒頭に表示する
```

## Note

The init command adds a rule to project CLAUDE.md that ensures
the continuity-ledger SKILL is executed every turn.
