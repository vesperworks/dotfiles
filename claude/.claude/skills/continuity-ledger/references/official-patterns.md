# Official Claude Code Patterns Reference

This document catalogs all official Claude Code patterns used in the Continuity Ledger implementation, with source URLs and rationale for each.

## Pattern Sources

All patterns are sourced from the official Claude Code documentation repository:
- Base URL: `https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/`

## Pattern 1: Skill Trigger Description

**Source**: [skills/skill-development/SKILL.md](https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/skill-development/SKILL.md)

**Pattern**:
```yaml
---
name: skill-name
description: This skill should be used when the user [specific trigger phrases]. [Brief purpose].
version: X.Y.Z
---
```

**Key Requirements**:
1. **Third-person format**: "This skill should be used when..." (NOT "Use this skill when...")
2. **Specific trigger phrases**: Include exact phrases that activate the skill
3. **Brief purpose**: One sentence explaining what the skill does

**Applied in Continuity Ledger**:
```yaml
description: This skill should be used when the user asks to "continue from last session",
"what did we do last time", "resume work", "where were we", "前回の続き", "どこまでやった",
or when starting a multi-step workflow that requires state tracking across sessions.
```

**Why This Pattern**:
- Enables Claude to properly activate skills based on user intent
- Third-person format aligns with how Claude processes skill metadata
- Specific phrases reduce false positives and improve accuracy

---

## Pattern 2: Progressive Disclosure Structure

**Source**: [agents/skill-reviewer.md](https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/agents/skill-reviewer.md)

**Pattern**:
```
skills/{skill-name}/
├── SKILL.md           # Layer 1+2: Metadata + Core content (<3000 words)
├── TEMPLATE.md        # Supporting templates
└── references/        # Layer 3: Detailed documentation (unlimited)
    ├── topic-1.md
    └── topic-2.md
```

**Key Requirements**:
1. **SKILL.md under 3000 words** (optimal: 1500-2000)
2. **References for deep dives**: Detailed content in `references/` directory
3. **Lazy loading**: Only load references when explicitly needed

**Applied in Continuity Ledger**:
```
.klaude/skills/continuity-ledger/
├── SKILL.md                        # ~1500 words
├── TEMPLATE.md                     # State file template
└── references/
    ├── trigger-detection.md        # Detailed trigger logic
    ├── state-management.md         # YAML/update patterns
    └── official-patterns.md        # This file
```

**Why This Pattern**:
- Minimizes context consumption when skill is not actively used
- Detailed information available when needed
- Scales with complexity without bloating base skill

---

## Pattern 3: State Persistence with YAML Frontmatter

**Source**: [skills/command-development/references/advanced-workflows.md](https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/command-development/references/advanced-workflows.md)

**Pattern**:
```markdown
---
last_updated: "2025-12-24T15:30:00+09:00"
field_1: "value"
field_2: "value"
---

# Content Section 1
...

# Content Section 2
...
```

**Key Requirements**:
1. **YAML frontmatter** at file start between `---` delimiters
2. **ISO 8601 datetime** for timestamps
3. **Markdown body** for human-readable content
4. **Git-friendly format** (text-based, mergeable)

**Applied in Continuity Ledger**:
```markdown
---
last_updated: "2025-12-24T15:30:00+09:00"
session_id: "abc123"
phase: "Implementation"
confidence: "high"
---

# Goal
[Content]

# State
[Content]
```

**Why This Pattern**:
- Standard format recognized by many tools
- Human-readable while machine-parseable
- Works well with version control

---

## Pattern 4: Fast-Path Exit

**Source**: [skills/plugin-settings/references/real-world-examples.md](https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/plugin-settings/references/real-world-examples.md)

**Pattern**:
```bash
if [[ ! -f "$STATE_FILE" ]]; then
  exit 0  # Not active - exit silently
fi
```

**Key Requirements**:
1. **Check conditions first**: Before any heavy processing
2. **Silent exit**: Don't output messages when not applicable
3. **Fast execution**: Minimize overhead for non-applicable cases

