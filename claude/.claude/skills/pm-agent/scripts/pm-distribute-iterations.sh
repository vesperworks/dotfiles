#!/bin/bash
# pm-distribute-iterations.sh - Distribute child issues across iterations
# Usage: pm-distribute-iterations.sh <parent_issue_number> [options]
#
# Distributes child issues (e.g., Features under an Epic) across multiple
# iterations, with optional cascading to descendants.
#
# Reference: https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project/using-the-api-to-manage-projects

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pm-utils.sh"

usage() {
  cat << EOF
Usage: $0 <parent_issue_number> [options]

Distribute child issues across multiple iterations.

Options:
  --repo <owner/repo>        Repository (default: auto-detect from git remote)
  --project <number>         Project number (required)
  --owner <login>            Project owner (@me for user, or org name)
  --iterations <list>        Comma-separated iteration names (required)
                             Example: "Sprint 1,Sprint 2,Sprint 3"
  --order <issue_numbers>    Custom order of issues (comma-separated)
                             Example: "15,12,18,14,16,13"
  --cascade                  Also cascade iteration to descendants of each issue
  --list                     List child issues and exit (for planning)
  --dry-run                  Show what would be done without executing
  -h, --help                 Show this help

Examples:
  # List Features under Epic #10
  $0 10 --project 1 --owner @me --list

  # Distribute Features across 3 sprints
  $0 10 --project 1 --owner @me --iterations "Sprint 1,Sprint 2,Sprint 3"

  # Custom order with cascade
  $0 10 --project 1 --owner @me \\
    --iterations "Sprint 1,Sprint 2,Sprint 3" \\
    --order "15,12,18,14,16,13" \\
    --cascade
EOF
  exit 1
}

# Default values
PARENT_ISSUE=""
REPO=""
PROJECT_NUMBER=""
PROJECT_OWNER=""
ITERATIONS=""
CUSTOM_ORDER=""
CASCADE=false
LIST_ONLY=false
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --repo) REPO="$2"; shift 2 ;;
    --project) PROJECT_NUMBER="$2"; shift 2 ;;
    --owner) PROJECT_OWNER="$2"; shift 2 ;;
    --iterations) ITERATIONS="$2"; shift 2 ;;
    --order) CUSTOM_ORDER="$2"; shift 2 ;;
    --cascade) CASCADE=true; shift ;;
    --list) LIST_ONLY=true; shift ;;
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
# GraphQL Functions (same as pm-cascade-iteration.sh)
# ============================================================

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
    query='query($login: String!, $number: Int!) {
      organization(login: $login) {
        projectV2(number: $number) {
          id
        }
      }
    }'
    result=$(gh api graphql -f login="$owner" -F number="$number" -f query="$query" --jq '.data.organization.projectV2.id' 2>/dev/null) || true

    if [[ -z "$result" || "$result" == "null" ]]; then
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

get_issue_node_id() {
  local repo="$1" issue_number="$2"
  gh api "repos/$repo/issues/$issue_number" --jq '.node_id'
}

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

find_iteration_field_id() {
  local fields_json="$1"
  echo "$fields_json" | jq -r '.[] | select(.dataType == "ITERATION") | .id' | head -1
}

find_iteration_id_by_title() {
  local fields_json="$1" title="$2"
  echo "$fields_json" | jq -r --arg t "$title" '
    .[] | select(.dataType == "ITERATION") | .configuration.iterations[]? | select(.title == $t) | .id
  ' | head -1
}

get_available_iterations() {
  local fields_json="$1"
  echo "$fields_json" | jq -r '.[] | select(.dataType == "ITERATION") | .configuration.iterations[]? | .title'
}

# Get issue's project item ID (for updating fields)
get_issue_item_id() {
  local repo="$1" issue_number="$2" project_number="$3"
  local owner="${repo%%/*}"
  local repo_name="${repo##*/}"

  local query='query($owner: String!, $repo: String!, $issueNumber: Int!) {
    repository(owner: $owner, name: $repo) {
      issue(number: $issueNumber) {
        projectItems(first: 10) {
          nodes {
            id
            project {
              number
            }
          }
        }
      }
    }
  }'

  gh api graphql \
    -f owner="$owner" \
    -f repo="$repo_name" \
    -F issueNumber="$issue_number" \
    -f query="$query" \
    --jq --argjson pn "$project_number" '.data.repository.issue.projectItems.nodes[] | select(.project.number == $pn) | .id' 2>/dev/null | head -1
}

# ============================================================
# Main Execution
# ============================================================

