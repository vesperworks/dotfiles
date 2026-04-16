---
name: sc
description: 'Smart commit: /sc (段階コミット) or /sc "message" (クイックコミット)'
---

# Smart Commit

## モード判定

- `$ARGUMENTS` が**空**の場合 → **段階コミットモード**（変更をグループ化して順次コミット）
- `$ARGUMENTS` が**ある**場合 → **クイックコミットモード**（従来の一括コミット）

---

## Step 0: VCS 検出

最初に VCS を自動検出する。以降の操作は検出結果に基づいて分岐する。

```bash
source ~/.claude/scripts/vcs-detect.sh
VCS=$(detect_vcs)  # → "jj" or "git"
```

- **jj リポジトリ**: ステージングなし。全変更が自動トラッキングされる
- **git リポジトリ**: 従来通りステージング + コミット

### Step 0.5: ブランチ戦略（jj のみ）

jj の場合、コミットを**どのブランチに配置するか**を事前に確認する。

**確認コマンド**:
```bash
# 現在のブランチ（bookmark）と DAG 構造
jj log -r 'ancestors(@, 5)'
jj bookmark list
```

**確認ポイント**:
1. 現在のワーキングコピーはどのブランチ上にあるか？
2. 変更ファイルの中に、現在のブランチとは**無関係な変更**が混在していないか？
3. main に直接入れるべき変更（独立した fix/feat）はあるか？

**判定結果を記録**（Step 2 で表示する）:
- **current**: 現在のブランチにそのまま split する
- **main**: main の子として配置する（split → rebase）
- **new:<name>**: 新しいブランチを作成して配置する（split → rebase → bookmark create → **Phase C で main にマージ**）
- **skip**: 今回はコミットしない（開発中の変更）

> **⚠️ ワーキングコピー切り替えの注意**: jj のワーキングコピーは1つしかない。
> 別エージェントが同じディレクトリで作業中の場合、`jj new main` 等でワーキングコピーを
> 切り替えるとファイルシステムが変わり影響が出る。その場合は rebase 方式（現在位置で
> split → 後から rebase で移動）を使うこと。

---

## クイックコミットモード（引数あり）

`/sc "message"` の形式で呼び出された場合、従来のスクリプトを実行：

```bash
~/.claude/scripts/smart-commit.sh "$ARGUMENTS"
```

VCS は smart-commit.sh 内で自動検出される。全変更を一括コミットします。

---

## 段階コミットモード（引数なし）

`/sc` の形式で呼び出された場合、以下のステップで段階的にコミット：

### Step 1: 変更分析

**jj の場合:**
1. `jj diff --name-only` で変更ファイル一覧を取得（ステージング概念なし）
2. `jj diff` で変更内容を確認
3. 変更内容を分析し、論理的なグループに分類提案

**git の場合:**
1. `git status --porcelain` で変更ファイル一覧を取得
2. `git diff --name-only` でステージングされていない変更を確認
3. `git diff --cached --name-only` でステージング済みの変更を確認
4. 変更内容を分析し、論理的なグループに分類提案

**グループ化の基準**:
- 同じディレクトリ内のファイル
- 同じ機能・目的に関連するファイル
- 同じコミットタイプ（feat/fix/docs等）に該当するファイル

### Step 1.5: センシティブ情報チェック（Sensitive Path Check）

コミット前に、変更ファイル内のセンシティブ情報を検出し、変換を提案する。

#### 検出対象

| パターン | 例 | 検出方法 |
|---------|-----|---------|
| **ユーザー名** | `{username}`, `$(whoami)` | `whoami` の結果でgrep |
| **絶対パス** | `/Users/xxx/...`, `/home/xxx/...` | `/Users/` または `/home/` でgrep |

#### 検出方法（security-utils.sh を使用）

```bash
# security-utils.sh をsourceして使用
source ~/.claude/scripts/security-utils.sh

# ステージング済みファイルのセンシティブ情報チェック
check_staged_sensitive
```

**利用可能な関数**:
- `check_staged_sensitive` - ステージング済みファイルをチェック
- `check_sensitive_info "file1" "file2"` - 指定ファイルをチェック
- `get_staged_files` - ステージング済みファイル一覧を取得

#### 検出時のフロー

**センシティブ情報が検出された場合**:

