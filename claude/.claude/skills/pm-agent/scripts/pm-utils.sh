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

# Get repository name from git remote origin
# Priority: 1. argument, 2. git remote get-url origin
# Supports both SSH (git@github.com:owner/repo.git) and HTTPS formats
get_repo() {
  if [[ -n "${1:-}" ]]; then
    echo "$1"
    return
  fi

  local remote_url
  remote_url=$(git remote get-url origin 2>/dev/null) || {
    echo "Error: Could not get git remote origin. Specify --repo owner/repo" >&2
    exit 1
  }

  # Parse owner/repo from remote URL
  # SSH format: git@github.com:owner/repo.git
  # HTTPS format: https://github.com/owner/repo.git
  local repo
  if [[ "$remote_url" =~ ^git@github\.com:(.+)\.git$ ]]; then
    repo="${BASH_REMATCH[1]}"
  elif [[ "$remote_url" =~ ^https://github\.com/(.+)\.git$ ]]; then
    repo="${BASH_REMATCH[1]}"
  elif [[ "$remote_url" =~ ^https://github\.com/(.+)$ ]]; then
    repo="${BASH_REMATCH[1]}"
  else
    echo "Error: Unsupported remote URL format: $remote_url" >&2
    exit 1
  fi

  echo "$repo"
}

# Get repository owner from owner/repo format
get_repo_owner() {
  local repo="$1"
  echo "${repo%%/*}"
}

# Check if repository owner is an organization
# Returns 0 (true) for organization, 1 (false) for user
is_org_repo() {
  local repo="$1"
  local owner
  owner=$(get_repo_owner "$repo")

  local owner_type
  owner_type=$(gh api "users/$owner" --jq '.type' 2>/dev/null)

  [[ "$owner_type" == "Organization" ]]
}

# Get organization's issue types (if available)
# Returns list of issue type names, empty if not available
get_org_issue_types() {
  local org="$1"
  gh api "orgs/$org/issue-types" --jq '.[].name' 2>/dev/null || true
}

# Set issue type for an issue (organization repos only)
# Reference: https://docs.github.com/en/rest/issues
set_issue_type() {
  local repo="$1" issue_number="$2" issue_type="$3"

  gh api "repos/$repo/issues/$issue_number" \
    -X PATCH \
    -f type="$issue_type" \
    --silent
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

# Get parent issue number for a sub-issue
# Returns parent issue number if exists, empty string otherwise
# Reference: https://docs.github.com/en/rest/issues/sub-issues
get_parent_issue() {
  local repo="$1" issue_number="$2"
  gh api "repos/$repo/issues/$issue_number" --jq '.parent.number // empty' 2>/dev/null || echo ""
}

# Remove sub-issue relationship (REST API)
# Reference: https://docs.github.com/en/rest/issues/sub-issues#remove-sub-issue
remove_sub_issue() {
  local repo="$1" parent_number="$2" child_number="$3"

  # Get child issue ID (numeric integer)
  local child_id
  child_id=$(get_issue_id "$repo" "$child_number")

  # DELETE from sub_issues endpoint
  gh api "repos/$repo/issues/$parent_number/sub_issues/$child_id" \
    -X DELETE \
    -H "Accept: application/vnd.github+json"
}

# Add sub-issue relationship (REST API)
# Reference: https://docs.github.com/en/rest/issues/sub-issues
# Note: sub_issue_id must be sent as integer, not string
add_sub_issue() {
  local repo="$1" parent_number="$2" child_number="$3"

  # Get child issue ID (numeric integer, not node_id)
  local child_id
  child_id=$(get_issue_id "$repo" "$child_number")

  # Validate child_id is a number
  if ! [[ "$child_id" =~ ^[0-9]+$ ]]; then
    echo "Error: Invalid issue ID for #$child_number: $child_id" >&2
    return 1
  fi

  # POST to sub_issues endpoint
  # Use -F (not -f) to send sub_issue_id as integer
  gh api "repos/$repo/issues/$parent_number/sub_issues" \
    -X POST \
    -H "Accept: application/vnd.github+json" \
    -F sub_issue_id="$child_id"
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

# Print colored message (to stderr, so they don't interfere with command substitution)
print_success() { echo "✅ $*" >&2; }
print_skip() { echo "⏭️ $*" >&2; }
print_warn() { echo "⚠️ $*" >&2; }
print_info() { echo "📝 $*" >&2; }
print_wait() { echo "⏳ $*" >&2; }
