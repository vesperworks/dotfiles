#!/bin/bash
set -euo pipefail

# pre-commit-sensitive-check.sh - コミット前にセンシティブ情報を検出
# PreToolUse (Bash) で stdin から JSON を受け取り、commit コマンドを検出する
# 検出時は exit 2 でコミットをブロック

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# stdin から JSON を読み取り、コマンドを抽出
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

[[ -z "$COMMAND" ]] && exit 0

# commit コマンド以外はスキップ
if ! echo "$COMMAND" | grep -qE '(jj (commit|split|describe)|git commit)'; then
	exit 0
fi

# CWD を取得
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
if [[ -n "$CWD" ]]; then
	cd "$CWD" || exit 0
fi

# コミット対象ファイルを特定
# jj split -- file1 file2 → -- 以降を抽出
# jj commit/describe, git commit → 全変更ファイル
target_files=()

if echo "$COMMAND" | grep -q ' -- '; then
	# -- 以降のファイル引数を抽出
	files_part="${COMMAND#*-- }"
	for file in $files_part; do
		[[ -f "$file" ]] && target_files+=("$file")
	done
fi

# ファイル引数がない場合は全変更ファイル
if [[ ${#target_files[@]} -eq 0 ]]; then
	if command -v jj &>/dev/null && jj root &>/dev/null 2>&1; then
		while IFS= read -r file; do
			[[ -n "$file" && -f "$file" ]] && target_files+=("$file")
		done < <(jj diff --name-only 2>/dev/null)
	else
		while IFS= read -r file; do
			[[ -n "$file" && -f "$file" ]] && target_files+=("$file")
		done < <(git diff --cached --name-only 2>/dev/null)
	fi
fi

[[ ${#target_files[@]} -eq 0 ]] && exit 0

# security-utils.sh のチェック関数を使用
source "$SCRIPT_DIR/../scripts/security-utils.sh"

output=$(check_sensitive_info "${target_files[@]}" 2>/dev/null) || true

if [[ -n "$output" ]]; then
	echo "⚠ センシティブ情報を検出しました:" >&2
	echo "$output" | grep -v '^TYPE:' | head -10 >&2
	echo "" >&2
	echo "対処: 相対パスや ~/ に変換するか、確認の上そのままコミットしてください。" >&2
	exit 2
fi

exit 0