1. 検出結果を表示：
```
## ⚠️ センシティブ情報を検出しました

以下のファイルに個人情報または絶対パスが含まれています：

| ファイル | 行番号 | 検出内容 |
|---------|--------|---------|
| `.klaude/settings.json` | L5 | `/Users/{username}/Works/...` |
| `CLAUDE.md` | L42 | `{username}` |
```

2. AskUserQuestion で対応を選択：
```yaml
AskUserQuestion:
  questions:
    - question: "センシティブ情報が検出されました。どのように対応しますか？"
      header: "対応"
      multiSelect: false
      options:
        - label: "相対パスに変換（推奨）"
          description: "/Users/xxx/project/src → src（プロジェクトルート基準）"
        - label: "~/ 形式に変換"
          description: "/Users/xxx → ~/"
        - label: "そのままコミット"
          description: "変換せずにコミットを続行（承認）"
        - label: "コミットを中止"
          description: "手動で修正してから再実行"
```

#### 変換ロジック

**相対パスに変換（推奨）**:
```bash
# jj の場合
PROJECT_ROOT=$(jj root)
# git の場合
PROJECT_ROOT=$(git rev-parse --show-toplevel)

# /Users/{username}/Works/project/src/file.ts → src/file.ts
sed -i '' "s|$PROJECT_ROOT/||g" <file>
```

**~/ 形式に変換**:
```bash
HOME_DIR=$HOME
# /Users/{username}/Works/...
# → ~/Works/...
sed -i '' "s|$HOME_DIR|~|g" <file>
```

**ユーザー名の置換**:
```bash
USERNAME=$(whoami)
# {actual_username} → {username} または削除
sed -i '' "s|$USERNAME|{username}|g" <file>
```

#### 注意事項

- 変換後は必ず `git diff` で変更内容を確認表示
- 変換により構文エラーが発生しないか注意（特にJSON、YAML）
- 変換対象外の場所（コードロジック内のパス等）は手動確認を促す

### Step 2: グループ確認（AskUserQuestion形式）

分析結果を表示した後、AskUserQuestionで確認を求める：

**まず、提案グループを表示**（jj の場合はブランチ配置先も含める）:
```
## コミットグループ提案

Commit 1: [feat] 新機能追加 → current (feat/auth)
  - src/feature.ts
  - src/feature.test.ts

Commit 2: [docs] ドキュメント更新 → main
  - README.md
  - CLAUDE.md

Commit 3: [chore] 設定変更 → main
  - ~/.claude/settings.json

Skip (開発中):
  - src/wip-feature.ts
```

> **jj**: `→ main` のコミットは split 後に `jj rebase` で main の子に移動される。
> `→ current` は現在のブランチにそのまま配置。`→ new:<name>` は新規ブランチ作成。

**次に、AskUserQuestionで確認**:
```yaml
AskUserQuestion:
  questions:
    - question: "このグループ構成でコミットしますか？"
      header: "確認"
      multiSelect: false
      options:
        - label: "はい、このまま進める"
          description: "提案されたグループでコミットを実行"
        - label: "グループを統合したい"
          description: "複数のコミットを1つにまとめる"
        - label: "グループを分割したい"
          description: "1つのコミットを複数に分ける"
        - label: "順序を変更したい"
          description: "コミットの実行順序を入れ替える"
```

**ユーザー選択による分岐**:

- **「はい、このまま進める」** → Step 3へ
- **「グループを統合したい」** → Step 2a（統合）へ
- **「グループを分割したい」** → Step 2b（分割）へ
- **「順序を変更したい」** → Step 2c（順序変更）へ

### Step 2a: グループ統合

```yaml
AskUserQuestion:
  questions:
    - question: "どのコミットを統合しますか？（複数選択可）"
      header: "統合"
      multiSelect: true
      options:
        - label: "Commit 1: [feat] 新機能追加"
          description: "src/feature.ts, src/feature.test.ts"
        - label: "Commit 2: [docs] ドキュメント更新"
          description: "README.md, CLAUDE.md"
        - label: "Commit 3: [chore] 設定変更"
          description: "~/.claude/settings.json"
```

選択されたコミットを1つに統合し、Step 2に戻って再確認。

### Step 2b: グループ分割

```yaml
AskUserQuestion:
  questions:
    - question: "どのコミットを分割しますか？"
      header: "分割"
      multiSelect: false
      options:
        - label: "Commit 1: [feat] 新機能追加"
          description: "src/feature.ts, src/feature.test.ts → 2つに分割"
        - label: "Commit 2: [docs] ドキュメント更新"
          description: "README.md, CLAUDE.md → 2つに分割"
```