**Applied in Continuity Ledger**:
```
IF CONTINUITY.md does not exist:
  IF user explicitly requested continuity:
    Offer to initialize CONTINUITY.md from template
  ELSE:
    Exit (skill not applicable)
```

**Why This Pattern**:
- Prevents unnecessary processing
- Reduces context pollution
- Improves overall responsiveness

---

## Pattern 5: Atomic State Updates

**Source**: [skills/plugin-settings/references/real-world-examples.md](https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/plugin-settings/references/real-world-examples.md)

**Pattern**:
```bash
TEMP_FILE="${STATE_FILE}.tmp.$$"
sed "s/^field: .*/field: $NEW_VALUE/" "$STATE_FILE" > "$TEMP_FILE"
mv "$TEMP_FILE" "$STATE_FILE"
```

**Key Requirements**:
1. **Write to temp file first**: Never modify original directly
2. **Unique temp file name**: Use PID (`$$`) for uniqueness
3. **Atomic move**: `mv` is atomic on POSIX filesystems
4. **Validate before move**: Ensure new content is valid

**Applied in Continuity Ledger**:
```bash
update_state_atomic() {
  local temp_file="${state_file}.tmp.$$"
  echo "$new_content" > "$temp_file"
  if validate_frontmatter "$temp_file"; then
    mv "$temp_file" "$state_file"
  else
    rm -f "$temp_file"
    return 1
  fi
}
```

**Why This Pattern**:
- Prevents corruption from interrupted writes
- Ensures state is always valid or unchanged
- Standard Unix/POSIX practice

---

## Pattern 6: SKILL.md Section Structure

**Source**: [skills/skill-development/SKILL.md](https://github.com/anthropics/claude-code/blob/main/plugins/plugin-dev/skills/skill-development/SKILL.md)

**Pattern**:
```markdown
# Skill Name

## Core Purpose
[What/Why/When in brief]

## Quick Checklist (初期応答で必ず確認)
[Immediate verification steps]

## Basic Workflow
[Step-by-step process]

## Rollback / Recovery
[Error recovery procedures]

## Advanced References
[Pointers to detailed docs]
```

**Key Requirements**:
1. **Core Purpose**: Brief explanation of skill's role
2. **Quick Checklist**: Items to verify immediately
3. **Basic Workflow**: Step-by-step process
4. **Rollback/Recovery**: Error handling
5. **Advanced References**: Links to detailed docs

**Applied in Continuity Ledger**: All sections implemented in SKILL.md

**Why This Pattern**:
- Consistent structure across all skills
- Enables quick orientation
- Facilitates maintenance and review

---

## Deviations and Justifications

### Deviation 1: State File Location

**Official Pattern**: `.local.md` files in skill directory
**Our Implementation**: `CONTINUITY.md` in project root

**Justification**:
- Project-wide state (not skill-specific)
- Easy access from any context
- Visible to users for manual editing
- Consistent with existing project conventions (PRPs/, thoughts/)

### Deviation 2: Japanese Trigger Phrases

**Official Pattern**: English-only examples
**Our Implementation**: Both English and Japanese phrases

**Justification**:
- Project-specific requirement (Japanese user base)
- Follows existing project patterns
- Does not violate official pattern (additive, not contradictory)

---

## Version Compatibility

These patterns are based on Claude Code documentation as of 2025-12-24.

**Compatibility Notes**:
- All patterns follow stable, documented interfaces
- No undocumented internals used
- Should remain compatible with future Claude Code updates
- If breaking changes occur, update this document with migration notes

---

## References Summary

| Pattern | Source File | Line/Section |
|---------|-------------|--------------|
| Skill Description | skill-development/SKILL.md | Frontmatter section |
| Progressive Disclosure | skill-reviewer.md | Quality criteria |
| YAML Frontmatter | advanced-workflows.md | State management |
| Fast-Path Exit | real-world-examples.md | Guard patterns |
| Atomic Updates | real-world-examples.md | File operations |
| SKILL.md Structure | skill-development/SKILL.md | Template section |
