---
description: Memory↔TaskList同期（完了タスク→メモリー反映、メモリー→タスク生成）
allowed-tools: Read, Edit, Write, Glob, TaskCreate, TaskList, TaskGet, TaskUpdate, AskUserQuestion
---

Use Skill `sync` to execute the Memory ↔ TaskList synchronization workflow.

Sync between:
- **Memory**: `~/.claude/projects/{project-slug}/memory/MEMORY.md` (auto-memory)
- **TaskList**: Claude Code TaskCreate/TaskList/TaskUpdate

Steps:
1. Read current MEMORY.md and TaskList state in parallel
2. Detect diffs (completed tasks not in memory, memory items not in tasks)
3. Auto-sync (ask user only on conflicts)
4. Output sync report
