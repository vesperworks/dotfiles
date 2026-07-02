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
else
	echo "Warning: security-utils.sh not found at $SECURITY_UTILS (validate_* functions unavailable)" >&2
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
		return 1
	}

	# Parse owner/repo from remote URL
	# SSH format: git@github.com:owner/repo.git
	# HTTPS format: https://github.com/owner/repo.git
	local repo
	if [[ "$remote_url" =~ ^git@github\.com:(.+)\.git$ ]]; then
		repo="${BASH_REMATCH[1]}"
	elif [[ "$remote_url" =~ ^https://github\.com/(.+)\.git$ ]]; then
		repo="${BASH_REMATCH[1]}"
	elif [[ "$remote_url" =~ ^https://github\.com/([^/]+/[^/]+)/?$ ]]; then
		repo="${BASH_REMATCH[1]}"
	else
		echo "Error: Unsupported remote URL format: $remote_url" >&2
		return 1
	fi

	echo "$repo"
}

# Get repository owner from owner/repo format
get_repo_owner() {
	local repo="$1"
	echo "${repo%%/*}"
}

# Get owner type ("Organization" | "User") with file cache (TTL: 5min)
# Shared across scripts/processes so repeated lookups cost zero API calls.
get_owner_type() {
	local owner="$1"
	local cache_file
	cache_file="$(get_pm_cache_dir)/owner-type-$(_pm_sanitize "$owner").txt"

	if is_cache_fresh "$cache_file" 300; then
		cat "$cache_file"
		return 0
	fi

	local owner_type
	owner_type=$(gh api "users/$owner" --jq '.type' 2>/dev/null) || {
		echo "Warning: failed to resolve owner type for $owner" >&2
		return 1
	}
	printf '%s\n' "$owner_type" >"$cache_file"
	printf '%s\n' "$owner_type"
}

# Check if repository owner is an organization
# Returns 0 (true) for organization, 1 (false) for user
is_org_repo() {
	local repo="$1"
	local owner
	owner=$(get_repo_owner "$repo")

	local owner_type
	owner_type=$(get_owner_type "$owner" 2>/dev/null)

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
	local repo="$1" parent_number="$2" child_number="$3" child_id="${4:-}"

	validate_repo "$repo" || return 1
	validate_number "$parent_number" || return 1
	validate_number "$child_number" || return 1

	# 4th arg lets callers pass a pre-fetched ID (batch lookups) and skip one GET
	[[ -z "$child_id" ]] && child_id=$(get_issue_id "$repo" "$child_number")

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

# Update issue type and/or milestone in a single PATCH
# (both target the same endpoint; merging halves the API calls in bulk creation)
update_issue_meta() {
	local repo="$1" issue_number="$2" issue_type="${3:-}" milestone_number="${4:-}"

	validate_repo "$repo" || return 1
	validate_number "$issue_number" || return 1

	local args=()
	[[ -n "$issue_type" ]] && args+=(-f type="$issue_type")
	if [[ -n "$milestone_number" ]]; then
		validate_number "$milestone_number" || return 1
		args+=(-F milestone="$milestone_number")
	fi
	[[ ${#args[@]} -eq 0 ]] && return 0

	gh api "repos/$repo/issues/$issue_number" \
		-X PATCH \
		"${args[@]}" \
		--silent
}

# Save checkpoint (for error recovery)
# Records (repo, number, title) so multi-repo runs don't collide on title alone.
save_checkpoint() {
	local checkpoint_file="$1" number="$2" title="$3" repo="${4:-}"
	if [[ ! -f "$checkpoint_file" ]]; then
		echo '{"created":[]}' >"$checkpoint_file"
	fi
	jq --arg n "$number" --arg t "$title" --arg r "$repo" \
		'.created += [{"number": $n, "title": $t, "repo": $r}]' "$checkpoint_file" >"${checkpoint_file}.tmp"
	mv "${checkpoint_file}.tmp" "$checkpoint_file"
}

# Check if issue already created (idempotency)
# Matches on (repo, title); legacy records without .repo match any repo.
is_already_created() {
	local checkpoint_file="$1" title="$2" repo="${3:-}"
	if [[ -f "$checkpoint_file" ]]; then
		jq -e --arg t "$title" --arg r "$repo" \
			'.created[] | select(.title == $t) | select((.repo // "") == "" or .repo == $r)' \
			"$checkpoint_file" >/dev/null 2>&1
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
# Uses GraphQL subIssues (first: 100 = GitHub's per-parent sub-issue limit,
# so no pagination is needed).
get_child_issues() {
	local repo="$1" parent_number="$2"
	local owner="${repo%%/*}" name="${repo##*/}"

	local query='query($owner: String!, $name: String!, $number: Int!) {
    repository(owner: $owner, name: $name) {
      issue(number: $number) {
        subIssues(first: 100) { nodes { number title } }
      }
    }
  }'

	gh api graphql -f owner="$owner" -f name="$name" -F number="$parent_number" -f query="$query" \
		--jq '[.data.repository.issue.subIssues.nodes[] | {number, title}]' 2>/dev/null || echo "[]"
}

# Get all descendants of an issue recursively (BFS, one query per LEVEL)
# Returns: JSON array of {number, title, depth}
# Example: [{"number": 11, "title": "Feature A", "depth": 1}, ...]
# Each level fetches every node's subIssues in ONE aliased GraphQL query
# (deeply nested single queries hit GitHub's MAX_NODE_LIMIT). Epic>Feature>
# Story>Task = 4 queries total, vs. one REST call per node before.
# Issue numbers come from the API itself (integers), safe to inline as aliases.
get_all_descendants() {
	local repo="$1" parent_number="$2" max_depth="${3:-10}"
	local owner="${repo%%/*}" name="${repo##*/}"

	local result="[]"
	local current_numbers="[$parent_number]"
	local depth=0

	while [[ $(echo "$current_numbers" | jq 'length') -gt 0 && $depth -lt $max_depth ]]; do
		local query_body
		query_body=$(echo "$current_numbers" |
			jq -r '.[] | "i\(.): issue(number: \(.)) { subIssues(first: 100) { nodes { number title } } }"' |
			tr '\n' ' ')

		local response
		response=$(gh api graphql -f owner="$owner" -f name="$name" \
			-f query="query(\$owner: String!, \$name: String!) { repository(owner: \$owner, name: \$name) { $query_body } }" \
			2>/dev/null) || break

		local children
		children=$(echo "$response" | jq '[.data.repository | to_entries[] | .value
        | select(. != null) | .subIssues.nodes[]? | {number, title}]')

		depth=$((depth + 1))
		[[ $(echo "$children" | jq 'length') -eq 0 ]] && break

		result=$(jq -n --argjson a "$result" \
			--argjson b "$(echo "$children" | jq --argjson d "$depth" '[.[] | . + {depth: $d}]')" \
			'$a + $b')
		current_numbers=$(echo "$children" | jq '[.[].number]')
	done

	echo "$result"
}

# ============================================================
# GitHub Projects V2 GraphQL Functions
# ============================================================

# Get project ID for user or organization
# Usage: get_project_id "@me" 1  OR  get_project_id "org-name" 1
# Project number -> node ID is immutable, so the result is cached (TTL: 5min).
# org/user are queried together in one request (GraphQL returns partial data
# even when one of the two fields errors out).
get_project_id() {
	local owner="$1" number="$2"
	local query result

	local cache_file
	cache_file="$(get_pm_cache_dir)/project-id-$(_pm_sanitize "${owner}_${number}").txt"
	if is_cache_fresh "$cache_file" 300; then
		cat "$cache_file"
		return 0
	fi

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
      user(login: $login) {
        projectV2(number: $number) {
          id
        }
      }
    }'
		# One of the two fields always errors (owner is either org or user) —
		# gh exits non-zero on partial errors and skips --jq, so parse the
		# partial data from raw stdout ourselves
		local response
		response=$(gh api graphql -f login="$owner" -F number="$number" -f query="$query" 2>/dev/null) || true
		result=$(echo "$response" | jq -r '.data | (.organization.projectV2.id // .user.projectV2.id) // empty' 2>/dev/null) || result=""
	fi

	# Cache only a well-formed project node ID (never raw error payloads)
	if [[ "$result" =~ ^PVT_[A-Za-z0-9_-]+$ ]]; then
		printf '%s\n' "$result" >"$cache_file"
	else
		result=""
	fi
	echo "$result"
}

# Get all fields including iteration configuration
# Field definitions rarely change, so the result is cached (TTL: 5min).
get_project_fields() {
	local project_id="$1"

	local cache_file
	cache_file="$(get_pm_cache_dir)/fields-$(_pm_sanitize "$project_id").json"
	if is_cache_fresh "$cache_file" 300; then
		cat "$cache_file"
		return 0
	fi

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

	local fields
	fields=$(gh api graphql -f projectId="$project_id" -f query="$query" --jq '.data.node.fields.nodes') || return 1
	printf '%s\n' "$fields" >"$cache_file"
	printf '%s\n' "$fields"
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
		# Build with jq (issue titles may contain quotes/backslashes)
		jq -nc --arg iid "$item_id" --arg it "$issue_title" \
			'{iterationId: null, title: null, fieldId: null, itemId: $iid, issueTitle: $it}'
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
	owner_type=$(get_owner_type "$owner") || {
		echo "Warning: could not determine owner type for $owner; fallback scan may be incomplete" >&2
		owner_type="User"
	}

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

		# Skip projects already found via Path 1 (linked) — no need to re-scan items
		if echo "$linked" | jq -e --arg id "$pid" 'any(.[]?; .id == $id)' >/dev/null 2>&1; then
			continue
		fi

		local repos
		repos=$(get_project_scope_repos "$pid" 2>/dev/null) || {
			echo "Warning: failed to scan items of project $pid (rate limit / auth?); skipping" >&2
			continue
		}

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
                url
                repository { nameWithOwner }
                issueType { name }
                assignees(first: 5) { nodes { login } }
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
                  iterationId
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

	local pages_dir
	pages_dir=$(mktemp -d "${TMPDIR:-/tmp}/vw-pm-items.XXXXXX") || return 1

	local cursor=""
	local has_next="true"
	local page_idx=0

	while [[ "$has_next" == "true" ]]; do
		local response
		if [[ -z "$cursor" ]]; then
			response=$(gh api graphql -f projectId="$project_id" -f query="$query")
		else
			response=$(gh api graphql -f projectId="$project_id" -f cursor="$cursor" -f query="$query")
		fi

		# Accumulate pages on disk; a single jq -s at the end avoids
		# re-parsing the growing JSON on every page (O(N^2))
		printf '%s' "$response" | jq '.data.node.items.nodes // []' \
			>"$pages_dir/page-$(printf '%04d' "$page_idx").json"
		page_idx=$((page_idx + 1))

		has_next=$(echo "$response" | jq -r '.data.node.items.pageInfo.hasNextPage // false')
		cursor=$(echo "$response" | jq -r '.data.node.items.pageInfo.endCursor // empty')
	done

	jq -s 'add // []' "$pages_dir"/page-*.json
	rm -rf "$pages_dir"
}

# Get distinct repos referenced in a Project's items (lightweight)
# Pages through items fetching ONLY content.repository — no labels/fieldValues —
# so the fallback project scan stays cheap. Result is cached via scope cache (TTL: 5min);
# the cache also lets pm-resolve-scope.sh reuse the scan result instead of re-fetching.
# Input:  project_id (GraphQL node ID)
# Output: JSON array of "owner/repo" strings (unique, sorted)
get_project_scope_repos() {
	local project_id="$1"

	local cached
	if cached=$(read_scope_cache "$project_id"); then
		echo "$cached"
		return 0
	fi

	local query='query($projectId: ID!, $cursor: String) {
    node(id: $projectId) {
      ... on ProjectV2 {
        items(first: 100, after: $cursor) {
          pageInfo { hasNextPage endCursor }
          nodes {
            content {
              __typename
              ... on Issue { repository { nameWithOwner } }
              ... on PullRequest { repository { nameWithOwner } }
            }
          }
        }
      }
    }
  }'

	local repos="[]"
	local cursor=""
	local has_next="true"

	while [[ "$has_next" == "true" ]]; do
		local response
		if [[ -z "$cursor" ]]; then
			response=$(gh api graphql -f projectId="$project_id" -f query="$query") || return 1
		else
			response=$(gh api graphql -f projectId="$project_id" -f cursor="$cursor" -f query="$query") || return 1
		fi

		repos=$(echo "$response" | jq --argjson acc "$repos" '
      $acc + [.data.node.items.nodes[]?.content
              | select(.__typename == "Issue" or .__typename == "PullRequest")
              | .repository.nameWithOwner]')

		has_next=$(echo "$response" | jq -r '.data.node.items.pageInfo.hasNextPage // false')
		cursor=$(echo "$response" | jq -r '.data.node.items.pageInfo.endCursor // empty')
	done

	repos=$(echo "$repos" | jq 'unique')
	write_scope_cache "$project_id" "$repos"
	echo "$repos"
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

# ============================================================
# Projects V2 Field Update Helpers
# ============================================================

# Update a single select field
update_single_select_field() {
	local project_id="$1" item_id="$2" field_id="$3" option_id="$4"
	local mutation='mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
    updateProjectV2ItemFieldValue(input: {
      projectId: $projectId
      itemId: $itemId
      fieldId: $fieldId
      value: {
        singleSelectOptionId: $optionId
      }
    }) {
      projectV2Item {
        id
      }
    }
  }'

	gh api graphql -f projectId="$project_id" -f itemId="$item_id" -f fieldId="$field_id" \
		-f optionId="$option_id" -f query="$mutation" --jq '.data.updateProjectV2ItemFieldValue.projectV2Item.id'
}

# Update a number field
update_number_field() {
	local project_id="$1" item_id="$2" field_id="$3" value="$4"
	local mutation='mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $value: Float!) {
    updateProjectV2ItemFieldValue(input: {
      projectId: $projectId
      itemId: $itemId
      fieldId: $fieldId
      value: {
        number: $value
      }
    }) {
      projectV2Item {
        id
      }
    }
  }'

	gh api graphql -f projectId="$project_id" -f itemId="$item_id" -f fieldId="$field_id" \
		-F value="$value" -f query="$mutation" --jq '.data.updateProjectV2ItemFieldValue.projectV2Item.id'
}

# Update a date field
update_date_field() {
	local project_id="$1" item_id="$2" field_id="$3" date_value="$4"
	local mutation='mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $date: Date!) {
    updateProjectV2ItemFieldValue(input: {
      projectId: $projectId
      itemId: $itemId
      fieldId: $fieldId
      value: {
        date: $date
      }
    }) {
      projectV2Item {
        id
      }
    }
  }'

	gh api graphql -f projectId="$project_id" -f itemId="$item_id" -f fieldId="$field_id" \
		-f date="$date_value" -f query="$mutation" --jq '.data.updateProjectV2ItemFieldValue.projectV2Item.id'
}

# Find option ID by name
find_option_id() {
	local fields_json="$1" field_name="$2" option_name="$3"
	echo "$fields_json" | jq -r --arg fn "$field_name" --arg on "$option_name" '
    .[] | select(.name == $fn) | .options[]? | select(.name == $on) | .id
  '
}

# Find field ID by name
find_field_id() {
	local fields_json="$1" field_name="$2"
	echo "$fields_json" | jq -r --arg fn "$field_name" '.[] | select(.name == $fn) | .id'
}

# Find the ITERATION-type field ID by name, falling back to type-based lookup
# when the name doesn't match (e.g. field named "Sprint" instead of "Iteration")
find_iteration_field_id() {
	local fields_json="$1" field_name="$2"
	local id
	id=$(echo "$fields_json" | jq -r --arg fn "$field_name" '.[] | select(.name == $fn) | .id')
	if [[ -z "$id" ]]; then
		id=$(echo "$fields_json" | jq -r '.[] | select(.dataType == "ITERATION") | .id' | head -1)
	fi
	echo "$id"
}

# Find iteration ID by title, falling back to type-based lookup
find_iteration_id() {
	local fields_json="$1" field_name="$2" iteration_title="$3"
	local result
	result=$(echo "$fields_json" | jq -r --arg fn "$field_name" --arg it "$iteration_title" '
    .[] | select(.name == $fn) | .configuration.iterations[]? | select(.title == $it) | .id
  ')
	if [[ -z "$result" ]]; then
		result=$(echo "$fields_json" | jq -r --arg it "$iteration_title" '
      .[] | select(.dataType == "ITERATION") | .configuration.iterations[]? | select(.title == $it) | .id
    ' | head -1)
	fi
	echo "$result"
}

# Look up a project item by issue number (+ optional repo) from a
# get_project_items result. Avoids per-issue GraphQL queries in loops.
# Input:  items_json, issue_number, repo (optional, "" = any)
# Output: JSON {itemId, iterationId} (iterationId null if unset); empty if not found
lookup_project_item() {
	local items_json="$1" issue_number="$2" repo="${3:-}"
	echo "$items_json" | jq -c --argjson n "$issue_number" --arg r "$repo" '
    [.[]
     | select(.content.number == $n)
     | select($r == "" or .content.repository.nameWithOwner == $r)
     | {itemId: .id,
        iterationId: ([.fieldValues.nodes[]? | select(.iterationId?) | .iterationId][0] // null)}
    ][0] // empty'
}

# ============================================================
# Scope Argument Resolution (shared by sprint-review / sprint-plan)
# ============================================================

# Build SCOPE_REPOS JSON array from CLI-style inputs.
# Precedence: scope_json > repos_csv > repo > auto-resolve (pm-resolve-scope.sh)
# Input:  scope_json, repos_csv, repo (each may be empty)
# Output: JSON array (may be [])
pm_scope_from_args() {
	local scope_json="$1" repos_csv="$2" repo="$3"
	local result=""

	if [[ -n "$scope_json" ]]; then
		result="$scope_json"
	elif [[ -n "$repos_csv" ]]; then
		result=$(printf '%s' "$repos_csv" | tr ',' '\n' | sed '/^[[:space:]]*$/d' | jq -R . | jq -s .)
	elif [[ -n "$repo" ]]; then
		result=$(jq -nc --arg r "$repo" '[$r]')
	else
		local resolved
		resolved=$("$SCRIPT_DIR/pm-resolve-scope.sh" 2>/dev/null) || true
		if [[ -n "$resolved" ]]; then
			result=$(echo "$resolved" | jq -c '.scopeRepos')
		fi
	fi
	[[ -z "$result" ]] && result="[]"
	echo "$result"
}
