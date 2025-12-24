#!/bin/bash
# pm-cascade-iteration.sh - Cascade iteration from parent to sub-issues
# Usage: pm-cascade-iteration.sh <parent_issue_number> [options]
#
# Automatically sets the same iteration for all sub-issues of a parent issue.
# Uses GraphQL API for Projects V2 and REST API for sub-issues.
#
# Reference: https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pm-utils.sh"

usage() {
  cat << EOF
Usage: $0 <parent_issue_number> [options]

Cascade iteration from a parent issue to its sub-issues.

Options:
  --repo <owner/repo>      Repository (default: auto-detect from git remote)
  --project <number>       Project number (required)
  --owner <login>          Project owner (@me for user, or org name)
  --recursive              Cascade to ALL descendants (not just direct children)
  --max-depth <N>          Maximum depth for recursive mode (default: 10)
  --dry-run                Show what would be done without executing
  -h, --help               Show this help

Examples:
  # Cascade to direct children only
  $0 10 --project 1 --owner @me

  # Cascade to ALL descendants (Epic → Feature → Story → Task)
  $0 10 --project 1 --owner @me --recursive

  # Dry run with recursive mode
  $0 10 --project 1 --owner @me --recursive --dry-run
EOF
  exit 1
}

# Default values
PARENT_ISSUE=""
REPO=""
PROJECT_NUMBER=""
PROJECT_OWNER=""
RECURSIVE=false
MAX_DEPTH=10
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --repo) REPO="$2"; shift 2 ;;
    --project) PROJECT_NUMBER="$2"; shift 2 ;;
    --owner) PROJECT_OWNER="$2"; shift 2 ;;
    --recursive) RECURSIVE=true; shift ;;
    --max-depth) MAX_DEPTH="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) usage ;;
    -*) echo "Unknown option: $1"; usage ;;
    *) PARENT_ISSUE="$1"; shift ;;
  esac
done

# Validate required arguments
[[ -z "$PARENT_ISSUE" ]] && { echo "Error: parent_issue_number is required"; usage; }
[[ -z "$PROJECT_NUMBER" ]] && { echo "Error: --project is required"; usage; }
[[ -z "$PROJECT_OWNER" ]] && { echo "Error: --owner is required"; usage; }

REPO="${REPO:-$(get_repo)}"

# ============================================================
# GraphQL Functions (adapted from pm-project-fields.sh)
# ============================================================

# Get project ID for user or organization
get_project_id() {
  local owner="$1" number="$2"
  local query result

  if [[ "$owner" == "@me" ]]; then
    query='query($number: Int!) {
      viewer {
        projectV2(number: $number) {
          id
        }
      }
    }'
    result=$(gh api graphql -F number="$number" -f query="$query" --jq '.data.viewer.projectV2.id')
  else
    # Try organization first
    query='query($login: String!, $number: Int!) {
      organization(login: $login) {
        projectV2(number: $number) {
          id
        }
      }
    }'
    result=$(gh api graphql -f login="$owner" -F number="$number" -f query="$query" --jq '.data.organization.projectV2.id' 2>/dev/null) || true

    if [[ -z "$result" || "$result" == "null" ]]; then
      # Try as user
      query='query($login: String!, $number: Int!) {
        user(login: $login) {
          projectV2(number: $number) {
            id
          }
        }
      }'
      result=$(gh api graphql -f login="$owner" -F number="$number" -f query="$query" --jq '.data.user.projectV2.id')
    fi
  fi

  echo "$result"
}

# Get all fields including iteration configuration
get_project_fields() {
  local project_id="$1"
  local query='query($projectId: ID!) {
    node(id: $projectId) {
      ... on ProjectV2 {
        fields(first: 50) {
          nodes {
            ... on ProjectV2Field {
              id
              name
              dataType
            }
            ... on ProjectV2IterationField {
              id
              name
              dataType
              configuration {
                iterations {
                  id
                  title
                  startDate
                }
              }
            }
            ... on ProjectV2SingleSelectField {
              id
              name
              dataType
              options {
                id
                name
              }
            }
          }
        }
      }
    }
  }'

  gh api graphql -f projectId="$project_id" -f query="$query" --jq '.data.node.fields.nodes'
}

