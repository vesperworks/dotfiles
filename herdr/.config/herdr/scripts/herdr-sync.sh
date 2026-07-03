#!/bin/bash
set -euo pipefail
# herdr-sync.sh — zoxide 履歴上位 N 件を herdr workspace として一括登録（冪等）。
# 詳細は -h（print_usage）を参照。

# label=basename の契約と共通関数（label_for_dir 等）は herdr-common.sh を参照
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=herdr-common.sh
source "$SCRIPT_DIR/herdr-common.sh"

print_usage() {
	cat <<'EOF'
使い方: herdr-sync.sh [-n] [N]

zoxide のディレクトリ履歴上位 N 件（デフォルト 10）を herdr の workspace として
一括登録する。既に同名 label が存在する場合はスキップする（冪等）。

オプション:
  -n    dry-run（登録内容を表示するだけで実行しない）

引数:
  N     zoxide 上位 N 件（デフォルト: 10）
EOF
}

dry_run=0
while getopts "nh" opt; do
	case "$opt" in
	n) dry_run=1 ;;
	h)
		print_usage
		exit 0
		;;
	*)
		print_usage >&2
		exit 1
		;;
	esac
done
shift $((OPTIND - 1))

top_n="${1:-${HERDR_SYNC_LIMIT:-10}}"
case "$top_n" in
'' | *[!0-9]*)
	echo "Error: N は正の整数で指定してください（指定値: ${top_n}）" >&2
	exit 1
	;;
esac

for cmd in herdr zoxide jq; do
	if ! command -v "$cmd" >/dev/null 2>&1; then
		echo "Error: 必要なコマンドが見つかりません: $cmd" >&2
		exit 1
	fi
done

# herdr workspace list は起動していないと失敗する（herdr サーバー未起動 = セットアップ不可）
if ! workspace_json=$(herdr workspace list 2>&1); then
	echo "Error: herdr workspace list に失敗しました（herdr サーバーが起動していないか、接続できません）" >&2
	echo "$workspace_json" >&2
	exit 1
fi

if ! existing_labels=$(printf '%s' "$workspace_json" | jq -r '.result.workspaces[]?.label' 2>&1); then
	echo "Error: herdr workspace list の JSON 解析に失敗しました" >&2
	echo "$existing_labels" >&2
	exit 1
fi

dirs=$(zoxide query -l | head -n "$top_n")

registered_count=0
skipped_count=0
# この実行中に登録（予定）した label を追記していき、同名衝突（別ディレクトリ同名）を検出する
session_labels=""

while IFS= read -r dir; do
	[ -z "$dir" ] && continue
	[ -d "$dir" ] || continue

	base=$(label_for_dir "$dir")

	# 既に herdr 側に同名 label が存在する → 冪等性のため無条件スキップ
	if printf '%s\n' "$existing_labels" | grep -Fxq "$base"; then
		skipped_count=$((skipped_count + 1))
		continue
	fi

	# この実行内で既に同名 label を登録（予定）済み → 別ディレクトリとの衝突なので警告してスキップ
	if printf '%s\n' "$session_labels" | grep -Fxq "$base"; then
		echo "警告: label '$base' が別ディレクトリと重複したためスキップします: $dir" >&2
		skipped_count=$((skipped_count + 1))
		continue
	fi

	if [ "$dry_run" = "1" ]; then
		echo "[dry-run] herdr workspace create --cwd \"$dir\" --label \"$base\" --no-focus"
	else
		if ! herdr workspace create --cwd "$dir" --label "$base" --no-focus >/dev/null; then
			echo "警告: '$base' の登録に失敗しました: $dir" >&2
			skipped_count=$((skipped_count + 1))
			continue
		fi
	fi

	session_labels="${session_labels}${base}
"
	registered_count=$((registered_count + 1))
done <<<"$dirs"

echo ""
if [ "$dry_run" = "1" ]; then
	echo "サマリ（dry-run）: 登録予定 ${registered_count} 件 / スキップ ${skipped_count} 件"
else
	echo "サマリ: 登録 ${registered_count} 件 / スキップ ${skipped_count} 件"
fi
