# Neovim Development Logs

## 📅 2025年12月（現在の月）

### 2025-12-14 - smear-cursor.nvim導入（完了）

**背景**: Neovide風のスミアカーソルエフェクトをAlacritty環境でも使いたい
**解決**: `smear-cursor.nvim`プラグインを導入。lazy.nvimで簡単インストール

**使用方法**:
- nvim再起動で自動有効化
- `:SmearCursorToggle` → 一時的にON/OFF切り替え

**技術的レガシー**:
- Neovim 0.10.2以上が必要（現環境: 0.11.1）
- ターミナル制限なし（Alacritty 0.15.1で動作確認）
- Cascadia Code等のlegacy computing symbols対応フォントで最適表示

**関連ファイル**:
- `lua/plugins/smear-cursor.lua` - 新規作成

**調査レポート**: `thoughts/shared/research/2025-12-14-nvim-alacritty-animation.md`

---

### 2025-12-14 - 見出しジャンプ：親見出しをデフォルト選択（完了）

**背景**: `<leader>h`でheading-jumpを開いた時、常に最初の見出しが選択されており、現在編集中のセクションに素早くアクセスできなかった
**解決**: カーソル行が所属する親見出しをデフォルト位置として自動選択するよう改善

**動作仕様**:
- `<leader>h` → 現在のカーソル位置から上に向かって最初の見出しを探し、その見出しをデフォルト選択
- カーソルが最初の見出しより上にある場合 → 最初の見出し（index=1）を選択
- カーソルが見出し上にある場合 → その見出し自体を選択

**技術的レガシー**:
- `find_parent_heading_index(current_lnum)`関数で親見出しのインデックスを計算
- `render_window()`でウィンドウ作成前にカーソル位置を保存し、作成後にデフォルト選択＋プレビュー同期

**関連ファイル**:
- `lua/user-plugins/heading-jump.lua` - 機能追加

---

### 2025-12-12 - 見出しジャンプ機能追加（完了）

**背景**: `<leader>H`でMarkdown見出し（H1〜H6）をリストアップし、j/kでプレビューしながら移動、Enterで確定する機能が欲しい
**解決**: `heading-jump.lua`を新規実装。`pending-tasks.lua`と同じUIパターンで統一感を維持

**動作仕様**:
- `<leader>h` → 見出しリストをフローティングウィンドウに表示（Normal mode）
- `j/k` → カーソル移動 + 本文側を該当行に移動＆中央表示 + **反転カラーでハイライト**
- `i` → fuzzy検索モードに入る（Insert mode）
  - **文字入力** → fuzzyマッチで該当見出しを選択＋プレビュー
  - `BS` → 入力文字を1文字削除して再検索
  - `Enter` → 確定ジャンプ、`Esc` → Normal modeに戻る
- `Enter` → 確定してジャンプ＆ウィンドウ閉じ
- `1-9` → 番号で直接ジャンプ
- `q`/`Esc` → ウィンドウを閉じる
- 見出しレベルに応じた色分け（tokyonight準拠）
- インデントでレベル階層を視覚化
- **プレビュー時は見出し色の反転カラー（背景色=見出し色、文字色=暗い）で強調**

**技術的レガシー**:
- `pending-tasks.lua`と同一のUIパターンで学習コストゼロ
- `vim.api.nvim_buf_add_highlight`で見出しレベル別のハイライト適用
- `preview_heading()`でソースバッファと連動したリアルタイムプレビュー
- `nvim_buf_set_extmark` + `line_hl_group`で行全体を反転カラーハイライト
- `nvim_create_namespace`でextmark管理、ウィンドウ終了時に自動クリア
- `InsertCharPre` + `vim.fn.matchfuzzy`でリアルタイムfuzzy検索
- Insert mode入力で文字をキャッチし、画面に表示せず検索に使用

**関連ファイル**:
- `lua/user-plugins/heading-jump.lua` - 新規作成
- `init.lua` - プラグイン読み込み追加

---

### 2025-12-12 - leader t / leader j キーバインド入れ替え（完了）

**背景**: ユーザーの使用頻度に合わせたキーバインド調整
**解決**: 2つのキーバインドを入れ替え
- `<leader>t` → 稼働中タイマーにジャンプ（旧: `<leader>j`）
- `<leader>j` → 進行中タスク表示（旧: `<leader>t`）

**関連ファイル**:
- `init.lua` - タイマージャンプのキーマップ
- `lua/user-plugins/pending-tasks.lua` - 進行中タスク表示のキーマップ

---

### 2025-12-11 - pending-tasks: j/k移動時の本文プレビュー機能（完了）