# Get issue's project item and its iteration value
get_issue_iteration() {
  local repo="$1" issue_number="$2" project_number="$3"
  local owner="${repo%%/*}"
  local repo_name="${repo##*/}"

  local query='query($owner: String!, $repo: String!, $issueNumber: Int!) {
    repository(owner: $owner, name: $repo) {
      issue(number: $issueNumber) {
        title
        projectItems(first: 10) {
          nodes {
            id
            project {
              id
              number
            }
            fieldValues(first: 20) {
              nodes {
                ... on ProjectV2ItemFieldIterationValue {
                  iterationId
                  title
                  field {
                    ... on ProjectV2IterationField {
                      id
                      name
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }'

  local result
  result=$(gh api graphql \
    -f owner="$owner" \
    -f repo="$repo_name" \
    -F issueNumber="$issue_number" \
    -f query="$query")

  # Extract issue title
  local issue_title
  issue_title=$(echo "$result" | jq -r '.data.repository.issue.title // ""')

  # Find the project item for the specified project
  local iteration_info
  iteration_info=$(echo "$result" | jq -r --argjson pn "$project_number" '
    .data.repository.issue.projectItems.nodes[]
    | select(.project.number == $pn)
    | .fieldValues.nodes[]
    | select(.iterationId != null)
    | {iterationId: .iterationId, title: .title, fieldId: .field.id, itemId: ""}
  ' 2>/dev/null | head -1)

  # Get the item ID separately
  local item_id
  item_id=$(echo "$result" | jq -r --argjson pn "$project_number" '
    .data.repository.issue.projectItems.nodes[]
    | select(.project.number == $pn)
    | .id
  ' 2>/dev/null | head -1)

  if [[ -n "$iteration_info" && "$iteration_info" != "null" ]]; then
    # Add item_id to the result
    echo "$iteration_info" | jq -c --arg iid "$item_id" --arg it "$issue_title" '. + {itemId: $iid, issueTitle: $it}'
  else
    echo "{\"iterationId\": null, \"title\": null, \"fieldId\": null, \"itemId\": \"$item_id\", \"issueTitle\": \"$issue_title\"}"
  fi
}

# Get issue node ID
get_issue_node_id() {
  local repo="$1" issue_number="$2"
  gh api "repos/$repo/issues/$issue_number" --jq '.node_id'
}

# Add issue to project, returns item ID
add_issue_to_project() {
  local project_id="$1" content_id="$2"
  local mutation='mutation($projectId: ID!, $contentId: ID!) {
    addProjectV2ItemById(input: {
      projectId: $projectId
      contentId: $contentId
    }) {
      item {
        id
      }
    }
  }'

  gh api graphql -f projectId="$project_id" -f contentId="$content_id" -f query="$mutation" \
    --jq '.data.addProjectV2ItemById.item.id'
}

# Update iteration field
update_iteration_field() {
  local project_id="$1" item_id="$2" field_id="$3" iteration_id="$4"
  local mutation='mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $iterationId: String!) {
    updateProjectV2ItemFieldValue(input: {
      projectId: $projectId
      itemId: $itemId
      fieldId: $fieldId
      value: {
        iterationId: $iterationId
      }
    }) {
      projectV2Item {
        id
      }
    }
  }'

  gh api graphql -f projectId="$project_id" -f itemId="$item_id" -f fieldId="$field_id" \
    -f iterationId="$iteration_id" -f query="$mutation" --jq '.data.updateProjectV2ItemFieldValue.projectV2Item.id'
}

# Find iteration field ID
find_iteration_field_id() {
  local fields_json="$1"
  echo "$fields_json" | jq -r '.[] | select(.dataType == "ITERATION") | .id' | head -1
}

# ============================================================
# Main Execution
# ============================================================

echo ""
echo "═══════════════════════════════════════════════"
echo "📋 pm-cascade-iteration.sh"
echo "───────────────────────────────────────────────"
echo "  Repository: $REPO"
echo "  Project: #$PROJECT_NUMBER"
echo "  Parent: #$PARENT_ISSUE"
[[ "$RECURSIVE" == true ]] && echo "  Mode: RECURSIVE (max depth: $MAX_DEPTH)"
[[ "$DRY_RUN" == true ]] && echo "  Mode: DRY RUN"
echo "═══════════════════════════════════════════════"
echo ""

# Step 1: Get project ID
echo "Fetching project information..."
PROJECT_ID=$(get_project_id "$PROJECT_OWNER" "$PROJECT_NUMBER")

if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "null" ]]; then
  echo "Error: Could not find project #$PROJECT_NUMBER for owner $PROJECT_OWNER" >&2
  exit 1
fi

# Step 2: Get project fields
FIELDS_JSON=$(get_project_fields "$PROJECT_ID")
ITERATION_FIELD_ID=$(find_iteration_field_id "$FIELDS_JSON")

if [[ -z "$ITERATION_FIELD_ID" || "$ITERATION_FIELD_ID" == "null" ]]; then
  echo "Error: Project #$PROJECT_NUMBER does not have an Iteration field" >&2
  exit 1
fi

# Step 3: Get parent issue's iteration
echo "Fetching parent #$PARENT_ISSUE iteration..."
PARENT_ITERATION_JSON=$(get_issue_iteration "$REPO" "$PARENT_ISSUE" "$PROJECT_NUMBER")

PARENT_ITERATION_ID=$(echo "$PARENT_ITERATION_JSON" | jq -r '.iterationId // empty')
PARENT_ITERATION_TITLE=$(echo "$PARENT_ITERATION_JSON" | jq -r '.title // empty')
PARENT_ISSUE_TITLE=$(echo "$PARENT_ITERATION_JSON" | jq -r '.issueTitle // empty')

if [[ -z "$PARENT_ITERATION_ID" || "$PARENT_ITERATION_ID" == "null" ]]; then
  echo ""
  echo "Error: Parent issue #$PARENT_ISSUE does not have an iteration set" >&2
  echo "Please set an iteration for the parent issue first using:" >&2
  echo "  pm-project-fields.sh $PARENT_ISSUE --project $PROJECT_NUMBER --owner $PROJECT_OWNER --iteration \"Sprint Name\"" >&2
  exit 1
fi

echo "  Parent: #$PARENT_ISSUE - $PARENT_ISSUE_TITLE"
echo "  Iteration: $PARENT_ITERATION_TITLE"
echo ""

# Step 4: Get sub-issues (direct or recursive)
if [[ "$RECURSIVE" == true ]]; then
  echo "Fetching all descendants (recursive)..."
  DESCENDANTS_JSON=$(get_all_descendants "$REPO" "$PARENT_ISSUE" "$MAX_DEPTH")
  TOTAL_COUNT=$(echo "$DESCENDANTS_JSON" | jq 'length')
else
  echo "Cascading to sub-issues..."
  DESCENDANTS_JSON=$(get_child_issues "$REPO" "$PARENT_ISSUE")
  TOTAL_COUNT=$(echo "$DESCENDANTS_JSON" | jq 'length')
fi

if [[ "$TOTAL_COUNT" -eq 0 ]]; then
  print_warn "No sub-issues found for #$PARENT_ISSUE"
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "📊 Summary"
  echo "───────────────────────────────────────────────"
  echo "  Parent: #$PARENT_ISSUE ($PARENT_ITERATION_TITLE)"
  echo "  Sub-issues: 0"
  echo "═══════════════════════════════════════════════"
  exit 0
fi

echo "  Found $TOTAL_COUNT issue(s) to process"
echo ""

# Step 5: Process each sub-issue
updated_count=0
skipped_count=0
max_depth_reached=0
current_depth=0

# Process by depth level for better output
if [[ "$RECURSIVE" == true ]]; then
  for depth in $(echo "$DESCENDANTS_JSON" | jq -r '.[].depth' | sort -u); do
    echo "Level $depth:"
    max_depth_reached=$depth

    while IFS= read -r item; do
      [[ -z "$item" ]] && continue

      sub_issue=$(echo "$item" | jq -r '.number')
      sub_issue_title=$(echo "$item" | jq -r '.title')

      # Get sub-issue's current iteration
      sub_iteration_json=$(get_issue_iteration "$REPO" "$sub_issue" "$PROJECT_NUMBER")
      sub_iteration_id=$(echo "$sub_iteration_json" | jq -r '.iterationId // empty')
      sub_item_id=$(echo "$sub_iteration_json" | jq -r '.itemId // empty')

      # Check if already has the same iteration
      if [[ "$sub_iteration_id" == "$PARENT_ITERATION_ID" ]]; then
        print_skip "#$sub_issue: $sub_issue_title (already $PARENT_ITERATION_TITLE)"
        ((skipped_count++))
        continue
      fi

      if [[ "$DRY_RUN" == true ]]; then
        echo "  Would update #$sub_issue: $sub_issue_title → $PARENT_ITERATION_TITLE"
        ((updated_count++))
        continue
      fi

      # Add to project if not already added
      if [[ -z "$sub_item_id" || "$sub_item_id" == "null" ]]; then
        node_id=$(get_issue_node_id "$REPO" "$sub_issue")
        sub_item_id=$(add_issue_to_project "$PROJECT_ID" "$node_id")
        if [[ -z "$sub_item_id" || "$sub_item_id" == "null" ]]; then
          print_warn "Failed to add #$sub_issue to project"
          continue
        fi
      fi

      # Update iteration
      if update_iteration_field "$PROJECT_ID" "$sub_item_id" "$ITERATION_FIELD_ID" "$PARENT_ITERATION_ID" >/dev/null 2>&1; then
        print_success "#$sub_issue: $sub_issue_title → $PARENT_ITERATION_TITLE"
        ((updated_count++))
      else
        print_warn "Failed to update #$sub_issue"
      fi
    done < <(echo "$DESCENDANTS_JSON" | jq -c --argjson d "$depth" '.[] | select(.depth == $d)')
    echo ""
  done
else
  # Non-recursive mode: process direct children only
  while IFS= read -r item; do
    [[ -z "$item" ]] && continue

    sub_issue=$(echo "$item" | jq -r '.number')
    sub_issue_title=$(echo "$item" | jq -r '.title')

    # Get sub-issue's current iteration
    sub_iteration_json=$(get_issue_iteration "$REPO" "$sub_issue" "$PROJECT_NUMBER")
    sub_iteration_id=$(echo "$sub_iteration_json" | jq -r '.iterationId // empty')
    sub_item_id=$(echo "$sub_iteration_json" | jq -r '.itemId // empty')

    # Check if already has the same iteration
    if [[ "$sub_iteration_id" == "$PARENT_ITERATION_ID" ]]; then
      print_skip "#$sub_issue: $sub_issue_title (already $PARENT_ITERATION_TITLE)"
      ((skipped_count++))
      continue
    fi

    if [[ "$DRY_RUN" == true ]]; then
      echo "Would update #$sub_issue: $sub_issue_title → $PARENT_ITERATION_TITLE"
      ((updated_count++))
      continue
    fi

    # Add to project if not already added
    if [[ -z "$sub_item_id" || "$sub_item_id" == "null" ]]; then
      node_id=$(get_issue_node_id "$REPO" "$sub_issue")
      sub_item_id=$(add_issue_to_project "$PROJECT_ID" "$node_id")
      if [[ -z "$sub_item_id" || "$sub_item_id" == "null" ]]; then
        print_warn "Failed to add #$sub_issue to project"
        continue
      fi
    fi

    # Update iteration
    if update_iteration_field "$PROJECT_ID" "$sub_item_id" "$ITERATION_FIELD_ID" "$PARENT_ITERATION_ID" >/dev/null 2>&1; then
      print_success "#$sub_issue: $sub_issue_title → $PARENT_ITERATION_TITLE"
      ((updated_count++))
    else
      print_warn "Failed to update #$sub_issue"
    fi
  done < <(echo "$DESCENDANTS_JSON" | jq -c '.[]')
fi

# Step 6: Summary
echo "═══════════════════════════════════════════════"
echo "📊 Summary"
echo "───────────────────────────────────────────────"
echo "  Parent: #$PARENT_ISSUE ($PARENT_ITERATION_TITLE)"
echo "  Updated: $updated_count issue(s)"
echo "  Skipped: $skipped_count issue(s)"
[[ "$RECURSIVE" == true ]] && echo "  Max depth reached: $max_depth_reached"
echo "═══════════════════════════════════════════════"
