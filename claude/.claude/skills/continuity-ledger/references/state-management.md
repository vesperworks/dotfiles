# State Management Best Practices

## Atomic State Updates

Always use temp file + move pattern to prevent corruption:

```bash
update_state_atomic() {
  local state_file="$1"
  local new_content="$2"
  local temp_file="${state_file}.tmp.$$"

  echo "$new_content" > "$temp_file"
  mv "$temp_file" "$state_file"
}
```

**Why**: `mv` is atomic on POSIX filesystems, preventing partial writes.

## CONTINUITY.md Sections

| Section | Purpose |
|---------|---------|
| Goal | Primary objective + success criteria |
| Constraints/Assumptions | Technical/organizational limits |
| Key Decisions | Timestamped decisions with rationale |
| State (Done/Now/Next) | Current progress |
| Open Questions | Unresolved items, UNCONFIRMED assumptions |
| Working Set | Active files |

## Update Guidelines

1. **Keep it short**: Facts only, prefer bullets
2. **Mark uncertainty**: Use `UNCONFIRMED:` prefix
3. **Timestamp decisions**: `[YYYY-MM-DD] Decision text`
4. **Update atomically**: Temp file + move

## Archive Strategy

When file grows large:
1. Move old decisions to `thoughts/shared/YYYY-MM-DD-continuity-archive.md`
2. Keep only recent/relevant content