**背景**: `<leader>t`で開くタスクリストウィンドウでj/k移動時、本文側も連動してほしい
**解決**: `M.preview_task()`関数を追加し、j/kキーマップでカーソル移動と同時に本文側を該当行に移動＆中央表示

**動作仕様**:
- `j` で下に移動 → 本文側も該当タスクの行に移動＆中央表示
- `k` で上に移動 → 本文側も該当タスクの行に移動＆中央表示
- ウィンドウは開いたまま（従来の`<CR>`でジャンプ＆閉じる動作も維持）

**関連ファイル**:
- `lua/user-plugins/pending-tasks.lua` - preview_task関数、j/kキーマップ追加

---

### 2025-12-11 - Flash.nvim 2文字ジャンプラベルのコントラスト反転（完了）

**背景**: `<leader>s`の2文字ジャンプで、1文字目と2文字目が同じ色で区別がつきにくかった
**解決**: 「次に押すべきキー」をピンク背景+白文字で強調し、状態によって色を反転させる

**動作仕様**:
| 状態 | 1文字目 | 2文字目 |
|------|---------|---------|
| 1文字目選択時 | ピンク背景+白文字 | 白背景+ピンク文字 |
| 2文字目選択時 | 白背景+ピンク文字 | ピンク背景+白文字 |

**使用方法**: `<leader>s` → 単語開始位置に2文字ラベル表示、常に次に押すキーがピンク背景で強調

**技術的レガシー**:
- `FlashLabelActive`（ピンク背景#ff007c + 白文字）と`FlashLabelInactive`（白背景 + ピンク文字）の2グループ
- `formatFirst`と`formatSecond`の2つのformat関数で1段階目/2段階目を切り替え
- Flash.nvimの2段階ジャンプ（action内の2回目のFlash.jump）で異なるformat関数を適用

**関連ファイル**:
- `lua/plugins/flash.lua` - formatFirst/formatSecond関数とハイライト定義

---

### 2025-12-11 - 進行中タスク表示プラグイン改善：見出し部分の色分け（完了）

**背景**: 見出し部分（`## 見出し >`）とタスク部分で色を分けて、見出しレベルを視覚的に識別したい
**解決**:
- `nvim_buf_add_highlight`の範囲指定機能で、1行を2つのハイライトに分割
- 見出し部分: Treesitterの`@markup.heading.N`色（Nは見出しレベル）
- タスク部分: `TaskInProgress`色（オレンジ）

**使用方法**:
- `<leader>t` → 進行中タスクのフローティングウィンドウをトグル
- ウィンドウ内で `1-9` キー → 該当タスクへ直接ジャンプ
- `j/k` → カーソル移動、`Enter` → カーソル行のタスクへジャンプ
- `q` or `Esc` → ウィンドウを閉じる

**表示形式**:
```
 1. (15m) ## 買い物 > リスト作成  (L:42)
          ^^^^^^^^^^^ ^^^^^^^^^^^^^^^^^^^
          H2色        オレンジ色
```

**技術的レガシー**:
- `nvim_buf_add_highlight(buf, ns_id, hl_group, line, col_start, col_end)`: 範囲指定ハイライト
- `@markup.heading.1`〜`@markup.heading.6`: Treesitterの見出しハイライトグループ
- `highlight_info`テーブルで各行の見出し開始/終了位置を記録
- 見出しがない場合は全体を`TaskInProgress`色で適用

**関連ファイル**:
- `lua/user-plugins/pending-tasks.lua` - メイン実装
- `thoughts/shared/research/2025-12-11-pending-tasks-floating-window.md` - 調査結果

---

## 📅 2025年11月

### 2025-11-19 - Esc検索ハイライトクリア機能追加（完了）

**背景**: 検索後のハイライトを素早く消したい
**解決**: `init.lua`に`<Esc>`キーで`:nohlsearch`を実行する設定を追加
**使用方法**: Normal modeで`<Esc>`を押すと検索ハイライトがクリアされる

**技術的レガシー**:
- `<cmd>nohlsearch<CR>`による検索ハイライト解除
- Vimの標準機能を活用したシンプルな実装

### 2025-11-11 - Markdown callout fold機能更新：専用foldlevel 7を復活（完了）