選択されたコミットのファイルを個別コミットに分割し、Step 2に戻って再確認。

### Step 2c: 順序変更

```yaml
AskUserQuestion:
  questions:
    - question: "最初に実行するコミットを選んでください"
      header: "順序"
      multiSelect: false
      options:
        - label: "Commit 1: [feat] 新機能追加"
          description: "現在: 1番目"
        - label: "Commit 2: [docs] ドキュメント更新"
          description: "現在: 2番目"
        - label: "Commit 3: [chore] 設定変更"
          description: "現在: 3番目"
```

選択された順序で並び替え、Step 2に戻って再確認。

### Step 3: TodoWrite でタスク化

各コミットをTodoアイテムとして登録：

```
TodoWrite([
  { content: "Commit 1: [feat] 新機能追加", status: "pending" },
  { content: "Commit 2: [docs] ドキュメント更新", status: "pending" },
  { content: "Commit 3: [chore] 設定変更", status: "pending" }
])
```

### Step 4: 順次コミット

各グループを順番に処理。VCS によってコマンドが異なる：

#### jj の場合（split → rebase → bookmark → merge）

**Phase A: Split（現在位置で分割）**

skip 以外のグループを順に split する。配置先に関係なく、まず現在位置で直列に分割：

最初〜最後の1つ前のグループまで:
1. **分離コミット**: `jj split -m "<type>(<scope>): <subject>" -- <files>`
2. **進捗更新**: TaskUpdate で該当タスクを `completed` にマーク
3. 次のグループへ進む

最後のグループ（skip がある場合 = ワーキングコピーに残す変更がある場合）:
4. **分離コミット**: `jj split -m "<type>(<scope>): <subject>" -- <files>`
5. 残りの変更はワーキングコピーに残る

最後のグループ（skip がない場合 = 全変更をコミットする場合）:
4. **メッセージ設定**: `jj describe -m "<type>(<scope>): <subject>"`（残り全変更にメッセージ）
5. **新ワーキングコピー**: `jj new`（新しい作業開始）

**Phase B: Rebase + Bookmark（配置先が `main` または `new:<name>` のコミットを移動）**

`→ current` 以外のコミットを正しい位置に rebase する：

```bash
# main 宛のコミットを main の子に移動
jj rebase -r <commit_id> -d main

# 新規ブランチ宛の場合は rebase 後に bookmark 作成
jj rebase -r <commit_id> -d main
jj bookmark create <branch_name> -r <commit_id>
```

> **重要**: rebase 後、直列チェーンの中間コミットが抜けるため、
> 後続コミットの親が自動的に繋ぎ直される（jj が自動処理）。

**jj 段階コミットの例（全て current 宛の場合）**:
```bash
jj split -m "feat(auth): add login validation" -- src/auth.ts src/auth.test.ts
jj split -m "docs: update README" -- README.md
jj describe -m "chore: update config"   # 最後の残り
jj new                                    # 新しいワーキングコピー
```

**Phase C: Merge（ブランチを main にマージコミットで合流）**

Phase B で作成したブランチを、マージコミットで main に統合する。各ブランチの履歴が独立して残る。

**判定ルール**:
- **ブランチなし**（全コミットが `→ main` 直系）→ 直列配置（マージコミット不要）
- **ブランチあり**（1つ以上の `→ new:<name>`）→ **必ずマージコミットで合流**。ブランチを切った = 独立した作業単位として分離した意図があるため、1つでもマージコミットで履歴を残す

**手順（2つ以上のブランチ）**:

1. **一括マージコミット作成**:
   ```bash
   # 全ブランチを一度にマージ（main + 全ブランチを親に持つコミット）
   jj new main <branch1> <branch2> ... -m "merge: <branch1> + <branch2> + ... into main

   - <commit1 summary>
   - <commit2 summary>"
   ```

2. **main を進めてブランチ削除**:
   ```bash
   jj bookmark set main -r @
   jj bookmark delete <branch1> <branch2> ...
   ```

3. **新しいワーキングコピー**:
   ```bash
   jj new  # main の上で新しい作業開始
   ```

