#!/bin/bash
# extract_index_context.sh
#
# Aggregate per-file summary caches into a single context document
# consumed by the index-generation phase. The LLM reads ONLY the output
# of this script; it never scans the target directory directly.
#
# Priority:
#   1. Summary cache at ./.claude/cache/vw-index/summaries/<path>.summary.md
#   2. Fallback: file header (head -20)
#
# Usage:
#   extract_index_context.sh <target-directory>
#
# Output:
#   $TMPDIR/vw-index/index_context.md

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
	echo "Usage: extract_index_context.sh <target-directory>" >&2
	exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
	echo "Error: directory not found: $TARGET_DIR" >&2
	exit 1
fi

TARGET_DIR="${TARGET_DIR%/}"
DIR_NAME=$(basename "$TARGET_DIR")
TARGET_PARENT=$(dirname "$TARGET_DIR")

# --- paths ---
CACHE_ROOT="./.claude/cache/vw-index/summaries"
TMP_DIR="${TMPDIR:-/tmp}/vw-index"
OUTPUT="${TMP_DIR}/index_context.md"
CACHE_LOG="${TMP_DIR}/cache_log.txt"
IGNORE_FILE="./.vwindexignore"

mkdir -p "$TMP_DIR"

# --- dependency check ---
if ! command -v fd >/dev/null 2>&1; then
	echo "Error: 'fd' is required. Install with: brew install fd (or apt install fd-find)" >&2
	exit 1
fi

# path helpers
to_dir_relative() {
	local full_path="$1"
	printf '%s' "${full_path#${TARGET_PARENT}/}"
}

# --- built-in excludes (same as build_summary_cache.sh) ---
BUILTIN_EXCLUDES='/(index\.md|\.DS_Store|Thumbs\.db)$|\.summary\.md$|/(\.git|\.hg|\.svn|node_modules|\.venv|venv|__pycache__|dist|build|target|\.next|\.nuxt|\.claude|\.cursor)/'

build_ignore_regex() {
	if [ ! -f "$IGNORE_FILE" ]; then
		return 0
	fi
	local pattern
	local first=1
	while IFS= read -r pattern || [ -n "$pattern" ]; do
		pattern="${pattern%%#*}"
		pattern="$(printf '%s' "$pattern" | awk '{$1=$1; print}')"
		[ -z "$pattern" ] && continue
		local re
		re="$(printf '%s' "$pattern" |
			sed -e 's/[.[\*^$+?{}|()]/\\&/g' \
				-e 's/\\\*/.*/g')"
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

# --- file discovery ---
ALL_FILES=$(fd --type f --extension md --hidden --no-ignore-vcs . "$TARGET_DIR" 2>/dev/null | sort)

if [ -z "$ALL_FILES" ]; then
	echo "No .md files found in: $TARGET_DIR" >&2
	exit 0
fi

FILTERED_FILES=$(printf '%s\n' "$ALL_FILES" | rg -v "$BUILTIN_EXCLUDES" || true)
if [ -n "$USER_IGNORE_REGEX" ]; then
	FILTERED_FILES=$(printf '%s\n' "$FILTERED_FILES" | rg -v "$USER_IGNORE_REGEX" || true)
fi

FILE_COUNT=$(printf '%s\n' "$FILTERED_FILES" | rg -c '.' || echo 0)

# --- cache hit/miss accounting ---
{
	echo "# Cache log"
	echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
	echo "Target: ${TARGET_DIR}"
	echo ""
} >"$CACHE_LOG"

cache_hit_count=0
cache_miss_count=0

while IFS= read -r f; do
	[ -z "$f" ] && continue
	cache_path="${CACHE_ROOT}/${f}.summary.md"
	if [ -f "$cache_path" ]; then
		cache_hit_count=$((cache_hit_count + 1))
		echo "[HIT]  $(to_dir_relative "$f")" >>"$CACHE_LOG"
	else
		cache_miss_count=$((cache_miss_count + 1))
		echo "[MISS] $(to_dir_relative "$f")" >>"$CACHE_LOG"
	fi
done <<<"$FILTERED_FILES"

# --- fallback: file header ---
extract_head_fallback() {
	local file="$1"
	head -20 "$file"
}

