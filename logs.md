# Neovim Development Logs

## 📅 2026年2月

### 2026-02-08 - 音声入力時のCSI uシーケンス文字化け修正

**変更内容**:
- 音声入力が改行(Ctrl+J)を送信した際、壊れたCSI uシーケンス `[27;5;106~` がテキストとして挿入される問題を修正
- autocmdで `TextChangedI`/`TextChanged` を監視し、該当文字列を自動削除

**原因**: 音声入力がCtrl+J(LF)をInput Method経路（テキスト直接挿入）で送信 → CSI uシーケンスが文字列としてバッファに混入

**試行錯誤**:
- keymap方式（`\x1b[27;5;106~` → `<CR>`）は効果なし（キーイベント経由ではなくテキスト挿入のため）
- autocmdによるテキスト変更監視+自動削除で対応

**関連ファイル**:
- `init.lua` - autocmd追加（L53-61）

---

### 2026-02-06 - 補完トリガーキー変更

**変更内容**:
- 補完トリガーキーを `;` → `<C-;>` に変更（セミコロン単体入力を可能に）

**関連ファイル**:
- `lua/plugins/cmp.lua` - mapping変更（L20）

---

### 2026-02-04 - Callout「Plan」タイプ追加

**変更内容**:
- `plan` タイプを追加（📋 Plan、lキー、青緑色 `#89dceb`）

**キー**: `<leader>c` → `l` = Plan

**関連ファイル**:
- `lua/plugins/render-markdown.lua` - calloutテーブル + ハイライト定義に plan 追加
- `lua/user-plugins/markdown-helper.lua` - callout_types に plan 追加（2箇所）
- `lua/user-plugins/markdown-fold.lua` - callout_icons に plan 追加

---

### 2026-02-04 - flash.nvim リファクタリング + cmigemo統合

**変更内容**:
- s/S/gr/gR/`<C-s>`/`<leader>s` のキーマップを削除（s/Sはvimネイティブ動作に復帰）
- modes.char を無効化、treesitter/treesitter_search/remote モードを削除
- f/t に単語境界ラベルジャンプを統合（2文字ラベル自動拡張つき）
- F/T に cmigemo対応文字検索を新規実装（ローマ字入力で日本語検索可能）
- `lua/user-plugins/migemo-bridge.lua` を新規作成（都度起動+Luaキャッシュ・フォールバック）

**キーマップ**:
| キー | 機能 |
|------|------|
| `f` | 単語境界ラベルジャンプ（マッチ位置に着地） |
| `t` | 単語境界ラベルジャンプ（1文字手前に着地） |
| `F` | cmigemo検索（マッチ位置に着地） |
| `T` | cmigemo検索（1文字手前に着地） |

**削除したキー**: `s`, `S`, `gr`, `gR`, `<C-s>`, `<leader>s`

**関連ファイル**:
- `lua/plugins/flash.lua` - キーバインド整理 + F/T migemo統合
- `lua/user-plugins/migemo-bridge.lua` - 新規作成（cmigemoプロセス管理）

**依存**: `brew install cmigemo`（未インストール時は英語のみのフォールバック）

---

### 2026-02-04 - Cmd+V CSI u変換の撤去・pペースト運用に変更

**背景**: 2/4に実装したCmd+V → CSI u変換が、Alacritty上のnvim外（bash/zsh）でCmd+Vによるシステムペーストを使えなくした

**原因**: Alacrittyのキーバインドはグローバルで、nvim起動中かどうかの条件分岐ができない。Cmd+Vを横取りしてCSI uシーケンスに変換していたため、nvim外ではペーストとして認識されなかった

**解決策**: CSI u変換を撤去し、nvim内ではpでペーストする運用に変更
- `vim.opt.clipboard:append("unnamedplus")`により、pはシステムクリップボードから貼り付ける
- nvim内: `p`でペースト（システムクリップボード）
- nvim外: `Cmd+V`でシステムペースト（Alacrittyデフォルト動作）

**削除したファイル/設定**:
- `~/.config/alacritty/alacritty.toml` - Cmd+V → CSI u変換キーバインド削除
- `init.lua` - `<C-S-v>` ペーストマッピング4行削除

