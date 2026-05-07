#!/bin/bash
# pm-utils.sh - PM Agent Common Utilities
# Usage: source pm-utils.sh
#
# This file provides common functions for pm-agent scripts.
# All functions are designed to work with sandbox restrictions.

# Load security utilities (required)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECURITY_UTILS="${SCRIPT_DIR}/../../../scripts/security-utils.sh"
if [[ -f "$SECURITY_UTILS" ]]; then
	# shellcheck source=../../../scripts/security-utils.sh
	source "$SECURITY_UTILS"
fi

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

	validate_repo "$repo" || return 1
	validate_number "$issue_number" || return 1

	gh api "repos/$repo/issues/$issue_number" \
		-X PATCH \
		-f type="$issue_type" \
		--silent
}

# Create milestone (REST API)
# Note: due_on is required by pm-agent policy for deadline management
create_milestone() {
	local repo="$1" title="$2" due_on="$3"

	validate_repo "$repo" || return 1
	[[ -z "$due_on" ]] && {
		echo "Error: due_on is required (pm-agent policy)" >&2
		return 1
	}
	validate_date "$due_on" || return 1

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

	validate_repo "$repo" || return 1
	validate_number "$issue_number" || return 1

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

	validate_repo "$repo" || return 1
	validate_number "$parent_number" || return 1
	validate_number "$child_number" || return 1

	local child_id
	child_id=$(get_issue_id "$repo" "$child_number")

	if ! [[ "$child_id" =~ ^[0-9]+$ ]]; then
		echo "Error: Invalid issue ID for #$child_number" >&2
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

	validate_repo "$repo" || return 1
	validate_number "$issue_number" || return 1
	validate_number "$milestone_number" || return 1

	gh api "repos/$repo/issues/$issue_number" \
		-X PATCH \
		-F milestone="$milestone_number" \
		--silent
}

