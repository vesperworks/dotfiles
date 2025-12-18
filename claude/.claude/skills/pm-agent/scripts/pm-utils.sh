#!/bin/bash
# pm-utils.sh - PM Agent Common Utilities
# Usage: source pm-utils.sh
#
# This file provides common functions for pm-agent scripts.
# All functions are designed to work with sandbox restrictions.

# Extract issue number from URL
# Input: https://github.com/owner/repo/issues/123
# Output: 123
extract_issue_number() {
  local url="$1"
  echo "$url" | grep -oE '[0-9]+$'
}

# Get repository name (sandbox-safe)
# Priority: 1. argument, 2. gh repo view
get_repo() {
  if [[ -n "${1:-}" ]]; then
    echo "$1"
    return
  fi
  gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || {
    echo "Error: Could not determine repository. Specify --repo owner/repo" >&2
    exit 1
  }
}

# Create milestone (REST API)
# Note: due_on is required by pm-agent policy for deadline management
create_milestone() {
  local repo="$1" title="$2" due_on="$3"
  [[ -z "$due_on" ]] && { echo "Error: due_on is required (pm-agent policy)" >&2; return 1; }
  gh api "repos/$repo/milestones" \
    -X POST \
    -f title="$title" \
    -f due_on="$due_on" \
    --jq '.number'
}

# Get issue ID (numeric, not node_id)
# Required for sub-issue REST API
# Reference: https://docs.github.com/en/rest/issues/sub-issues
get_issue_id() {
  local repo="$1" issue_number="$2"
  gh api "repos/$repo/issues/$issue_number" --jq '.id'
}

# Add sub-issue relationship (REST API)
# Reference: https://docs.github.com/en/rest/issues/sub-issues
add_sub_issue() {
  local repo="$1" parent_number="$2" child_number="$3"

  # Get child issue ID (numeric)
  local child_id
  child_id=$(get_issue_id "$repo" "$child_number")

  # POST to sub_issues endpoint
  gh api "repos/$repo/issues/$parent_number/sub_issues" \
    -X POST \
    -f sub_issue_id="$child_id"
}

# Assign milestone to issue (REST API)
assign_milestone() {
  local repo="$1" issue_number="$2" milestone_number="$3"
  gh api "repos/$repo/issues/$issue_number" \
    -X PATCH \
    -F milestone="$milestone_number" \
    --silent
}

# Save checkpoint (for error recovery)
save_checkpoint() {
  local checkpoint_file="$1" number="$2" title="$3"
  if [[ ! -f "$checkpoint_file" ]]; then
    echo '{"created":[]}' > "$checkpoint_file"
  fi
  jq --arg n "$number" --arg t "$title" \
    '.created += [{"number": $n, "title": $t}]' "$checkpoint_file" > "${checkpoint_file}.tmp"
  mv "${checkpoint_file}.tmp" "$checkpoint_file"
}

# Check if issue already created (idempotency)
is_already_created() {
  local checkpoint_file="$1" title="$2"
  if [[ -f "$checkpoint_file" ]]; then
    jq -e --arg t "$title" '.created[] | select(.title == $t)' "$checkpoint_file" >/dev/null 2>&1
  else
    return 1
  fi
}

# Print colored message
print_success() { echo "✅ $*"; }
print_skip() { echo "⏭️ $*"; }
print_warn() { echo "⚠️ $*"; }
print_info() { echo "📝 $*"; }
print_wait() { echo "⏳ $*"; }