---

### 2026-02-03 - heading-jump max_items拡張（50→100）

**変更内容**:
- `max_items`を50から100に変更（50では見出し数が足りないケースに対応）

**関連ファイル**:
- `lua/user-plugins/heading-jump.lua` - max_items変更（L9）

---

### 2026-02-01 - obsidian.nvim frontmatter・footer無効化

**変更内容**:
- frontmatter自動追加を無効化（`frontmatter = { enabled = false }`）
- footer表示を無効化（`footer = { enabled = false }`）

**関連ファイル**:
- `lua/plugins/obsidian.lua` - frontmatter/footer設定追加

---

## 📅 2026年1月

### 2026-01-31 - obsidian.nvim community fork補完調査（結論：;手動補完で運用）

**調査結果**:
- community forkは`[[`だけでは自動補完が発動しない（1文字以上入力が必要）
- 原因: `can_complete`関数が`search == ""`で`false`を返す仕様
- `trigger_characters`追加は逆効果だった（競合発生）
- obsidianソース自体は正常に登録されている（`vim.b.obsidian_buffer = true`）

**運用方法**:
| 操作 | 動作 |
|------|------|
| `[[test;` | ノート補完 |
| `#tag;` | タグ補完 |
| `./` | パス補完（自動） |

**関連ファイル**:
- `lua/plugins/cmp.lua` - markdown用にobsidian/obsidian_tags/obsidian_newソースを明示的に追加

---

### 2026-01-30 - obsidian.nvim community fork移行・wikilink機能強化

**変更内容**:
- `epwalsh/obsidian.nvim` → `obsidian-nvim/obsidian.nvim` (community fork)に移行
- キャッシュ有効化で補完高速化
- プレビューウィンドウで`r`キー → `:Obsidian rename`を実行
- UI/checkbox無効化（render-markdown.nvim・独自タスクステータスを使用）

**API変更対応**:
- `client:resolve_note()` → `obsidian.search.resolve_note()`（配列を返す）
- パス: `note.path` → `note.path.filename`
- コマンド: `ObsidianRename` → `Obsidian rename`
- キーマップ: mappings → callbacks.enter_note

**関連ファイル**:
- `lua/plugins/obsidian.lua` - community fork、cache、ui/checkbox無効化、callbacks設定
- `lua/plugins/cmp.lua` - markdown用ソース追加
- `lua/user-plugins/obsidian-hover-preview.lua` - API対応、rキーマップ追加

---

### 2026-01-26 - leader m 移動後のカーソル復帰

**変更内容**:
- タスク移動（`<leader>m*`）後、カーソルが元の位置の1行上に戻るように変更
- 移動方向（上/下）を考慮した行番号計算

**対象キーマップ**: mn, mw, md, ms, mm, mb, mi（全7つ）

**関連ファイル**:
- `init.lua` - move_selection_to_heading 関数にカーソル復帰処理を追加

---

### 2026-01-23 - Callout「Prompt」タイプ追加

**変更内容**:
- `prompt` タイプを追加（💬 Prompt、pキー）
- `quote` のアイコンを 💬 → 🗣️ に変更

**キー**: `<leader>c` → `p` = Prompt

**関連ファイル**:
- `lua/user-plugins/markdown-helper.lua` - callout_types に prompt 追加（2箇所）

---

### 2026-01-16 - Raycast「Edit in Neovim」機能追加

**背景**: 他のアプリで入力中のテキストをnvimで編集したい

**変更内容**:
- Raycast Script Command `edit-in-nvim.sh` を新規作成
- AeroSpaceでフローティングウィンドウとして表示

**技術的メモ**:
- `mktemp` でランダムファイル名を生成すると動作しない → 固定ファイル名 `/tmp/nvim-clipboard-edit.md` を使用
- AeroSpaceの `on-window-detected` + `window-title-regex-substring` はAlacrittyのタイトル設定タイミングの問題で動作しない
- 解決策: `( sleep 0.3; aerospace layout floating ) &` でバックグラウンド遅延実行

**使い方**:
1. テキストを選択 → `Cmd+C`
2. Raycast起動 → 「Edit in Neovim」
3. nvimで編集 → `:wq`
4. 元のアプリで `Cmd+V`

