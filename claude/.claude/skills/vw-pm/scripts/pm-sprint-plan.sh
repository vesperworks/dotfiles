#!/bin/bash
# pm-sprint-plan.sh - Sprint Planning data collector (multi-repo aware)
# Usage: pm-sprint-plan.sh [options]
#
# Collects data for Sprint Planning:
#   - Current Sprint (target Sprint to plan into)
#   - In Progress carryover (previous Sprint, Status="In Progress")
#   - Backlog candidates (Status=Todo|Backlog, Sprint未割当)
#   - Project items grouped by assignee
#
# Multi-repo handling:
#   - SCOPE_REPOS is recorded for downstream use (--scope / --repos / --repo / auto).
#   - Project items are pulled by project_id (already cross-repo).
#   - Each item carries its repository.nameWithOwner.
#
# Output: JSON (consumed by LLM in /vw-pm SPRINT.md flow)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pm-utils.sh"

usage() {
	cat <<EOF
Usage: $0 [options]

Collect data for Sprint Planning.

Options:
  --repo <owner/repo>      Single repository (back-compat).
  --repos a/r1,a/r2        Comma-separated list of repos (multi-repo mode).
  --scope '<json_array>'   JSON array of repos (e.g. pm-resolve-scope.sh .scopeRepos).
  --project <number>       Project number (required)
  --owner <login>          Project owner (@me for user, or org name) (required)
  --sprint <name>          Target Sprint name (default: current iteration)
  -h, --help               Show this help

Resolution precedence: --scope > --repos > --repo > auto-detect (cwd).

Output: JSON with the following shape:
{
  "currentSprint": { "id": "...", "title": "Sprint 17", "startDate": "...", "duration": 5 },
  "previousSprint": { "id": "...", "title": "Sprint 16", "startDate": "...", "duration": 5 },
  "sprintFieldId": "PVTIF_...",
  "carryover": [{ "number": N, "title": "...", "status": "In Progress", "assignees": [...], "previousSprint": "Sprint 16" }],
  "backlog": [{ "number": N, "title": "...", "status": "Todo|Backlog", "priority": "...", "assignees": [...] }],
  "byAssignee": { "user1": { "carryover": [...], "backlog": [...] } }
}
EOF
	exit 1
}

REPO=""
REPOS_CSV=""
SCOPE_INPUT=""
PROJECT_NUMBER=""
PROJECT_OWNER=""
SPRINT_NAME=""

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
	-h | --help) usage ;;
	*)
		echo "Unknown option: $1" >&2
		usage
		;;
	esac
done

# Resolve cwd repo (best-effort)
CWD_REPO=""
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	CWD_REPO=$(get_repo "" 2>/dev/null || echo "")
fi
REPO="${REPO:-$CWD_REPO}"

# Build SCOPE_REPOS (precedence: --scope > --repos > --repo > auto-resolve)
SCOPE_REPOS=$(pm_scope_from_args "$SCOPE_INPUT" "$REPOS_CSV" "$REPO")

[[ -z "$PROJECT_NUMBER" ]] && {
	echo "Error: --project required" >&2
	exit 1
}
[[ -z "$PROJECT_OWNER" ]] && {
	echo "Error: --owner required" >&2
	exit 1
}

PROJECT_ID=$(get_project_id "$PROJECT_OWNER" "$PROJECT_NUMBER")
[[ -z "$PROJECT_ID" || "$PROJECT_ID" == "null" ]] && {
	echo "Error: Project not found ($PROJECT_OWNER/#$PROJECT_NUMBER)" >&2
	exit 1
}

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

# Resolve current target Sprint
if [[ -z "$SPRINT_NAME" ]]; then
	CURRENT_SPRINT=$(echo "$ITERATIONS_JSON" | jq -c '.configuration.iterations | sort_by(.startDate) | .[0]')
