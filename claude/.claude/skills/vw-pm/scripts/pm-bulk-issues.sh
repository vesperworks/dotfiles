#!/bin/bash
# pm-bulk-issues.sh - Bulk issue creation with checkpoint
# Usage: pm-bulk-issues.sh <issues.json> [--repo owner/repo] [--milestone N] [--dry-run]
#
# Creates multiple GitHub Issues from a JSON file.
# Features:
#   - Checkpoint for error recovery (idempotent)
#   - Dry-run mode for preview
#   - Batch processing with rate limit protection
#   - Milestone assignment via REST API
#   - Per-issue repo override via .repo field (multi-repo mode)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pm-utils.sh"

# Load security utilities (required)
SECURITY_UTILS="${SCRIPT_DIR}/../../../scripts/security-utils.sh"
# shellcheck source=../../../scripts/security-utils.sh
source "$SECURITY_UTILS" || {
	echo "Error: security-utils.sh not found" >&2
	exit 1
}

usage() {
	cat <<EOF
Usage: $0 <issues.json> [options]

Options:
  --repo <owner/repo>    Default repository (used when an issue has no .repo field)
                         Auto-detected from cwd if omitted.
  --milestone <N>        Milestone number to assign (applied per issue's repo)
  --dry-run              Preview without creating issues
  --checkpoint <file>    Checkpoint file path (default: /tmp/claude/pm-checkpoint.json)
  --batch-size <N>       Issues per batch (default: 20)
  --delay <sec>          Delay between batches (default: 1)
  -h, --help             Show this help

Input JSON format:
[
  {"title": "Task name", "body": "Description", "type": "task",
   "labels": ["other-label"], "repo": "owner/repo"}
]

Per-issue repo (multi-repo mode):
  - If "repo" is present on an issue, it is used as the creation target.
  - Otherwise, the --repo argument (or auto-detected cwd repo) is used.
  - Issue Type / labels handling is decided per-issue based on its repo type.

Type handling (context-aware, evaluated per repo):
  - Organization repos: "type" field sets Issue Type via API
  - Personal repos: "type" field becomes "type:<value>" label
  - Labels in "labels" array are always applied
EOF
	exit 1
}

# Default values
ISSUES_FILE=""
REPO=""
MILESTONE=""
DRY_RUN=false
BATCH_SIZE=20
DELAY_SEC=1
CHECKPOINT_FILE="/tmp/claude/pm-checkpoint.json"

# Parse arguments
while [[ $# -gt 0 ]]; do
	case $1 in
	--repo)
		REPO="$2"
		shift 2
		;;
	--milestone)
		MILESTONE="$2"
		shift 2
		;;
	--dry-run)
		DRY_RUN=true
		shift
		;;
	--checkpoint)
		CHECKPOINT_FILE="$2"
		shift 2
		;;
	--batch-size)
		BATCH_SIZE="$2"
		shift 2
		;;
	--delay)
		DELAY_SEC="$2"
		shift 2
		;;
	-h | --help) usage ;;
	-*)
		echo "Unknown option: $1"
		usage
		;;
	*)
		ISSUES_FILE="$1"
		shift
		;;
	esac
done

# Validate input
[[ -z "$ISSUES_FILE" ]] && {
	echo "Error: issues.json is required"
	usage
}
[[ ! -f "$ISSUES_FILE" ]] && {
	echo "Error: File not found: $ISSUES_FILE"
	exit 1
}

# Determine default repo (used when an issue has no .repo field)
# If every issue has its own .repo, --repo is optional.
ALL_HAVE_REPO=$(jq 'all(.[]; has("repo") and (.repo != null) and (.repo != ""))' "$ISSUES_FILE" 2>/dev/null || echo "false")
if [[ -z "$REPO" && "$ALL_HAVE_REPO" != "true" ]]; then
	REPO=$(get_repo)
fi

# Ensure checkpoint directory exists
mkdir -p "$(dirname "$CHECKPOINT_FILE")"

