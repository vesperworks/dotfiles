#!/bin/bash
# herdr-common.sh — herdr スクリプト共通ヘルパー（source して使う。直接実行しない）
#
# 契約: workspace の同一性判定キーは「label = ディレクトリ basename」（label_for_dir）。
# herdr API (v0.7.1) の workspace list が cwd を返さないための制約。
# 既知の制限: 同名 basename の別ディレクトリは既存 workspace 扱いになる。
# cwd が API に載ったら同一性キーを cwd に切り替える。

# ディレクトリ → workspace label の変換規則（全スクリプトで必ずこれを使う）
label_for_dir() {
	printf '%s\n' "${1##*/}"
}

# herdr workspace list の JSON（サーバー未接続時は空文字）
ws_json() {
	herdr workspace list 2>/dev/null || true
}

# $1: ws_json の出力 → label 一覧（改行区切り）
ws_labels() {
	printf '%s\n' "$1" |
		jq -r '.result.workspaces[]?.label' 2>/dev/null || true
}
