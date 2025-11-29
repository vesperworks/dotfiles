# remove/ - 削除候補ファイル置き場

このディレクトリには、プロジェクトから削除予定のレガシーファイルが格納されています。

## 移動日時

**2025-11-29** - プロジェクト整理計画の実施
**2025-11-30** - クリティカル修正とクリーンアップ実施

## 移動理由

本プロジェクトは「役割進化型ワークフロー」へ移行し、以下の構造変更が行われました：

1. **worktree管理の廃止**: git worktreeベースの複雑なワークフローを廃止
2. **Skills構造への移行**: `.claude/prompts/` から `.claude/skills/` へ完全移行
3. **PRP駆動型タスク管理**: `todo.md` から `PRPs/` + `vw-task-manager` エージェントへ移行

これらの変更により、以下のファイル・ディレクトリが不要となりました。

## 移動対象ファイル一覧

### 1. scripts/legacy-hooks/

**移動ファイル**:
- `setup-hooks.sh` (git worktree用フック初期化)
- `cleanup-hooks.sh` (git worktree用フック削除)
- `update-hooks.sh` (git worktree用フック更新)

**理由**: CLAUDE.mdで「worktree廃止」と明記されており、これらは古いworktree時代の管理スクリプトのため不要。

**移動コミット**: プロジェクト整理実施時
**削除日時**: 2025-11-30（git rm実行済み）

---

### 2. prompts/prompts-legacy/ [削除済み]

**移動ファイル**: `.claude/prompts/` ディレクトリ全体（830行）
- `explorer.md`
- `planner.md`
- `coder.md`
- `coder-test.md`
- `coder-impl.md`
- `tester.md`

**理由**:
- CLAUDE.mdで「Skills構造に移行済み」と明記
- 現在は `.claude/agents/vw-*.md` (8エージェント) と `.claude/skills/` (6スキル) に統合済み
- Progressive Disclosure 3層構造（Frontmatter/Body/References）を採用

**移動コミット**: プロジェクト整理実施時
**削除日時**: 2025-11-30（git rm実行済み）

---

### 3. refactored_process.md [削除済み]

**理由**: multi-feature.mdのリファクタリング報告書。過去の改善記録で、現在は参照されていない。

**移動コミット**: プロジェクト整理実施時

---

### 4. todo.md

**理由**:
- PRP駆動型開発への移行により、`PRPs/` ディレクトリと `vw-task-manager` エージェントが代替機能を提供
- 内容は `done.md` にアーカイブ済み（2025-11-29）

**移動コミット**: プロジェクト整理実施時
**削除日時**: 2025-11-30（git rm実行済み）

---

### 5. reports/cleanup-phase-2025-06-26/

**旧パス**: `report/temp-cleanup/`

**理由**:
- 一時的な名前「temp」のまま放置されていた
- 適切な時系列アーカイブ名（cleanup-phase-2025-06-26）に変更

**内容**: 2025-06-26時点のクリーンアップフェーズのレポート（11ファイル）

**移動コミット**: プロジェクト整理実施時

---

### 6. reports/explore-results-bugfix-*.md

**旧パス**: `report/archive/`

**移動ファイル**:
- `explore-results-bugfix-multi.md`
- `explore-results-bugfix-fix-3.md`

**理由**: 過去のバグ修正時の探索結果。アーカイブの一元化。

**移動コミット**: プロジェクト整理実施時

---

### 7. scripts/parallel-agent-utils.sh

**移動日時**: 2025-11-30

**理由**:
- 未定義関数への呼び出しが複数存在（worktree-utils.shへの依存）
- アクティブな使用が一切ない（.klaude/agents/, commands/, skills/からの参照なし）
- レガシーworktreeアーティファクト：旧「並列TDDエージェント」ワークフローの遺物
- 現在は `vw-developer`（TDD実装）と `vw-qa-tester`（テスト）を使用

**サイズ**: 641行

**移動コミット**: クリティカル修正とクリーンアップ実施時

---

### 8. hooks/textlint-hook.sh

**移動日時**: 2025-11-30

**理由**:
- settings.json hooksに未登録（アクティブに使用されていない）
- Textlintはプロジェクト固有（グローバル `.claude` ではなく個別プロジェクトで設定すべき）
- レガシードキュメントでのみ2件参照

**移動コミット**: クリティカル修正とクリーンアップ実施時

---

## 削除候補リスト（将来的な完全削除の参考）

### 推奨削除時期: 3-6ヶ月後（2025-02〜2025-05頃）

以下の条件を満たした場合、完全削除を検討：

1. ✅ 新しいワークフロー（役割進化型）が安定稼働している
2. ✅ レガシーファイルへの参照が完全になくなっている
3. ✅ Git履歴で復元可能であることを確認済み

### 削除優先度

#### 高優先度（ほぼ確実に削除可能）
- ~~`scripts/legacy-hooks/` - worktree完全廃止により100%不要~~ **[2025-11-30削除済み]**
- ~~`prompts/prompts-legacy/` - Skills移行完了により100%不要~~ **[2025-11-30削除済み]**
- ~~`todo.md` - PRP移行完了により100%不要~~ **[2025-11-30削除済み]**

#### 中優先度（確認後削除）
- ~~`refactored_process.md` - 参照されていない過去の記録~~ **[2025-11-30削除済み]**
- `reports/cleanup-phase-2025-06-26/` - 歴史的価値は低い（保管中、2025-05-01見直し）
- `reports/explore-results-bugfix-*.md` - 歴史的価値は低い（保管中、2025-05-01見直し）
- `scripts/parallel-agent-utils.sh` - 未使用、worktreeレガシー（保管中、3-6ヶ月後削除検討）
- `hooks/textlint-hook.sh` - 未登録、プロジェクト固有（保管中、3-6ヶ月後削除検討）

## Git履歴の保持

すべてのファイルは `git mv` で移動されているため、Git履歴は保持されています。

必要時は以下のコマンドで復元可能：

```bash
# 特定ファイルの復元
git mv remove/prompts/prompts-legacy .claude/prompts

# Git履歴の確認
git log --follow remove/prompts/prompts-legacy/explorer.md
```

## 関連ドキュメント

- **CLAUDE.md**: プロジェクト概要と最新のアーキテクチャ説明
- **PRPs/done/PRP-002B-progressive-disclosure-with-agent-optimization.md**: Skills移行の詳細
- **PRPs/done/PRP-003-cleanup-unnecessary-files-and-directories.md**: 前回のクリーンアップ記録

## 最終更新

- **作成日**: 2025-11-29
- **最終更新**: 2025-11-30
- **作成者**: プロジェクト整理計画の実施
- **関連コミット**:
  - 2025-11-29: プロジェクト整理実施コミット
  - 2025-11-30: クリティカル修正とクリーンアップ実施コミット
