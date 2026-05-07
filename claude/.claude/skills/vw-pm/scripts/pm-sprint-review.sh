#!/bin/bash
# pm-sprint-review.sh - Sprint Review data collector (multi-repo aware)
# Usage: pm-sprint-review.sh [options]
#
# Collects data for a Sprint Review:
#   - Target Sprint period (defaults to most recently completed)
#   - git commits within the period (cwd repo only — see note)
#   - merged PRs within the period (collected from each SCOPE_REPOS entry)
#   - Project items associated with the Sprint (Status, Open/Closed)
#   - Done candidate hints (close-references in PR/commit messages)
#
# Multi-repo handling:
#   - SCOPE_REPOS is built from --scope / --repos / --repo / auto-detect.
#   - PR list is collected per repo and tagged with the source repo.
#   - Project items already carry repository.nameWithOwner from GraphQL.
#   - git log only inspects cwd (other repos are not cloned locally);
#     for cross-repo commit attribution rely on PR data.
#
# Output: JSON (consumed by LLM in /vw-pm SPRINT.md flow)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pm-utils.sh"

usage() {
	cat <<EOF
Usage: $0 [options]

Collect data for Sprint Review.

Options:
  --repo <owner/repo>      Single repository (back-compat). Used as cwd repo.
  --repos a/r1,a/r2        Comma-separated list of repos (multi-repo mode).
  --scope '<json_array>'   JSON array of repos (e.g. output of pm-resolve-scope.sh .scopeRepos).
  --project <number>       Project number (required)
  --owner <login>          Project owner (@me for user, or org name) (required)
  --sprint <name>          Sprint name (default: most recent completed)
  --limit <N>              Max PRs to fetch per repo (default: 100)
  -h, --help               Show this help

Resolution precedence: --scope > --repos > --repo > auto-detect (cwd).

Output: JSON with the following shape:
{
  "sprint": { "title": "Sprint 16", "startDate": "2026-04-20", "endDate": "2026-04-24", "duration": 5 },
  "period": { "since": "2026-04-20", "until": "2026-04-26" },
  "scopeRepos": ["owner/r1", "owner/r2"],
  "cwdRepo": "owner/r1",
  "commits": [{ "sha": "...", "author": "...", "date": "...", "message": "...", "repo": "owner/r1" }],
  "prs": [{ "number": N, "author": "...", "title": "...", "mergedAt": "...", "closes": [...], "repo": "owner/r1" }],
  "projectItems": [{ "number": N, "repo": "...", "title": "...", "state": "OPEN|CLOSED", "status": "Done|Todo|...", "assignees": [...], "issueType": "Task|Bug|...", "url": "..." }],
  "doneCandidates": [{ "issueNumber": N, "repo": "owner/r1", "reason": "close-ref|title-match", "evidence": "..." }]
}

The LLM consumes this and renders a tree per author, then asks the user
to confirm Status=Done + Issue Close.
EOF
	exit 1
}

REPO=""
REPOS_CSV=""
SCOPE_INPUT=""
PROJECT_NUMBER=""
PROJECT_OWNER=""
SPRINT_NAME=""
LIMIT=100

while [[ $# -gt 0 ]]; do
	case $1 in
	--repo)
		REPO="$2"
		shift 2
		;;
	--repos)
		REPOS_CSV="$2"
		shift 2
		;;
	--scope)
		SCOPE_INPUT="$2"
		shift 2
		;;
	--project)
		PROJECT_NUMBER="$2"
		shift 2
		;;
	--owner)
		PROJECT_OWNER="$2"
		shift 2
		;;
	--sprint)
		SPRINT_NAME="$2"
		shift 2
		;;
	--limit)
		LIMIT="$2"
		shift 2
		;;
	-h | --help) usage ;;
	*)
		echo "Unknown option: $1" >&2
		usage
		;;
	esac
done

# Resolve cwd repo (best-effort, only used for git log + sole fallback)
CWD_REPO=""
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	CWD_REPO=$(get_repo "" 2>/dev/null || echo "")
fi
REPO="${REPO:-$CWD_REPO}"

# Build SCOPE_REPOS (precedence: --scope > --repos > --repo > auto-resolve)
build_scope_repos() {
	local result=""
	if [[ -n "$SCOPE_INPUT" ]]; then
		result="$SCOPE_INPUT"
	elif [[ -n "$REPOS_CSV" ]]; then
		result=$(printf '%s' "$REPOS_CSV" | tr ',' '\n' | sed '/^[[:space:]]*$/d' | jq -R . | jq -s .)
	elif [[ -n "$REPO" ]]; then
		result=$(jq -nc --arg r "$REPO" '[$r]')
	else
		# Auto-resolve via pm-resolve-scope.sh
		local resolved
		resolved=$("$SCRIPT_DIR/pm-resolve-scope.sh" 2>/dev/null) || true
		if [[ -n "$resolved" ]]; then
			result=$(echo "$resolved" | jq -c '.scopeRepos')
		fi
	fi
	[[ -z "$result" ]] && result="[]"
	echo "$result"
}

