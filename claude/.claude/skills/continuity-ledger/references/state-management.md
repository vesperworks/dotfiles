# State Management Best Practices

This document covers YAML frontmatter parsing, atomic updates, and state validation patterns.

## YAML Frontmatter Structure

Following the official Claude Code pattern from `advanced-workflows.md`:

```yaml
---
last_updated: "2025-12-24T15:30:00+09:00"
session_id: "abc123"
phase: "Implementation"
confidence: "high"
---
```

### Field Definitions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| last_updated | ISO 8601 datetime | Yes | When this file was last modified |
| session_id | string | No | Unique identifier for linking related sessions |
| phase | enum | Yes | Current project phase |
| confidence | enum | Yes | Confidence in state accuracy |

### Valid Phase Values

```
Planning → Design → Implementation → Testing → Review → Done
```

### Valid Confidence Values

```
low | medium | high
```

## Parsing YAML Frontmatter

### Bash Implementation

```bash
#!/bin/bash
# Parse YAML frontmatter from CONTINUITY.md

parse_frontmatter() {
  local file="$1"
  local field="$2"

  # Extract content between first two '---' lines
  sed -n '/^---$/,/^---$/p' "$file" | \
    grep "^${field}:" | \
    sed "s/^${field}: *//" | \
    tr -d '"'
}

# Usage
LAST_UPDATED=$(parse_frontmatter "CONTINUITY.md" "last_updated")
PHASE=$(parse_frontmatter "CONTINUITY.md" "phase")
CONFIDENCE=$(parse_frontmatter "CONTINUITY.md" "confidence")
```

### Validation

```bash
validate_frontmatter() {
  local file="$1"

  # Check file exists
  if [[ ! -f "$file" ]]; then
    echo "ERROR: File not found: $file"
    return 1
  fi

  # Check frontmatter delimiters
  local delimiter_count
  delimiter_count=$(grep -c "^---$" "$file")
  if [[ "$delimiter_count" -lt 2 ]]; then
    echo "ERROR: Invalid YAML frontmatter (missing delimiters)"
    return 1
  fi

  # Check required fields
  for field in last_updated phase confidence; do
    if ! grep -q "^${field}:" "$file"; then
      echo "ERROR: Missing required field: $field"
      return 1
    fi
  done

  # Validate phase value
  local phase
  phase=$(parse_frontmatter "$file" "phase")
  case "$phase" in
    Planning|Design|Implementation|Testing|Review|Done) ;;
    *)
      echo "ERROR: Invalid phase value: $phase"
      return 1
      ;;
  esac

  # Validate confidence value
  local confidence
  confidence=$(parse_frontmatter "$file" "confidence")
  case "$confidence" in
    low|medium|high) ;;
    *)
      echo "ERROR: Invalid confidence value: $confidence"
      return 1
      ;;
  esac

  echo "OK: Frontmatter valid"
  return 0
}
```

## Atomic State Updates

Following the official pattern from `real-world-examples.md`:

```bash
update_state_atomic() {
  local state_file="$1"
  local new_content="$2"

  # Create temp file with unique suffix (PID)
  local temp_file="${state_file}.tmp.$$"

  # Write to temp file
  echo "$new_content" > "$temp_file"

  # Validate temp file before moving
  if ! validate_frontmatter "$temp_file"; then
    rm -f "$temp_file"
    echo "ERROR: New content failed validation, aborting"
    return 1
  fi

  # Atomic move (rename is atomic on POSIX)
  mv "$temp_file" "$state_file"

  echo "OK: State updated atomically"
  return 0
}
```

### Update Specific Field

```bash
update_frontmatter_field() {
  local file="$1"
  local field="$2"
  local value="$3"

  local temp_file="${file}.tmp.$$"

  # Update the field value
  sed "s/^${field}:.*/${field}: \"${value}\"/" "$file" > "$temp_file"

  # Validate and move
  if validate_frontmatter "$temp_file"; then
    mv "$temp_file" "$file"
    return 0
  else
    rm -f "$temp_file"
    return 1
  fi
}

# Usage: Update last_updated timestamp
update_frontmatter_field "CONTINUITY.md" "last_updated" "$(date -Iseconds)"
```

## State Sections Management

### Append to Decisions Section