echo ""
echo "═══════════════════════════════════════════════"
echo "📋 pm-distribute-iterations.sh"
echo "───────────────────────────────────────────────"
echo "  Repository: $REPO"
echo "  Project: #$PROJECT_NUMBER"
echo "  Parent: #$PARENT_ISSUE"
[[ "$CASCADE" == true ]] && echo "  Cascade: enabled"
[[ "$DRY_RUN" == true ]] && echo "  Mode: DRY RUN"
echo "═══════════════════════════════════════════════"
echo ""

# Step 1: Get project ID and fields
echo "Fetching project information..."
PROJECT_ID=$(get_project_id "$PROJECT_OWNER" "$PROJECT_NUMBER")

if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "null" ]]; then
  echo "Error: Could not find project #$PROJECT_NUMBER for owner $PROJECT_OWNER" >&2
  exit 1
fi

FIELDS_JSON=$(get_project_fields "$PROJECT_ID")
ITERATION_FIELD_ID=$(find_iteration_field_id "$FIELDS_JSON")

if [[ -z "$ITERATION_FIELD_ID" || "$ITERATION_FIELD_ID" == "null" ]]; then
  echo "Error: Project #$PROJECT_NUMBER does not have an Iteration field" >&2
  exit 1
fi

# Step 2: Get parent issue info
PARENT_TITLE=$(gh api "repos/$REPO/issues/$PARENT_ISSUE" --jq '.title' 2>/dev/null || echo "Unknown")
echo "  Parent: #$PARENT_ISSUE - $PARENT_TITLE"
echo ""

# Step 3: Get child issues
CHILDREN_JSON=$(get_child_issues "$REPO" "$PARENT_ISSUE")
CHILD_COUNT=$(echo "$CHILDREN_JSON" | jq 'length')

if [[ "$CHILD_COUNT" -eq 0 ]]; then
  echo "Error: No child issues found for #$PARENT_ISSUE" >&2
  exit 1
fi

echo "Found $CHILD_COUNT child issue(s):"
echo ""

# Display child issues
idx=1
while IFS= read -r item; do
  num=$(echo "$item" | jq -r '.number')
  title=$(echo "$item" | jq -r '.title')
  echo "  $idx. #$num - $title"
  ((idx++))
done < <(echo "$CHILDREN_JSON" | jq -c '.[] | sort_by(.number)' 2>/dev/null || echo "$CHILDREN_JSON" | jq -c '.[]')

echo ""

# List-only mode
if [[ "$LIST_ONLY" == true ]]; then
  echo "Use --order to specify custom order, e.g.:"
  echo "  --order \"$(echo "$CHILDREN_JSON" | jq -r '[.[].number] | join(",")')\""
  exit 0
fi

# Validate iterations
if [[ -z "$ITERATIONS" ]]; then
  echo "Error: --iterations is required" >&2
  echo ""
  echo "Available iterations:"
  get_available_iterations "$FIELDS_JSON" | while read -r iter; do
    echo "  - $iter"
  done
  exit 1
fi