**背景**: calloutを親見出しと同じfoldlevelにしていたため、`zc`を2回押してもH6→H1のような段階的なクローズ挙動にならず、callout単体の開閉感が薄れていた。
**解決**: `markdown-fold.lua`に`CALLOUT_LEVEL = 7`を導入し、callout開始行は常に`">7"`でfoldを開くよう変更。callout本体は`7`を維持しつつ、末尾では`<parent_level`を返し、さらに直後の行で親レベルに戻す分岐を追加してfoldリークを防止。
**使用方法**:
- callout行で`zc` → callout（foldlevel 7）のみ閉じる
- 同じ位置で再度`zc` → 親見出し（foldlevel 1-6）が閉じる
- 見出しのないcalloutでも常にfoldlevel 7として扱われる

**技術的レガシー**:
- fold階層を定数で固定する`CALLOUT_LEVEL`パターン
- `get_parent_heading_level()`を用いてcallout終端と直後の行で親レベルへ戻し、`=`によるレベル継承を断ち切る実装
- `<parent_level`と直後の明示レベル指定でfold終端を確実に制御するテクニック

### 2025-11-10 - Markdown helperリーダーキー常時有効化 & Alt移動キー送出テンプレ追加（完了）

**背景**: Cursor/VSCode起動時は`vim.g.vscode`で`init.lua`が早期returnするため、Markdown helperの`<leader>`系マップが読み込まれていなかった。またAlt+hjklでmini.moveを動かす際、VSCodeがキーイベントを受け取らずNeovimに到達していなかった。
**解決**: `init.lua`の冒頭で`require('user-plugins.markdown-helper').setup_keymaps()`を実行してからVSCode判定するよう変更し、通常/VSCode双方で同じMarkdownショートカットを利用可能にした。併せて`vscode-alt-move-keybindings.json`を追加し、`"command": "vscode-neovim.send"`経由で`Alt+hjkl`をNeovimへ送信するキーバインド例を共有。
**使用方法**:
- VSCode/Cursorの`keybindings.json`に`vscode-alt-move-keybindings.json`の内容を追記すると、`Alt+hjkl`がmini.moveへ届く
- Markdownファイルで`<leader>1-6`, `<leader>*`, `<leader>-`, `<leader>x`, `<leader>c`などがVSCode上でも即時利用可能
**技術的レガシー**:
- VSCode用ガード前に副作用を持つ`require`を済ませることで、共有キーマップを維持しつつ二重ロードを避けるパターン
- `vscode-neovim.send`コマンドを用いたキー送出例をテンプレ化しておくと、追加のCtrl/Alt系マップにも流用しやすい

### 2025-11-10 - VSCode Neovim分岐と専用設定の導入（完了）

**背景**: Cursor/VSCode上でvscode-neovimを使う際、従来のVSCodeVim設定が混在して競合していた。Neovim側でも通常UI用設定を読み込むため、キーやプラグイン挙動が不安定になっていた。
**解決**: `init.lua`で`vim.g.vscode`判定を追加し、VSCode環境では早期に`lua/vscode-config.lua`を読み込む構成へ変更。`vscode-config.lua`ではVSCode APIキーマップ、相対番号/サインカラム無効化、最小構成のlazy.nvimセットアップ（mini.move/surround/comment, leap）を定義し、通常Neovim側とは独立した挙動に分離。
**使用方法**: VSCode/Cursorでvscode-neovimを起動すると自動的に専用設定が読み込まれる。`<leader>ff`でQuick Open、`gd`で定義ジャンプ、`<C-h/j/k/l>`でエディタグループ移動など、VSCodeアクションへ透過的にアクセスできる。通常のNeovim起動時は従来の`config.lazy`やユーザープラグインがそのまま動作。
**技術的レガシー**:
- `vim.g.vscode`判定で設定を二分し、副作用のあるrequireをVSCode側から遮断する実装パターン
- VSCode内ではUI系オプションをNeovim側で無効化し、VSCode APIを`require('vscode').action()`経由で呼び出す
- lazy.nvimを複数回セットアップするケース（VSCode専用 vs 通常）でも同一`lazypath`を共有しつつ衝突を防ぐ手順
- VSCode用プラグインは必要最低限のモーション/編集系に限定し、UI依存プラグインは読み込まない

### 2025-11-10 - Markdown callout fold機能修正：親見出しと兄弟関係に変更（完了）

**背景**: callout foldが動作せず、`zc`すると親見出しが閉じられてしまう。calloutを見出しの子供ではなく兄弟として扱う必要があった
**解決**: calloutのfoldlevelを固定値7から親見出しと同じレベルに変更。`get_parent_heading_level()`関数で親見出しレベルを取得し、calloutを兄弟関係として配置
**使用方法**: 
- `zc` → callout上でcalloutのみ閉じる ✅
- `zc` → 見出し上で見出しのみ閉じる ✅
- calloutと見出しが独立して操作可能