```bash
add_decision() {
  local file="$1"
  local decision="$2"
  local timestamp
  timestamp=$(date +%Y-%m-%d)

  local temp_file="${file}.tmp.$$"

  # Insert decision after "# Decisions" line
  awk -v ts="$timestamp" -v dec="$decision" '
    /^# Decisions/ {
      print
      getline  # Skip to next line
      print "- [" ts "] " dec
      print
      next
    }
    { print }
  ' "$file" > "$temp_file"

  mv "$temp_file" "$file"
}
```

### Update State Section

```bash
update_state_section() {
  local file="$1"
  local phase="$2"
  local progress="$3"

  local temp_file="${file}.tmp.$$"

  # Update Current Phase line
  sed "s/^Current Phase:.*$/Current Phase: ${phase}/" "$file" > "$temp_file"

  # Update Progress line
  sed -i '' "s/^Progress:.*$/Progress: ${progress}/" "$temp_file"

  mv "$temp_file" "$file"
}
```

## Archive Strategy

When CONTINUITY.md grows too large (> 50KB):

```bash
archive_old_state() {
  local file="$1"
  local archive_dir="thoughts/shared"
  local timestamp
  timestamp=$(date +%Y-%m-%d)

  # Check file size
  local size
  size=$(stat -f%z "$file" 2>/dev/null || stat --printf="%s" "$file")

  if [[ "$size" -gt 51200 ]]; then  # 50KB
    echo "State file exceeds 50KB, archiving..."

    # Create archive
    local archive_file="${archive_dir}/${timestamp}-continuity-archive.md"
    cp "$file" "$archive_file"

    # Trim original (keep only recent content)
    # This is project-specific logic
    echo "Archive created: $archive_file"
    echo "Manual trimming of CONTINUITY.md recommended"
  fi
}
```

## Error Recovery

### Corruption Detection

```bash
check_state_integrity() {
  local file="$1"

  # Basic file check
  if [[ ! -f "$file" ]] || [[ ! -s "$file" ]]; then
    return 1
  fi

  # YAML frontmatter check
  if ! validate_frontmatter "$file"; then
    return 1
  fi

  # Required sections check
  for section in "# Goal" "# Constraints" "# Decisions" "# State" "# Working Set"; do
    if ! grep -q "^${section}$" "$file"; then
      echo "WARNING: Missing section: $section"
    fi
  done

  return 0
}
```

### Recovery from Corruption

```bash
recover_state() {
  local file="$1"

  # Try git recovery first
  if git status "$file" &>/dev/null; then
    echo "Attempting git recovery..."
    git checkout HEAD~1 -- "$file" 2>/dev/null && return 0
    git checkout HEAD -- "$file" 2>/dev/null && return 0
  fi

  # Fall back to template
  echo "Initializing fresh from template..."
  local template_dir
  template_dir="$(dirname "$0")/../.klaude/skills/continuity-ledger"
  if [[ -f "${template_dir}/TEMPLATE.md" ]]; then
    # Extract template content (between code fences)
    sed -n '/^```markdown$/,/^```$/p' "${template_dir}/TEMPLATE.md" | \
      sed '1d;$d' > "$file"
    return 0
  fi

  echo "ERROR: Could not recover state"
  return 1
}
```

## Concurrency Considerations

While rare in Claude Code context, handle potential concurrent access:

```bash
# Use lock file for critical updates
update_with_lock() {
  local file="$1"
  local lock_file="${file}.lock"

  # Acquire lock (with timeout)
  local timeout=5
  local count=0
  while [[ -f "$lock_file" ]] && [[ "$count" -lt "$timeout" ]]; do
    sleep 1
    ((count++))
  done

  if [[ -f "$lock_file" ]]; then
    echo "ERROR: Could not acquire lock after ${timeout}s"
    return 1
  fi

  # Create lock
  echo $$ > "$lock_file"

  # Perform update
  # ... update logic ...

  # Release lock
  rm -f "$lock_file"
}
```

## Best Practices Summary

1. **Always validate** before writing new state
2. **Use atomic operations** (temp file + move)
3. **Preserve structure** when updating specific sections
4. **Archive proactively** when file grows large
5. **Log changes** in Decisions section with timestamps
6. **Handle errors gracefully** with git fallback
7. **Keep UNCONFIRMED section** actively maintained
