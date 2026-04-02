#!/usr/bin/env bash
set -eo pipefail

# Tokyo Night git-status.sh の jj 対応オーバーライド
# jj リポではブックマーク名、git リポではブランチ名を表示
# テーマカラーは Tokyo Night から取得

TOKYO_NIGHT_DIR="$HOME/.config/tmux/plugins/tokyo-night-tmux"

# Tokyo Night テーマ読み込み（-u 不可: themes.sh の連想配列が未定義変数扱いになる）
# shellcheck source=/dev/null
source "$TOKYO_NIGHT_DIR/src/themes.sh"

cd "$1" || exit 1

RESET="#[fg=${THEME[foreground]},bg=${THEME[background]},nobold,noitalics,nounderscore,nodim]"

# === ブランチ名取得（jj / git 自動判定） ===
BRANCH=""
if command -v jj &>/dev/null && jj root &>/dev/null 2>&1; then
	# jj リポ: カレントチェンジセットのブックマーク名を取得
	BRANCH=$(jj log -r @ --no-graph -T 'bookmarks.map(|b| b.name()).join(", ")' 2>/dev/null)
	if [ -z "$BRANCH" ]; then
		# ワーキングコピーにブックマークがなければ親を参照
		BRANCH=$(jj log -r '@-' --no-graph -T 'bookmarks.map(|b| b.name()).join(", ")' 2>/dev/null)
	fi
	if [ -z "$BRANCH" ]; then
		# どちらにもない場合は change-id の短縮形
		BRANCH=$(jj log -r @ --no-graph -T 'change_id.shortest(8)' 2>/dev/null)
	fi
else
	BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

if [ -z "$BRANCH" ]; then
	exit 0
fi

if [[ ${#BRANCH} -gt 25 ]]; then
	BRANCH="${BRANCH:0:25}…"
fi

# === 変更状態の取得 ===
STATUS=$(git status --porcelain 2>/dev/null | grep -cE "^(M| M)") || STATUS=0

SYNC_MODE=0
NEED_PUSH=0

STATUS_CHANGED=""
STATUS_INSERTIONS=""
STATUS_DELETIONS=""
STATUS_UNTRACKED=""

if [[ $STATUS -ne 0 ]]; then
	read -ra DIFF_COUNTS <<<"$(git diff --numstat 2>/dev/null | awk 'NF==3 {changed+=1; ins+=$1; del+=$2} END {printf("%d %d %d", changed, ins, del)}')"
	CHANGED_COUNT=${DIFF_COUNTS[0]:-0}
	INSERTIONS_COUNT=${DIFF_COUNTS[1]:-0}
	DELETIONS_COUNT=${DIFF_COUNTS[2]:-0}

	SYNC_MODE=1
fi

UNTRACKED_COUNT="$(git ls-files --other --directory --exclude-standard 2>/dev/null | wc -l | xargs)" || UNTRACKED_COUNT=0

if [[ ${CHANGED_COUNT:-0} -gt 0 ]]; then
	STATUS_CHANGED="${RESET}#[fg=${THEME[yellow]},bg=${THEME[background]},bold] ${CHANGED_COUNT} "
fi

if [[ ${INSERTIONS_COUNT:-0} -gt 0 ]]; then
	STATUS_INSERTIONS="${RESET}#[fg=${THEME[green]},bg=${THEME[background]},bold] ${INSERTIONS_COUNT} "
fi

if [[ ${DELETIONS_COUNT:-0} -gt 0 ]]; then
	STATUS_DELETIONS="${RESET}#[fg=${THEME[red]},bg=${THEME[background]},bold] ${DELETIONS_COUNT} "
fi

if [[ ${UNTRACKED_COUNT:-0} -gt 0 ]]; then
	STATUS_UNTRACKED="${RESET}#[fg=${THEME[black]},bg=${THEME[background]},bold] ${UNTRACKED_COUNT} "
fi

# === リモート同期状態 ===
if [[ $SYNC_MODE -eq 0 ]]; then
	# shellcheck disable=SC1083
	NEED_PUSH=$(git log '@{push}..' 2>/dev/null | wc -l | xargs) || NEED_PUSH=0
	if [[ $NEED_PUSH -gt 0 ]]; then
		SYNC_MODE=2
	fi
fi

# ステータスアイコン
case "$SYNC_MODE" in
1) REMOTE_STATUS="$RESET#[bg=${THEME[background]},fg=${THEME[bred]},bold]▒ 󱓎" ;;
2) REMOTE_STATUS="$RESET#[bg=${THEME[background]},fg=${THEME[red]},bold]▒ 󰛃" ;;
*) REMOTE_STATUS="$RESET#[bg=${THEME[background]},fg=${THEME[green]},bold]▒ " ;;
esac

echo "$REMOTE_STATUS $RESET$BRANCH $STATUS_CHANGED$STATUS_INSERTIONS$STATUS_DELETIONS$STATUS_UNTRACKED"