# --- summary retrieval (cache or fallback) ---
get_summary_or_fallback() {
	local file="$1"
	local cache_file="${CACHE_ROOT}/${file}.summary.md"

	if [ -f "$cache_file" ]; then
		# strip header (source/mtime/generated lines)
		awk '
      /^generated: / { in_header=0; next }
      in_header { next }
      /^source: / || /^mtime: / { in_header=1; next }
      { print }
    ' "$cache_file"
		return
	fi

	echo "_(no summary cache — fallback: first 20 lines of source)_"
	echo ""
	echo '```'
	extract_head_fallback "$file"
	echo '```'
}

# --- timeline extraction ---
# Rule: if filename starts with YYYYMMDD or YYYY-MM-DD, use that as the date.
# Otherwise mark as 0000-00-00 (sorts last).
extract_timeline() {
	local files="$1"
	printf '%s\n' "$files" | while IFS= read -r file; do
		[ -z "$file" ] && continue
		basename_file=$(basename "$file")

		date_str=""
		# YYYYMMDD prefix
		if printf '%s' "$basename_file" | grep -qE '^[0-9]{8}'; then
			yyyy=$(printf '%s' "$basename_file" | cut -c1-4)
			mm=$(printf '%s' "$basename_file" | cut -c5-6)
			dd=$(printf '%s' "$basename_file" | cut -c7-8)
			date_str="${yyyy}-${mm}-${dd}"
		# YYYY-MM-DD prefix
		elif printf '%s' "$basename_file" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}'; then
			date_str=$(printf '%s' "$basename_file" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}')
		# YYYY-MM prefix (monthly files, treat as first of month)
		elif printf '%s' "$basename_file" | grep -qE '^[0-9]{4}-[0-9]{2}([._-]|\.md$)'; then
			ym=$(printf '%s' "$basename_file" | grep -oE '^[0-9]{4}-[0-9]{2}')
			date_str="${ym}-01"
		fi

		[ -z "$date_str" ] && date_str="0000-00-00"

		title=$(printf '%s' "$basename_file" |
			sed -E 's/^[0-9]{4}-?[0-9]{2}-?[0-9]{2}_?-?//; s/^[0-9]{4}-[0-9]{2}_?-?//; s/\.md$//')
		# Fall back to basename (without extension) if stripping left nothing useful
		if [ -z "$title" ]; then
			title=$(printf '%s' "$basename_file" | sed -E 's/\.md$//')
		fi
		rel_path=$(to_dir_relative "$file")

		printf '%s\t%s\t%s\n' "$date_str" "$title" "$rel_path"
	done | sort
}

# --- output ---
{
	echo "# ${DIR_NAME} — Index Context"
	echo ""
	echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
	echo "Target:    ${TARGET_DIR}/"
	echo "Files:     ${FILE_COUNT} (cache hits: ${cache_hit_count}, misses: ${cache_miss_count})"
	echo ""
	echo "---"
	echo ""

	echo "## Timeline (date-ordered)"
	echo ""
	extract_timeline "$FILTERED_FILES" | while IFS=$'\t' read -r date title file; do
		echo "- **${date}**: ${title} → \`${file}\`"
	done
	echo ""
	echo "---"
	echo ""

	echo "## Per-file summaries"
	echo ""
	printf '%s\n' "$FILTERED_FILES" | while IFS= read -r file; do
		[ -z "$file" ] && continue
		basename_file=$(basename "$file")

		echo "### ${basename_file}"
		echo "source: $(to_dir_relative "$file")"
		echo ""
		get_summary_or_fallback "$file"
		echo ""
		echo "---"
		echo ""
	done

} >"$OUTPUT"

output_size=$(wc -c <"$OUTPUT" | tr -d ' ')
output_chars=$(wc -m <"$OUTPUT" | tr -d ' ')

echo "Context extraction complete."
echo "  Output:    ${OUTPUT}"
echo "  Cache log: ${CACHE_LOG}"
echo "  Size:      ${output_size} bytes (${output_chars} chars)"
echo "  Files:     ${FILE_COUNT} | cache hits: ${cache_hit_count} | misses: ${cache_miss_count}"
echo ""
if [ "$cache_miss_count" -gt 0 ]; then
	echo "Warning: ${cache_miss_count} file(s) have no summary cache."
	echo "  For best quality, run the summary phase first:"
	echo "    1. scripts/build_summary_cache.sh ${TARGET_DIR}"
	echo "    2. Invoke vw-file-summarizer agent"
	echo "    3. Re-run this script"
fi