else
	CURRENT_SPRINT=$(echo "$ITERATIONS_JSON" | jq -c --arg t "$SPRINT_NAME" '
    [.configuration.iterations[]?, .configuration.completedIterations[]?] | map(select(.title == $t)) | .[0]
  ')
fi

[[ -z "$CURRENT_SPRINT" || "$CURRENT_SPRINT" == "null" ]] && {
	echo "Error: Target Sprint not found" >&2
	exit 1
}

# Previous Sprint = most recently completed before current
CURRENT_START=$(echo "$CURRENT_SPRINT" | jq -r '.startDate')
PREVIOUS_SPRINT=$(echo "$ITERATIONS_JSON" | jq -c --arg s "$CURRENT_START" '
  .configuration.completedIterations | map(select(.startDate < $s)) | sort_by(.startDate) | reverse | .[0] // null
')

# Fetch all project items
# (shared paginated fetch from pm-utils.sh — includes iterationId/Status/
#  Priority/assignees/issueType needed below)
ITEMS_RAW=$(get_project_items "$PROJECT_ID")

# Project items normalized (only Open issues with content)
NORMALIZED=$(echo "$ITEMS_RAW" | jq '
  [.[]
   | select(.content.number and .content.state == "OPEN")
   | {
       number: .content.number,
       repo: (.content.repository.nameWithOwner // null),
       title: .content.title,
       url: .content.url,
       issueType: (.content.issueType.name // null),
       assignees: [.content.assignees.nodes[]?.login],
       status: ([.fieldValues.nodes[] | select(.field.name? == "Status") | .name][0] // null),
       priority: ([.fieldValues.nodes[] | select(.field.name? == "Priority") | .name][0] // null),
       sprintTitle: ([.fieldValues.nodes[] | select(.field.name? == "Sprint") | .title][0] // null),
       sprintId: ([.fieldValues.nodes[] | select(.field.name? == "Sprint") | .iterationId][0] // null)
     }
  ]')

# Carryover = ALL In Progress items, regardless of which Sprint they were in
# (deliberately not filtered to the previous Sprint — In Progress without a
#  Sprint assignment would otherwise be silently dropped from planning)
CARRYOVER=$(echo "$NORMALIZED" | jq '
  [.[]
   | select(.status == "In Progress")
   | . + { previousSprint: .sprintTitle }
  ]')

# Backlog candidates = Status in [Todo, Backlog, null] AND Sprint not assigned to current
CURRENT_ID=$(echo "$CURRENT_SPRINT" | jq -r '.id')
BACKLOG=$(echo "$NORMALIZED" | jq --arg cs "$CURRENT_ID" '
  [.[]
   | select((.status == "Todo" or .status == "Backlog" or .status == null) and .sprintId != $cs)
  ]')

# Group by assignee
BY_ASSIGNEE=$(jq -n --argjson c "$CARRYOVER" --argjson b "$BACKLOG" '
  ([($c[] | .assignees[]? // "_unassigned"), ($b[] | .assignees[]? // "_unassigned")] | unique) as $logins
  | reduce $logins[] as $u ({};
      .[$u] = {
        carryover: [$c[] | select(if (.assignees | length) == 0 then $u == "_unassigned" else (.assignees | index($u)) end)],
        backlog: [$b[] | select(if (.assignees | length) == 0 then $u == "_unassigned" else (.assignees | index($u)) end)]
      }
    )
')

jq -n \
	--argjson current "$CURRENT_SPRINT" \
	--argjson previous "$PREVIOUS_SPRINT" \
	--arg sprintFieldId "$SPRINT_FIELD_ID" \
	--argjson scopeRepos "$SCOPE_REPOS" \
	--arg cwdRepo "$CWD_REPO" \
	--argjson carryover "$CARRYOVER" \
	--argjson backlog "$BACKLOG" \
	--argjson byAssignee "$BY_ASSIGNEE" '
  {
    currentSprint: $current,
    previousSprint: $previous,
    sprintFieldId: $sprintFieldId,
    scopeRepos: $scopeRepos,
    cwdRepo: (if $cwdRepo == "" then null else $cwdRepo end),
    carryover: $carryover,
    backlog: $backlog,
    byAssignee: $byAssignee
  }
'