**関連ファイル**:
- `~/.config/raycast/scripts/edit-in-nvim.sh` - 新規作成

---

### 2026-01-16 - タスク移動キーバインド追加

**変更内容**:
- `<leader>mb` → `# BACKLOG` への移動を追加
- `<leader>mi` → `# WIP` への移動を追加

**ファイル**: init.lua (173-174行目)

---

### 2026-01-14 - tmux PTY経由でのIME状態同期問題の解決（完了）

**背景**: tmux内のNeovimで日本語入力後、Escで抜けるとシステムIME表示はENになるが、実際の入力は日本語のまま継続する問題が再発

**調査プロセス**:
1. im-select.lua の確認 → macism設定済み ✅
2. tmux.conf の確認 → focus-events on ✅
3. macismバージョン確認 → v3.0.10（最新）✅
4. tmux外でmacismテスト → 正常動作 ✅
5. Neovim内でmacism手動実行 → **システムIMEは変わるがNeovim内入力は変わらない** ❌

**根本原因**:
- macismはシステムIMEを正しく切り替えている（メニューバーがENになる）
- しかし**tmux PTY経由の入力コンテキストにはIME変更が反映されない**
- これはtmuxがPTY（疑似端末）を介してアプリケーションを動かす仕組みに起因
- im-select.nvimやmacismの設定では解決不可能な問題

**解決策**:
- **Karabiner-Elements**でキーボードレベルでIME切り替えを実行
- CapsLock単体押し → `japanese_eisuu` + `escape` を送信
- tmux/Neovimに依存せず、システムレベルでIMEが確実に切り替わる

**変更内容**:
```diff
# ~/.config/karabiner/karabiner.json (149-161行目)
- "to_if_alone": [{ "key_code": "escape" }],
+ "to_if_alone": [
+     { "key_code": "japanese_eisuu" },
+     { "key_code": "escape" }
+ ],
```

**副次的な変更**:
- im-select.lua: `default_command`をフルパス（`/opt/homebrew/bin/macism`）に変更

**技術的メモ**:
- tmux PTYはmacOSのIME状態変更を反映しない既知の制限
- Karabiner-Elementsでキー入力レベルで対応するのが最も確実
- 01-13の「書類ごとに入力ソース切り替え」問題とは別の原因

**関連ファイル**:
- `~/.config/karabiner/karabiner.json` - CapsLock設定修正
- `~/.config/nvim/lua/plugins/im-select.lua` - フルパス変更

---

### 2026-01-13 - IME切り替え問題の解決：tmux内でEsc後も日本語入力が継続する問題（完了）

**背景**: Insert modeで日本語入力後、Escで抜けるとシステムIMEはENに切り替わるが、次のキー入力が日本語のままになる問題が発生

**原因調査プロセス**:
1. Karabiner-Elements → 原因ではない（無効化しても再現）
2. tmux外でテスト → 問題なし（**tmuxが原因と特定**）
3. escape-time調整 → 効果なし
4. macismへ切り替え → 効果なし
5. **macOSの「書類ごとに入力ソースを自動的に切り替える」** → これが原因

**根本原因**:
- macOSの「書類ごとに入力ソースを自動的に切り替える」がオンだと、tmux内の各ペインが別の「書類」として扱われる
- im-select/macismでシステムIMEを切り替えても、tmux内の「書類」のIME状態は別管理される
- 結果：システムIME表示はENなのに、実際の入力はJPのまま

**解決策**:
- **システム設定 > キーボード > 入力ソース > 「書類ごとに入力ソースを自動的に切り替える」をオフ**

**副次的な変更**:
- im-select → macismへ切り替え（im-select.nvim公式推奨）
- `async_switch_im = false` を追加（IME切り替え完了を待つ）

**関連ファイル**:
- `lua/plugins/im-select.lua` - macismへ変更、async_switch_im追加

**技術的メモ**:
- macismはSwift製でim-selectより新しく、macOS APIとの親和性が高い
- インストール: `brew tap laishulu/homebrew && brew install macism`

---

