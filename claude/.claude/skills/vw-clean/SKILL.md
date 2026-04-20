---
name: vw-clean
description: Claude のサンドボックスで rm / mv が拒否されたファイル、セッションで作った一時ファイル、同一内容の重複 MD、$TMPDIR/claude 配下の作業残骸などを特定し、ユーザーに「何を消すか」を一覧で説明・確認した上で、macOS の `trash` コマンド（ゴミ箱に送る＝復元可能）を生成して `pbcopy` でクリップボードに送る。ユーザーはターミナルに貼って実行するだけで片付く。Use when the user says 「掃除して」「不要ファイル消して」「rm できなかったやつ片付けて」「trash してまとめて」「/vw-clean」等。NOT for 重要ファイル／作業成果物の削除（必ず確認プロンプトを挟む）and NOT for `rm -rf` 系の破壊的一括削除（trash 経由で復元可能な範囲に限定）。
---

# vw-clean 掃除スキル

Claude のセッション中、サンドボックス制約で `rm` / `mv` が拒否されたファイルや、`$TMPDIR/claude` 配下に溜まった作業残骸を、**ゴミ箱送り（復元可能）** の形で片付ける。

## 背景（なぜこのスキルが必要か）

Claude Code のサンドボックスは `rm` / `mv` を標準で拒否することが多く、Write 上書き戦略で回避すると **重複ファイル** が残る。また一時作業で `$TMPDIR/claude/...` に作ったファイルも片付け忘れがち。セッション末に機械的にまとめて `trash` することで：

- 重複ファイルを消して使う側を迷わせない
- 一時作業領域を空にして次のセッションを綺麗に始める
- `rm` と違いゴミ箱経由なので復元可能（**怖くない**）

## トリガー

ユーザーの発話例:

- 「掃除して」「片付けて」「いらないファイル消して」
- 「rm できなかったやつまとめて処理して」
- 「trash してほしい」「ゴミ箱に送って」
- 「/vw-clean」
- 「一時ファイル整理」「$TMPDIR/claude を空にして」

## 対象ファイル（候補）

以下のカテゴリを **優先度順** にスキャンする。対象はこのセッションで触れたものに限定し、ユーザーが過去作った他のファイルには手を出さない。

1. **サンドボックスで `rm` / `mv` が拒否された残骸**
   - 典型: Write 上書き戦略で同内容の重複になった `*-text.md` / `*-rebuild.md` / `*-tmp.md`
   - セッションの会話履歴から「rm denied」「mv denied」のログを探す
2. **`$TMPDIR/claude/` 配下の作業用ファイル**
   - 例: `$TMPDIR/claude/docling-xlsm/*`, `$TMPDIR/claude/docling-check/*`, `$TMPDIR/claude/docling-pptx/*`
   - スキル経由で作った中間生成物はここに溜まる
3. **失敗した変換の空/ゴミ出力**
   - 例: 766 byte しかない OCR 失敗 MD（画像 placeholder の羅列のみ）
   - 0 byte ファイル
4. **ユーザーが明示的に指定したもの**
   - 「xxx.md も一緒に消して」等の追加指示

## 実行手順

### Step 1: 候補を列挙

会話履歴・`$TMPDIR/claude/` 配下・作業ログを元に候補をリストアップ。各候補について:

- 絶対パス
- サイズ
- 削除理由（重複／失敗出力／一時ファイル 等）

### Step 2: ユーザーに確認（AskUserQuestion）

**AskUserQuestion ツールを必ず使う**。各候補ファイルをまとめて一画面で見せ、ユーザーに「削除対象として進めてよいか」を聞く。質問は1〜2問で済ませる:

例:
```
質問: 「以下のファイルを trash（ゴミ箱送り）します。よろしいですか？」
選択肢:
  - 全部OK、進める（Recommended）
  - 一部だけOK（具体的に指示する）
  - 今回はやめる
```

**安全第一**: 重要そうなファイル（作業成果物の本体、ユーザーが長い時間をかけて作ったもの）が候補に混ざっていたら、個別に確認を取る。

### Step 3: `trash` コマンドを生成

対象ファイルが承認されたら、`trash` コマンドを組み立てる:

```bash
trash "/path/to/file1" "/path/to/file2" "/path/to/dir/"
```

- **パスは必ずダブルクォート** で囲む（日本語・スペース・`()` 対応）
- 複数ファイルはスペース区切りで1コマンドにまとめてよい
- ディレクトリ丸ごと消す場合もそのまま `trash /path/to/dir` で OK（`trash` は -r 不要）

### Step 4: `pbcopy` でクリップボードに送る

```bash
printf '%s' 'trash "/path/to/file1" "/path/to/file2"' | pbcopy
```

- `printf '%s'` を使う（`echo` だと末尾改行がクリップボードに入って貼り付け時に勝手に実行されうる）
- **シングルクォート で全体を囲む**ことで、パス内のダブルクォートをそのまま pbcopy に渡せる
- `dangerouslyDisableSandbox: true` が必要なことが多い（pbcopy が sandbox allow リスト外）

検証のため直後に `pbpaste` で内容確認する（これも `dangerouslyDisableSandbox: true`）。

### Step 5: ユーザーにコマンドと解説を提示

チャット出力に以下をまとめて書く:

