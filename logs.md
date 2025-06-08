# Neovim Development Logs

## 2025-06-08

### `<leader>-` markdownリスト補完の複数行対応実装（完了）

**問題:**
- `<leader>-`でのmarkdownリスト補完が単一行のみの対応だった
- Visual modeで複数行を選択してリストマーカーを一括適用したい要望
- 初回のVisual mode選択時に範囲が正しく取得できない問題

**解決策:**
- `lua/user-plugins/markdown-helper.lua`の`insert_list_item()`関数を複数行対応に拡張
- Visual mode中の現在の選択範囲を直接取得する方法に変更
```lua
-- Visual mode中の現在の選択範囲を直接取得
local visual_start = vim.fn.getpos("v")  -- Visual mode開始位置
local cursor_pos = vim.api.nvim_win_get_cursor(0)  -- 現在のカーソル位置

start_row = visual_start[2]  -- 開始行
end_row = cursor_pos[1]      -- 終了行

-- 選択方向によって開始と終了を整理
if start_row > end_row then
  start_row, end_row = end_row, start_row
end
```

**最終実装内容:**
- Normal mode/Visual mode両対応のキーマッピング
- Visual mode中の正確な範囲取得
- 選択方向（上→下、下→上）の自動判定
- インデント保持機能
- 適切なカーソル位置調整

**使用方法:**
- **単一行**: `<leader>-`で現在行にリストマーカーを追加/削除
- **複数行**: Visual mode (V) で複数行選択 → `<leader>-`で選択した全行に一括適用
- **トグル動作**: リストマーカーがあれば削除、なければ追加

**メリット:**
- ノートテイキング時の効率が大幅向上
- 大量のテキストを一括でリスト化可能
- 既存の単一行機能は完全に保持
- `<leader>*`も同時に複数行対応済み
- 初回Visual mode選択から確実に動作

**技術的解決:**
- `vim.fn.getpos("'<")`と`vim.fn.getpos("'>")`の代わりに`vim.fn.getpos("v")`を使用
- Visual mode中のリアルタイム選択範囲取得を実現
- デバッグ機能を活用した段階的な問題解決

---

## 2025-06-06

### tmux-thumbs システムクリップボード連携修正

**問題:**
- tmux-thumbsでコピーした内容がシステムクリップボード（pbcopy）に反映されない
- tmuxの内部バッファには保存されるが、macOSのクリップボードに連携されていない

**解決策:**
```bash
# システムクリップボードへの直接コピー
set -g @thumbs-command 'echo -n {} | pbcopy'

# 大文字ヒント時はシステムクリップボード＋ペースト
set -g @thumbs-upcase-command 'echo -n {} | pbcopy && tmux set-buffer -- {} && tmux paste-buffer'

# OSC52プロトコルでの統合も有効化
set -g @thumbs-osc52 1
```

**修正後の動作:**
- 小文字のヒント (例: `a`, `b`) → システムクリップボードにコピー
- 大文字のヒント (例: `A`, `B`) → システムクリップボード＋tmuxバッファにコピー＋その場でペースト
- `pbpaste`でシステムクリップボードの内容確認可能
- nvimやその他のアプリとのクリップボード共有が正常動作

**確認方法:**
```bash
# 設定再読み込み
Ctrl+a → r

# thumbsでコピー後
pbpaste  # システムクリップボードの内容確認
```

### tmux-thumbs プラグイン導入

**実装内容:**
- `fcsonline/tmux-thumbs` プラグインをTPM経由で追加
- vimium/vimperatorライクなテキスト選択機能を実装
- Rustベースの高速な実装でパフォーマンス向上

**設定詳細:**
```bash
# トリガーキー
set -g @thumbs-key f  # Ctrl+a → f で起動

# 便利な設定
set -g @thumbs-reverse enabled      # 右から左へヒント配置
set -g @thumbs-unique enabled       # 同じテキストには同じヒント
set -g @thumbs-upcase-command 'tmux set-buffer -- {} && tmux paste-buffer'  # 大文字でコピー＋ペースト

# パフォーマンス向上
set -g visual-activity off
set -g visual-bell off
set -g visual-silence on

# 追加の正規表現パターン
set -g @thumbs-regexp-1 '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'  # Email
set -g @thumbs-regexp-2 'https?://[^\s]+'  # URL
set -g @thumbs-regexp-3 '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'  # IP Address
```

**使用方法:**
- `Ctrl+a` → `f` でthumbsモード起動
- 画面上のテキスト（URL、ファイルパス、ハッシュなど）にヒント文字が表示
- 小文字のヒント → コピーのみ
- 大文字のヒント → コピー＋ペースト
- `Space`で複数選択モード
- 矢印キーでナビゲーション

**メリット:**
- ノートテイキング時のURL/ファイルパスコピーが爆速化
- マウスを使わずにキーボードのみで効率的な操作
- 既存のキーバインドとの競合なし
- 高速なRust実装で遅延なし

**次回作業:**
1. tmuxセッション再起動後、`Ctrl+a` → `I` でプラグインインストール
2. 動作確認とカスタマイズ調整

---

## 2025-06-05

### tmux プロンプト表示問題の修正

**問題:**
- tmux内でzshプロンプトが改行されて表示される問題
- lualineが完全に消える問題

**原因:**
- `.zshrc`の`tmux_auto_start()`関数で`exit 0`を使用していたため、zshの初期化プロセスが途中で終了
- これによりnvimの設定（lualine含む）が正しく読み込まれていなかった

**解決策:**
```bash
tmux_auto_start() {
    local session_name="main"
    
    # tmux内では何もしない
    [ -n "$TMUX" ] && return
    
    # tmuxコマンドが存在しない場合は何もしない
    command -v tmux &> /dev/null || return
    
    # エラー時はシェルを継続
    set +e
    
    if tmux has-session -t "$session_name" 2>/dev/null; then
        echo "Attaching to existing tmux session: $session_name"
        exec tmux attach-session -t "$session_name"
    else
        echo "Creating new tmux session: $session_name"
        exec tmux new-session -s "$session_name"
    fi
    
    set -e
}
```

**変更点:**
- `exit 0`を`exec`に変更
- tmux内での重複実行を防ぐチェックを追加
- より安全なエラーハンドリング

**結果:**
- プロンプト表示が正常化
- lualineが正しく表示されるように修復

### Telescope live_grep キーバインド追加

**実装内容:**
- `<leader>g` で Telescope の live_grep を起動できるように設定
- `lua/plugins/telescope.lua` にキーマッピングを追加

**変更詳細:**
```lua
vim.keymap.set('n', '<leader>g', builtin.live_grep, { desc = "テキスト検索 (Leader+G)" })
```

**機能:**
- プロジェクト内のテキストをリアルタイム検索
- ノートテイキング時の検索効率が向上
- 既存のキーマッピングと統一感のある設定

**結果:**
- 動作確認済み
- ノートテイキング環境の改善完了

---
