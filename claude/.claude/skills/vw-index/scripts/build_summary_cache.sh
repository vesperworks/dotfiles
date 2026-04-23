#!/bin/bash
# build_summary_cache.sh
#
# Scan a target directory for Markdown files and produce a summarization
# target list. Files whose cache is present and matches current mtime are
# skipped. Cache invalidation: mtime comparison.
#
# This script does NOT call an LLM. LLM invocation is handled by the
# vw-file-summarizer agent, consuming the output of this script.
#
# Usage:
#   build_summary_cache.sh <target-directory>
#
# Output:
#   $TMPDIR/vw-index/summary_targets.md   (list of files needing summary)
#
# Cache layout (cwd-relative):
#   ./.claude/cache/vw-index/summaries/<relative-path>.summary.md
#
# Ignore rules:
#   - Built-in defaults (SKILL outputs, VCS, common build artifacts)
#   - ./.vwindexignore (gitignore syntax) for project-specific patterns

set -euo pipefail

export PATH="$HOME/.cargo/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

# --- arguments ---
TARGET_DIR=""
while [ $# -gt 0 ]; do
	case "$1" in
	-*)
		echo "Unknown option: $1" >&2
		exit 1
		;;
	*)
		TARGET_DIR="$1"
		shift
		;;
	esac
done

if [ -z "$TARGET_DIR" ]; then
	echo "Usage: build_summary_cache.sh <target-directory>" >&2
	exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
	echo "Error: directory not found: $TARGET_DIR" >&2
	exit 1
fi

TARGET_DIR="${TARGET_DIR%/}"

# --- paths (cwd-relative) ---
CACHE_ROOT="./.claude/cache/vw-index/summaries"
TMP_DIR="${TMPDIR:-/tmp}/vw-index"
TARGETS_FILE="${TMP_DIR}/summary_targets.md"
IGNORE_FILE="./.vwindexignore"

mkdir -p "$CACHE_ROOT" "$TMP_DIR"

# --- dependency check ---
if ! command -v fd >/dev/null 2>&1; then
	echo "Error: 'fd' is required. Install with: brew install fd (or apt install fd-find)" >&2
	exit 1
fi

# --- built-in default excludes (domain-neutral) ---
# These are patterns that should NEVER be indexed:
#   - Skill's own output (index.md) and cache (*.summary.md)
#   - Version control and build artifacts
BUILTIN_EXCLUDES='/(index\.md|\.DS_Store|Thumbs\.db)$|\.summary\.md$|/(\.git|\.hg|\.svn|node_modules|\.venv|venv|__pycache__|dist|build|target|\.next|\.nuxt|\.claude|\.cursor)/'