**技術的レガシー**:
- Vimのfold階層：親子関係vs兄弟関係の理解が重要
- 固定foldlevel → 動的foldlevelへの変更パターン
- 上方向への見出し検索アルゴリズム（`get_parent_heading_level()`）
- callout終了処理（`<7`）は不要（親レベルで自動終了）

### 2025-11-10 - Markdown callout fold機能デバッグ：callout終端でfoldを確実に閉じる修正（完了）

**背景**: `is_callout_start()` は正しく機能していたが、callout本体の末尾で foldexpr が `<レベル` を返していなかったため、callout行で `zc` を実行すると親見出し全体が閉じてしまっていた
**解決**: 次行の状態を確認する `getline_or_empty()` を追加し、callout本体の最終行で `<parent_level` を返すように変更。デバッグ版でも同様の挙動を記録してログ出力するように調整
**使用方法**:
- `setlocal foldexpr=v:lua.require('user-plugins.markdown-fold').foldexpr()` で callout 単位の開閉が可能
- `zc` を callout 開始行で実行 → callout ブロックのみ閉じる
- 親見出しを `zo` してから `zc` → 見出しと独立して callout を閉じられる

**技術的レガシー**:
- foldexpr で `<n` を返すと、その行で fold が確実に終端する
- `getline_or_empty()` のようなガード付きヘルパーで範囲外アクセスを防止
- デバッグ版でも本番と同じ fold レベルを返すことでログの信頼性を担保

### 2025-11-10 - Markdown callout fold適用の自動化：after/ftpluginへ移動（完了）

**背景**: Neovim標準の`ftplugin/markdown.vim`が後段で再度`foldexpr=MarkdownFold()`を設定してしまい、手動で`setlocal foldexpr=v:lua.require('user-plugins.markdown-fold').foldexpr()`を実行しないとカスタムfoldが使えなかった
**解決**: ユーザー定義のftpluginを`after/ftplugin/markdown.vim`に移動し、標準設定が適用された後にカスタムfoldexpr/foldtextを上書きするよう調整。これによりMarkdownファイルを開くだけでcallout foldが有効になる
**使用方法**:
- Markdownファイルを開くだけで自動的に`foldexpr`と`foldtext`がカスタム実装に切り替わる
- デバッグ等で一時的に別foldexprを設定しても、バッファを開き直せば `after/ftplugin` が再度適用される

**技術的レガシー**:
- Neovimの`'runtimepath'`順序：ユーザーの`ftplugin`は標準より後に配置することで上書きが可能
- `after/ftplugin`ディレクトリを使うと、標準設定を保持したまま追加/修正ができる

---

### 2025-11-10 - Markdown callout fold機能デバッグ：foldlevel階層修正（完了）

**背景**: callout foldが動作せず、ファイルが存在していなかった。calloutが見出しよりも先に（浅く）畳まれる問題が発生していた
**解決**: `markdown-fold.lua`を実装し、foldlevelを正しく設定。見出し（foldlevel 1-6）よりもcallout（foldlevel 7）を深い階層に配置
**使用方法**: 
- `za` → calloutの折りたたみトグル
- `zM` → すべて閉じる（見出しが先、calloutは後）
- `zR` → すべて開く

**技術的レガシー**:
- Vimのfoldlevel仕様：値が小さいほど優先的に畳まれる
- 見出し階層：`#`=1, `##`=2, ..., `######`=6
- callout階層：foldlevel=7（見出しよりも深く）
- callout検出パターン：`^%s*>%s*%[!%w+%]`（Lua正規表現）
- callout本体継続判定：`^%s*>`（開始行以外）
- foldexprでの階層制御：`>7`（開始）、`7`（継続）、`<7`（終了）

---

### 2025-11-07 - Markdown callout fold機能実装：callout専用の折りたたみ機能追加（完了）

**背景**: `> [!type]`形式のObsidian calloutをzcで折りたたみたい。通常のblock quoteは対象外とし、見出しfoldと共存させたい
**解決**: カスタムLua関数でfoldexprを実装。calloutパターン（`> [!type]`）を検出し、callout本体のみを折りたたみ対象とする。見出しfoldは既存通り動作を維持
**使用方法**: 
- `za` → calloutの折りたたみトグル
- `zc` → calloutを閉じる
- `zo` → calloutを開く
- `zM` → すべて閉じる（見出し + callout）
- `zR` → すべて開く