# Save checkpoint (for error recovery)
save_checkpoint() {
	local checkpoint_file="$1" number="$2" title="$3"
	if [[ ! -f "$checkpoint_file" ]]; then
		echo '{"created":[]}' >"$checkpoint_file"
	fi
	jq --arg n "$number" --arg t "$title" \
		'.created += [{"number": $n, "title": $t}]' "$checkpoint_file" >"${checkpoint_file}.tmp"
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

# ============================================================
# Sub-issue Traversal Functions
# ============================================================

# Get direct child issues with title
# Returns: JSON array of {number, title}
# Example: [{"number": 11, "title": "Feature A"}, ...]
get_child_issues() {
	local repo="$1" parent_number="$2"
	gh api "repos/$repo/issues/$parent_number/sub_issues" \
		--jq '[.[] | {number: .number, title: .title}]' 2>/dev/null || echo "[]"
}

# Get all descendants of an issue recursively (BFS)
# Returns: JSON array of {number, title, depth}
# Example: [{"number": 11, "title": "Feature A", "depth": 1}, ...]
get_all_descendants() {
	local repo="$1" parent_number="$2" max_depth="${3:-10}"

	local result="[]"
	local current_queue next_queue
	local current_depth=1

	# Initialize with direct children
	current_queue=$(gh api "repos/$repo/issues/$parent_number/sub_issues" \
		--jq '[.[] | {number: .number, title: .title}]' 2>/dev/null || echo "[]")

	while [[ $(echo "$current_queue" | jq 'length') -gt 0 ]] && [[ $current_depth -le $max_depth ]]; do
		next_queue="[]"

		# Process each item in current queue
		while IFS= read -r item; do
			[[ -z "$item" ]] && continue

			local num title
			num=$(echo "$item" | jq -r '.number')
			title=$(echo "$item" | jq -r '.title')

			# Add to result with depth
			result=$(echo "$result" | jq --argjson n "$num" --arg t "$title" --argjson d "$current_depth" \
				'. + [{number: $n, title: $t, depth: $d}]')

			# Get children for next level (if not at max depth)
			if [[ $current_depth -lt $max_depth ]]; then
				local children
				children=$(gh api "repos/$repo/issues/$num/sub_issues" \
					--jq '[.[] | {number: .number, title: .title}]' 2>/dev/null || echo "[]")
				next_queue=$(echo "[$next_queue, $children]" | jq -s 'add | add // []')
			fi
		done < <(echo "$current_queue" | jq -c '.[]')

		current_queue="$next_queue"
		((current_depth++))
	done

	echo "$result"
}

# ============================================================
# GitHub Projects V2 GraphQL Functions
# ============================================================

# Get project ID for user or organization
# Usage: get_project_id "@me" 1  OR  get_project_id "org-name" 1
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

# Get issue node ID (GraphQL ID)
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

# Update iteration field value
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

# Find iteration field ID from project fields JSON
find_iteration_field_id() {
	local fields_json="$1"
	echo "$fields_json" | jq -r '.[] | select(.dataType == "ITERATION") | .id' | head -1
}

# Find iteration ID by title from project fields JSON
find_iteration_id_by_title() {
	local fields_json="$1" title="$2"
	echo "$fields_json" | jq -r --arg t "$title" '
    .[] | select(.dataType == "ITERATION") | .configuration.iterations[]? | select(.title == $t) | .id
  ' | head -1
}

# Get available iterations from project fields JSON
get_available_iterations() {
	local fields_json="$1"
	echo "$fields_json" | jq -r '.[] | select(.dataType == "ITERATION") | .configuration.iterations[]? | .title'
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
	# Note: Using 'select(.iterationId)' instead of 'select(.iterationId != null)'
	# to avoid bash history expansion issues with '!' character
	# Note: Using 'jq -c' for compact output and array indexing to get first match
	iteration_info=$(echo "$result" | jq -c --argjson pn "$project_number" '
    [.data.repository.issue.projectItems.nodes[]
    | select(.project.number == $pn)
    | .fieldValues.nodes[]
    | select(.iterationId)
    | {iterationId: .iterationId, title: .title, fieldId: .field.id, itemId: ""}][0] // null
  ' 2>/dev/null)

	# Get the item ID separately
	local item_id
	item_id=$(echo "$result" | jq -r --argjson pn "$project_number" '
    [.data.repository.issue.projectItems.nodes[]
    | select(.project.number == $pn)
    | .id][0] // empty
  ' 2>/dev/null)

	if [[ -n "$iteration_info" && "$iteration_info" != "null" ]]; then
		# Add item_id to the result
		echo "$iteration_info" | jq -c --arg iid "$item_id" --arg it "$issue_title" '. + {itemId: $iid, issueTitle: $it}'
	else
		echo "{\"iterationId\": null, \"title\": null, \"fieldId\": null, \"itemId\": \"$item_id\", \"issueTitle\": \"$issue_title\"}"
	fi
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

	# Note: Using pipe to jq instead of --jq because we need --argjson for project_number
	gh api graphql \
		-f owner="$owner" \
		-f repo="$repo_name" \
		-F issueNumber="$issue_number" \
		-f query="$query" 2>/dev/null | jq -r --argjson pn "$project_number" '
      [.data.repository.issue.projectItems.nodes[]
      | select(.project.number == $pn)
      | .id][0] // empty
    '
}

# ============================================================
# Multi-repo Resolution: Repo <-> Projects V2 Reverse Lookup
# ============================================================

# Get GitHub Projects V2 associated with a repository (open only)
#
# Two paths are merged:
#   (1) Linked projects (fast)
#       repository.projectsV2 returns projects explicitly linked via
#       Project Settings > Workflows > Linked repositories.
#   (2) Item-bearing projects (fallback scan)
#       Owner's projects whose items reference any Issue/PR from this repo.
#       This is required because adding an Issue to a Project does NOT
#       automatically link the repository.
#
# Input:  owner/repo
# Output: JSON array of {id, number, title, url, ownerLogin, ownerType} (distinct by id)
get_projects_for_repo() {
	local repo="$1"
	validate_repo "$repo" || return 1

	local owner="${repo%%/*}"
	local name="${repo##*/}"

	# --- Path 1: Linked projects (repository.projectsV2) ---
	local linked_query='query($owner: String!, $name: String!) {
    repository(owner: $owner, name: $name) {
      projectsV2(first: 20) {
        nodes {
          id
          number
          title
          url
          closed
          owner {
            __typename
            ... on User { login }
            ... on Organization { login }
          }
        }
      }
    }
  }'

	local linked
	linked=$(gh api graphql \
		-f owner="$owner" \
		-f name="$name" \
		-f query="$linked_query" \
		--jq '[.data.repository.projectsV2.nodes[]
           | select(.closed == false)
           | {id, number, title, url,
              ownerLogin: .owner.login,
              ownerType: .owner.__typename}]' 2>/dev/null) || linked="[]"

	# --- Path 2: Scan owner's projects for items referencing this repo ---
	local owner_type
	owner_type=$(gh api "users/$owner" --jq '.type' 2>/dev/null)

	local owner_projects_query
	if [[ "$owner_type" == "Organization" ]]; then
		owner_projects_query='query($login: String!) {
      organization(login: $login) {
        projectsV2(first: 50) {
          nodes {
            id
            number
            title
            url
            closed
            owner {
              __typename
              ... on User { login }
              ... on Organization { login }
            }
          }
        }
      }
    }'
	else
		owner_projects_query='query($login: String!) {
      user(login: $login) {
        projectsV2(first: 50) {
          nodes {
            id
            number
            title
            url
            closed
            owner {
              __typename
              ... on User { login }
              ... on Organization { login }
            }
          }
        }
      }
    }'
	fi

	local all_projects
	all_projects=$(gh api graphql \
		-f login="$owner" \
		-f query="$owner_projects_query" \
		--jq '[.data | (.organization // .user) | .projectsV2.nodes[] | select(.closed == false)]' 2>/dev/null) || all_projects="[]"

	local matched="[]"
	while IFS= read -r project; do
		[[ -z "$project" ]] && continue
		local pid
		pid=$(echo "$project" | jq -r '.id')

		local repos
		repos=$(get_project_scope_repos "$pid" 2>/dev/null) || continue

		if echo "$repos" | jq -e --arg r "$repo" 'any(.[]?; . == $r)' >/dev/null 2>&1; then
			local entry
			entry=$(echo "$project" | jq '{id, number, title, url,
                                       ownerLogin: .owner.login,
                                       ownerType: .owner.__typename}')
			matched=$(jq -n --argjson a "$matched" --argjson b "$entry" '$a + [$b]')
		fi
	done < <(echo "$all_projects" | jq -c '.[]')

	# --- Union (distinct by id) ---
	jq -n --argjson a "$linked" --argjson b "$matched" '$a + $b | unique_by(.id)'
}