# --- load .vwindexignore patterns ---
# Convert gitignore-style patterns to a regex OR chain.
# Rules supported: literal paths, *.glob, dir/ (trailing slash), leading # comment, blank lines.
build_ignore_regex() {
	if [ ! -f "$IGNORE_FILE" ]; then
		return 0
	fi
	local pattern
	local first=1
	while IFS= read -r pattern || [ -n "$pattern" ]; do
		# strip comments and whitespace
		pattern="${pattern%%#*}"
		pattern="$(printf '%s' "$pattern" | awk '{$1=$1; print}')"
		[ -z "$pattern" ] && continue
		# convert glob to regex
		local re
		re="$(printf '%s' "$pattern" |
			sed -e 's/[.[\*^$+?{}|()]/\\&/g' \
				-e 's/\\\*/.*/g')"
		# directory pattern: trailing slash
		case "$pattern" in
		*/)
			re="${re%/}"
			re="(^|/)${re}(/|$)"
			;;
		/*)
			re="^${re#\\/}(/|$)"
			;;
		*)
			re="(^|/)${re}(/|$)"
			;;
		esac
		if [ "$first" -eq 1 ]; then
			printf '%s' "$re"
			first=0
		else
			printf '|%s' "$re"
		fi
	done <"$IGNORE_FILE"
}

USER_IGNORE_REGEX="$(build_ignore_regex)"

# --- mtime helper (macOS / Linux compat) ---
get_mtime() {
	local file="$1"
	if stat -f %m "$file" >/dev/null 2>&1; then
		stat -f %m "$file"
	else
		stat -c %Y "$file"
	fi
}

# --- file discovery ---
ALL_FILES=$(fd --type f --extension md --hidden --no-ignore-vcs . "$TARGET_DIR" 2>/dev/null | sort)

if [ -z "$ALL_FILES" ]; then
	echo "No .md files found in: $TARGET_DIR" >&2
	exit 0
fi

# --- apply built-in excludes ---
FILTERED_FILES=$(printf '%s\n' "$ALL_FILES" | rg -v "$BUILTIN_EXCLUDES" || true)

# --- apply .vwindexignore ---
if [ -n "$USER_IGNORE_REGEX" ]; then
	FILTERED_FILES=$(printf '%s\n' "$FILTERED_FILES" | rg -v "$USER_IGNORE_REGEX" || true)
fi

# --- cache check ---
TARGETS_LIST="${TMP_DIR}/.targets.tmp"
: >"$TARGETS_LIST"

HITS=0
MISSES=0

while IFS= read -r file; do
	[ -z "$file" ] && continue

	cache_file="${CACHE_ROOT}/${file}.summary.md"
	current_mtime=$(get_mtime "$file")

	if [ -f "$cache_file" ]; then
		cached_mtime=$(rg '^mtime: ' "$cache_file" 2>/dev/null | head -1 | awk '{print $2}' || echo "")
		if [ "$cached_mtime" = "$current_mtime" ]; then
			HITS=$((HITS + 1))
			continue
		fi
	fi

	printf '%s\t%s\n' "$file" "$current_mtime" >>"$TARGETS_LIST"
	MISSES=$((MISSES + 1))
done <<<"$FILTERED_FILES"

# --- emit targets file ---
{
	echo "# Summary Target List"
	echo ""
	echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
	echo "Target directory: ${TARGET_DIR}"
	echo "Targets: ${MISSES} | Cache hits: ${HITS}"
	echo ""
	echo "---"
	echo ""
	echo "## Files to summarize"
	echo ""
	if [ "$MISSES" -gt 0 ]; then
		while IFS=$'\t' read -r file mtime; do
			echo "- \`${file}\` (mtime: \`${mtime}\`)"
		done <"$TARGETS_LIST"
	else
		echo "_(none — all cached)_"
	fi
	echo ""
	echo "---"
	echo ""
	echo "## Agent instructions"
	echo ""
	echo "For each file above:"
	echo ""
	echo "1. Read the source file (prefer structured sections; for long files, read head + main headings)."
	echo "2. Generate a structured summary in **100 lines or fewer**, using the template below."
	echo "3. Write the summary to \`${CACHE_ROOT}/<source-path>.summary.md\`."
	echo "4. The output header MUST include:"
	echo "   - \`source: <source path>\`"
	echo "   - \`mtime: <UNIX epoch seconds>\` (use the mtime from this list)"
	echo "   - \`generated: YYYY-MM-DD HH:MM\`"
	echo ""
	echo "Summary template (section headings in English; body language follows source):"
	echo ""
	echo '```markdown'
	echo "# <filename>"
	echo "source: <source path>"
	echo "mtime: <unix seconds>"
	echo "generated: YYYY-MM-DD HH:MM"
	echo ""
	echo "## Overview"
	echo "(3 lines max — what this file is about)"
	echo ""
	echo "## Key Topics"
	echo "- **Topic**: 1-2 line description"
	echo ""
	echo "## Decisions"
	echo "- (any decisions made, if present)"
	echo ""
	echo "## Open Questions"
	echo "- (unresolved items, if present)"
	echo '```'
} >"$TARGETS_FILE"

rm -f "$TARGETS_LIST"

# --- report ---
echo "Summary cache scan: ${TARGET_DIR}"
echo "  Targets: ${MISSES} | Cache hits: ${HITS}"
echo "  Target list: ${TARGETS_FILE}"
echo "  Cache root:  ${CACHE_ROOT}"
echo ""
if [ "$MISSES" -gt 0 ]; then
	echo "Next: invoke the vw-file-summarizer agent with ${TARGETS_FILE}"
else
	echo "All files cached. No summarization needed."
fi
