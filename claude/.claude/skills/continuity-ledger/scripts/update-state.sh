#!/bin/bash
# Continuity Ledger State Update Script
# Atomic updates for CONTINUITY.md following official Claude Code patterns
#
# Usage:
#   ./update-state.sh [command] [args...]
#
# Commands:
#   timestamp              Update last_updated to current time
#   phase <value>          Update phase (Planning|Design|Implementation|Testing|Review|Done)
#   confidence <value>     Update confidence (low|medium|high)
#   decision "<text>"      Add a new decision with today's date
#   validate               Validate CONTINUITY.md structure
#   archive                Archive if file exceeds 50KB

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../../../" && pwd)"
STATE_FILE="${PROJECT_ROOT}/CONTINUITY.md"
ARCHIVE_DIR="${PROJECT_ROOT}/thoughts/shared"
MAX_SIZE=51200  # 50KB

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse YAML frontmatter field
parse_frontmatter() {
  local field="$1"
  sed -n '/^---$/,/^---$/p' "$STATE_FILE" | \
    grep "^${field}:" | \
    sed "s/^${field}: *//" | \
    tr -d '"'
}

# Validate YAML frontmatter
validate_frontmatter() {
  local file="${1:-$STATE_FILE}"

  # Check file exists
  if [[ ! -f "$file" ]]; then
    echo -e "${RED}ERROR: File not found: $file${NC}"
    return 1
  fi

  # Check frontmatter delimiters
  local delimiter_count
  delimiter_count=$(grep -c "^---$" "$file" || true)
  if [[ "$delimiter_count" -lt 2 ]]; then
    echo -e "${RED}ERROR: Invalid YAML frontmatter (missing delimiters)${NC}"
    return 1
  fi

  # Check required fields
  for field in last_updated phase confidence; do
    if ! grep -q "^${field}:" "$file"; then
      echo -e "${RED}ERROR: Missing required field: $field${NC}"
      return 1
    fi
  done

  # Validate phase value
  local phase
  phase=$(sed -n '/^---$/,/^---$/p' "$file" | grep "^phase:" | sed 's/^phase: *//' | tr -d '"')
  case "$phase" in
    Planning|Design|Implementation|Testing|Review|Done) ;;
    *)
      echo -e "${RED}ERROR: Invalid phase value: $phase${NC}"
      return 1
      ;;
  esac

  # Validate confidence value
  local confidence
  confidence=$(sed -n '/^---$/,/^---$/p' "$file" | grep "^confidence:" | sed 's/^confidence: *//' | tr -d '"')
  case "$confidence" in
    low|medium|high) ;;
    *)
      echo -e "${RED}ERROR: Invalid confidence value: $confidence${NC}"
      return 1
      ;;
  esac

  echo -e "${GREEN}OK: Frontmatter valid${NC}"
  return 0
}

# Atomic update of frontmatter field
update_field() {
  local field="$1"
  local value="$2"

  local temp_file="${STATE_FILE}.tmp.$$"

  # Update the field value
  sed "s/^${field}:.*/${field}: \"${value}\"/" "$STATE_FILE" > "$temp_file"

  # Validate and move
  if validate_frontmatter "$temp_file" >/dev/null 2>&1; then
    mv "$temp_file" "$STATE_FILE"
    echo -e "${GREEN}Updated ${field} to: ${value}${NC}"
    return 0
  else
    rm -f "$temp_file"
    echo -e "${RED}ERROR: Update failed validation${NC}"
    return 1
  fi
}

# Update timestamp
update_timestamp() {
  local timestamp
  timestamp=$(date -Iseconds)
  update_field "last_updated" "$timestamp"
}

# Update phase
update_phase() {
  local phase="$1"
  case "$phase" in
    Planning|Design|Implementation|Testing|Review|Done)
      update_field "phase" "$phase"
      update_timestamp
      ;;
    *)
      echo -e "${RED}ERROR: Invalid phase. Use: Planning|Design|Implementation|Testing|Review|Done${NC}"
      return 1
      ;;
  esac
}

# Update confidence
update_confidence() {
  local confidence="$1"
  case "$confidence" in
    low|medium|high)
      update_field "confidence" "$confidence"
      update_timestamp
      ;;
    *)
      echo -e "${RED}ERROR: Invalid confidence. Use: low|medium|high${NC}"
      return 1
      ;;
  esac
}