# Detect distinct repos referenced by the input (default + per-issue)
DISTINCT_REPOS=$(jq -r --arg d "$REPO" '
	[.[] | (.repo // $d)] | map(select(. != "" and . != null)) | unique | .[]
' "$ISSUES_FILE")

# Cache is_org_repo results (bash 3.2: parallel arrays, no associative array)
CACHED_REPO_NAMES=()
CACHED_REPO_IS_ORG=()

cache_lookup_is_org() {
	local r="$1" i
	for i in "${!CACHED_REPO_NAMES[@]}"; do
		if [[ "${CACHED_REPO_NAMES[$i]}" == "$r" ]]; then
			[[ "${CACHED_REPO_IS_ORG[$i]}" == "true" ]]
			return $?
		fi
	done
	if is_org_repo "$r"; then
		CACHED_REPO_NAMES+=("$r")
		CACHED_REPO_IS_ORG+=("true")
		return 0
	else
		CACHED_REPO_NAMES+=("$r")
		CACHED_REPO_IS_ORG+=("false")
		return 1
	fi
}

echo "═══════════════════════════════════════════════"
echo "📋 pm-bulk-issues.sh"
echo "───────────────────────────────────────────────"
if [[ -n "$REPO" ]]; then
	echo "  Default repo: $REPO"
fi
echo "  Distinct repos in input:"
while IFS= read -r r; do
	[[ -z "$r" ]] && continue
	if cache_lookup_is_org "$r"; then
		echo "    - $r → 📋 Organization (Issue Types via API)"
	else
		echo "    - $r → 👤 Personal (type:* labels)"
	fi
done <<<"$DISTINCT_REPOS"
echo "═══════════════════════════════════════════════"
echo ""

[[ "$DRY_RUN" == true ]] && echo "🔍 DRY RUN MODE - no issues will be created"
echo ""

created_issues=()
skipped_count=0
count=0

while IFS= read -r issue; do
	# Extract values from JSON
	raw_title=$(echo "$issue" | jq -r '.title')
	raw_body=$(echo "$issue" | jq -r '.body // ""')
	issue_type=$(echo "$issue" | jq -r '.type // ""')
	raw_labels=$(echo "$issue" | jq -r '.labels // [] | join(",")')
	per_issue_repo=$(echo "$issue" | jq -r '.repo // empty')

	# Resolve target repo for this issue (.repo > --repo > cwd)
	issue_repo="${per_issue_repo:-$REPO}"
	if [[ -z "$issue_repo" ]]; then
		print_warn "Skipping issue with no resolvable repo (no .repo field, no --repo): ${raw_title:-<no-title>}"
		continue
	fi

	# Decide repo type for this issue
	if cache_lookup_is_org "$issue_repo"; then
		IS_ORG=true
	else
		IS_ORG=false
	fi

	# Validate and sanitize inputs
	if [[ -z "$raw_title" ]] || [[ "$raw_title" == "null" ]]; then
		print_warn "Skipping issue with empty title"
		continue
	fi
	title=$(sanitize_string "$raw_title" 256)
	if [[ -z "$title" ]]; then
		print_warn "Skipping issue with invalid title"
		continue
	fi

	body=""
	if [[ -n "$raw_body" ]] && [[ "$raw_body" != "null" ]]; then
		body=$(sanitize_string "$raw_body" 65536)
	fi

	labels=""
	if [[ -n "$raw_labels" ]] && validate_labels "$raw_labels"; then
		labels="$raw_labels"
	elif [[ -n "$raw_labels" ]]; then
		print_warn "Invalid labels format, skipping labels"
	fi

	if [[ -n "$issue_type" ]] && ! validate_issue_type "$issue_type"; then
		print_warn "Invalid issue type: $issue_type"
		issue_type=""
	fi

	# Check checkpoint (idempotency)
	if is_already_created "$CHECKPOINT_FILE" "$title"; then
		print_skip "Skip (exists): $title"
		skipped_count=$((skipped_count + 1))
		continue
	fi

	if [[ "$DRY_RUN" == true ]]; then
		echo "Would create [$issue_repo]: $title"
		[[ -n "$labels" ]] && echo "  └─ Labels: $labels"
		[[ -n "$MILESTONE" ]] && echo "  └─ Milestone: #$MILESTONE"
		continue
	fi

	# Build gh issue create arguments (use issue_repo, not the global REPO)
	args=(--repo "$issue_repo" --title "$title" --body "${body:- }")

	# Handle type field based on repository type
	final_labels="$labels"
	if [[ -n "$issue_type" ]] && [[ "$IS_ORG" == false ]]; then
		# Personal repo: add type as label
		if [[ -n "$final_labels" ]]; then
			final_labels="type:$issue_type,$final_labels"
		else
			final_labels="type:$issue_type"
		fi
	fi
	[[ -n "$final_labels" ]] && args+=(--label "$final_labels")

	# Create issue
	if url=$(gh issue create "${args[@]}"); then
		number=$(extract_issue_number "$url")

		print_success "Created $issue_repo#$number: $title"
		created_issues+=("$issue_repo#$number")

		# Save checkpoint
		save_checkpoint "$CHECKPOINT_FILE" "$number" "$title"

		# Set Issue Type for organization repos (via REST API)
		if [[ -n "$issue_type" ]] && [[ "$IS_ORG" == true ]]; then
			if set_issue_type "$issue_repo" "$number" "$issue_type" 2>/dev/null; then
				echo "   ↳ Issue Type: $issue_type"
			else
				print_warn "Failed to set Issue Type '$issue_type' for $issue_repo#$number"
			fi
		fi

		# Assign milestone if specified
		if [[ -n "$MILESTONE" ]]; then
			if assign_milestone "$issue_repo" "$number" "$MILESTONE" 2>/dev/null; then
				echo "   ↳ Assigned to milestone #$MILESTONE"
			else
				print_warn "Failed to assign milestone #$MILESTONE to $issue_repo#$number"
			fi
		fi
	else
		print_warn "Failed to create [$issue_repo]: $title"
	fi

	# Batch delay for rate limit protection
	count=$((count + 1))
	if ((count % BATCH_SIZE == 0)); then
		print_wait "Batch complete ($count issues), waiting ${DELAY_SEC}s..."
		sleep "$DELAY_SEC"
	fi
done < <(jq -c '.[]' "$ISSUES_FILE")

echo ""
echo "═══════════════════════════════════════════════"
echo "📊 Summary"
echo "───────────────────────────────────────────────"
if [[ "$DRY_RUN" == true ]]; then
	echo "  Mode: DRY RUN (no issues created)"
else
	echo "  Created: ${#created_issues[@]} issues"
	echo "  Skipped: $skipped_count issues"
	echo "  Checkpoint: $CHECKPOINT_FILE"
fi
echo "═══════════════════════════════════════════════"

# Output created issues (repo#number format) for downstream processing
if [[ ${#created_issues[@]} -gt 0 ]]; then
	echo ""
	print_info "Created: ${created_issues[*]}"
fi
