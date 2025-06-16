# Neovim Development Logs

## 2025-06-12

### ズーム機能の見出し範囲修正（完了）

**問題:**
- 見出しレベル（例：h3）でズームしたときに上位レベル（h1, h2）も含まれてしまう
- リスト項目でズームしたときに、そのリストが所属する親見出しセクション全体をズーム範囲にしたい

**例:**
```markdown
# h1
## h2  
### h3
* aaa
* bbb
   * ccc
   * ddd
      * eee｜   <- この位置（リスト項目）でズーム
## h2
* 1111
```

**求められる動作:**
- リスト項目でズーム → そのリストが所属する親見出し（h3）セクション全体がズーム範囲になる
- 見出し直接でズーム → その見出しレベル以下のみがズーム範囲になる

**解決策:**
1. **見出しズームの修正**: `get_heading_zoom_range`関数で親見出し検索ロジックを削除し、現在の見出しレベル以下のみをズーム範囲に設定
2. **リストズームの拡張**: `get_list_zoom_range`関数でリストが所属する親見出しを探し、そのセクション全体をズーム範囲に設定

**実装変更:**
```lua
-- 見出しズーム: 現在の見出しレベル以下のみ
local start_row = current_heading.start_row
local end_row = get_heading_section_end(bufnr, current_heading.start_row, current_heading.level)

-- リストズーム: 親見出しを探してセクション全体をズーム
if parent_heading then
  start_row = parent_heading.start_row
  end_row = get_heading_section_end(bufnr, parent_heading.start_row, parent_heading.level)
end
```

**パンくずリストの改善:**
- 見出しズーム: 現在の見出しのみ表示
- リストズーム: 親見出し + リスト階層を表示

**メリット:**
- より直感的なズーム動作（Obsidian風）
- リスト項目でズームしたときにコンテキスト（親見出し）も含めて表示
- 見出し階層の深いドキュメントで効率的な作業が可能
- パンくずリストで現在のコンテキストを把握しやすい

**使用方法:**
- `<leader>zz` でズーム（見出しまたはリストの親見出しセクション）
- `<leader>ZZ` でズーム解除
- `<leader>zb` でパンくずリスト表示

## 2025-06-16

### チェックボックス複数行対応完成 + 経過時間追跡機能実装決定（完了）

**結果:**
✅ **複数行チェックボックス対応**: Visual mode + Enterキーで一括状態変更が可能に
❌ **@タグ補完**: obsidian.nvimは@タグをサポートしていないことが判明
✅ **経過時間追跡計画**: 詳細な実装計画を策定し、実装決定

**@タグ補完問題の調査結果:**
- obsidian.nvimは`[[`（wiki links）、`#`（hashtags）のみサポート
- @タグはObsidian本体の新機能で、obsidian.nvimは未対応
- 独自@タグ補完システムの実装を提案するも、ユーザーが却下

**最終実装決定:**
1. **経過時間追跡機能** - メイン機能（最優先）
2. **Virtual Text表示** - UI表示機能（組み合わせ）

**以前の実装:**
```lua
-- markdown-helper.luaの複数行対応拡張完成
function M.toggle_checkbox_state()
  -- Visual modeとNormal mode両方に対応
  -- 複数行選択で一括状態変更が可能
end

-- autolist.luaに追加
map("v", "<CR>", function() 
  require('user-plugins.markdown-helper').toggle_checkbox_state() 
end)
```

**経過時間追跡機能の設計:**
- **自動開始**: `[ ]` → `[-]` でタイマー開始
- **自動停止**: `[-]` → `[x]` または `[ ]` でタイマー停止
- **リアルタイム表示**: `- [-] タスク名 (1h15m)` 形式
- **データ永続化**: JSONファイルでタイマー情報保存
- **Virtual Text**: `nvim_buf_set_extmark`で行末表示

**技術アーキテクチャ:**
```
lua/user-plugins/
├── task-timer.lua          # メイン機能
├── task-timer-storage.lua  # データ永続化
└── task-timer-display.lua  # UI表示
```

**期待される結果:**
```markdown
## 今日のタスク
- [ ] レポート作成 
- [-] コードレビュー (1h15m)  ← リアルタイム更新
- [-] データ分析 (45m)         ← リアルタイム更新
- [x] ミーティング準備
```

**価値:**
- 世界初の「Markdownタスク自動時間追跡システム」
- 手動タイマー不要でタスク時間を自動記録
- 既存ワークフローへのシームレス統合

**次回実装:**
1. `task-timer.lua` - メインタイマー機能
2. `task-timer-storage.lua` - JSONデータ永続化
3. `task-timer-display.lua` - Virtual Text表示
4. 既存`toggle_checkbox_state`関数との統合