# Get project meta by GraphQL node ID
# Input:  project_id (GraphQL node ID, e.g. PVT_xxx)
# Output: JSON {id, number, title, url, ownerLogin, ownerType} (single object)
get_project_meta_by_id() {
	local project_id="$1"
	[[ -z "$project_id" ]] && {
		echo "Error: project_id is required" >&2
		return 1
	}

	local query='query($id: ID!) {
    node(id: $id) {
      ... on ProjectV2 {
        id
        number
        title
        url
        closed
        owner {
          __typename
          ... on User { login }
          ... on Organization { login }
        }
      }
    }
  }'

	gh api graphql -f id="$project_id" -f query="$query" \
		--jq '.data.node | {id, number, title, url, closed,
                        ownerLogin: .owner.login,
                        ownerType: .owner.__typename}'
}

# Get all items in a Project V2 with pagination
# Input:  project_id (GraphQL node ID)
# Output: JSON array of items with content (Issue/PR), repository, fieldValues
get_project_items() {
	local project_id="$1"

	[[ -z "$project_id" ]] && {
		echo "Error: project_id is required" >&2
		return 1
	}

	local query='query($projectId: ID!, $cursor: String) {
    node(id: $projectId) {
      ... on ProjectV2 {
        items(first: 100, after: $cursor) {
          pageInfo { hasNextPage endCursor }
          nodes {
            id
            content {
              __typename
              ... on Issue {
                number
                title
                state
                repository { nameWithOwner }
                labels(first: 20) { nodes { name } }
              }
              ... on PullRequest {
                number
                title
                state
                repository { nameWithOwner }
              }
            }
            fieldValues(first: 30) {
              nodes {
                ... on ProjectV2ItemFieldIterationValue {
                  title
                  field { ... on ProjectV2IterationField { name } }
                }
                ... on ProjectV2ItemFieldSingleSelectValue {
                  name
                  field { ... on ProjectV2SingleSelectField { name } }
                }
              }
            }
          }
        }
      }
    }
  }'

	local result="[]"
	local cursor=""
	local has_next="true"

	while [[ "$has_next" == "true" ]]; do
		local response
		if [[ -z "$cursor" ]]; then
			response=$(gh api graphql -f projectId="$project_id" -f query="$query")
		else
			response=$(gh api graphql -f projectId="$project_id" -f cursor="$cursor" -f query="$query")
		fi

		local page_nodes
		page_nodes=$(echo "$response" | jq '.data.node.items.nodes // []')
		result=$(jq -n --argjson a "$result" --argjson b "$page_nodes" '$a + $b')

		has_next=$(echo "$response" | jq -r '.data.node.items.pageInfo.hasNextPage // false')
		cursor=$(echo "$response" | jq -r '.data.node.items.pageInfo.endCursor // empty')
	done

	echo "$result"
}

