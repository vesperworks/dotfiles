# Official Claude Code Patterns Reference

Patterns used in the Continuity Ledger implementation.

## Pattern 1: Fast-Path Exit

```
IF state file does not exist:
  → Exit silently (skill not applicable)
```

**Why**: Prevents unnecessary processing, reduces context pollution.

## Pattern 2: Progressive Disclosure Structure

```
skills/{skill-name}/
├── SKILL.md           # Core content (<3000 words)
├── TEMPLATE.md        # Supporting templates
└── references/        # Detailed documentation
```

**Why**: Minimizes context consumption when skill is not actively used.

## Pattern 3: Atomic State Updates

```bash
temp_file="${state_file}.tmp.$$"
echo "$content" > "$temp_file"
mv "$temp_file" "$state_file"
```

**Why**: `mv` is atomic on POSIX, prevents corruption from interrupted writes.

## Pattern 4: Every-Turn Workflow

When state file exists:
1. Read at start of every turn
2. Detect changes in goal/constraints/decisions/state
3. Update if changes detected
4. Display Ledger Snapshot in reply

**Why**: Ensures state survives context compaction without manual intervention.