1. **コピーしたコマンド**（コードブロックで）
2. **どのファイルをなぜ消すか**（表形式が見やすい）
3. **実行方法**: 「ターミナルで Cmd+V → Enter」
4. **復元方法**: Finder の「ゴミ箱を開く」→ 右クリック → 「戻す」

### Step 6: 実行確認（任意）

ユーザーから「消えたよ」「done」等の応答があったら、対象ファイルが実際に消えたか `ls` 等で確認してスキル完了。

## フォールバック

### `trash` コマンドが無い環境

Homebrew の `trash` が未インストールなら、以下に切り替える:

**推奨: osascript 経由（macOS 標準、追加インストール不要）**
```bash
osascript -e 'tell application "Finder" to delete POSIX file "/path/to/file"'
```

**代替: `mv ~/.Trash/`（軽量・高速だが Finder の「戻す」で元の場所に復元不可）**
```bash
mv "/path/to/file" ~/.Trash/
```

**最終手段: 素の `rm`（ゴミ箱に入らない・復元不可、警告必須）**
```bash
rm "/path/to/file"
```

ユーザーの環境に `trash` があるかは `which trash` または `command -v trash` で事前チェック可能。ない場合は提案前に「`brew install trash` でインストールしますか？ それとも osascript を使いますか？」と聞く。

### 複数ファイルの osascript 版

osascript で複数ファイルを一度に削除する場合:

```bash
osascript -e 'tell application "Finder" to delete every item of {POSIX file "/path1", POSIX file "/path2"}'
```

ただし **可読性が下がる** ので、複数ファイルは `trash` 推奨。

## 実行例

### 例 1: 重複 MD の片付け

会話の流れ:
1. ユーザー「/vw-clean」
2. Claude: 候補を列挙
   - `/Users/foo/Downloads/work/otoinep_v1-text.md` (12kB) — Write上書きでマスターと重複
   - `$TMPDIR/claude/docling-xlsm/11.md` (23MB) — 不要な中間生成物
3. AskUserQuestion で承認取得
4. `printf '%s' 'trash "/Users/foo/Downloads/work/otoinep_v1-text.md" "$TMPDIR/claude/docling-xlsm/11.md"' | pbcopy`
5. 「クリップボードに送りました、ターミナルで Cmd+V → Enter してください」

### 例 2: `$TMPDIR/claude/` 丸ごと空にする

```bash
printf '%s' 'trash "$TMPDIR/claude"/*' | pbcopy
```

ただし **glob 展開は貼った先のシェルで行われる** ので、引用符内の `$TMPDIR` は展開されて実行される。実行前にユーザーに「次のセッションでも一時作業領域が必要なら、ここはそのままでも構いません」と補足する。

## 注意事項（MUST）

- **勝手に `Bash rm` を実行しない**。必ず pbcopy 経由でユーザーの手に戻す。サンドボックスを外して `rm` すると、セッション終盤の Claude の誤判断で重要ファイルが消える事故の元。
- **重要ファイルは個別確認**。AskUserQuestion で「これはマスター版ですか？」と一回問う。
- **`rm -rf /` 系は絶対生成しない**。root・home・親ディレクトリ指定が入っていたら即停止してユーザーにエラー報告。
- **pbcopy の引数エスケープ**を間違えない:
  - 正: `printf '%s' 'trash "..."' | pbcopy`（シングルクォートで全体を囲み、内側はダブルクォート）
  - 誤: `echo trash "..." | pbcopy`（末尾改行が入り、パス内に $ があると展開される）
- **`$TMPDIR` は絶対に残さず、実値パスに展開してから pbcopy に送る**（重要）:
  - Claude Code の Bash ツールの `$TMPDIR` は独自オーバーライドされており、典型的には `/tmp/claude-<uid>/`（例: `/tmp/claude-503/`）
  - 一方ユーザーのログインシェルの `$TMPDIR` は macOS 標準の `/var/folders/sv/.../T/` 等、**別の値**
  - したがって `trash "$TMPDIR/claude/..."` のようにシングルクォートで `$TMPDIR` を残すと、ユーザーのシェル側で展開されて存在しないパスになり `fnfErr: File not found` になる
  - **必ず `ls` 等で実値パス（`/tmp/claude-<uid>/claude/...` または `/private/tmp/claude-<uid>/claude/...`）を確認してから、その絶対パスで `trash` コマンドを組み立てる**
  - `echo $TMPDIR` の結果をそのまま使わず、`ls -la $TMPDIR/claude/...` でファイルが見えているパスをコピーすること
  - 失敗例: `printf '%s' 'trash "$TMPDIR/claude/foo.md"' | pbcopy` → NG（シングルクォートで $TMPDIR が貼付先展開される）
  - 成功例: `printf '%s' 'trash "/tmp/claude-503/claude/foo.md"' | pbcopy` → OK（実値）
- **スキル内で `trash` を直接実行しない**。ユーザーの明示的な承認があっても、pbcopy 経由でターミナルから実行してもらう設計を崩さない（この一手間が事故防止になる）。

## 対象外

- **Git 管理下のファイル削除**（`git rm` を使うべき、このスキルは単なるファイル掃除用）
- **ネットワーク共有・Dropbox 等のクラウド同期フォルダ**（同期先にも影響するため個別確認）
- **システムファイル**（`~/Library/`, `/System/`, `/Library/` 配下）
- **Time Machine バックアップ**
- **`.git/` 配下**（リポジトリ破壊のリスク）