SCOPE_REPOS=$(build_scope_repos)
SCOPE_COUNT=$(echo "$SCOPE_REPOS" | jq 'length')

if [[ "$SCOPE_COUNT" -eq 0 ]]; then
	echo "Error: SCOPE_REPOS is empty (specify --repo / --repos / --scope, or run inside a git repo)" >&2
	exit 1
fi

[[ -z "$PROJECT_NUMBER" ]] && {
	echo "Error: --project required" >&2
	exit 1
}
[[ -z "$PROJECT_OWNER" ]] && {
	echo "Error: --owner required" >&2
	exit 1
}

# 1. Resolve Sprint metadata
PROJECT_ID=$(get_project_id "$PROJECT_OWNER" "$PROJECT_NUMBER")
[[ -z "$PROJECT_ID" || "$PROJECT_ID" == "null" ]] && {
	echo "Error: Project not found ($PROJECT_OWNER/#$PROJECT_NUMBER)" >&2
	exit 1
}

# Build iteration query (org-vs-user agnostic via projectV2 node)
ITERATIONS_JSON=$(gh api graphql -f projectId="$PROJECT_ID" -f query='
query($projectId: ID!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      fields(first: 50) {
        nodes {
          ... on ProjectV2IterationField {
            id
            name
            configuration {
              duration
              iterations { id title startDate duration }
              completedIterations { id title startDate duration }
            }
          }
        }
      }
    }
  }
}' --jq '.data.node.fields.nodes | map(select(.configuration)) | .[0]')

[[ -z "$ITERATIONS_JSON" || "$ITERATIONS_JSON" == "null" ]] && {
	echo "Error: No Iteration field found in project" >&2
	exit 1
}

SPRINT_FIELD_ID=$(echo "$ITERATIONS_JSON" | jq -r '.id')

if [[ -z "$SPRINT_NAME" ]]; then
	SPRINT_META=$(echo "$ITERATIONS_JSON" | jq -c '.configuration.completedIterations | sort_by(.startDate) | reverse | .[0]')
