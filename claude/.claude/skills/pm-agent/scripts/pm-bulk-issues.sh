#!/bin/bash
# pm-bulk-issues.sh - Bulk issue creation with checkpoint
# Usage: pm-bulk-issues.sh <issues.json> [--repo owner/repo] [--milestone N] [--dry-run]
#
# Creates multiple GitHub Issues from a JSON file.
# Features:
#   - Checkpoint for error recovery (idempotent)
#   - Dry-run mode for preview
#   - Batch processing with rate limit protection
#   - Milestone assignment via REST API

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pm-utils.sh"

usage() {
  cat << EOF
Usage: $0 <issues.json> [options]

Options:
  --repo <owner/repo>    Repository (default: auto-detect)
  --milestone <N>        Milestone number to assign
  --dry-run              Preview without creating issues
  --checkpoint <file>    Checkpoint file path (default: /tmp/claude/pm-checkpoint.json)
  --batch-size <N>       Issues per batch (default: 20)
  --delay <sec>          Delay between batches (default: 1)
  -h, --help             Show this help

Input JSON format:
[
  {"title": "Task name", "body": "Description", "labels": ["type:task"]}
]
EOF
  exit 1
}

# Default values
ISSUES_FILE=""
REPO=""
MILESTONE=""
DRY_RUN=false
BATCH_SIZE=20
DELAY_SEC=1
CHECKPOINT_FILE="/tmp/claude/pm-checkpoint.json"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --repo) REPO="$2"; shift 2 ;;
    --milestone) MILESTONE="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --checkpoint) CHECKPOINT_FILE="$2"; shift 2 ;;
    --batch-size) BATCH_SIZE="$2"; shift 2 ;;
    --delay) DELAY_SEC="$2"; shift 2 ;;
    -h|--help) usage ;;
    -*) echo "Unknown option: $1"; usage ;;
    *) ISSUES_FILE="$1"; shift ;;
  esac
done

# Validate input
[[ -z "$ISSUES_FILE" ]] && { echo "Error: issues.json is required"; usage; }
[[ ! -f "$ISSUES_FILE" ]] && { echo "Error: File not found: $ISSUES_FILE"; exit 1; }

# Get repository
REPO="${REPO:-$(get_repo)}"

# Ensure checkpoint directory exists
mkdir -p "$(dirname "$CHECKPOINT_FILE")"

echo "Creating issues for $REPO..."
[[ "$DRY_RUN" == true ]] && echo "🔍 DRY RUN MODE - no issues will be created"
echo ""

created_issues=()
skipped_count=0
count=0

while IFS= read -r issue; do
  title=$(echo "$issue" | jq -r '.title')
  body=$(echo "$issue" | jq -r '.body // ""')
  labels=$(echo "$issue" | jq -r '.labels // [] | join(",")')

  # Check checkpoint (idempotency)
  if is_already_created "$CHECKPOINT_FILE" "$title"; then
    print_skip "Skip (exists): $title"
    ((skipped_count++))
    continue
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo "Would create: $title"
    [[ -n "$labels" ]] && echo "  └─ Labels: $labels"
    [[ -n "$MILESTONE" ]] && echo "  └─ Milestone: #$MILESTONE"
    continue
  fi

  # Build gh issue create arguments
  args=(--repo "$REPO" --title "$title")
  [[ -n "$body" ]] && args+=(--body "$body")
  [[ -n "$labels" ]] && args+=(--label "$labels")

  # Create issue
  if url=$(gh issue create "${args[@]}"); then
    number=$(extract_issue_number "$url")

    print_success "Created #$number: $title"
    created_issues+=("$number")

    # Save checkpoint
    save_checkpoint "$CHECKPOINT_FILE" "$number" "$title"

    # Assign milestone if specified
    if [[ -n "$MILESTONE" ]]; then
      if assign_milestone "$REPO" "$number" "$MILESTONE" 2>/dev/null; then
        echo "   ↳ Assigned to milestone #$MILESTONE"
      else
        print_warn "Failed to assign milestone #$MILESTONE to #$number"
      fi
    fi
  else
    print_warn "Failed to create: $title"
  fi

  # Batch delay for rate limit protection
  ((count++))
  if ((count % BATCH_SIZE == 0)); then
    print_wait "Batch complete ($count issues), waiting ${DELAY_SEC}s..."
    sleep "$DELAY_SEC"
  fi
done < <(jq -c '.[]' "$ISSUES_FILE")

echo ""
echo "═══════════════════════════════════════════════"
echo "📊 Summary"
echo "───────────────────────────────────────────────"
if [[ "$DRY_RUN" == true ]]; then
  echo "  Mode: DRY RUN (no issues created)"
else
  echo "  Created: ${#created_issues[@]} issues"
  echo "  Skipped: $skipped_count issues"
  echo "  Checkpoint: $CHECKPOINT_FILE"
fi
echo "═══════════════════════════════════════════════"

# Output created issue numbers for downstream processing
if [[ ${#created_issues[@]} -gt 0 ]]; then
  echo ""
  print_info "Created issue numbers: ${created_issues[*]}"
fi