# Parse iterations into array
IFS=',' read -ra ITERATION_NAMES <<< "$ITERATIONS"
ITERATION_COUNT=${#ITERATION_NAMES[@]}

echo "Distribution plan:"
echo "  $CHILD_COUNT issue(s) → $ITERATION_COUNT iteration(s)"
echo ""

# Build ordered list of issues
if [[ -n "$CUSTOM_ORDER" ]]; then
  IFS=',' read -ra ORDERED_ISSUES <<< "$CUSTOM_ORDER"
  echo "Using custom order: $CUSTOM_ORDER"
else
  # Default: sort by issue number
  mapfile -t ORDERED_ISSUES < <(echo "$CHILDREN_JSON" | jq -r '.[].number' | sort -n)
  echo "Using default order (by issue number)"
fi

echo ""

# Calculate distribution
CHUNK_SIZE=$(( (${#ORDERED_ISSUES[@]} + ITERATION_COUNT - 1) / ITERATION_COUNT ))

# Validate iterations exist
for iter_name in "${ITERATION_NAMES[@]}"; do
  iter_name=$(echo "$iter_name" | xargs)  # Trim whitespace
  iter_id=$(find_iteration_id_by_title "$FIELDS_JSON" "$iter_name")
  if [[ -z "$iter_id" || "$iter_id" == "null" ]]; then
    echo "Error: Iteration '$iter_name' not found in project" >&2
    echo ""
    echo "Available iterations:"
    get_available_iterations "$FIELDS_JSON" | while read -r iter; do
      echo "  - $iter"
    done
    exit 1
  fi
done

# Show distribution plan
echo "Distribution:"
for ((i=0; i<ITERATION_COUNT; i++)); do
  iter_name=$(echo "${ITERATION_NAMES[$i]}" | xargs)
  start=$((i * CHUNK_SIZE))
  end=$((start + CHUNK_SIZE))
  if [[ $end -gt ${#ORDERED_ISSUES[@]} ]]; then
    end=${#ORDERED_ISSUES[@]}
  fi

  if [[ $start -lt ${#ORDERED_ISSUES[@]} ]]; then
    issues_in_iter=("${ORDERED_ISSUES[@]:$start:$((end-start))}")
    echo "  $iter_name: ${issues_in_iter[*]}"
  else
    echo "  $iter_name: (none)"
  fi
done

echo ""

# Dry run mode
if [[ "$DRY_RUN" == true ]]; then
  echo "DRY RUN - no changes made"
  exit 0
fi

# Execute distribution
echo "Executing distribution..."
echo ""

updated_count=0
cascade_count=0

for ((i=0; i<ITERATION_COUNT; i++)); do
  iter_name=$(echo "${ITERATION_NAMES[$i]}" | xargs)
  iter_id=$(find_iteration_id_by_title "$FIELDS_JSON" "$iter_name")

  start=$((i * CHUNK_SIZE))
  end=$((start + CHUNK_SIZE))
  if [[ $end -gt ${#ORDERED_ISSUES[@]} ]]; then
    end=${#ORDERED_ISSUES[@]}
  fi

  for ((j=start; j<end; j++)); do
    issue_num="${ORDERED_ISSUES[$j]}"
    issue_title=$(echo "$CHILDREN_JSON" | jq -r --argjson n "$issue_num" '.[] | select(.number == $n) | .title')

    # Get or create project item
    item_id=$(get_issue_item_id "$REPO" "$issue_num" "$PROJECT_NUMBER")
    if [[ -z "$item_id" || "$item_id" == "null" ]]; then
      node_id=$(get_issue_node_id "$REPO" "$issue_num")
      item_id=$(add_issue_to_project "$PROJECT_ID" "$node_id")
    fi

    if [[ -z "$item_id" || "$item_id" == "null" ]]; then
      print_warn "Failed to add #$issue_num to project"
      continue
    fi

    # Update iteration
    if update_iteration_field "$PROJECT_ID" "$item_id" "$ITERATION_FIELD_ID" "$iter_id" >/dev/null 2>&1; then
      print_success "#$issue_num: $issue_title → $iter_name"
      ((updated_count++))
    else
      print_warn "Failed to set iteration for #$issue_num"
      continue
    fi

    # Cascade to descendants if enabled
    if [[ "$CASCADE" == true ]]; then
      descendants=$(get_all_descendants "$REPO" "$issue_num" 10)
      desc_count=$(echo "$descendants" | jq 'length')

      if [[ "$desc_count" -gt 0 ]]; then
        while IFS= read -r desc; do
          [[ -z "$desc" ]] && continue

          desc_num=$(echo "$desc" | jq -r '.number')
          desc_title=$(echo "$desc" | jq -r '.title')
          desc_depth=$(echo "$desc" | jq -r '.depth')

          # Get or create project item for descendant
          desc_item_id=$(get_issue_item_id "$REPO" "$desc_num" "$PROJECT_NUMBER")
          if [[ -z "$desc_item_id" || "$desc_item_id" == "null" ]]; then
            desc_node_id=$(get_issue_node_id "$REPO" "$desc_num")
            desc_item_id=$(add_issue_to_project "$PROJECT_ID" "$desc_node_id")
          fi

          if [[ -n "$desc_item_id" && "$desc_item_id" != "null" ]]; then
            if update_iteration_field "$PROJECT_ID" "$desc_item_id" "$ITERATION_FIELD_ID" "$iter_id" >/dev/null 2>&1; then
              echo "    └── #$desc_num: $desc_title → $iter_name"
              ((cascade_count++))
            fi
          fi
        done < <(echo "$descendants" | jq -c '.[]')
      fi
    fi
  done
done

# Summary
echo ""
echo "═══════════════════════════════════════════════"
echo "📊 Summary"
echo "───────────────────────────────────────────────"
echo "  Parent: #$PARENT_ISSUE"
echo "  Issues distributed: $updated_count"
[[ "$CASCADE" == true ]] && echo "  Cascade updates: $cascade_count"
echo "  Iterations used: $ITERATION_COUNT"
echo "═══════════════════════════════════════════════"