# Add decision
add_decision() {
  local decision="$1"
  local timestamp
  timestamp=$(date +%Y-%m-%d)

  local temp_file="${STATE_FILE}.tmp.$$"

  # Insert decision after "# Decisions" line
  awk -v ts="$timestamp" -v dec="$decision" '
    /^# Decisions/ {
      print
      getline
      if ($0 ~ /^$/ || $0 ~ /^-/) {
        print ""
        print "- [" ts "] " dec
      }
      print
      next
    }
    { print }
  ' "$STATE_FILE" > "$temp_file"

  mv "$temp_file" "$STATE_FILE"
  echo -e "${GREEN}Added decision: ${decision}${NC}"
  update_timestamp
}

# Archive old state
archive_state() {
  # Check file size
  local size
  if [[ "$(uname)" == "Darwin" ]]; then
    size=$(stat -f%z "$STATE_FILE" 2>/dev/null || echo 0)
  else
    size=$(stat --printf="%s" "$STATE_FILE" 2>/dev/null || echo 0)
  fi

  if [[ "$size" -gt "$MAX_SIZE" ]]; then
    echo -e "${YELLOW}State file exceeds 50KB (${size} bytes), archiving...${NC}"

    # Ensure archive directory exists
    mkdir -p "$ARCHIVE_DIR"

    # Create archive
    local timestamp
    timestamp=$(date +%Y-%m-%d)
    local archive_file="${ARCHIVE_DIR}/${timestamp}-continuity-archive.md"
    cp "$STATE_FILE" "$archive_file"

    echo -e "${GREEN}Archive created: ${archive_file}${NC}"
    echo -e "${YELLOW}Manual trimming of CONTINUITY.md recommended${NC}"
  else
    echo -e "${GREEN}State file size OK (${size} bytes, limit: ${MAX_SIZE})${NC}"
  fi
}

# Show current state summary
show_state() {
  if [[ ! -f "$STATE_FILE" ]]; then
    echo -e "${RED}CONTINUITY.md not found${NC}"
    return 1
  fi

  echo "=== Continuity Ledger State ==="
  echo "File: $STATE_FILE"
  echo ""
  echo "Frontmatter:"
  echo "  last_updated: $(parse_frontmatter 'last_updated')"
  echo "  session_id:   $(parse_frontmatter 'session_id')"
  echo "  phase:        $(parse_frontmatter 'phase')"
  echo "  confidence:   $(parse_frontmatter 'confidence')"
  echo ""

  # File size
  local size
  if [[ "$(uname)" == "Darwin" ]]; then
    size=$(stat -f%z "$STATE_FILE" 2>/dev/null || echo 0)
  else
    size=$(stat --printf="%s" "$STATE_FILE" 2>/dev/null || echo 0)
  fi
  echo "Size: ${size} bytes"
}

# Main command dispatch
main() {
  local command="${1:-show}"

  case "$command" in
    timestamp)
      update_timestamp
      ;;
    phase)
      if [[ -z "${2:-}" ]]; then
        echo -e "${RED}Usage: $0 phase <Planning|Design|Implementation|Testing|Review|Done>${NC}"
        exit 1
      fi
      update_phase "$2"
      ;;
    confidence)
      if [[ -z "${2:-}" ]]; then
        echo -e "${RED}Usage: $0 confidence <low|medium|high>${NC}"
        exit 1
      fi
      update_confidence "$2"
      ;;
    decision)
      if [[ -z "${2:-}" ]]; then
        echo -e "${RED}Usage: $0 decision \"<decision text>\"${NC}"
        exit 1
      fi
      add_decision "$2"
      ;;
    validate)
      validate_frontmatter
      ;;
    archive)
      archive_state
      ;;
    show)
      show_state
      ;;
    *)
      echo "Usage: $0 [command] [args...]"
      echo ""
      echo "Commands:"
      echo "  show                   Show current state (default)"
      echo "  timestamp              Update last_updated to current time"
      echo "  phase <value>          Update phase"
      echo "  confidence <value>     Update confidence"
      echo "  decision \"<text>\"      Add a new decision"
      echo "  validate               Validate CONTINUITY.md structure"
      echo "  archive                Archive if file exceeds 50KB"
      exit 1
      ;;
  esac
}

main "$@"
