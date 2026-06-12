#!/usr/bin/env bats
# sesh picker / cc-common の回帰テスト
# 実行: bats tmux/.config/tmux/tests/sesh_spec.bats

SCRIPTS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../scripts" && pwd)"

ALL_SCRIPTS=(
	cc-common.sh
	sesh-sessions.sh
	sesh-picker.sh
	save-pane-hash.sh
	cc-question-preview.sh
	cc-wait-count.sh
)

@test "bash -n: 全スクリプトが /bin/bash (3.2) で構文 OK" {
	for f in "${ALL_SCRIPTS[@]}"; do
		/bin/bash -n "$SCRIPTS_DIR/$f"
	done
}

@test "bash 3.2 非互換構文（declare -A / local -n / mapfile / \${var^^}）を含まない" {
	cd "$SCRIPTS_DIR"
	run grep -REn 'declare -A|local -n|mapfile|readarray|\$\{[A-Za-z_]+(\^\^|,,)\}' "${ALL_SCRIPTS[@]}"
	[ "$status" -ne 0 ]
}

@test "sanitize_name: 危険文字を _ に変換する" {
	source "$SCRIPTS_DIR/cc-common.sh"
	result=$(sanitize_name 'a b/c$d')
	[ "$result" = "a_b_c_d" ]
}

@test "sanitize_name: 英数・ドット・ハイフンは保持する" {
	source "$SCRIPTS_DIR/cc-common.sh"
	result=$(sanitize_name 'Abc-1.2_x')
	[ "$result" = "Abc-1.2_x" ]
}

@test "cache_key_for_args: '-t' が picker と status-right で同一キーになる" {
	source "$SCRIPTS_DIR/cc-common.sh"
	k1=$(cache_key_for_args "-t")
	k2=$(cache_key_for_args "-t")
	[ "$k1" = "$k2" ]
	[ -n "$k1" ]
}

@test "cache_key_for_args: 引数なしは default" {
	source "$SCRIPTS_DIR/cc-common.sh"
	[ "$(cache_key_for_args)" = "default" ]
}

@test "ensure_ps_snapshot: TTL 内の連続呼び出しでスナップショットを再生成しない" {
	source "$SCRIPTS_DIR/cc-common.sh"
	snap1=$(ensure_ps_snapshot)
	mtime1=$(stat -f %m "$snap1")
	snap2=$(ensure_ps_snapshot)
	mtime2=$(stat -f %m "$snap2")
	[ "$snap1" = "$snap2" ]
	[ "$mtime1" = "$mtime2" ]
	# 中身が ps 形式（pid ppid %cpu rss comm）である
	head -1 "$snap1" | grep -qE '^[[:space:]]*[0-9]+[[:space:]]+[0-9]+'
}

@test "compute_pane_hash: 同一セッションで冪等（tmux 必須、無ければ skip）" {
	if ! tmux list-sessions >/dev/null 2>&1; then
		skip "tmux server not running"
	fi
	source "$SCRIPTS_DIR/cc-common.sh"
	sess=$(tmux list-sessions -F '#{session_name}' | head -1)
	h1=$(compute_pane_hash "$sess")
	h2=$(compute_pane_hash "$sess")
	[ -n "$h1" ]
	[ "$h1" = "$h2" ]
}

@test "load_saved_pane_hash: 保存ファイルが無ければ空文字" {
	source "$SCRIPTS_DIR/cc-common.sh"
	result=$(load_saved_pane_hash "no-such-session-$$-$RANDOM")
	[ -z "$result" ]
}

@test "save-pane-hash.sh → load_saved_pane_hash の往復一致（tmux 必須）" {
	if ! tmux list-sessions >/dev/null 2>&1; then
		skip "tmux server not running"
	fi
	source "$SCRIPTS_DIR/cc-common.sh"
	sess=$(tmux list-sessions -F '#{session_name}' | head -1)
	bash "$SCRIPTS_DIR/save-pane-hash.sh" "$sess"
	saved=$(load_saved_pane_hash "$sess")
	[ -n "$saved" ]
	# 40 桁 hex (shasum)
	echo "$saved" | grep -qE '^[0-9a-f]{40}$'
}