**技術的レガシー**:
- Vim標準の`MarkdownFold()`からLuaカスタム実装への移行パターン
- 正規表現による高度なパターンマッチング（`^%s*>%s*%[!%w+%]`）
- 見出しfold（既存）とcalloutfold（新規）の共存アーキテクチャ
- カスタムfoldtext：calloutタイプ別アイコン表示（📝/⚠️/❌/ℹ️/💡/✅/❓/🤔）
- `v:lua.require()`によるVimscriptからLua関数の呼び出しパターン

---

### 2025-11-07 - gp.nvim ツリー化プロンプト追加：文章の階層的構造化機能（完了）

**背景**: 長文や複雑な文章を意味・構造ごとに階層的に分解して整理したい
**解決**: TreeStructureプロンプトを実装。文章を「主題」「要素」「補足」「具体例」「条件」「感情」などの意味単位に分け、論理的な階層構造として出力
**使用方法**: 
- `<leader>l` → `f` → 🌳 ツリー化 (追加)
- 個別コマンド: `<leader>lf`
- コマンド直接実行: `:GpTreeStructure`
- キーバインド `asdfghjkl;` の順番に準拠（`f`が次の空きキー）

**技術的レガシー**:
- 意味の親子関係に基づく階層構造構築アルゴリズム
- Markdownリスト形式（`-`とインデント）での構造化出力
- 抽象→具体の順での階層配置
- 2スペースインデントによる視覚的な階層表現
- 視覚マーカー: 🌳📋（処理完了時に自動削除）

---

### 2025-11-06 - gp.nvim シンプル化プロンプト追加：要約と用語精査機能（完了）

**背景**: 長文や複雑な文章を核心だけに圧縮し、用語を厳密に精査して理解を深めたい。さらに「一撃で解決」するための質問を自動生成したい
**解決**: SimplifyTextプロンプトを実装。入力を1行の結論に圧縮し、必要時に用語精査（f様式）・噛み砕き（m様式）・箇条書き（t様式）を出力。最後に不足している情報を特定する「一撃解決の質問」（Q）を必須出力
**使用方法**: 
- `<leader>l` → `s` → 🔍 シンプル化 (追加)
- 個別コマンド: `<leader>ls`
- コマンド直接実行: `:GpSimplifyText`
- ※ToDo抽出は`<leader>le`に変更

**技術的レガシー**:
- 1行結論による核心抽出アルゴリズム
- 用語精査による文脈適合性の検証パターン
- 複数出力フォーマット（デフォルト/m/t/f）の様式別適用
- 一撃解決の質問によるYes/Noまたは択一形式の情報追加
- キーバインドの再配置による機能追加の柔軟性

---

### 2025-11-06 - gp.nvim並行処理対応：ノート整理append化と視認性向上（完了）

**背景**: ノート整理を書き換えではなく追加にしたい。処理中に他の行を編集したい。処理結果の挿入位置を明確にしたい
**解決**: 
- CompactNoteを`rewrite`から`append`に変更し、選択範囲の直後に結果を追加
- 各プロンプトの出力に視認性の高い絵文字マーカー追加（✨📝 AI整理結果、✅📋 TODO抽出結果、🎯✅ タスク分解結果）
- gp.nvimの非同期処理により、複数の処理を並行実行しながら他の行を自由に編集可能
**使用方法**: 
- 従来通り`<leader>la/ls/ld/le`で実行
- 処理中に別の範囲を選択して追加処理を実行可能
- 処理中に他の行を自由に編集可能
- 結果は各選択範囲の直後に絵文字マーカー付きで追加

**技術的レガシー**:
- gp.nvimの非同期処理（`vim.loop`）による並行実行パターン
- 処理対象範囲と編集範囲を分離することで競合回避
- 視覚的マーカーによるUX向上（セパレーター + 絵文字 + タイトル）

---

### 2025-11-04 - gp.nvim タスク分解プロンプト追加：GTDメソッドによる25分粒度のタスク分解（完了）

**背景**: 大きなタスクを1ポモドーロ（25分）で完了できる実行可能な単位に分解したい
**解決**: BreakdownTaskプロンプトを実装。GTDメソッドに基づき、タスクを25分以内で完了できる具体的なアクションに分解し、優先度・実行順序付きで出力
**使用方法**: 
- `<leader>l` → `d` → ✅ タスク分解 (追加)
- 個別コマンド: `<leader>ld`
- コマンド直接実行: `:GpBreakdownTask`

**技術的レガシー**:
- GTDメソッドに基づくタスク分解アルゴリズム
- 1ポモドーロ（25分）粒度での実行可能性判定
- 優先度の自動判定（🔴高/🟡中/⚪️低）
- 依存関係に基づく実行順序の構造化
- 不明確要素への⚠️マーカー付与

---

