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
# status-interval 3s ごとに呼ばれるため jj 起動は 1 回に統合:
# @ の bookmark / 親の bookmark / change-id をタブ区切りで一括取得し bash 側で選ぶ。
# jj リポでなければ jj log が失敗して空になり、git にフォールバックする。
BRANCH=""
JJ_OUT=""
if command -v jj &>/dev/null; then
	JJ_OUT=$(jj log -r @ --no-graph \
		-T 'bookmarks.map(|b| b.name()).join(", ") ++ "\t" ++ parents.map(|c| c.bookmarks().map(|b| b.name()).join(", ")).join(", ") ++ "\t" ++ change_id.shortest(8)' \
		2>/dev/null) || JJ_OUT=""
fi
if [ -n "$JJ_OUT" ]; then
	IFS=$'\t' read -r WC_BOOKMARKS PARENT_BOOKMARKS CHANGE_ID <<<"$JJ_OUT"
	BRANCH="${WC_BOOKMARKS:-${PARENT_BOOKMARKS:-$CHANGE_ID}}"
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
