#!/bin/bash
# pm-sprint-review.sh - Sprint Review data collector
# Usage: pm-sprint-review.sh [options]
#
# Collects data for a Sprint Review:
#   - Target Sprint period (defaults to most recently completed)
#   - git commits within the period (per author)
#   - merged PRs within the period (per author)
#   - Project items associated with the Sprint (Status, Open/Closed)
#   - Done candidate hints (close-references in PR/commit messages)
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
  --repo <owner/repo>      Repository (default: auto-detect from git remote)
  --project <number>       Project number (required)
  --owner <login>          Project owner (@me for user, or org name) (required)
  --sprint <name>          Sprint name (default: most recent completed)
  --limit <N>              Max PRs/commits to fetch per author (default: 100)
  -h, --help               Show this help

Output: JSON with the following shape:
{
  "sprint": { "title": "Sprint 16", "startDate": "2026-04-20", "endDate": "2026-04-24", "duration": 5 },
  "period": { "since": "2026-04-20", "until": "2026-04-26" },
  "commits": [{ "sha": "...", "author": "...", "date": "...", "message": "..." }],
  "prs": [{ "number": N, "author": "...", "title": "...", "mergedAt": "...", "closes": [...] }],
  "projectItems": [{ "number": N, "title": "...", "state": "OPEN|CLOSED", "status": "Done|Todo|...", "assignees": [...], "issueType": "Task|Bug|...", "url": "..." }],
  "doneCandidates": [{ "issueNumber": N, "reason": "close-ref|title-match", "evidence": "..." }]
}

The LLM consumes this and renders a tree per author, then asks the user
to confirm Status=Done + Issue Close.
EOF
	exit 1
}

REPO=""
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

REPO=$(get_repo "$REPO")
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

# 2. Collect commits (--all branches, period bounded)
COMMITS_JSON=$(git log --all --since="$START 00:00" --until="$PERIOD_UNTIL 00:00" \
	--pretty=format:'{"sha":"%h","author":"%an","email":"%ae","date":"%ad","message":"%f"}' --date=short |
	jq -s '.' 2>/dev/null || echo "[]")

# 3. Collect merged PRs (using gh's merged: search)
PR_QUERY="merged:${START}..${END}"
PRS_JSON=$(gh pr list --repo "$REPO" --state merged --search "$PR_QUERY" --limit "$LIMIT" \
	--json number,title,body,author,mergedAt,headRefName |
	jq '[.[] | {
      number: .number,
      title: .title,
      author: .author.login,
      mergedAt: (.mergedAt | split("T")[0]),
      headRefName: .headRefName,
      closes: [.body // "" | scan("(?:close[sd]?|fixe?[sd]?|resolve[sd]?|refs?)\\s*#(\\d+)"; "i") | tonumber]
    }]')

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
# Strategy: Issues whose number appears in PR `closes` lists or commit messages, but Status != Done
DONE_CANDIDATES=$(jq -n --argjson items "$ITEMS_JSON" --argjson prs "$PRS_JSON" --argjson commits "$COMMITS_JSON" '
  [
    ($items[] | select(.status != "Done")) as $item
    | (
        ($prs[] | select(.closes | index($item.number)) | { issueNumber: $item.number, reason: "close-ref", evidence: ("PR #" + (.number|tostring)) }),
        ($commits[] | select(.message | test("#" + ($item.number|tostring) + "(\\b|_)")) | { issueNumber: $item.number, reason: "commit-ref", evidence: .sha })
      )
  ] | unique_by(.issueNumber, .reason, .evidence)
')

# 6. Output combined JSON
jq -n \
	--argjson sprint "$SPRINT_META" \
	--arg sprintFieldId "$SPRINT_FIELD_ID" \
	--arg periodSince "$START" \
	--arg periodUntil "$END" \
	--argjson commits "$COMMITS_JSON" \
	--argjson prs "$PRS_JSON" \
	--argjson items "$ITEMS_JSON" \
	--argjson candidates "$DONE_CANDIDATES" '
  {
    sprint: $sprint,
    sprintFieldId: $sprintFieldId,
    period: { since: $periodSince, until: $periodUntil },
    commits: $commits,
    prs: $prs,
    projectItems: $items,
    doneCandidates: $candidates
  }
'