### 2026-01-12 - noice.nvim導入：コマンドライン・通知のモダンUI化（完了）

**背景**: NeoVimの`:` コマンドバーを上部ポップアップで表示し、通知もモダンUIにしたい

**変更内容**:
- noice.nvim + 依存プラグイン（nui.nvim, nvim-notify）をインストール
- コマンドライン → 上部ポップアップ表示
- メッセージ/通知 → フローティング表示

**設定ポイント**:
- `presets` で起動時E21エラー回避
- `popupmenu.backend = "nui"` で補完連携改善
- `lsp.override` でnvim-cmpとの統合

**関連ファイル**:
- `lua/plugins/noice.lua` - 新規作成

**調査レポート**: `thoughts/shared/research/2026-01-12-nvim-ui-plugins.md`

---

### 2026-01-12 - heading-jump H6色をピンクに変更（完了）

**背景**: `<leader>h`の見出しジャンプでH6が紫になっていた

**変更内容**:
- H6の色を `#9d7cd8`（暗い紫）から `#fca7ea`（tokyonight moonピンク）に変更

**関連ファイル**:
- `lua/user-plugins/heading-jump.lua` - heading_colors配列のH6色変更（L393）

---

### 2026-01-10 - oil.nvimソート順変更：ディレクトリ優先＋更新日時降順（完了）

**背景**: oilのソート順を「ディレクトリが優先」「更新日時が新しい順」に変更したい

**変更内容**:
- `sort`設定に`type`カラムを追加（ディレクトリ優先）
- 複数条件ソート: `type` (asc) → `mtime` (desc)

**変更箇所**: `lua/plugins/oil.lua:17-23`
```lua
view_options = {
  show_hidden = true,
  sort = {
    { "type", "asc" },    -- ディレクトリ優先
    { "mtime", "desc" },  -- 更新日時の降順（上が最新）
  },
},
```

**技術的メモ**:
- `sort`は`view_options`の中に配置する必要がある（トップレベルでは効かない）

**関連ファイル**:
- `lua/plugins/oil.lua` - sort設定変更

---

### 2026-01-10 - leader x タスク解除パターン拡張（完了）

**背景**: `<leader>x`で新しいタスクステータス記号（`>`, `v`）を持つ行が解除できなかった

**変更内容**:
- チェックボックス検出パターンを `%[[ x%-/]%]` → `%[[ x%-/>v]%]` に拡張
- 6種類すべてのステータス記号で解除可能に

**対応記号**:
| シンボル | 名前 | 修正前 | 修正後 |
|----------|------|--------|--------|
| ` ` | 未着手 | ✅ | ✅ |
| `>` | 実行中 | ❌ | ✅ |
| `/` | 中断中 | ✅ | ✅ |
| `v` | 成功 | ❌ | ✅ |
| `x` | 失敗 | ✅ | ✅ |
| `-` | 中止 | ✅ | ✅ |

**関連ファイル**:
- `lua/user-plugins/markdown-helper.lua` - toggle_as_task()のパターン修正（L102, L104）

---

### 2026-01-09 - Zenモード改善：中央開始・透明度・twilight範囲調整（完了）

**背景**: Zenモード開始時にカーソルを画面中央で打ち始めたい。背景透明度が高すぎる。twilightの明るい範囲を広げたい。

**変更内容**:
- Zenモード開始時に冒頭30行の空行を挿入（終了時に自動削除）
- twilight contextを2→1に変更（現在行のみ明るい）
- twilight dimming alphaを0.25→0.5に変更（周辺文字を明るいグレーに）

**技術的メモ**:
- Neovimの`virt_lines_above`は行0で動作しない制限（Issue #16166）があるため、空行挿入で対応
- `on_close`で空行を削除し、ファイルを汚さない

**関連ファイル**:
- `lua/plugins/zen-modes.lua` - on_open/on_close、twilight設定変更

---

### 2026-01-08 - Markdown見出しzoom機能：現在セクションにフォーカス（完了）

**背景**: 現在の見出しセクションだけを表示し、他のセクションは折りたたみたい

