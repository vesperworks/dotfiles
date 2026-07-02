#!/bin/bash
# tokyo-night-tmux の status-left を再適用 + 自前 status-right を再構成。
# Moshi 等の外部クライアントが接続時に `set -g status-right ""` や
# `unbind -T root WheelUp/DownStatus` でサーバ全体の設定を上書きする副作用を
# 打ち消すため、after-new-session / client-session-changed / client-attached
# の各 hook から呼び出される。

set -euo pipefail

TMUX_DIR="${HOME}/.config/tmux"

# status-left/right を tokyo-night-tmux の初期化スクリプトで再適用
"${TMUX_DIR}/plugins/tokyo-night-tmux/tokyo-night.tmux"

# status-right を完全リセット → 必要な widget だけ再構成
tmux set -g status-right ""
tmux set -ga status-right "#(${TMUX_DIR}/plugins/tokyo-night-tmux/src/path-widget.sh #{pane_current_path})"
tmux set -ga status-right "#(${TMUX_DIR}/scripts/git-status-jj.sh #{pane_current_path})"
tmux set -ga status-right "#(${TMUX_DIR}/scripts/cc-wait-count.sh)"
tmux set -ga status-right "#(${TMUX_DIR}/plugins/tmux-continuum/scripts/continuum_save.sh)"
tmux set -g status-interval 3 # tmux.conf L51 と同値を維持（WAIT/NEW カウント追従のため）

# Moshi が unbind するキーをデフォルト bind に復元
tmux bind -T root WheelUpStatus select-window -t :- 2>/dev/null || true
tmux bind -T root WheelDownStatus select-window -t :+ 2>/dev/null || true
