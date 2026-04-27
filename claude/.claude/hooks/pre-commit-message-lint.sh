#!/bin/bash
set -euo pipefail

# pre-commit-message-lint.sh - コミットメッセージの「ダサい」要素を検出
# PreToolUse (Bash) で stdin から JSON を受け取り、jj/git の commit 系を検出する
# 違反時は exit 2 でコミットをブロック
#
# 検出項目:
#   1. AI生成痕跡（Co-Authored-By: 等）
#   2. AI絵文字署名（🤖, Generated with...）
#   3. Conventional Commits 形式違反（type(scope): subject）
#   4. subject の冗長/曖昧（wip, update files, misc 等）
#   5. subject の文末ピリオド
#   6. subject 50文字超過

DEBUG="${CLAUDE_HOOKS_DEBUG:-false}"
DEBUG_LOG="$HOME/.claude/hooks/debug.log"

debug_log() {
	if [[ "$DEBUG" == "true" ]]; then
		echo "[pre-commit-message-lint] $1" >>"$DEBUG_LOG"
	fi
	return 0
}

# stdin から JSON を読み取り、コマンドを抽出
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

[[ -z "$COMMAND" ]] && exit 0

# commit メッセージを伴うコマンド以外はスキップ
# 対象: jj commit/split/describe -m, git commit -m
if ! echo "$COMMAND" | grep -qE '(jj (commit|split|describe)|git commit)'; then
	exit 0
fi

# -m オプションがない（エディタ起動）場合はチェック対象外
# JJ_EDITOR=true で空メッセージのまま describe するケースもスキップ
if ! echo "$COMMAND" | grep -qE '(-m|--message)[ =]'; then
	debug_log "No -m option, skipping"
	exit 0
fi

debug_log "Command: $COMMAND"

# -m "..." または -m '...' のメッセージ部分を抽出
# Python で堅牢に shlex 解析（bash の単純な regex だとクオート escape を取り損なう）
# bash 3.2 互換のため ${var@Q} は使わず、環境変数経由で受け渡す
MESSAGE=$(
	COMMAND="$COMMAND" python3 - <<'PYEOF' 2>/dev/null
import os
import shlex
import sys

cmd = os.environ.get("COMMAND", "")
try:
    tokens = shlex.split(cmd)
except ValueError:
    sys.exit(0)

# 複数の -m を結合（git commit -m "subject" -m "body" 形式に対応）
parts = []
i = 0
while i < len(tokens):
    tok = tokens[i]
    if tok in ("-m", "--message") and i + 1 < len(tokens):
        parts.append(tokens[i + 1])
        i += 2
        continue
    if tok.startswith("-m") and len(tok) > 2:
        parts.append(tok[2:])
    elif tok.startswith("--message="):
        parts.append(tok[len("--message="):])
    i += 1

print("\n\n".join(parts))
PYEOF
)

if [[ -z "$MESSAGE" ]]; then
	debug_log "No message extracted"
	exit 0
fi

debug_log "Message: $MESSAGE"

# subject = メッセージの最初の行
SUBJECT=$(echo "$MESSAGE" | head -n1)

errors=()

# --- 1. AI生成痕跡 ---
ai_attribution_patterns=(
	'Co-Authored-By:'
	'Co-authored-by:'
	'co-authored-by:'
	'Generated with Claude'
	'Generated with AI'
	'Generated with GPT'
	'Made with Claude'
	'Made with AI'
	'Claude Code'
	'noreply@anthropic.com'
)
for pattern in "${ai_attribution_patterns[@]}"; do
	if echo "$MESSAGE" | grep -qiF "$pattern"; then
		errors+=("AI生成痕跡: '$pattern'")
	fi
done

# --- 2. AI絵文字署名 ---
ai_emoji_patterns=(
	'🤖'
	'✨ Generated'
)
for pattern in "${ai_emoji_patterns[@]}"; do
	if echo "$MESSAGE" | grep -qF "$pattern"; then
		errors+=("AI絵文字署名: '$pattern'")
	fi
done

# --- 3. Conventional Commits 形式 ---
# type(scope): subject または type: subject
# type は feat/fix/docs/style/refactor/test/chore/perf/build/ci/revert/merge
# (merge は jj のマージコミット用に許容)
conventional_re='^(feat|fix|docs|style|refactor|test|chore|perf|build|ci|revert|merge)(\([a-z0-9._/-]+\))?!?: .+'
if ! echo "$SUBJECT" | grep -qE "$conventional_re"; then
	errors+=("Conventional Commits 形式違反: '$SUBJECT'")
	errors+=("  期待: type(scope): subject  例: feat(auth): add login validation")
fi

# --- 4. subject の冗長/曖昧 ---
# subject 部分（: の後ろ）を取り出して判定
subject_body=$(echo "$SUBJECT" | sed -E 's/^[a-z]+(\([^)]+\))?!?: //')
vague_patterns=(
	'^wip$'
	'^WIP$'
	'^update files?$'
	'^update$'
	'^fix$'
	'^fix bug$'
	'^fix bugs$'
	'^misc$'
	'^misc changes$'
	'^stuff$'
	'^changes$'
	'^minor changes?$'
	'^small fix$'
	'^tweaks?$'
)
for pattern in "${vague_patterns[@]}"; do
	if echo "$subject_body" | grep -qiE "$pattern"; then
		errors+=("subject が曖昧: '$subject_body' （何を変えたか伝わらない）")
		break
	fi
done

# --- 5. subject の文末ピリオド ---
if echo "$SUBJECT" | grep -qE '\.$'; then
	errors+=("subject 末尾のピリオド: '$SUBJECT'")
fi

# --- 6. subject 50文字超過（ASCII想定。日本語は1文字=複数bytesになるので警告のみ） ---
subject_len=${#SUBJECT}
if [[ $subject_len -gt 72 ]]; then
	# 72文字超は確実にダサい（git log --oneline で折れる）
	errors+=("subject が長すぎ ($subject_len 文字 > 72): '$SUBJECT'")
fi

# --- 結果判定 ---
if [[ ${#errors[@]} -gt 0 ]]; then
	echo "⛔ コミットメッセージの品質チェックで違反を検出しました:" >&2
	for err in "${errors[@]}"; do
		echo "   - $err" >&2
	done
	echo "" >&2
	echo "対処: メッセージを修正してから再実行してください。" >&2
	echo "形式: type(scope): subject  （type = feat/fix/docs/style/refactor/test/chore/perf/build/ci/revert/merge）" >&2
	exit 2
fi

debug_log "All checks passed: $SUBJECT"
exit 0