**変更内容**:
- `<leader>zz` でzoom/unzoomトグル
- 現在のカーソル位置から親見出しを検出
- `zM`（全て閉じる）→ `zv`（現在位置だけ開く）のシンプル実装

**キーマップ**:
| キー | 機能 |
|------|------|
| `<leader>zz` | Zoom/Unzoom トグル（Markdownのみ） |

**動作**:
- zoom: 全見出しを閉じ、現在の見出しセクションのみ表示
- unzoom: `zR`で全て開く

**技術的メモ**:
- `vim.wo.foldlevel = 0`では閉じないケースあり、`normal! zM`を使用
- `zO`（再帰的に開く）ではなく`zv`（最小限開く）を使用

**関連ファイル**:
- `lua/user-plugins/markdown-zoom.lua` - 新規作成
- `init.lua` - セットアップ追加（L77-80）

---

### 2026-01-08 - Extract to Note：選択範囲を新規ノートに抽出（完了）

**背景**: Visual modeで選択した範囲を新規ノートとして抽出し、元の箇所にはwikilinkを残したい

**変更内容**:
- `<leader>a` (Visual mode) で選択範囲を新規ノートに抽出
- 1行目からタイトルを抽出（`#+ ` を除去）
- タイトルがファイル名になる
- 保存先はMainVaultルート

**動作**:
1. Visual modeで範囲選択
2. `<leader>a` を押す
3. 新規ファイル作成: `{タイトル}.md`
4. 元ファイルの選択範囲 → `[[タイトル]]` に置換

**新規ファイルの構造**:
```markdown
# タイトル

（2行目以降の本文）

[[YYYY-MM-DD]]
```

**関連ファイル**:
- `lua/user-plugins/markdown-helper.lua` - `extract_to_note()` 関数追加（L897-986）、キーマップ追加（L874-876）

---

### 2026-01-08 - タスクステータス拡張：Obsidianタスク連携対応（完了）

**背景**: Obsidianタスクと連動するため、`- [ ]`のステータスを6種類に拡張したい

**変更内容**:
- トグル順序を6ステータスに拡張
- 各ステータスに色・スタイルを適用（extmark使用）
- タイマー連携のシンボルを`[-]`から`[>]`に変更

**ステータス一覧**:
| シンボル | 名前 | タイプ | 色 | 効果 |
|----------|------|--------|-----|------|
| ` ` | 未着手 | TODO | グレー | - |
| `>` | 実行中 | IN_PROGRESS | 青 | 太字 |
| `/` | 中断中 | IN_PROGRESS | 黄 | イタリック |
| `v` | 成功 | DONE | 薄緑灰 | 打ち消し線 |
| `x` | 失敗 | DONE | 薄赤灰 | 打ち消し線 |
| `-` | 中止 | CANCELLED | 薄灰 | 打ち消し線 |

**トグル順序**:
```
[ ] → [>] → [/] → [v] → [x] → [-] → [ ]
```

**技術的メモ**:
- `matchadd`では`strikethrough`が効かないため、`extmark`で実装
- `BufEnter`, `TextChanged`, `TextChangedI`, `InsertLeave`イベントでリアルタイム更新
- ハイライトグループ名を`TaskStatus*`に統一（Callout用の`RenderMarkdown*`と分離）

**関連ファイル**:
- `lua/plugins/render-markdown.lua` - ハイライト定義・extmark適用
- `lua/user-plugins/markdown-helper.lua` - トグル順序変更（L188-206）
- `lua/user-plugins/pending-tasks.lua` - パターン変更（`[-]`→`[>]`）
- `lua/user-plugins/task-timer.lua` - 実行中検出パターン変更
- `lua/user-plugins/task-timer-display.lua` - 表示パターン変更

---

### 2026-01-08 - leader m 拡張：複数セクションへの移動対応（完了）

**背景**: `<leader>m`を拡張して、複数のセクション見出しへの移動に対応したい

**変更内容**:
- `move_selection_to_heading(pattern)` 汎用関数を作成
- 5つのキーマップを追加

**キーマップ**:
| キー | 移動先 |
|------|--------|
| `<leader>mn` | `# NEXT` のすぐ下 |
| `<leader>mw` | `## WANTS` のすぐ下 |
| `<leader>md` | `# DONE` セクションの一番下 |
| `<leader>ms` | `## SHOULD` のすぐ下 |
| `<leader>mm` | `## MUST` のすぐ下 |

