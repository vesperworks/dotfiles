---
description: Initialize or show the Continuity Ledger
argument-hint: [init|show]
allowed-tools: Read, Write
---

## Command: show (default)

Display full CONTINUITY.md contents. If not exists, suggest `init`.

## Command: init

Create CONTINUITY.md with the standard format. Prompt for Goal.

## Note

Once CONTINUITY.md exists, the continuity-ledger SKILL handles everything automatically:
- Reads at start of every turn
- Updates when goal/constraints/decisions/state change
- Displays Ledger Snapshot in replies