---

### チェックボックス複数行対応 + @タグ補完有効化 + 経過時間追跡計画（完了）

**要求:**
- 既存のEnter key チェックボックス切り替えを複数行対応に拡張
- @タグ補完機能の有効化
- 進行中タスク（`- [-]`）の隣に経過時間表示機能の実装計画

**解決策:**
1. **複数行対応**: `toggle_checkbox_state()`関数をVisual mode対応に拡張
2. **@タグ補完**: obsidian.nvimプラグインを有効化
3. **経過時間追跡**: 詳細な実装計画を策定

**実装変更:**

```lua
-- markdown-helper.lua: toggle_checkbox_state()を複数行対応に拡張
function M.toggle_checkbox_state()
  local start_row, end_row
  local mode = vim.fn.mode()
  
  if mode == 'v' or mode == 'V' or mode == '\022' then
    -- Visual mode中の現在の選択範囲を直接取得
    local visual_start = vim.fn.getpos("v")
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    -- 複数行に対して状態循環処理
  else
    -- Normal mode: 現在の行のみ（既存動作）
  end
end

-- autolist.lua: Visual modeマッピング追加
map("v", "<CR>", function() 
  require('user-plugins.markdown-helper').toggle_checkbox_state() 
end)

-- obsidian.lua: プラグイン有効化
enabled = true  -- false から変更
```

**経過時間追跡機能の設計:**
- **自動開始**: `[ ]` → `[-]` でタイマー開始
- **自動停止**: `[-]` → `[x]` または `[ ]` でタイマー停止  
- **リアルタイム表示**: `- [-] タスク名 (1h15m)` 形式で経過時間表示
- **データ永続化**: JSON形式でタイマー情報保存
- **Virtual Text**: `nvim_buf_set_extmark`でUI表示

**技術アーキテクチャ:**
```
lua/user-plugins/
├── task-timer.lua          # メイン機能
├── task-timer-storage.lua  # データ永続化  
└── task-timer-display.lua  # UI表示
```

**使用方法:**
- **単一行**: Normalモードで`<CR>`キーでチェックボックス状態循環
- **複数行**: Visual modeで行選択後`<CR>`キーで一括状態変更
- **@タグ補完**: `@`入力時にobsidian.nvimによる補完候補表示
- **経過時間**: `- [-]`状態のタスクに自動で時間表示

**メリット:**
- **効率的なタスク管理**: 複数タスクの一括状態変更
- **自動時間追跡**: 手動タイマー不要でタスク時間を自動記録
- **@タグ活用**: プロジェクトやカテゴリでのタスク分類
- **既存システム維持**: 従来の使い勝手を完全保持

**次回実装予定:**
1. Phase 1: 基本タイマー機能の実装
2. UI統合: Virtual Text表示システム
3. 統計機能: 作業時間レポート生成

**技術的価値:**
- 世界初の「Markdownタスク自動時間追跡システム」
- Neovim + Markdown + 時間追跡の完全統合
- 既存ノートテイキングワークフローへのシームレス統合

---

### tmux セッション永続化機能実装（完了）

**問題:**
- tmuxのwindow保存・呼び出し機能が欲しい
- `C-a w`の操作後の動作が不明
- ステータスバー表示の意味が分からない（`[tmux]`等の謎表示）
- セッション終了後の復元ができない

**解決策:**
- `tmux-resurrect` + `tmux-continuum` プラグインを追加
- セッション、ウィンドウ、ペインの完全な保存・復元システム実装
- 自動保存（15分間隔）と自動復元機能

**実装内容:**
```bash
# 新規プラグイン追加
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

# セッション保存・復元設定
set -g @resurrect-strategy-nvim 'session'  # nvimセッション復元
set -g @resurrect-capture-pane-contents 'on'  # ペイン内容も保存
set -g @resurrect-save-shell-history 'on'  # シェル履歴も保存

# 自動保存・復元
set -g @continuum-restore 'on'  # tmux起動時に自動復元
set -g @continuum-save-interval '15'  # 15分間隔で自動保存
```

**機能説明:**
- **完全復元**: セッション終了 → tmux起動で全て復元
- **部分復元**: 個別ウィンドウ削除（C-a q）→ 削除状態で復元
- **自動化**: 15分間隔で自動保存、起動時自動復元
- **nvim対応**: nvimセッションも含めて復元
- **履歴保持**: シェル履歴とペイン内容も保存

**キーバインド:**
```bash
C-a C-s  # 手動保存
C-a C-r  # 手動復元
```