else
	SPRINT_META=$(echo "$ITERATIONS_JSON" | jq -c --arg t "$SPRINT_NAME" '
    [.configuration.iterations[]?, .configuration.completedIterations[]?] | map(select(.title == $t)) | .[0]
  ')
fi

[[ -z "$SPRINT_META" || "$SPRINT_META" == "null" ]] && {
	echo "Error: Sprint not found: $SPRINT_NAME" >&2
	exit 1
}

START=$(echo "$SPRINT_META" | jq -r '.startDate')
DURATION=$(echo "$SPRINT_META" | jq -r '.duration')
END=$(date -j -v+"${DURATION}"d -f "%Y-%m-%d" "$START" +%Y-%m-%d 2>/dev/null ||
	date -d "$START + $DURATION days" +%Y-%m-%d)
SPRINT_ID=$(echo "$SPRINT_META" | jq -r '.id')
SPRINT_TITLE=$(echo "$SPRINT_META" | jq -r '.title')

# Period covers a few days past Sprint end to catch follow-up commits
PERIOD_UNTIL=$(date -j -v+1d -f "%Y-%m-%d" "$END" +%Y-%m-%d 2>/dev/null ||
	date -d "$END + 1 day" +%Y-%m-%d)

# 2. Collect commits from cwd repo only (git log requires a local working tree).
#    Other SCOPE_REPOS contribute via PR data instead.
if [[ -n "$CWD_REPO" ]] && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	COMMITS_JSON=$(git log --all --since="$START 00:00" --until="$PERIOD_UNTIL 00:00" \
		--pretty=format:'{"sha":"%h","author":"%an","email":"%ae","date":"%ad","message":"%f"}' --date=short |
		jq -s --arg r "$CWD_REPO" '[.[] | . + {repo: $r}]' 2>/dev/null || echo "[]")
else
	COMMITS_JSON="[]"
fi

# 3. Collect merged PRs from each SCOPE_REPOS entry (tagged with source repo)
PR_QUERY="merged:${START}..${END}"
PRS_JSON="[]"
while IFS= read -r repo_entry; do
	[[ -z "$repo_entry" ]] && continue
	page=$(gh pr list --repo "$repo_entry" --state merged --search "$PR_QUERY" --limit "$LIMIT" \
		--json number,title,body,author,mergedAt,headRefName 2>/dev/null |
		jq --arg r "$repo_entry" '[.[] | {
        repo: $r,
        number: .number,
        title: .title,
        author: .author.login,
        mergedAt: (.mergedAt | split("T")[0]),
        headRefName: .headRefName,
        closes: [.body // "" | scan("(?:close[sd]?|fixe?[sd]?|resolve[sd]?|refs?)\\s*#(\\d+)"; "i") | .[0] | tonumber]
      }]' 2>/dev/null || echo "[]")
	PRS_JSON=$(jq -n --argjson a "$PRS_JSON" --argjson b "$page" '$a + $b')
done < <(echo "$SCOPE_REPOS" | jq -r '.[]')

# 4. Collect Project items in this Sprint (paginated)
ITEMS_RAW="[]"
CURSOR=""
HAS_NEXT=true
while [[ "$HAS_NEXT" == "true" ]]; do
	if [[ -z "$CURSOR" ]]; then
		PAGE=$(gh api graphql -f projectId="$PROJECT_ID" -f query='
      query($projectId: ID!) {
        node(id: $projectId) {
          ... on ProjectV2 {
            items(first: 100) {
              pageInfo { hasNextPage endCursor }
              nodes {
                id
                fieldValues(first: 30) {
                  nodes {
                    ... on ProjectV2ItemFieldSingleSelectValue {
                      name
                      field { ... on ProjectV2SingleSelectField { name } }
                    }
                    ... on ProjectV2ItemFieldIterationValue {
                      iterationId
                      title
                      field { ... on ProjectV2IterationField { name } }
                    }
                  }
                }
                content {
                  ... on Issue {
                    number
                    title
                    state
                    url
                    repository { nameWithOwner }
                    issueType { name }
                    assignees(first: 5) { nodes { login } }
                  }
                }
              }
            }
          }
        }
      }')
	else
		PAGE=$(gh api graphql -f projectId="$PROJECT_ID" -f cursor="$CURSOR" -f query='
      query($projectId: ID!, $cursor: String!) {
        node(id: $projectId) {
          ... on ProjectV2 {
            items(first: 100, after: $cursor) {
              pageInfo { hasNextPage endCursor }
              nodes {
                id
                fieldValues(first: 30) {
                  nodes {
                    ... on ProjectV2ItemFieldSingleSelectValue {
                      name
                      field { ... on ProjectV2SingleSelectField { name } }
                    }
                    ... on ProjectV2ItemFieldIterationValue {
                      iterationId
                      title
                      field { ... on ProjectV2IterationField { name } }
                    }
                  }
                }
                content {
                  ... on Issue {
                    number
                    title
                    state
                    url
                    repository { nameWithOwner }
                    issueType { name }
                    assignees(first: 5) { nodes { login } }
                  }
                }
              }
            }
          }
        }
      }')
	fi
	ITEMS_RAW=$(jq -n --argjson a "$ITEMS_RAW" --argjson b "$(echo "$PAGE" | jq '.data.node.items.nodes')" '$a + $b')
	HAS_NEXT=$(echo "$PAGE" | jq -r '.data.node.items.pageInfo.hasNextPage')
	CURSOR=$(echo "$PAGE" | jq -r '.data.node.items.pageInfo.endCursor')
done

# Filter to items associated with the target Sprint
ITEMS_JSON=$(echo "$ITEMS_RAW" | jq --arg sid "$SPRINT_ID" '
  [.[]
   | select(.content.number)
   | . as $item
   | (.fieldValues.nodes[]? | select(.iterationId? == $sid)) as $iter
   | select($iter)
   | {
       number: $item.content.number,
       repo: ($item.content.repository.nameWithOwner // null),
       title: $item.content.title,
       state: $item.content.state,
       url: $item.content.url,
       issueType: ($item.content.issueType.name // null),
       assignees: [$item.content.assignees.nodes[]?.login],
       status: ([$item.fieldValues.nodes[] | select(.field.name? == "Status") | .name][0] // null),
       sprint: $iter.title
     }
  ]')

# 5. Detect Done candidates
# Strategy: Issues whose number+repo appears in PR `closes` or commit messages,
# but Status != Done.  Match repo to avoid number collisions across SCOPE_REPOS.
DONE_CANDIDATES=$(jq -n --argjson items "$ITEMS_JSON" --argjson prs "$PRS_JSON" --argjson commits "$COMMITS_JSON" '
  [
    ($items[] | select(.status != "Done")) as $item
    | (
        ($prs[] | select(.repo == $item.repo) | select(.closes | index($item.number))
          | { issueNumber: $item.number, repo: $item.repo, reason: "close-ref",
              evidence: ("PR " + .repo + "#" + (.number|tostring)) }),
        ($commits[] | select(.repo == $item.repo) | select(.message | test("#" + ($item.number|tostring) + "(\\b|_)"))
          | { issueNumber: $item.number, repo: $item.repo, reason: "commit-ref", evidence: .sha })
      )
  ] | unique_by(.issueNumber, .repo, .reason, .evidence)
')

# 6. Output combined JSON
jq -n \
	--argjson sprint "$SPRINT_META" \
	--arg sprintFieldId "$SPRINT_FIELD_ID" \
	--arg periodSince "$START" \
	--arg periodUntil "$END" \
	--argjson scopeRepos "$SCOPE_REPOS" \
	--arg cwdRepo "$CWD_REPO" \
	--argjson commits "$COMMITS_JSON" \
	--argjson prs "$PRS_JSON" \
	--argjson items "$ITEMS_JSON" \
	--argjson candidates "$DONE_CANDIDATES" '
  {
    sprint: $sprint,
    sprintFieldId: $sprintFieldId,
    period: { since: $periodSince, until: $periodUntil },
    scopeRepos: $scopeRepos,
    cwdRepo: (if $cwdRepo == "" then null else $cwdRepo end),
    commits: $commits,
    prs: $prs,
    projectItems: $items,
    doneCandidates: $candidates
  }
'