**技術的メモ**:
- DRY原則に従い、パターンと`to_bottom`フラグを引数として受け取る汎用関数を作成
- `to_bottom=true`の場合、次の見出しの直前またはファイル末尾に移動
- 既存の`<leader>m`は`<leader>mn`に移行

**関連ファイル**:
- `init.lua` - 汎用関数とキーマップ追加（L128-174）

---

### 2026-01-08 - cheatsheet.nvim + which-key.nvim導入（完了）

**背景**: nvimの元々のコマンド（dd, yy, ciw等）とカスタムキーマップをサッと確認したい

**導入プラグイン**:
- `cheatsheet.nvim` - Vim標準コマンドのチートシート表示（Telescope連携）
- `which-key.nvim` - キー入力中に候補をポップアップ表示

**キーマップ**:
| キー | 機能 |
|------|------|
| `<leader>?` | チートシート検索（Vim標準コマンド、Nerd Fonts、Regex等） |
| `<leader>k` | カスタムキーマップ検索（既存Telescope） |
| `<leader>` + 300ms待機 | 次のキー候補をポップアップ表示 |

**関連ファイル**:
- `lua/plugins/cheatsheet.lua` - 新規作成
- `lua/plugins/which-key.lua` - 新規作成

---

### 2026-01-08 - Callout foldlevelをH6以下に修正（完了）

**背景**: calloutの折りたたみが見出しと同列（兄弟関係）になっていたため、`zc`でcalloutだけを閉じられなかった

**変更内容**:
- callout終了時に親見出しレベルに戻す処理を削除
- calloutは常にfoldlevel 7（H6より深い階層）として扱う

**動作**:
- `zc` → callout上でcallout（foldlevel 7）のみ閉じる
- 再度`zc` → 親見出し（foldlevel 1-6）が閉じる
- calloutと見出しが独立した階層として操作可能

**技術的メモ**:
- callout終了時に`<7`を返すことでfold終端を確実に制御
- 親レベルへの復帰は`=`による自動継承に任せる

**関連ファイル**:
- `lua/user-plugins/markdown-fold.lua` - foldexpr修正（L92-98）

---

## 📅 2025年12月（圧縮版）

### Wikilink Surround（12-30）
**背景**: Visual modeで選択範囲を`[[wikilink]]`形式で囲みたい
**解決**: `<leader>[` でVisual mode選択範囲を `[[]]` で囲む
**技術的メモ**: Vimネイティブのキーシーケンス `c[[<C-r>"]]<Esc>` を使用

### Obsidianリンクホバープレビュー（12-29）
**背景**: `[[wikilink]]`上にカーソルを500ms置くとプレビュー表示したい
**解決**: フローティングウィンドウでプレビュー、ZZ/ZQ/q/Escで閉じる、gfで本編集
**ファイル**: `lua/user-plugins/obsidian-hover-preview.lua`

### leader m 移動先変更（12-29）
**解決**: `# NEXT` の1行上に移動、移動した行の前に空白行を1行追加
**技術的メモ**: `vim.fn.line("v")` と `vim.fn.line(".")` で現在の選択を取得

### Callout拡張：AI追加・Quote整理（12-29）
**変更**: `ai`(🤖)追加、`quote`→Callout形式、`blockquote`新規追加
**キー**: `a`=ai, `q`=quote, `b`=blockquote, `n`=note

### leader c クオート解除修正（12-27）
**原因**: `^%s*>%s*%[!`パターンが通常クオート行を検出しなかった
**解決**: 検出パターンを`^%s*>`に変更

### Zen Mode透明度切り替え（12-27）
**解決**: on_open: opacity 0.05、on_close: opacity 0.8
**技術的メモ**: Alacrittyはファイル変更を自動検出して即座に反映

### 補完トリガーキー変更（12-27）
**変更**: `<C-Space>` → `;` で補完メニュー表示

### pending-tasks プレビューハイライト（12-26）
**解決**: j/k移動時に本文側の選択行に背景色（#292e42）をextmarkで追加

