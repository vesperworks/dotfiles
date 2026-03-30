#!/bin/bash
# resurrect-save-guard.sh — @resurrect-hook-post-save-all から呼ばれる
# セッション数が大幅に減少した save で last が上書きされた場合、known-good に戻す
# 背景: macOS 再起動後に continuum-save が空に近い状態で last を上書きする問題の防止
set -euo pipefail

RESURRECT_DIR="$HOME/.local/share/tmux/resurrect"
LAST_FILE="$RESURRECT_DIR/last"
KNOWN_GOOD="$RESURRECT_DIR/known-good"
MIN_SESSIONS=3

# last シンボリックリンクが存在しなければ何もしない
[[ -L "$LAST_FILE" ]] || exit 0

# last が指すファイルのユニークセッション数を取得
last_target="$RESURRECT_DIR/$(readlink "$LAST_FILE")"
[[ -f "$last_target" ]] || exit 0
current_count=$(awk -F'\t' '$1=="pane"{print $2}' "$last_target" | sort -u | wc -l | tr -d ' ')

if [[ "$current_count" -ge "$MIN_SESSIONS" ]]; then
  # 正常なセッション数 → known-good を更新
  ln -fs "$(readlink "$LAST_FILE")" "$KNOWN_GOOD"
else
  # セッション数が少なすぎ → known-good があれば last を戻す
  if [[ -L "$KNOWN_GOOD" ]]; then
    known_good_basename="$(readlink "$KNOWN_GOOD")"
    known_good_target="$RESURRECT_DIR/$known_good_basename"
    if [[ -f "$known_good_target" ]]; then
      ln -fs "$known_good_basename" "$LAST_FILE"
      tmux display-message "resurrect: session count ($current_count) too low, reverted last → known-good"
    fi
  fi
fi