### 2025-11-04 - gp.nvim ToDo抽出プロンプト追加：音声文字起こしからタスクリスト自動生成（完了）

**背景**: 音声レコーディングの文字起こしから実行可能なToDoを抽出したい
**解決**: ExtractTodoプロンプトを実装。音声文字起こしから行動が必要な発言・決定事項を抽出し、実行可能なタスクリスト形式で出力
**使用方法**: 
- `<leader>l` → `e` → 📋 ToDo抽出 (追加)
- 個別コマンド: `<leader>le`
- コマンド直接実行: `:GpExtractTodo`

**技術的レガシー**:
- 音声文字起こしに特化したプロンプト設計
- 時系列順でのタスク抽出アルゴリズム
- 進捗状態（`[ ]`, `[-]`, `[x]`, `[/]`）の自動判定
- 不明確なタスクへの⚠️マーカー付与

---

### 2025-11-04 - gp.nvimメニュー整理：不要なプロンプト削除とキーバインド変更（完了）

**背景**: gp.nvimに実装していた6つのプロンプトのうち、実際に使うのはノート整理のみだった
**解決**: TranslateJP/ExplainCode/FixGrammar/RefactorCode/Summarizeの5つを削除し、CompactNoteのみ残した。キーバインドを`n`から`a`に変更
**使用方法**: 
- `<leader>l` → LLMプロンプトメニューを表示
  - `a` → 📝 ノート整理 (追加)
- 個別コマンド: `<leader>la`
- コマンド直接実行: `:GpCompactNote`

**技術的レガシー**:
- YAGNI原則に従った不要機能の削除
- 実際の使用状況に基づいた機能の絞り込み
- シンプルなUIの維持

---

## 📅 2025年10月

### 2025-10-28 - gp.nvim導入：OpenAI GPT統合とカスタムプロンプト実装（完了）

**背景**: Visual modeで選択したテキストに特定のプロンプトを適用し、構造化されたノートに変換したい
**解決**: gp.nvimプラグインを導入し、`<leader>c`風のInsert modeメニューUIで複数のGPTプロンプトを実装。ノート整理・翻訳・コード説明・文法修正・リファクタリング・要約の6種類を実装
**使用方法**: 
- `<leader>l` → LLMプロンプトメニューを表示
  - `n` → 📝 ノート整理 (追加)
  - `t` → 🇯🇵 日本語翻訳 (追加)
  - `e` → 💡 コード説明 (ポップアップ)
  - `f` → ✍️  文法修正 (書き換え)
  - `r` → 🔧 リファクタリング (分割)
  - `s` → 📋 要約 (追加)
- 個別コマンド: `<leader>ln`, `<leader>lt`, `<leader>le`, `<leader>lf`, `<leader>lr`, `<leader>ls`
- コマンド直接実行: `:GpCompactNote`, `:GpTranslateJP`, `:GpExplainCode`, `:GpFixGrammar`, `:GpRefactorCode`, `:GpSummarize`

**技術的レガシー**:
- gp.nvim hooksによるGPTs風カスタムプロンプト実装パターン
- `<leader>c`風Insert modeメニューUIとの統一感
- Luaの長文字列リテラル`[[...]]`でXMLタグをそのまま記述
- `{{selection}}`変数による選択範囲の自動挿入
- 出力ターゲットの使い分け: `rewrite`(書き換え), `append`(追加), `popup`(ポップアップ), `vnew`(分割)
- 環境変数`OPENAI_API_KEY`によるAPI認証

---

## 📅 2025年9月

### 2025-09-24 - tmux-continuum自動保存修復：1ヶ月間停止していた自動保存機能復旧（完了）

**背景**: tmux-resurrect/continuumの自動保存が8月22日以降停止し、古すぎるセッションが復元されていた
**解決**: continuumプラグインの手動再起動とタイマー設定の再初期化により15分間隔での自動保存復活
**使用方法**: 自動保存（15分間隔）、手動保存（Ctrl+a + Ctrl+s）、手動復元（Ctrl+a + Ctrl+r）

**技術的レガシー**:
- tmux-continuumはtmux内部タイマーを使用（独立プロセスなし）
- プラグイン停止時は`tmux run-shell continuum.tmux`で再起動
- 保存場所: `~/.local/share/tmux/resurrect/`（XDG準拠）
- テスト方法: 間隔を短縮（5分）して動作確認後に元設定（15分）に戻す

---

### 2025-09-18 - vw photos_monitorコマンド実装：Photos/iCloud同期モニタリング機能（完了）

