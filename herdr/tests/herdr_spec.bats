#!/usr/bin/env bats
# herdr stow パッケージ（config.toml + herdr-picker.sh + herdr-sync.sh）の回帰テスト
# 実行: bats herdr/.config/herdr/tests/herdr_spec.bats
#
# herdr サーバーへの実接続はしない（静的検証中心）。

HERDR_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
SCRIPTS_DIR="$HERDR_DIR/scripts"
CONFIG_FILE="$HERDR_DIR/config.toml"

ALL_SCRIPTS=(
	herdr-picker.sh
	herdr-sync.sh
	herdr-open.sh
	herdr-migrate.sh
)

# --- 共通: 存在・実行権限・シェバン・set -euo pipefail --------------------------

@test "herdr-picker.sh: 存在し実行権限を持つ" {
	[ -f "$SCRIPTS_DIR/herdr-picker.sh" ]
	[ -x "$SCRIPTS_DIR/herdr-picker.sh" ]
}

@test "herdr-sync.sh: 存在し実行権限を持つ" {
	[ -f "$SCRIPTS_DIR/herdr-sync.sh" ]
	[ -x "$SCRIPTS_DIR/herdr-sync.sh" ]
}

@test "herdr-open.sh: 存在し実行権限を持つ" {
	[ -f "$SCRIPTS_DIR/herdr-open.sh" ]
	[ -x "$SCRIPTS_DIR/herdr-open.sh" ]
}

@test "herdr-migrate.sh: 存在し実行権限を持つ" {
	[ -f "$SCRIPTS_DIR/herdr-migrate.sh" ]
	[ -x "$SCRIPTS_DIR/herdr-migrate.sh" ]
}

@test "herdr-common.sh: 存在し、label_for_dir / ws_json / ws_labels を定義している" {
	[ -f "$SCRIPTS_DIR/herdr-common.sh" ]
	grep -qE '^label_for_dir\(\)' "$SCRIPTS_DIR/herdr-common.sh"
	grep -qE '^ws_json\(\)' "$SCRIPTS_DIR/herdr-common.sh"
	grep -qE '^ws_labels\(\)' "$SCRIPTS_DIR/herdr-common.sh"
}

@test "全スクリプトが herdr-common.sh を source している（規則の一元化）" {
	for f in "${ALL_SCRIPTS[@]}"; do
		grep -q 'herdr-common.sh' "$SCRIPTS_DIR/$f"
	done
}

@test "herdr-open.sh: focus と create --cwd の両分岐が存在する" {
	grep -qE 'herdr workspace focus' "$SCRIPTS_DIR/herdr-open.sh"
	grep -qE 'herdr workspace create --cwd' "$SCRIPTS_DIR/herdr-open.sh"
}

@test "herdr-open.sh: open_workspace は label 第2引数を受け取り、省略時は label_for_dir にフォールバックする（PRP-027 Phase 1）" {
	grep -qE 'label="\$\{2:-\}"' "$SCRIPTS_DIR/herdr-open.sh"
	grep -qE 'label="\$\(label_for_dir "\$dir"\)"' "$SCRIPTS_DIR/herdr-open.sh"
}

@test "herdr-open.sh: main が第2引数（label）を open_workspace に渡す（PRP-027 Phase 1）" {
	# is_inside_herdr 分岐と通常分岐の両方で label を引き継ぐこと
	count=$(grep -cE 'open_workspace "\$dir" "\$label"' "$SCRIPTS_DIR/herdr-open.sh")
	[ "$count" -eq 2 ]
}

@test "herdr-migrate.sh: claude 判定の正規表現（バージョン番号形式）が存在する（PRP-027 Phase 2）" {
	grep -qF 'CLAUDE_VERSION_PATTERN=' "$SCRIPTS_DIR/herdr-migrate.sh"
	grep -qF '^[0-9]+\.[0-9]+\.[0-9]+$' "$SCRIPTS_DIR/herdr-migrate.sh"
	grep -qF '[[ "$cmd" =~ $CLAUDE_VERSION_PATTERN ]]' "$SCRIPTS_DIR/herdr-migrate.sh"
}