# Get distinct repos referenced in a Project's items
# Input:  project_id (GraphQL node ID)
# Output: JSON array of "owner/repo" strings (unique, sorted)
get_project_scope_repos() {
	local project_id="$1"
	get_project_items "$project_id" |
		jq '[.[].content
           | select(.__typename == "Issue" or .__typename == "PullRequest")
           | .repository.nameWithOwner] | unique'
}

# ============================================================
# Cache Helpers (Session-scoped, TTL-based)
# ============================================================

# Check if cache file is fresh (within TTL seconds)
# Input:  file_path, ttl_seconds (default 300)
# Returns: 0 (fresh), 1 (stale or missing)
is_cache_fresh() {
	local file="$1" ttl="${2:-300}"
	[[ -f "$file" ]] || return 1

	local mtime now age
	if [[ "$(uname)" == "Darwin" ]]; then
		mtime=$(stat -f %m "$file" 2>/dev/null) || return 1
	else
		mtime=$(stat -c %Y "$file" 2>/dev/null) || return 1
	fi
	now=$(date +%s)
	age=$((now - mtime))

	[[ $age -lt $ttl ]]
}

# Cache directory for vw-pm session caches
get_pm_cache_dir() {
	local dir="${TMPDIR:-/tmp}/vw-pm"
	mkdir -p "$dir"
	echo "$dir"
}

# Sanitize a string for use in a filename
# Input:  arbitrary string
# Output: alphanumeric + underscore only
_pm_sanitize() {
	local s="$1"
	echo "${s//[^a-zA-Z0-9]/_}"
}

# Read scope cache for a project (SCOPE_REPOS + project meta)
# Input:  project_id
# Output: JSON if fresh, exit 1 otherwise
read_scope_cache() {
	local project_id="$1"
	local cache_file
	cache_file="$(get_pm_cache_dir)/scope-$(_pm_sanitize "$project_id").json"

	if is_cache_fresh "$cache_file" 300; then
		cat "$cache_file"
		return 0
	fi
	return 1
}

# Write scope cache for a project
# Input:  project_id, json_content
write_scope_cache() {
	local project_id="$1" data="$2"
	local cache_file
	cache_file="$(get_pm_cache_dir)/scope-$(_pm_sanitize "$project_id").json"
	printf '%s\n' "$data" >"$cache_file"
}

