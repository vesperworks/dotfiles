---
name: continuity-ledger
description: Maintains CONTINUITY.md as the canonical session briefing designed to survive context compaction. Automatically reads and updates the ledger every turn when the file exists. Does nothing if CONTINUITY.md is not initialized.
version: 0.2.0
---

# Continuity Ledger (Compaction-Safe)

## Core Purpose

Maintain a single Continuity Ledger (`CONTINUITY.md`) as the canonical session briefing designed to survive context compaction. Do not rely on earlier chat text unless it's reflected in the ledger.

**Key Distinction**:
- **TodoWrite**: Short-term execution scaffolding (3-7 step plan)
- **Continuity Ledger**: Long-running continuity across compaction (what/why/current state)

## Fast-Path Exit

```
IF CONTINUITY.md does not exist:
  → Do nothing (skill is inactive)
  → User must run /vw:continuity init to activate
```

**This skill only activates when CONTINUITY.md exists.**

## Every-Turn Workflow

When CONTINUITY.md exists, execute this at the **start of every assistant turn**:

### Step 1: Read Ledger

```
Read CONTINUITY.md
Parse current state:
- Goal (incl. success criteria)
- Constraints/Assumptions
- Key decisions
- State (Done/Now/Next)
- Open questions
- Working set
```

### Step 2: Detect Changes

Check if any of these changed during the conversation:
- Goal
- Constraints/Assumptions
- Key decisions (new decision made)
- Progress state (Done/Now/Next)
- Important tool outcomes (file edits, test results, etc.)

### Step 3: Update Ledger (if changes detected)

```
IF changes detected:
  Update relevant sections in CONTINUITY.md
  Update last_updated timestamp
  Write atomically (temp file → move)
```

### Step 4: Display Ledger Snapshot

Begin every reply with a brief snapshot:

```markdown
## Ledger Snapshot
**Goal**: [Primary objective]
**Now**: [Current task]
**Next**: [Upcoming task]
**Open**: [Unresolved questions, if any]

---
[Continue with the actual work]
```

**Full ledger display**: Only when it materially changes or when user asks.

## Auto-Update Triggers

Update CONTINUITY.md whenever any of these change:

| Trigger | Example |
|---------|---------|
| Goal changes | User redefines objective |
| New constraint | "We can't use library X" |
| Key decision made | "Let's use JWT for auth" |
| State progress | Task completed, new blocker |
| Tool outcome | Test failed, file created |

## Compaction Detection

If you notice missing recall or a compaction/summary event:

1. Refresh/rebuild the ledger from visible context
2. Mark gaps as `UNCONFIRMED`
3. Ask up to 1-3 targeted questions
4. Continue working

## CONTINUITY.md Format

```markdown
# Goal
[Primary objective in 1-2 sentences]

Success criteria:
- [ ] Criterion 1
- [ ] Criterion 2

# Constraints/Assumptions
- Technical: [...]
- Organizational: [...]
- Time: [...]

# Key Decisions
- [2025-12-24] Decision with rationale
- [2025-12-23] Earlier decision

# State

## Done
- Completed item 1
- Completed item 2

## Now
- Current task

## Next
- Upcoming task 1
- Upcoming task 2

# Open Questions
- [ ] Question requiring user input
- [ ] UNCONFIRMED: Assumption needing verification

# Working Set
- path/to/active/file.ts
- .brain/PRPs/PRP-XXX-name.md
```

## Guidelines

### Keep It Short and Stable
- Facts only, no transcripts
- Prefer bullets
- Mark uncertainty as `UNCONFIRMED` (never guess)

### Consistency with TodoWrite
- Keep them consistent
- When plan or state changes, update ledger at intent/progress level
- Not every micro-step

### Atomic Updates
- Always use temp file + move pattern
- Prevents corruption on interruption

## References

- [State Management](./references/state-management.md)
- [Official Patterns](./references/official-patterns.md)