@test "herdr-migrate.sh: remain-on-exit の設定と復元（trap 経由）が存在する（PRP-027 Phase 2）" {
	grep -qF 'tmux set-option -t "$session:" remain-on-exit on' "$SCRIPTS_DIR/herdr-migrate.sh"
	grep -qF 'restore_remain_on_exit "$session"' "$SCRIPTS_DIR/herdr-migrate.sh"
	grep -qF 'trap "restore_remain_on_exit' "$SCRIPTS_DIR/herdr-migrate.sh"
	grep -qF 'tmux set-option -u -t "$session:" remain-on-exit' "$SCRIPTS_DIR/herdr-migrate.sh"
}

@test "herdr-migrate.sh: busy ガード（esc to interrupt）が存在する（PRP-027 Phase 2）" {
	grep -qF "BUSY_MARKER='esc to interrupt'" "$SCRIPTS_DIR/herdr-migrate.sh"
	grep -qF 'grep -qi "$BUSY_MARKER"' "$SCRIPTS_DIR/herdr-migrate.sh"
}

@test "herdr-migrate.sh: workspace_id / resume uuid の jq パースが存在する（PRP-027 Phase 2）" {
	grep -qF '.result.workspace.workspace_id' "$SCRIPTS_DIR/herdr-migrate.sh"
	grep -qF "grep -oE 'claude --resume [0-9a-f-]{36}'" "$SCRIPTS_DIR/herdr-migrate.sh"
}

@test "herdr-migrate.sh: claude でなければ herdr-open.sh にフォールバックする（PRP-027 Phase 2）" {
	grep -qF 'exec "$HERDR_OPEN" "$cwd" "$session"' "$SCRIPTS_DIR/herdr-migrate.sh"
}

@test "全スクリプトのシェバンが #!/bin/bash である" {
	for f in "${ALL_SCRIPTS[@]}"; do
		head -1 "$SCRIPTS_DIR/$f" | grep -qFx '#!/bin/bash'
	done
}

@test "全スクリプトが set -euo pipefail を持つ" {
	for f in "${ALL_SCRIPTS[@]}"; do
		grep -qFx 'set -euo pipefail' "$SCRIPTS_DIR/$f"
	done
}

@test "bash -n: 全スクリプトが /bin/bash (3.2) で構文 OK" {
	for f in "${ALL_SCRIPTS[@]}"; do
		/bin/bash -n "$SCRIPTS_DIR/$f"
	done
}

# --- herdr-picker.sh ---------------------------------------------------------

@test "herdr-picker.sh: --list-all / --list-ws / --list-dirs の内部モードが定義されている" {
	grep -qFx -- '--list-all)' "$SCRIPTS_DIR/herdr-picker.sh"
	grep -qFx -- '--list-ws)' "$SCRIPTS_DIR/herdr-picker.sh"
	grep -qFx -- '--list-dirs)' "$SCRIPTS_DIR/herdr-picker.sh"
}

@test "herdr-picker.sh: workspace focus と workspace create --cwd の両分岐が存在する" {
	grep -qE 'herdr workspace focus' "$SCRIPTS_DIR/herdr-picker.sh"
	grep -qE 'herdr workspace create --cwd' "$SCRIPTS_DIR/herdr-picker.sh"
}

@test "herdr-picker.sh: tmux セッション移植（tses ソースと ctrl-s バインド）が存在する" {
	grep -qFx -- '--list-tses)' "$SCRIPTS_DIR/herdr-picker.sh"
	grep -qE -- '--bind="ctrl-s:' "$SCRIPTS_DIR/herdr-picker.sh"
	grep -qE 'tses\)' "$SCRIPTS_DIR/herdr-picker.sh"
}

