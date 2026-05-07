#!/bin/bash
# pm-resolve-scope.sh
#
# Resolve PM Agent multi-repo scope:
#   cwd repo  ->  linked Project (GraphQL reverse lookup)
#              ->  SCOPE_REPOS  (distinct repos in Project items)
#              ->  MAIN_REPO    (cwd match | dev latest pushed | first)
#
# Usage:
#   pm-resolve-scope.sh                          # auto-detect from cwd
#   pm-resolve-scope.sh --project <number>       # specify by project number
#   pm-resolve-scope.sh --project <number> --owner <login>
#   pm-resolve-scope.sh --project-id <PVT_xxx>   # specify by node id
#   pm-resolve-scope.sh --refresh                # ignore cache
#
# Output: JSON to stdout
#   {
#     mode:        "single" | "multi" | "ambiguous" | "error",
#     cwdRepo:     "owner/repo" | null,
#     project:     {id, number, title, url, ownerLogin, ownerType} | null,
#     scopeRepos:  ["owner/repo", ...],
#     mainRepo:    "owner/repo" | null,
#     candidates:  [project, ...]    // ambiguous mode only
#   }
#
# Exit codes:
#   0  success (mode == single | multi)
#   2  ambiguous (caller must pick a project from candidates)
#   1  error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./pm-utils.sh
source "${SCRIPT_DIR}/pm-utils.sh"

# ---- argv parse ----
PROJECT_NUMBER=""
PROJECT_ID=""
OWNER_INPUT=""
REFRESH=false

while [[ $# -gt 0 ]]; do
	case "$1" in
	--project)
		PROJECT_NUMBER="$2"
		shift 2
		;;
	--project-id)
		PROJECT_ID="$2"
		shift 2
		;;
	--owner)
		OWNER_INPUT="$2"
		shift 2
		;;
	--refresh)
		REFRESH=true
		shift
		;;
	-h | --help)
		grep "^#" "$0" | sed 's/^# \{0,1\}//'
		exit 0
		;;
	*)
		echo "Error: Unknown argument: $1" >&2
		exit 1
		;;
	esac
done

# ---- cache refresh ----
if [[ "$REFRESH" == "true" ]]; then
	rm -f "$(get_pm_cache_dir)"/scope-*.json "$(get_pm_cache_dir)"/repo-meta-*.json
fi

# ---- detect cwd repo (best-effort) ----
CWD_REPO=""
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	CWD_REPO=$(get_repo "" 2>/dev/null || echo "")
fi

# ---- resolve project ----
PROJECT_META="null"

resolve_project() {
	# Path A: explicit project id
	if [[ -n "$PROJECT_ID" ]]; then
		PROJECT_META=$(get_project_meta_by_id "$PROJECT_ID")
		return 0
	fi

	# Path B: project number + owner
	if [[ -n "$PROJECT_NUMBER" ]]; then
		local owner="${OWNER_INPUT:-@me}"
		PROJECT_ID=$(get_project_id "$owner" "$PROJECT_NUMBER")
		if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "null" ]]; then
			echo "Error: project number $PROJECT_NUMBER not found for owner $owner" >&2
			return 1
		fi
		PROJECT_META=$(get_project_meta_by_id "$PROJECT_ID")
		return 0
	fi

	# Path C: auto-detect from cwd
	if [[ -z "$CWD_REPO" ]]; then
		echo "Error: cwd is not a git repo and no --project specified" >&2
		return 1
	fi

	local projects count
	projects=$(get_projects_for_repo "$CWD_REPO")
	count=$(echo "$projects" | jq 'length')

	case "$count" in
	0)
		# No project linked: emit single-repo mode and exit
		jq -n --arg r "$CWD_REPO" '{
				mode: "single",
				cwdRepo: $r,
				project: null,
				scopeRepos: [$r],
				mainRepo: $r,
				candidates: []
			}'
		exit 0
		;;
	1)
		PROJECT_META=$(echo "$projects" | jq '.[0]')
		PROJECT_ID=$(echo "$PROJECT_META" | jq -r '.id')
		return 0
		;;
	*)
		# Ambiguous: emit candidates and exit 2
		jq -n --arg r "$CWD_REPO" --argjson c "$projects" '{
				mode: "ambiguous",
				cwdRepo: $r,
				project: null,
				scopeRepos: [],
				mainRepo: null,
				candidates: $c
			}'
		exit 2
		;;
	esac
}

resolve_project

# ---- expand SCOPE_REPOS ----
SCOPE_REPOS=$(get_project_scope_repos "$PROJECT_ID")

# ---- choose MAIN_REPO ----
MAIN_REPO=$(resolve_main_repo "$CWD_REPO" "$SCOPE_REPOS")

# ---- output ----
jq -n \
	--arg r "$CWD_REPO" \
	--argjson p "$PROJECT_META" \
	--argjson s "$SCOPE_REPOS" \
	--arg m "$MAIN_REPO" '{
		mode: "multi",
		cwdRepo: $r,
		project: $p,
		scopeRepos: $s,
		mainRepo: $m,
		candidates: []
	}'
