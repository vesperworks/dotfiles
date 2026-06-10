#!/bin/bash
# pm-list-issues.sh - List issues across SCOPE_REPOS (multi-repo aware)
# Usage: pm-list-issues.sh [options]
#
# Collects issues from every repo in scope and tags each with its source repo.
# Replaces the inline while-loop previously documented in ANALYSIS.md so the
# SKILL flow stays a single script invocation.
#
# Options:
#   --repo <owner/repo>      Single repository
#   --repos a/r1,a/r2        Comma-separated list of repos
#   --scope '<json_array>'   JSON array of repos (pm-resolve-scope.sh .scopeRepos)
#   --state <all|open|closed>  Issue state filter (default: all)
#   --limit <N>              Max issues per repo (default: 100)
#
# Resolution precedence: --scope > --repos > --repo > auto-resolve (cwd).
#
# Output: JSON array of {number, title, state, labels, repo}

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./pm-utils.sh
source "${SCRIPT_DIR}/pm-utils.sh"

REPO=""
REPOS_CSV=""
SCOPE_INPUT=""
STATE="all"
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
	--state)
		STATE="$2"
		shift 2
		;;
	--limit)
		LIMIT="$2"
		shift 2
		;;
	-h | --help)
		grep "^#" "$0" | sed 's/^# \{0,1\}//'
		exit 0
		;;
	*)
		echo "Unknown option: $1" >&2
		exit 1
		;;
	esac
done

case "$STATE" in
all | open | closed) ;;
*)
	echo "Error: --state must be all|open|closed" >&2
	exit 1
	;;
esac

SCOPE_REPOS=$(pm_scope_from_args "$SCOPE_INPUT" "$REPOS_CSV" "$REPO")
SCOPE_COUNT=$(echo "$SCOPE_REPOS" | jq 'length')
if [[ "$SCOPE_COUNT" -eq 0 ]]; then
	echo "Error: No repos resolved (specify --repo / --repos / --scope, or run inside a git repo)" >&2
	exit 1
fi

# Fetch repos in parallel (independent API calls)
TMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/vw-pm-issues.XXXXXX")
idx=0
while IFS= read -r repo_entry; do
	[[ -z "$repo_entry" ]] && continue
	(
		gh issue list --repo "$repo_entry" --state "$STATE" --limit "$LIMIT" \
			--json number,title,labels,state 2>/dev/null |
			jq --arg r "$repo_entry" '[.[] | . + {repo: $r}]' 2>/dev/null || echo "[]"
	) >"$TMP_DIR/issues-$(printf '%04d' "$idx").json" &
	idx=$((idx + 1))
done < <(echo "$SCOPE_REPOS" | jq -r '.[]')
wait

jq -s 'add // []' "$TMP_DIR"/issues-*.json 2>/dev/null || echo "[]"
rm -rf "$TMP_DIR"
