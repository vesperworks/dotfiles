# CONTINUITY.md Template

Use this template to initialize a new CONTINUITY.md file in the project root.

## Template

```markdown
---
last_updated: "YYYY-MM-DDTHH:MM:SS+09:00"
session_id: ""
phase: "Planning"
confidence: "medium"
---

# Goal

[Describe the primary objective of the current project/feature in 1-2 sentences.
This should answer: "What are we trying to achieve?"]

# Constraints

## Technical
- [Technology stack limitations]
- [Performance requirements]
- [Compatibility requirements]

## Organizational
- [Team structure constraints]
- [Code ownership rules]
- [Review requirements]

## Time
- [Deadlines if any]
- [Sprint/iteration boundaries]

# Decisions

[Record significant decisions with timestamps and rationale]

- [YYYY-MM-DD] **Decision**: [What was decided]
  - Rationale: [Why this decision was made]
  - Alternatives considered: [Other options that were rejected]

# State

**Current Phase**: Planning | Design | Implementation | Testing | Review | Done

**Progress**: [Percentage or milestone description]

**Next Steps**:
1. [Immediate next action]
2. [Following action]
3. [...]

**Blockers** (if any):
- [Description of blocker and who/what can resolve it]

# Working Set

## Active Files
[Files currently being worked on]
- path/to/file1.md
- path/to/file2.ts

## Related PRPs
[Project Requirement Plans related to current work]
- PRPs/PRP-XXX-name.md

## Related Documentation
[Documentation that should be kept in context]
- docs/architecture.md
- thoughts/shared/YYYY-MM-DD-topic.md

# UNCONFIRMED

[Items that are assumed but not yet verified. These MUST be confirmed before relying on them.]

- [ ] Assumption 1: [Description of what is assumed]
- [ ] Assumption 2: [Another uncertain item]

---

## Usage Notes

### When to Update

Update CONTINUITY.md at these checkpoints:
1. **Session Start**: Load and verify current state
2. **Major Decision**: Record with timestamp and rationale
3. **Phase Transition**: Update phase and progress
4. **New Assumption**: Add to UNCONFIRMED section
5. **Session End**: Capture current state for next session

### YAML Frontmatter Fields

| Field | Type | Description |
|-------|------|-------------|
| last_updated | ISO 8601 datetime | When this file was last modified |
| session_id | string | Unique identifier for the current session (optional) |
| phase | enum | Current project phase (Planning/Design/Implementation/Testing/Review/Done) |
| confidence | enum | Confidence level in current state (low/medium/high) |

### Confidence Levels

- **high**: All information verified, no major uncertainties
- **medium**: Most information reliable, some assumptions present
- **low**: Significant uncertainties, many items in UNCONFIRMED

### Archiving

When CONTINUITY.md exceeds 50KB or contains outdated information:
1. Move old entries to `thoughts/shared/YYYY-MM-DD-continuity-archive.md`
2. Keep only recent/relevant entries in CONTINUITY.md
3. Update last_updated timestamp
```

## Initialization Command

To create a new CONTINUITY.md:

```bash
# Copy template (remove the code fence markers)
# Then customize for your project
```

Or use the `/vw:continuity init` command if available.