**背景**: Photos/iCloudの同期状況を視覚的に監視し、I/O状況とphotolibrarydプロセスの進捗を同時に追跡したい
**解決**: 既存のbashスクリプトを`vw photos_monitor`として`.vw`ディレクトリに配置、統一されたvwツールセットに追加
**使用方法**: `vw photos_monitor --volume /Volumes/MyBook4TB --library "/path/to/Photo Library.photoslibrary"` - ボリュームI/Oとphotolibrarydログを並列監視

**技術的レガシー**:
- 外部スクリプトのvwツールセット統合パターン
- 複数プロセス並列監視（I/O + ログストリーム）
- iostat + log streamコマンドによるmacOSシステム監視手法

---

## 📅 2025年8月

### 2025-08-18 - VW CCC実装：Claude Code文脈コマンド生成機能（完了）

**背景**: Claude Codeに現在の文脈に沿ったコマンドを考えてもらい、クリップボードにペーストしたい
**解決**: `vw ccc`コマンドでClaude Codeの`-p`モードを活用し、プロジェクト文脈でコマンド生成＆クリップボードコピー
**使用方法**: `vw ccc "ghでpr作るコマンド考えて"` - 生成されたコマンドが自動でクリップボードにコピー

**技術的レガシー**:
- Claude Code CLIとの外部連携パターン
- プロンプト強化による実行可能コマンド出力の制御
- 既存vwツールセットとの統一インターフェース設計

---

## 📅 2025年7月

### 2025-07-14 - Think & Idea Callout追加：思考・アイデア記録機能実装（完了）

**背景**: 思考プロセスとアイデアの可視化・記録が必要
**解決**: `<leader>c`のCallout機能に`think`と`idea`を追加、自動でタイトルに`#think`・`#idea`を挿入
**使用方法**: 
- `<leader>c` → `t` → 🤔 Think callout作成
- `<leader>c` → `i` → 💡 Idea callout作成

**技術的レガシー**: 
- ObsidianのCallout標準に準拠した実装
- render-markdown.nvimとの統合によるアイコン表示
- 自動タイトル挿入による一貫性確保

---

### 2025-07-14 - vw commitコマンド実装：Git commit結果のクリップボード自動コピー機能（完了）

**背景**: git commitの実行結果をすぐに活用したい
**解決**: `vw commit`コマンドでgit commit実行結果をクリップボードに自動コピー
**使用方法**: `vw commit -m "メッセージ"` - 結果が自動でクリップボードにコピー

**技術的レガシー**:
- bash $@を使った引数の完全転送
- 2>&1でstdoutとstderrの両方をキャッチ
- 絵文字とテキストを組み合わせた視覚的フィードバック

---

### 2025-07-14 - git-commit-gen機能拡張：生成コマンドのクリップボード自動コピー機能（完了）

**背景**: AI生成されたコミットコマンドをすぐに実行したい
**解決**: 既存の`git-commit-gen`スクリプトに生成コマンドの自動クリップボードコピー機能を追加
**使用方法**: `vw git-commit-gen` - AIで生成されたコマンドが自動でクリップボードにコピー

---

### 2025-07-14 - E94エラー完全解決：iCloudパス対応のタスクタイマージャンプ機能修正（完了）

**背景**: `<leader>j`タイマージャンプ機能で`E94: No matching buffer`エラーが発生
**解決**: `vim.fn.swapname()`関数によるE94エラーの原因を特定し、swapファイルチェック処理を完全削除
**使用方法**: `<leader>j`でiCloudファイルでもエラーなくジャンプ

**技術的レガシー**:
- デバッグログとコマンドテストによる効率的な問題解決手法
- iCloudファイルシステム対応のベストプラクティス
- 複雑な処理を削除することで信頼性を向上させる設計思想

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

---

## 📋 主要キーマップ一覧

### タスク管理
- `<leader>c` → Callout/コードブロック作成（think, idea含む）
- `<leader>x` → タスク化トグル（複数行対応）
- `<CR>` → タスク状態循環（タイマー連携）
- `<leader>j` → 進行中タスク表示（pending-tasks）

### タイマー機能
- `<leader>t` → 稼働中タイマーにジャンプ（x: 見失ったタスク削除）
- `<leader>Ta` → アクティブタイマー表示
- `<leader>Ts` → タイマー再スキャン
- `<leader>Ti` → タイマーデータ情報
- `<leader>Tq` → 全タイマー停止
- `<leader>Tc` → タイマーデータクリア
- `<leader>TD` → デバッグモード切替

