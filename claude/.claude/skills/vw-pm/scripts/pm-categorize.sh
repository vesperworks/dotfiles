#!/bin/bash
# pm-categorize.sh
#
# Categorize a repository as dev | other | unknown using:
#   - name pattern (-frontend / -docs / ...)
#   - GitHub topics (documentation / wiki / planning / ...)
#   - primary language (TS/JS/Python/Go/Rust/Lua/Shell/... -> dev)
#
# Note: Task TEXT classification (議事録 -> dev/other) is intentionally NOT
#   handled here. That decision is delegated to the LLM (vw-pm SKILL flow),
#   which has full meeting-note context and handles polite/indirect phrasing
#   better than any keyword dictionary.
#
# Usage:
#   pm-categorize.sh <owner/repo>
#       Output: dev | other | unknown   (single token)
#
#   pm-categorize.sh --batch <repo1> [<repo2> ...]
#       Output: JSON object {"<repo>": "<category>", ...}
#
#   pm-categorize.sh --main <scope_repos_json>
#       Resolve the "main repository" from a JSON array of repos.
#       Priority: cwd match > dev latest pushed > first repo.
#       Output: owner/repo (single token)
#
# Examples:
#   pm-categorize.sh vesperworks/dotfiles
#   pm-categorize.sh --batch vesperworks/dotfiles vesperworks/test-ghProjects-Agents
#   pm-categorize.sh --main '["a/x","a/y"]'

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./pm-utils.sh
source "${SCRIPT_DIR}/pm-utils.sh"

usage() {
	grep "^#" "$0" | sed 's/^# \{0,1\}//'
}

case "${1:-}" in
"" | -h | --help)
	usage
	exit 0
	;;
--batch)
	shift
	[[ $# -eq 0 ]] && {
		echo "Error: --batch requires at least one repo" >&2
		exit 1
	}
	result="{}"
	for repo in "$@"; do
		cat=$(classify_repo_meta "$repo" 2>/dev/null || echo "unknown")
		result=$(echo "$result" | jq --arg r "$repo" --arg c "$cat" '. + {($r): $c}')
	done
	echo "$result"
	;;
--main)
	scope_json="${2:-}"
	[[ -z "$scope_json" ]] && {
		echo "Error: --main requires JSON array of repos" >&2
		exit 1
	}
	cwd_repo=""
	if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		cwd_repo=$(get_repo "" 2>/dev/null || echo "")
	fi
	resolve_main_repo "$cwd_repo" "$scope_json"
	;;
*)
	# Single repo mode
	classify_repo_meta "$1"
	;;
esac
