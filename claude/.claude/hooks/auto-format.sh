#!/bin/bash

# auto-format.sh - PostToolUse hook for Write|Edit|MultiEdit
# ファイル編集後に拡張子に応じた自動フォーマットを実行する
#
# Input: stdin JSON with tool_input.file_path
# Output: exit 0 (always allow)

DEBUG="${CLAUDE_HOOKS_DEBUG:-false}"
DEBUG_LOG="$HOME/.claude/hooks/debug.log"

debug_log() {
	[[ "$DEBUG" == "true" ]] && echo "[auto-format] $1" >>"$DEBUG_LOG"
}

# stdin から JSON を読み取り
INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

if [[ -z "$FILE_PATH" ]]; then
	debug_log "file_path not found in input"
	exit 0
fi

debug_log "Processing: $FILE_PATH"

if [[ ! -f "$FILE_PATH" ]]; then
	debug_log "File does not exist: $FILE_PATH"
	exit 0
fi

EXTENSION="${FILE_PATH##*.}"
BASENAME=$(basename "$FILE_PATH")
DIRNAME=$(dirname "$FILE_PATH")

# プロジェクトルートを探す（親ディレクトリを遡る）
find_project_root() {
	local dir="$1"
	while [[ "$dir" != "/" ]]; do
		if [[ -f "$dir/package.json" ]] || [[ -f "$dir/pyproject.toml" ]] || [[ -d "$dir/.git" ]]; then
			echo "$dir"
			return 0
		fi
		dir=$(dirname "$dir")
	done
	echo "$1"
}

PROJECT_ROOT=$(find_project_root "$DIRNAME")
debug_log "Project root: $PROJECT_ROOT"

case "$EXTENSION" in
js | ts | tsx | jsx | mjs | cjs)
	debug_log "TS/JS format: $BASENAME"

	if [[ -f "$PROJECT_ROOT/biome.json" ]] || [[ -f "$PROJECT_ROOT/biome.jsonc" ]]; then
		(cd "$PROJECT_ROOT" && npx biome check --write "$FILE_PATH" 2>&1) || true
	elif [[ -f "$PROJECT_ROOT/package.json" ]]; then
		# package.json の format スクリプトがあれば使う
		if jq -e '.scripts.format' "$PROJECT_ROOT/package.json" &>/dev/null; then
			(cd "$PROJECT_ROOT" && npx prettier --write "$FILE_PATH" 2>&1) || true
		fi
	fi
	;;

py)
	debug_log "Python format: $BASENAME"

	if command -v uv &>/dev/null; then
		uv run ruff format "$FILE_PATH" 2>&1 || true
		uv run ruff check --fix "$FILE_PATH" 2>&1 || true
	elif command -v ruff &>/dev/null; then
		ruff format "$FILE_PATH" 2>&1 || true
		ruff check --fix "$FILE_PATH" 2>&1 || true
	fi
	;;

sh)
	debug_log "Shell format: $BASENAME"

	if command -v shfmt &>/dev/null; then
		shfmt -w "$FILE_PATH" 2>&1 || true
	fi
	if command -v shellcheck &>/dev/null; then
		shellcheck "$FILE_PATH" 2>&1 || true
	fi
	;;

*)
	debug_log "No formatter for extension: $EXTENSION"
	;;
esac

debug_log "Done: $BASENAME"
exit 0
