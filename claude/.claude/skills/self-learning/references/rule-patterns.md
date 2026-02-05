# Rule Patterns

ミスを汎用ルールに変換するためのパターン集。

## Overview

具体的なミスを効果的なルールに変換するには、適切な形式を選び、品質基準（METAルール）に従う必要がある。このガイドでは、ルール形式の種類、変換テンプレート、重複検出・マージの方法を解説する。

## ルール形式の種類

### 1. ABSOLUTE形式（禁止・必須）

最も強い制約。違反は許容されない。

**構文**:
```markdown
**NEVER** {禁止行動}
**ALWAYS** {必須行動}
```

**使用場面**:
- セキュリティに関わる制約
- データ損失を防ぐルール
- 一貫性が絶対に必要な場合

**例**:
```markdown
**NEVER** include `Co-Authored-By:` in commit messages

**ALWAYS** use parameterized queries for SQL operations
```

### 2. GUIDELINE形式（推奨・非推奨）

推奨度合いを示す柔軟なルール。状況に応じて例外を許容。

**構文**:
```markdown
**Prefer** {推奨行動} over {非推奨行動} because {理由}
**Avoid** {非推奨行動} when {条件}
```

**使用場面**:
- コードスタイルの統一
- ベストプラクティスの共有
- 複数の正解がある場合

**例**:
```markdown
**Prefer** `const` over `let` for variables that are never reassigned because it prevents accidental mutations.

**Avoid** nested callbacks when async/await is available for better readability.
```

### 3. PATTERN形式（条件付き）

特定の状況でのみ適用されるルール。

**構文**:
```markdown
**When** {条件}, **do** {行動} (not {避けるべき行動})
**If** {条件}, **then** {行動}
```

**使用場面**:
- 特定のファイルタイプへの適用
- 特定のワークフロー中のルール
- コンテキスト依存の判断

**例**:
```markdown
**When** editing CLAUDE.md, **do** use Edit tool for partial updates (not Write tool for full replacement)

**If** the error is "sandbox restriction", **then** retry with `dangerouslyDisableSandbox: true`
```

## METAルール（品質基準）

生成するルールが従うべき品質基準。

### 1. WHYファースト

**理由を先に説明**し、その後でルールを述べる。

```markdown
❌ 悪い例:
NEVER use eval()

✅ 良い例:
eval() allows arbitrary code execution and is a major security vulnerability.
**NEVER** use eval() in any context.
```

### 2. 具体的であること

曖昧な表現を避け、**具体的な行動**を指定する。

```markdown
❌ 悪い例:
Write good commit messages

✅ 良い例:
Format commit messages as: <type>(<scope>): <subject>
- type: feat, fix, docs, style, refactor, test, chore
- scope: affected component (optional)
- subject: imperative mood, no period at end
```

### 3. 例を含める

**良い例と悪い例**の両方を示す。

```markdown
✅ 良い例:
```typescript
// Good
const users = await db.select().from(usersTable).where(eq(id, userId));

// Bad
const users = await db.query(`SELECT * FROM users WHERE id = ${userId}`);
```
```

### 4. 1ルール=1箇条書き

複数の概念を1つのルールに詰め込まない。

```markdown
❌ 悪い例:
NEVER use eval(), always validate input, and prefer const over let

✅ 良い例:
- **NEVER** use eval() — arbitrary code execution risk
- **ALWAYS** validate user input — prevent injection attacks
- **Prefer** const over let — prevent accidental reassignment
```

### 5. 検証可能であること

ルールが守られているかを**客観的に判断**できるようにする。

```markdown
❌ 悪い例:
Write clean code

✅ 良い例:
Keep functions under 30 lines of code
```

## 変換テンプレート

### 入力 → 出力の変換フロー

```
[具体的なミス]
    ↓
[根本原因の特定]
    ↓
[適切な形式の選択]
    ↓
[汎用ルールの生成]
    ↓
[METAルール適用チェック]
```

### テンプレート

```markdown
## {ルールタイトル}

{WHY: 1-2文でなぜこのルールが必要か}

{RULE: 選択した形式（ABSOLUTE/GUIDELINE/PATTERN）でルールを記述}

**例**:
- Good: {正しい例}
- Bad: {間違った例}

<!-- 経緯: {元のミスの要約（将来の参照用）} -->
```

### 変換例

**入力**: 「CLAUDE.mdをWriteツールで上書きしたら内容が消えた」

**変換後**:
```markdown
## CLAUDE.md の編集には Edit ツールを使用

CLAUDE.md を Write ツールで上書きすると、意図せず既存内容が失われる可能性がある。

**When** editing CLAUDE.md, **do** use the Edit tool for partial updates (not Write tool for full replacement).

**例**:
- Good: `Edit(file_path: "CLAUDE.md", old_string: "...", new_string: "...")`
- Bad: `Write(file_path: "CLAUDE.md", content: "新しい内容のみ")`

<!-- 経緯: Write ツールで CLAUDE.md を更新した際、既存ルールがプレースホルダーに置換された -->
```

## 重複検出の基準

### セマンティック類似度

以下のパターンは「重複」と判定:

| パターン | 例 |
|---------|-----|
| **同義語** | "NEVER use eval()" ≈ "eval() is prohibited" |
| **包含関係** | "No SQL injection" ⊂ "Always use parameterized queries" |
| **具体化** | "Use const" ⊂ "Use const for variables never reassigned" |

### 矛盾検出

以下のパターンは「矛盾」と判定:

| パターン | 例 |
|---------|-----|
| **直接矛盾** | "ALWAYS use X" vs "NEVER use X" |
| **間接矛盾** | "Prefer A over B" vs "Prefer B over A" |
| **条件矛盾** | "When X, do Y" vs "When X, do Z"（Y≠Z） |

### マージ戦略

| 状況 | 戦略 | アクション |
|------|------|-----------|
| 新ルールが既存を具体化 | **マージ** | 既存ルールに詳細を追加 |
| 既存ルールが新ルールを包含 | **スキップ** | 新ルールは不要 |
| 両方が独立した観点 | **両方保持** | 別々のルールとして保存 |
| 直接矛盾 | **置換確認** | ユーザーにどちらを採用するか確認 |
| 表現の違いのみ | **統合** | より明確な表現に統一 |

## マージ提案の形式

重複検出時、以下の形式で提案:

```markdown
## 🔄 重複を検出しました

**既存ルール** (in {file_path}):
> {existing_rule_content}

**新しいルール**:
> {new_rule_content}

**判定**: {セマンティック類似 | 包含関係 | 矛盾}

**推奨アクション**:
- [ ] マージ: 既存ルールに詳細を追加
- [ ] 置換: 既存ルールを新ルールで更新
- [ ] 両方保持: 別々のルールとして保存
- [ ] スキップ: 新ルールを保存しない
```

## Best Practices

- **小さく始める**: 最初は1つのルールから。関連ルールは後で追加
- **定期的な見直し**: 古くなったルールは削除または更新
- **スコープを明確に**: グローバルかプロジェクト固有かを意識
- **チーム合意**: 共有ルールは関係者と合意してから追加

## Common Pitfalls

- **過度な抽象化**: 具体性を失うと適用できなくなる
- **ルールの肥大化**: 1つのルールに複数概念を詰め込まない
- **例外なしの絶対ルール**: 正当な例外がある場合は PATTERN 形式を使用
- **WHY の省略**: 理由なきルールは無視されやすい