@test "herdr-picker.sh: tses ケースは同名 label 存在時に focus、無ければ create する（重複 create の穴を防ぐ、PRP-027 Phase 1）" {
	# tses) ブロックだけを抽出して focus/create の両分岐を確認する
	run awk '/^\ttses\)/{flag=1} flag{print} /^\t\t;;/{if(flag){exit}}' "$SCRIPTS_DIR/herdr-picker.sh"
	[ "$status" -eq 0 ]
	echo "$output" | grep -qE 'ws_labels "\$tses_json"'
	echo "$output" | grep -qE 'herdr workspace focus "\$tses_ws_id"'
	echo "$output" | grep -qE 'herdr workspace create --cwd "\$tses_cwd" --label "\$data" --focus'
}

@test "herdr-picker.sh: fzf バインド ctrl-a / ctrl-w / ctrl-x / ctrl-d が定義されている" {
	grep -qE -- '--bind="ctrl-a:' "$SCRIPTS_DIR/herdr-picker.sh"
	grep -qE -- '--bind="ctrl-w:' "$SCRIPTS_DIR/herdr-picker.sh"
	grep -qE -- '--bind="ctrl-x:' "$SCRIPTS_DIR/herdr-picker.sh"
	grep -qE 'ctrl-d:execute-silent' "$SCRIPTS_DIR/herdr-picker.sh"
}

@test "herdr-picker.sh: fzf-tmux を使っていない（素の fzf であること）" {
	# コメント行（fzf-tmux を使わない理由の説明）を除外し、実際の呼び出しにのみ絞って検証する
	run bash -c "grep -v '^[[:space:]]*#' '$SCRIPTS_DIR/herdr-picker.sh' | grep -F 'fzf-tmux'"
	[ "$status" -ne 0 ]
}

# --- herdr-sync.sh -----------------------------------------------------------

@test "herdr-sync.sh: dry-run オプション（-n）の分岐が存在する" {
	grep -qE 'getopts "nh"' "$SCRIPTS_DIR/herdr-sync.sh"
	grep -qE 'n\) dry_run=1' "$SCRIPTS_DIR/herdr-sync.sh"
	grep -qE 'if \[ "\$dry_run" = "1" \]' "$SCRIPTS_DIR/herdr-sync.sh"
}

@test "herdr-sync.sh: 冪等ガード（grep -Fx 照合）が存在する" {
	grep -qE 'grep -Fxq "\$base"' "$SCRIPTS_DIR/herdr-sync.sh"
}

@test "herdr-sync.sh: --no-focus で create している" {
	grep -qE 'herdr workspace create --cwd "\$dir" --label "\$base" --no-focus' "$SCRIPTS_DIR/herdr-sync.sh"
}

# --- config.toml --------------------------------------------------------------

@test "config.toml: [keys] セクションと prefix = ctrl+b が明示されている" {
	grep -qFx '[keys]' "$CONFIG_FILE"
	grep -qE '^prefix = "ctrl\+b"$' "$CONFIG_FILE"
}

@test "config.toml: [[keys.command]] に herdr-picker.sh の参照が存在する" {
	grep -qFx '[[keys.command]]' "$CONFIG_FILE"
	grep -qF 'herdr-picker.sh' "$CONFIG_FILE"
}

# --- 品質ゲート ----------------------------------------------------------------

@test "shellcheck: 全スクリプト + herdr-common.sh を通る（-x: source 解決）" {
	# shellcheck の source= 相対パスは CWD 基準のため scripts/ に移動して実行
	cd "$SCRIPTS_DIR"
	run shellcheck -x herdr-picker.sh herdr-sync.sh herdr-open.sh herdr-migrate.sh herdr-common.sh
	[ "$status" -eq 0 ]
}

@test "bash 3.2 非互換構文（declare -A / mapfile / readarray）を含まない" {
	cd "$SCRIPTS_DIR"
	run grep -REn 'declare -A|local -n|mapfile|readarray|\$\{[A-Za-z_]+(\^\^|,,)\}' "${ALL_SCRIPTS[@]}" herdr-common.sh
	[ "$status" -ne 0 ]
}