### LLMプロンプト
- `<leader>l` → LLMプロンプトメニュー
  - `a` → 📝 ノート整理 (追加)
  - `s` → 🔍 シンプル化 (追加)
  - `d` → ✅ タスク分解 (追加)
  - `f` → 🌳 ツリー化 (追加)
  - `e` → 📋 ToDo抽出 (追加)
- 個別コマンド: `<leader>la`, `<leader>ls`, `<leader>ld`, `<leader>lf`, `<leader>le`

### ファイル操作
- `<leader>o` → スマートファイルオープン（smart-open.nvim）

### vwツールセット
- `vw commit` → Git commit + クリップボードコピー
- `vw git-commit-gen` → AI生成コミットコマンド + クリップボードコピー
- `vw git-templ` → GitHubプライベートテンプレート作成
- `vw ccc` → Claude Code文脈コマンド生成 + クリップボードコピー
- `vw photos_monitor` → Photos/iCloud同期モニタリング（I/O + プロセスログ）

---

## 🗂️ 実装履歴（2025年6月以前）

### 2025-07-01 - smart-open.nvim実装
**解決**: Mozillaのfrecencyアルゴリズムによる賢いファイル順序付け
**使用方法**: `<leader>o`でスマートファイルオープン

### 2025-07-05 - git-commit-genツール追加
**解決**: git diffの変更内容をClaudeで分析し、実行可能なコミットコマンドを生成
**使用方法**: `vw git-commit-gen`

### 2025-07-05 - vwツールセット実装
**解決**: GitHubプライベートテンプレート作成の完全自動化
**使用方法**: `vw git-templ my-template`

### 2025-07-01 - swapファイル生成回避実装
**解決**: `remove_lost_tasks()`でのswapファイル生成リスクを完全排除
**技術的レガシー**: 直接ファイル読み込みによるバッファシステム回避

### 2025-07-01 - E94エラー完全根絶
**解決**: 全バッファ操作の安全化、統一されたエラーハンドリングシステム
**技術的レガシー**: `vim.api.nvim_buf_is_valid()`を使った堅牢なバッファ検証

### 2025-06-30 - leader-jエラー解決
**解決**: Obsidianファイルパス処理改善、環境変数名統一
**技術的レガシー**: Vim/Neovimのパス展開機能の適切な活用

### 2025-06-29 - obsidian-zoom v2実装
**解決**: 標準のfold機能を活用したシンプルなMarkdown見出しズーム
**技術的レガシー**: 複雑な処理を削除して軽量化する設計思想

### 2025-06-29 - Markdown見出しfold機能実装
**解決**: ftpluginで確実なfold機能実現
**使用方法**: `za`でfoldトグル

### 2025-06-25 - タスクキャンセル機能追加
**解決**: ローテーション順序を`[ ]` → `[-]` → `[x]` → `[/]` → `[ ]`に拡張
**技術的レガシー**: タスク状態管理の包括的設計

### 2025-06-23 - タイマージャンプ機能swapファイル対応実装
**解決**: swapファイル事前検出とユーザー選択肢の提供
**技術的レガシー**: `vim.fn.swapname()`による事前検出テクニック

### 2025-06-20 - leader-x複数行対応実装
**解決**: Visual modeでの複数行一括チェックボックス状態切り替え
**技術的レガシー**: Normal & Visual mode両対応のキーマップ設計

### 2025-06-19 - leader-j UI統一 & 見失ったタスク削除機能実装
**解決**: leader-cと同じInsert modeベースUI、見失ったタスクの自動検出・削除
**使用方法**: `<leader>j` → `x`で見失ったタスク削除

### 2025-06-18 - tmux.confダブルクリックタイルレイアウト機能追加
**解決**: ダブルクリックでペインをタイルレイアウトに変更
**使用方法**: ペインをダブルクリック → タイルレイアウト

### 2025-06-18 - tmuxセッション名「main」設定場所調査
**調査結果**: `~/.zshrc`の`tmux_auto_start()`関数内、現在は無効状態

### 2025-06-17 - 重大なバグ修正：安全なストレージシステム実装
**解決**: データ消失バグの完全根絶、安全なマージ機能実装
**技術的レガシー**: ファイルベースデータベースの安全なCRUD操作実装

### 2025-06-16 - Timer実装の全問題修正
**解決**: バッファ切り替え検出強化、タイマー重複防止、状態変更検出改善
**技術的レガシー**: extmarkの重複描画防止、tmux環境での完璧な表示継続

### Phase 1 & 2: タイマー文字列ベース化実装
**解決**: 行番号依存から文字列ベースへの永続化システム移行
**技術的レガシー**: 完全マッチ → 部分マッチの階層検索アルゴリズム