# ============================================================
# Repo Metadata + Category Classification
# ============================================================

# Get repo metadata with cache (TTL: 5min)
# Input:  owner/repo
# Output: JSON {language, topics, name, pushed_at, fullName}
get_repo_meta() {
	local repo="$1"
	validate_repo "$repo" || return 1

	local cache_file
	cache_file="$(get_pm_cache_dir)/repo-meta-$(_pm_sanitize "$repo").json"

	if is_cache_fresh "$cache_file" 300; then
		cat "$cache_file"
		return 0
	fi

	local meta
	meta=$(gh api "repos/$repo" --jq '{
    language,
    topics,
    name,
    pushed_at,
    fullName: .full_name
  }') || return 1

	printf '%s\n' "$meta" >"$cache_file"
	printf '%s\n' "$meta"
}

# Classify a repository as dev | other | unknown
# Priority: name pattern -> topics -> primary language
# Input:  owner/repo
# Output: dev | other | unknown
classify_repo_meta() {
	local repo="$1"
	local meta
	meta=$(get_repo_meta "$repo") || return 1

	local language name topics_csv
	language=$(echo "$meta" | jq -r '.language // empty')
	name=$(echo "$meta" | jq -r '.name // empty')
	topics_csv=$(echo "$meta" | jq -r '.topics // [] | join(",")')

	# Step 1: name pattern (strong signal)
	case "$name" in
	*-frontend | *-backend | *-app | *-api | *-web | *-mobile | *-server | *-client)
		echo "dev"
		return 0
		;;
	*-docs | *-wiki | *-pm | *-roadmap | *-notes | *-planning)
		echo "other"
		return 0
		;;
	esac

	# Step 2: topics
	case ",$topics_csv," in
	*,documentation,* | *,project-management,* | *,planning,* | *,wiki,*)
		echo "other"
		return 0
		;;
	esac

	# Step 3: primary language
	case "$language" in
	TypeScript | JavaScript | Python | Go | Rust | Lua | Ruby | Java | C | C++ | Swift | Kotlin | PHP | Shell | Dockerfile | "Vim Script" | "Vim script")
		echo "dev"
		return 0
		;;
	Markdown | "")
		echo "other"
		return 0
		;;
	esac

	echo "unknown"
}

# ============================================================
# Main Repository Resolution
# ============================================================

# Resolve the "main repository" from SCOPE_REPOS
# Priority:
#   1. cwd repo if it appears in SCOPE_REPOS
#   2. most recently pushed dev-classified repo
#   3. first repo in SCOPE_REPOS (final fallback)
# Input:  cwd_repo (may be empty), scope_repos_json (JSON array)
# Output: owner/repo (single string)
resolve_main_repo() {
	local cwd_repo="$1" scope_repos_json="$2"

	# Priority 1: cwd repo if in scope
	if [[ -n "$cwd_repo" ]]; then
		local match
		match=$(echo "$scope_repos_json" | jq -r --arg r "$cwd_repo" '.[] | select(. == $r)')
		if [[ -n "$match" ]]; then
			echo "$cwd_repo"
			return 0
		fi
	fi

	# Priority 2: most recently pushed dev-classified repo
	local best="" best_pushed=""
	while IFS= read -r repo; do
		[[ -z "$repo" ]] && continue
		local cat
		cat=$(classify_repo_meta "$repo" 2>/dev/null || echo "unknown")
		if [[ "$cat" == "dev" ]]; then
			local pushed
			pushed=$(get_repo_meta "$repo" 2>/dev/null | jq -r '.pushed_at // empty')
			if [[ -z "$best_pushed" ]] || [[ "$pushed" > "$best_pushed" ]]; then
				best="$repo"
				best_pushed="$pushed"
			fi
		fi
	done < <(echo "$scope_repos_json" | jq -r '.[]')

	if [[ -n "$best" ]]; then
		echo "$best"
		return 0
	fi

	# Priority 3: first repo (final fallback)
	echo "$scope_repos_json" | jq -r '.[0] // empty'
}