### Zen Writing Mode（12-26）
**解決**: `<leader>Z`で新規ファイル作成 → Zen Mode + Typewriter自動起動
**ファイル名**: `$OBSIDIAN_VAULT_PATH/Inbox/zen{YYYYMMDD-HHmm}.md`

### gitsigns設定簡素化（12-26）
**変更**: `word_diff`と`show_deleted`を削除、`current_line_blame`のみ維持

### Zen Mode統合（12-26）
**解決**: `<leader>z`でZen Mode + Typewriter同時トグル
**キー**: `<leader>z`=統合、`<leader>zm`=Zen単体、`<leader>zt`=Typewriter単体

### oil.nvim + oil-git-status.nvim導入（12-24）
**キー**: `<leader>e`=Explorer、`-`=親ディレクトリ、`g.`=隠しファイル切替

### gitsigns + diffview導入（12-24）
**キー**: `<leader>do/dc/dh`=Diffview操作、`<leader>dp/ds/dr/db`=hunk操作、`]d/[d`=hunk移動

### Emacs風キーバインド（12-18）
**変更**: `<C-a>`=行頭、`<C-e>`=行末、`<C-k>`=kill-line、`<C-Space>`=補完

### tmuxウィンドウアイコン（12-17）
**解決**: `tmux-nerd-font-window-name`プラグイン追加（依存: yq v4以上）

### pending-tasks ソート順変更（12-16）
**変更**: タイマーなしを除外、経過時間が短い順にソート

### heading-jump max_items拡張（12-16）
**変更**: `max_items`を20から50に変更

### smear-cursor.nvim導入（12-14）
**解決**: Neovide風のスミアカーソルエフェクトをAlacritty環境で実現
**要件**: Neovim 0.10.2以上、Cascadia Code等のlegacy computing symbols対応フォント

### 見出しジャンプ親見出しデフォルト選択（12-14）
**解決**: カーソル行が所属する親見出しをデフォルト位置として自動選択

### 見出しジャンプ機能（12-12）
**解決**: `<leader>h`で見出しリスト表示、j/kプレビュー、i=fuzzy検索、1-9=番号ジャンプ
**技術的メモ**: `nvim_buf_set_extmark` + `line_hl_group`で反転カラーハイライト

### leader t/j キーバインド入れ替え（12-12）
**変更**: `<leader>t`=タイマージャンプ、`<leader>j`=進行中タスク表示

### pending-tasks j/k本文プレビュー（12-11）
**解決**: j/k移動で本文側も該当行に移動＆中央表示

### Flash.nvim 2文字ジャンプラベル改善（12-11）
**解決**: 「次に押すべきキー」をピンク背景+白文字で強調、状態によって色を反転

### 進行中タスク見出し色分け（12-11）
**解決**: 見出し部分=`@markup.heading.N`色、タスク部分=オレンジ色

---

## 📅 2025年11月（圧縮版）

### Esc検索ハイライトクリア（11-19）
**解決**: `<Esc>`キーで`:nohlsearch`を実行

### Markdown callout fold機能（11-07〜11-11）
**背景**: `> [!type]`形式のObsidian calloutをzcで折りたたみたい
**解決**: calloutをfoldlevel 7（見出しより深い階層）に配置、`after/ftplugin`で自動適用
**技術的メモ**:
- foldexprで`>7`（開始）、`7`（継続）、`<7`（終了）を返す
- `get_parent_heading_level()`で親見出しレベルを取得
- Neovimの`virt_lines_above`は行0で動作しない制限あり（Issue #16166）

### VSCode Neovim分岐と専用設定（11-10）
**解決**: `vim.g.vscode`判定でVSCode環境では`lua/vscode-config.lua`を読み込む
**技術的メモ**: VSCode APIを`require('vscode').action()`経由で呼び出す

### Markdown helperリーダーキー常時有効化（11-10）
**解決**: `init.lua`冒頭でMarkdown helper読み込み、VSCode/Cursorでも同じショートカット利用可能