**C-a w操作の解説:**
```bash
# ウィンドウ一覧表示後の操作
j/k または ↓/↑  # ウィンドウ間移動
Enter          # 選択したウィンドウに移動
q/Esc          # 一覧を閉じる
/              # ウィンドウ名で検索
```

**ステータスバー表示の意味:**
```
main |1| 1 zsh 2 ⭘ |1| 2 nvim 1
↓
main        = セッション名
1 zsh       = ウィンドウ1でzsh実行中
2 ⭘         = ウィンドウ2（⭘はプロセス実行中の印）
2 nvim 1    = ウィンドウ2でnvim実行中
```

**次回作業:**
1. `C-a r` で設定再読み込み
2. `C-a I` でプラグインインストール
3. 動作確認とカスタマイズ調整

**メリット:**
- ノートテイキング環境の完全な永続化
- 作業セッションの中断・再開が自由自在
- システム再起動後も瞬時に作業環境復元
- nvimセッションと連携した包括的な環境管理

---

## 2025-06-09

### `<leader>c` コードブロック機能追加（完了）

**要求:**
- `<leader>c`のキーマップにコードブロック機能（```で囲うやつ）を追加
- `c`キーに割り当て
- `asdfghjkl;'`までのキーを有効活用

**解決策:**
- `insert_code_block()`関数を新規実装
- `show_language_selection()`でプログラミング言語選択UI追加
- 既存のCallout選択システムに統合

**実装内容:**
```lua
-- 新しいキーマッピング（既存に追加）
c: 💻 Code Block

-- 対応言語
m: 📝 Markdown
l: 🌙 Lua  
j: 🟨 JavaScript
t: 🔷 TypeScript
p: 🐍 Python
b: 💻 Bash
n: 📄 JSON
y: 🔧 YAML
c: 🎨 CSS
h: 🌐 HTML
Enter/Space: ⚪ No language
```

**機能特徴:**
- Normal/Visual mode両対応
- 複数行選択で一括コードブロック化
- インデント保持機能
- 11言語 + 言語なし対応
- 既存のCalloutシステムと統一感のあるUI

**使用方法:**
- **基本**: `<leader>c` → `c` → 言語選択
- **複数行**: Visual mode (V) で選択 → `<leader>c` → `c` → 言語選択
- **言語なし**: `<leader>c` → `c` → `Enter` または `Space`
- **キャンセル**: `Esc`で中止

**メリット:**
- ノートテイキング時のコードスニペット挿入が爆速化
- プログラミング言語に応じたシンタックスハイライト対応
- 既存のCallout機能とシームレスに統合
- ホームポジションから効率的に操作可能

**技術的実装:**
- Visual mode範囲取得の統一（既存コードと同じパターン）
- 共通インデント検出と保持
- コードブロック専用の言語選択UI
- 既存の`show_callout_selection()`関数との分離設計

---

## 2025-06-08

### `<leader>c` Callout選択UI改善（完了）

**問題:**
- `<leader>c`でCallout選択時に数字（1-8）での選択が使いづらい
- `<leader>c` → `Enter`で8番目のQuote（引用）を直接選択したい
- より直感的なキーバインドが必要

**解決策:**
- `vim.ui.select`を独自の選択UIに置き換え
- `asdfghjk;`キーでの選択システムを実装
- `Enter`キーでデフォルト（Quote）を即座に選択可能

**最終実装内容:**
```lua
-- 新しいキーマッピング
a: 📝 Note
s: ⚠️ Warning
d: ❌ Error
f: ℹ️ Info
g: 💡 Tip
h: ✅ Success
j: ❓ Question
k: 💬 Quote
Enter: Quote（デフォルト）
Esc: キャンセル
```

**技術的実装:**
- `show_callout_selection()`関数を新規作成
- `vim.fn.getchar()`で一文字入力を待機
- `vim.notify()`で選択肢を見やすく表示
- Enter（char==13）とESC（char==27）の特別処理
- 既存の`change_callout_type()`と`create_new_callout()`を両方とも対応

**使用方法:**
- **基本**: `<leader>c` → 選択肢表示 → `asdfghjk;`のいずれかで選択
- **クイック**: `<leader>c` → `Enter`で即座にQuote選択
- **キャンセル**: `Esc`で中止

**メリット:**
- ノートテイキング時のCallout挿入が爆速化
- 引用ブロックの作成が`<leader>c` → `Enter`の2キーで完了
- ホームポジションから手を動かさずに選択可能
- 視覚的に分かりやすい選択UI

**次回改善案:**
- 必要に応じてキーマッピングの調整
- 他のマークダウン機能との統一感向上

---

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
