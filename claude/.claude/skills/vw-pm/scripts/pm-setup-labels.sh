#!/bin/bash
# pm-setup-labels.sh - Context-aware label creation for pm-agent
# Usage: pm-setup-labels.sh [owner/repo] [options]
#
# Creates labels based on repository type:
# - Personal repos: type:* labels (priority managed via Projects V2 Fields)
# - Org repos: No type labels (use Issue Types), no priority labels
#
# Multi-repo support:
#   --all-repos          Apply to all SCOPE_REPOS (auto-resolved via pm-resolve-scope.sh)
#   --repos a/r1,a/r2    Apply to a comma-separated list of repos
#   --scope '<json>'     Apply to a JSON array of repos
#
# Idempotent: skips existing labels.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pm-utils.sh"

usage() {
	cat <<EOF
Usage: $0 [owner/repo] [options]

Options:
  --force-labels         Create all labels regardless of repo type (legacy mode)
  --with-priority        Also create priority:* labels (deprecated)
  --all-repos            Apply to all SCOPE_REPOS (auto via pm-resolve-scope.sh)
  --repos a/r1,a/r2      Apply to comma-separated list of repos
  --scope '<json_array>' Apply to JSON array of repos
  -h, --help             Show this help

Resolution precedence: --scope > --repos > --all-repos > positional > cwd auto.

Behavior by repository type (per repo, evaluated independently):
  Personal repos: Creates type:* labels only
  Org repos:      No labels created (use Issue Types instead)

Priority is always managed via Projects V2 Fields, not labels.
EOF
	exit 1
}

# Default values
REPO=""
REPOS_CSV=""
SCOPE_INPUT=""
ALL_REPOS=false
FORCE_LABELS=false
WITH_PRIORITY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
	case $1 in
	--force-labels)
		FORCE_LABELS=true
		shift
		;;
	--with-priority)
		WITH_PRIORITY=true
		shift
		;;
	--all-repos)
		ALL_REPOS=true
		shift
		;;
	--repos)
		REPOS_CSV="$2"
		shift 2
		;;
	--scope)
		SCOPE_INPUT="$2"
		shift 2
		;;
	-h | --help) usage ;;
	-*)
		echo "Unknown option: $1"
		usage
		;;
	*)
		REPO="$1"
		shift
		;;
	esac
done

# Build SCOPE_REPOS based on precedence
build_scope_repos() {
	local result=""
	if [[ -n "$SCOPE_INPUT" ]]; then
		result="$SCOPE_INPUT"
	elif [[ -n "$REPOS_CSV" ]]; then
		result=$(printf '%s' "$REPOS_CSV" | tr ',' '\n' | sed '/^[[:space:]]*$/d' | jq -R . | jq -s .)
	elif [[ "$ALL_REPOS" == "true" ]]; then
		local resolved
		resolved=$("$SCRIPT_DIR/pm-resolve-scope.sh" 2>/dev/null) || true
		if [[ -n "$resolved" ]]; then
			result=$(echo "$resolved" | jq -c '.scopeRepos')
		fi
	elif [[ -n "$REPO" ]]; then
		result=$(jq -nc --arg r "$REPO" '[$r]')
	else
		# Auto-detect cwd
		local cwd
		cwd=$(get_repo 2>/dev/null || echo "")
		[[ -n "$cwd" ]] && result=$(jq -nc --arg r "$cwd" '[$r]')
	fi
	[[ -z "$result" ]] && result="[]"
	echo "$result"
}

SCOPE_REPOS=$(build_scope_repos)
SCOPE_COUNT=$(echo "$SCOPE_REPOS" | jq 'length')
if [[ "$SCOPE_COUNT" -eq 0 ]]; then
	echo "Error: No repos resolved (specify a repo, --repos, --scope, or --all-repos)" >&2
	exit 1
fi

# Label definitions: name:color:description
type_labels=(
	"type:epic:5319E7:マイルストーン"
	"type:feature:0052CC:機能要件"
	"type:story:00875A:ユーザーストーリー"
	"type:task:97A0AF:実装タスク"
	"type:bug:D73A4A:バグ修正"
)

priority_labels=(
	"priority:high:B60205:最優先"
	"priority:medium:FBCA04:通常"
	"priority:low:0E8A16:低優先度"
)

