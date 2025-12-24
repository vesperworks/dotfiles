---
name: continuity-ledger
description: This skill should be used when the user asks to "continue from last session", "what did we do last time", "resume work", "where were we", "前回の続き", "どこまでやった", or when starting a multi-step workflow that requires state tracking across sessions. Provides session state persistence to survive context compression in long sessions.
version: 0.1.0
---

# Continuity Ledger

## Core Purpose

Persist critical project state (goals, decisions, constraints, working context) across sessions to survive Claude Code's automatic context compression. Separates long-term state persistence from short-term task tracking (TodoWrite).

**Key Distinction**:
- **TodoWrite**: Short-term tasks (< 1 day), in-session tracking
- **Continuity Ledger**: Long-term state, cross-session persistence, decisions & constraints

## Quick Checklist (初期応答で必ず確認)

1. CONTINUITY.md ファイルが存在するか確認
2. 存在する場合: YAML frontmatter を読み込み、最終更新日時を確認
3. 存在しない場合: ユーザーに初期化を提案
4. Goal/Constraints/Decisions セクションを簡潔に要約
5. UNCONFIRMED セクションの項目があれば確認を促す
6. 現在のセッションの作業コンテキストを State セクションに反映

## Basic Workflow

### Step 1: State Detection (Fast-Path Exit)

```
IF CONTINUITY.md does not exist:
  IF user explicitly requested continuity:
    Offer to initialize CONTINUITY.md from template
  ELSE:
    Exit (skill not applicable)
```

### Step 2: State Loading

Read CONTINUITY.md and parse:
- YAML frontmatter (last_updated, session_id, phase, confidence)
- Goal section (primary objective)
- Constraints section (technical/organizational/time)
- Decisions section (with timestamps)
- State section (current phase, progress)
- Working Set section (active files)
- UNCONFIRMED section (assumptions requiring verification)

### Step 3: State Presentation

Summarize loaded state to user:
```
## Session Continuity Loaded

**Goal**: [Primary objective]
**Phase**: [Current phase] (X% progress)
**Last Updated**: [timestamp]

### Key Decisions
- [Most recent 3-5 decisions]

### Active Working Set
- [Currently relevant files]

### Requires Confirmation (UNCONFIRMED)
- [ ] [Items needing verification]
```

### Step 4: State Update

At significant checkpoints:
1. Update State section with current progress
2. Add new Decisions with timestamps
3. Move confirmed items from UNCONFIRMED
4. Update Working Set if files changed
5. Write atomically (temp file → move)

## Trigger Phrases

This skill activates on:
- "continue from last session" / "前回の続き"
- "what did we do last time" / "どこまでやった"
- "resume work" / "作業を再開"
- "where were we" / "どこまで進んだ"
- Multi-step workflow initiation requiring state persistence

## State File Structure (CONTINUITY.md)

```markdown
---
last_updated: "2025-12-24T15:30:00+09:00"
session_id: "abc123"
phase: "Implementation"
confidence: "high"
---

# Goal
[Primary objective in 1-2 sentences]

# Constraints
- Technical: [...]
- Organizational: [...]
- Time: [...]

# Decisions
- [2025-12-24] Decision description with rationale
- [2025-12-23] Earlier decision...

# State
Current Phase: [phase name]
Progress: [percentage or milestone]
Next Steps: [immediate next actions]

# Working Set
Active Files:
- path/to/file1.md
- path/to/file2.ts

Related PRPs:
- PRPs/PRP-XXX-name.md

# UNCONFIRMED
- [ ] Assumption that needs verification
- [ ] Another uncertain item
```

## Rollback / Recovery (状態破損時)

1. **Corruption Detection**: YAML frontmatter parsing failure
2. **Recovery Options**:
   - Git checkout previous version: `git checkout HEAD~1 -- CONTINUITY.md`
   - Initialize fresh from template
3. **Prevention**: Always use atomic updates (temp file + move)

## Advanced References

For detailed guidance, see:
- [Trigger Detection Patterns](./references/trigger-detection.md)
- [State Management Best Practices](./references/state-management.md)
- [Official Claude Code Patterns](./references/official-patterns.md)