**jj 段階コミットの例（混在する場合）**:
```bash
# Phase A: Split（全て現在位置で直列に分割）
jj split -m "feat(sheldon): add stow package" -- sheldon/ install.sh
jj split -m "feat(zsh): add p10k config" -- zsh/
jj split -m "feat(tmux): add resurrect guard" -- tmux/scripts/guard.sh tmux/tmux.conf

# Phase B: Rebase + Bookmark（全コミットを main の子に配置）
jj rebase -r <sheldon_commit> -d main
jj bookmark create feat/sheldon -r <sheldon_commit>
jj rebase -r <zsh_commit> -d main
jj bookmark create feat/zsh -r <zsh_commit>
jj rebase -r <tmux_commit> -d main
jj bookmark create feat/tmux -r <tmux_commit>

# Phase C: 一括マージ
jj new main feat/sheldon feat/zsh feat/tmux -m "merge: feat/sheldon + feat/zsh + feat/tmux into main

- feat(sheldon): add stow package
- feat(zsh): add p10k config
- feat(tmux): add resurrect guard"
jj bookmark set main -r @
jj bookmark delete feat/sheldon feat/zsh feat/tmux
jj new
```

**結果の DAG**:
```
@  (empty) ← ワーキングコピー
○      main  merge: feat/sheldon + feat/zsh + feat/tmux into main
├─┬─╮
│ │ ○  feat(tmux): add resurrect guard
│ ○    feat(zsh): add p10k config
○      feat(sheldon): add stow package
├─╯
◆  main@origin
```

#### git の場合（従来動作）

1. **ステージング**: `git add <specific-files>` （グループ内のファイルのみ）
2. **メッセージ生成**: 変更内容から適切なコミットメッセージを生成
3. **コミット実行**: `git commit -m "<type>(<scope>): <subject>\n\n<body>"`
4. **進捗更新**: TodoWrite で該当タスクを `completed` にマーク
5. 次のグループへ進む

### Step 5: 完了サマリー

全コミット完了後、結果を表示：

```bash
# jj の場合
jj log -r 'bookmarks() & mine()'  # 自分の bookmark 付きコミット一覧
jj bookmark list                   # bookmark 状態を表示

# git の場合
git log --oneline -N  # N = 作成したコミット数
```

**jj の場合、以下も表示**:
- 作成/更新された bookmark 一覧
- 各 bookmark の origin に対する ahead 状態
- push コマンドのヒント: `jj git push --bookmark feat/<scope>`

---

## コミットメッセージ形式

```
<type>(<scope>): <subject>

<body>
```

### ⚠️ 絶対禁止事項

**以下の内容をコミットメッセージに含めてはならない**:

- `Co-Authored-By:` 行（いかなる形式も禁止）
- `Author:` 行
- `Generated with Claude Code` 等のAI生成表記
- `🤖` 絵文字やAI関連のフッター

**正しい例**:
```
feat(auth): add login validation

Implement email format checking and password strength validation
```

**禁止例**（これらは絶対に書かない）:
```
feat(auth): add login validation

Co-Authored-By: Claude <noreply@anthropic.com>
```

```
feat(auth): add login validation

🤖 Generated with Claude Code
```

### Type
- **feat**: 新機能
- **fix**: バグ修正
- **docs**: ドキュメントのみの変更
- **style**: コードの意味に影響しない変更（空白、フォーマット等）
- **refactor**: バグ修正でも機能追加でもないコード変更
- **test**: テストの追加や修正
- **chore**: ビルドプロセスやツールの変更

---

## 使用例

### 段階コミット（推奨）
```bash
/sc
# → 変更を分析 → グループ提案 → 順次コミット
```

### クイックコミット（従来動作）
```bash
/sc ダークモード対応
# → 全変更を一括コミット（feat: implement dark mode theme support）
```

---

## 注意事項

- 段階コミットモードでは、各グループごとに個別のコミットが作成されます
- VCS は自動検出されます（jj 優先。colocate モードでは jj が検出される）
- **jj モード**: ステージング概念なし。全変更が自動トラッキング。`jj split` → `jj rebase` で段階コミット
- **jj ブランチ戦略**: Step 0.5 で各グループの配置先を決定し、Phase B で rebase する。**split だけで終わらせない**
- **git モード**: 従来通り `git add` + `git commit`。ステージングされていない変更も自動ステージングされます
- コミット前に変更内容を確認することを推奨します