# Create labels from array passed as arguments
# Usage: create_labels "name:color:desc" "name:color:desc" ...
# Returns: "created_count skipped_count"
create_labels() {
	local created=0
	local skipped=0

	for item in "$@"; do
		IFS=':' read -r name color desc <<<"$item"
		if gh label create "$name" --color "$color" --description "$desc" --repo "$REPO" 2>/dev/null; then
			print_success "Created: $name"
			((created++))
		else
			print_skip "Exists: $name"
			((skipped++))
		fi
	done

	echo "$created $skipped"
}

echo "═══════════════════════════════════════════════"
echo "📋 pm-setup-labels.sh"
echo "───────────────────────────────────────────────"
echo "  Scope: $SCOPE_COUNT repo(s)"
echo "$SCOPE_REPOS" | jq -r '.[]' | while IFS= read -r r; do
	echo "    - $r"
done
echo "═══════════════════════════════════════════════"
echo ""

total_created=0
total_skipped=0
processed=0

while IFS= read -r repo_iter; do
	[[ -z "$repo_iter" ]] && continue
	# REPO is referenced by create_labels via global; reassign per iteration
	REPO="$repo_iter"
	processed=$((processed + 1))

	echo "─── [$processed/$SCOPE_COUNT] $REPO ───"

	# Determine repository type for this iteration
	IS_ORG=false
	if is_org_repo "$REPO"; then
		IS_ORG=true
		echo "  Type: 📋 Organization repository"
	else
		echo "  Type: 👤 Personal repository"
	fi
	echo ""

	if [[ "$FORCE_LABELS" == true ]]; then
		# Legacy mode: create all labels
		echo "⚠️ Force mode: Creating all labels (legacy behavior)"
		echo ""

		echo "Creating type:* labels..."
		read -r created skipped <<<"$(create_labels "${type_labels[@]}")"
		((total_created += created))
		((total_skipped += skipped))

		if [[ "$WITH_PRIORITY" == true ]]; then
			echo ""
			echo "Creating priority:* labels..."
			read -r created skipped <<<"$(create_labels "${priority_labels[@]}")"
			((total_created += created))
			((total_skipped += skipped))
		fi

	elif [[ "$IS_ORG" == true ]]; then
		# Organization repository
		echo "📋 Organization repository detected"
		echo ""
		echo "→ type:* ラベルは作成しません"
		echo "  代わりに GitHub Issue Types を使用してください:"
		echo "  Settings → Planning → Issue types"
		echo ""
		echo "→ priority は Projects V2 フィールドで管理します"
		echo ""

		# Check if Issue Types are available
		owner=$(get_repo_owner "$REPO")
		issue_types=$(get_org_issue_types "$owner")
		if [[ -n "$issue_types" ]]; then
			echo "✅ 利用可能な Issue Types:"
			echo "$issue_types" | while read -r t; do
				echo "   - $t"
			done
		else
			echo "⚠️ Issue Types が設定されていません"
			echo "   組織設定から Issue Types を作成してください"
		fi

		echo ""
		print_info "ラベル作成をスキップしました"

	else
		# Personal repository
		echo "👤 Personal repository detected"
		echo ""
		echo "→ type:* ラベルを作成します"
		echo "→ priority は Projects V2 フィールドで管理します"
		echo ""

		echo "Creating type:* labels..."
		read -r created skipped <<<"$(create_labels "${type_labels[@]}")"
		((total_created += created))
		((total_skipped += skipped))

		if [[ "$WITH_PRIORITY" == true ]]; then
			echo ""
			echo "⚠️ --with-priority is deprecated. Use Projects V2 Fields instead."
			echo "Creating priority:* labels..."
			read -r created skipped <<<"$(create_labels "${priority_labels[@]}")"
			((total_created += created))
			((total_skipped += skipped))
		fi
	fi
	echo ""
done < <(echo "$SCOPE_REPOS" | jq -r '.[]')

echo "═══════════════════════════════════════════════"
echo "📊 Total Summary ($processed repo(s))"
echo "───────────────────────────────────────────────"
echo "  Labels created: $total_created"
echo "  Labels skipped: $total_skipped"
echo "═══════════════════════════════════════════════"