### gp.nvimプロンプト実装（11-04〜11-06）
**機能**: ノート整理、シンプル化、タスク分解、ツリー化、ToDo抽出
**キー**: `<leader>l` → `a/s/d/f/e`
**技術的メモ**: `rewrite`から`append`に変更、非同期処理で並行実行可能

---

## 📅 2025年10月以前（圧縮版）

### gp.nvim導入（10-28）
**解決**: Visual modeで選択したテキストにGPTプロンプトを適用
**技術的メモ**: `{{selection}}`変数、環境変数`OPENAI_API_KEY`

### tmux-continuum自動保存修復（09-24）
**解決**: `tmux run-shell continuum.tmux`で再起動
**保存場所**: `~/.local/share/tmux/resurrect/`

### VW CCC実装（08-18）
**使用方法**: `vw ccc "ghでpr作るコマンド考えて"`

### Think & Idea Callout追加（07-14）
**キー**: `<leader>c` → `t`=Think、`i`=Idea

### E94エラー完全解決（07-14）
**解決**: swapファイルチェック処理を完全削除、iCloudパス対応

### smart-open.nvim（07-01）
**キー**: `<leader>o`でスマートファイルオープン

---

## 📚 技術的レガシー・パターン集

### 🎨 UI実装パターン
- **Insert modeベースの選択UI**: LSP風の文字入力受付システム（leader-c, leader-j, leader-l）
- **フローティングウィンドウ**: 角丸ボーダー + タイトル + プロンプトの統一デザイン
- **非同期処理**: `vim.schedule()`でNeovimの内部制限を回避

### 🔧 エラーハンドリングパターン
- **バッファ有効性チェック**: `vim.api.nvim_buf_is_valid()`と`pcall()`の組み合わせ
- **段階的デバッグ**: debug_log無効化 → 必要最小限ログ → 原因特定の効率的プロセス
- **安全なファイル操作**: swapファイル事前検出、既存バッファ優先処理

### 📁 ファイルシステム対応
- **iCloudパス対応**: Mobile Documents配下の特殊パス構造への完全対応
- **パス正規化**: `vim.fn.expand()`でチルダ展開とパス正規化
- **直接ファイル読み込み**: `io.open()`でNeovimバッファシステムを回避

### 🔄 Fold実装パターン
- **foldlevel階層制御**: `>n`（開始）、`n`（継続）、`<n`（終了）
- **親見出し検索**: 上方向への見出し検索アルゴリズム
- **after/ftplugin**: 標準設定を上書きする確実な方法

### 🖥️ macOS/tmux連携
- **IME切り替え**: Karabiner-Elementsでキーボードレベル対応が最も確実
- **tmux PTY制限**: macOSのIME状態変更はtmux内に反映されない
- **AeroSpace**: `on-window-detected`はウィンドウタイトル設定タイミングに依存

---

## 📋 主要キーマップ一覧

### タスク管理
- `<leader>c` → Callout/コードブロック作成（think, idea, ai含む）
- `<leader>x` → タスク化トグル（複数行対応）
- `<CR>` → タスク状態循環（タイマー連携）
- `<leader>j` → 進行中タスク表示（pending-tasks）

### ナビゲーション
- `<leader>h` → 見出しジャンプ（fuzzy検索対応）
- `<leader>o` → スマートファイルオープン
- `<leader>e` → Explorer（oil.nvim）
- `<leader>m*` → セクション移動（n/w/d/s/m/b/i）

### タイマー機能
- `<leader>t` → 稼働中タイマーにジャンプ
- `<leader>T*` → タイマー操作（a/s/i/q/c/D）

### Zen/集中モード
- `<leader>z` → Zen + Typewriter トグル
- `<leader>Z` → Zen Writing Mode（新規ファイル作成）
- `<leader>zz` → Markdown見出しzoom

### LLMプロンプト
- `<leader>l` → LLMプロンプトメニュー（a/s/d/f/e）

### Git操作
- `<leader>d*` → Diffview/hunk操作（o/c/h/p/s/r/b）
- `]d/[d` → 次/前の変更箇所

### その他
- `<leader>?` → チートシート検索
- `<leader>k` → カスタムキーマップ検索
- `<leader>[` → Wikilink Surround
- `<leader>a` → Extract to Note
