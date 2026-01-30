# CONTINUITY.md Template

## Template

```markdown
# Goal

[Primary objective in 1-2 sentences]

Success criteria:
- [ ] Criterion 1
- [ ] Criterion 2

# Constraints/Assumptions

- [Technical/organizational/time constraints]
- [Key assumptions]

# Key Decisions

- [YYYY-MM-DD] Decision with rationale

# State

## Done
- [Completed items]

## Now
- [Current task]

## Next
- [Upcoming tasks]

# Open Questions

- [Questions requiring user input]
- UNCONFIRMED: [Assumptions needing verification]

# Working Set

- [Active files/.brain/PRPs/commands]
```

## Usage

Initialize with `/vw:continuity init` or copy this template manually.

Once CONTINUITY.md exists, the skill automatically:
- Reads at start of every turn
- Updates when goal/constraints/decisions/state change
- Displays Ledger Snapshot in replies
