# Multi-TDD Development - 役割進化型ワークフロー

バグ修正や小規模機能開発のためのTDD特化型役割進化ワークフローです。TDDのRed-Green-Refactorサイクルに沿って進行します。

## 使用方法
`/multi-tdd "バグまたは機能の説明"`

例: 
- `/multi-tdd "認証トークンの有効期限チェックが機能していない"`
- `/multi-tdd "パスワードバリデーションの追加"`

## オプション
- `--cleanup` - 実行後に./tmp/の古いファイルをクリーンアップ
- `--cleanup-days N` - N日以上前のファイルを削除（デフォルト: 7）

<tdd_evolution_flow>
TDDサイクルに特化した役割進化：

🐛 Bug Hunter → 🧪 Test Designer → 💡 Implementer → 🔧 Refactorer
     (調査)         (Red Phase)      (Green Phase)    (Refactor Phase)

**IMPORTANT**: TDDの原則を厳守し、必ずテストを先に作成してから実装に進みます。
</tdd_evolution_flow>

## 実行フロー

<bughunter_phase>
**Bug Hunter Mode 🐛 - バグの原因調査・要件の明確化**

1. **調査タスク**:
   - バグの再現手順の確認
   - 関連コードの特定
   - 根本原因の分析
   - 影響範囲の確認

2. **成果物の保存**:
   - 調査結果を `./tmp/{timestamp}-bughunter-report.md` に保存
   - **MUST**: 再現可能な手順を明確に記録

3. **Bug Investigation Report形式**:
   ```markdown
   # Bug Investigation Report
   
   ## Issue: [バグの説明]
   
   ## Reproduction Steps:
   1. [再現手順]
   
   ## Root Cause:
   [根本原因の説明]
   
   ## Affected Files:
   - [影響を受けるファイル一覧]
   
   ## Proposed Solution:
   [解決策の提案]
   ```
</bughunter_phase>

<testdesigner_phase>
**Test Designer Mode 🧪 - Red Phase (失敗するテストの作成)**

1. **テスト設計タスク**:
   - `<bughunter_phase>`の調査結果を基にテストケース設計
   - 現在失敗するテストを作成
   - エッジケースのテストも含める
   - テスト実行して失敗を確認

2. **TDD Red Phase原則**:
   - **MUST**: 実装前にテストを作成
   - **MUST**: テストが失敗することを確認
   - **NEVER**: この段階で実装を行わない

3. **Test Design形式**:
   ```javascript
   // 例: 認証トークンの有効期限チェックテスト
   describe('Auth Token Validation', () => {
     it('should reject expired tokens', () => {
       const expiredToken = generateToken({ expiresIn: -1 });
       expect(() => validateToken(expiredToken)).toThrow('Token expired');
     });
   });
   ```

4. **テスト実行の確認**:
   ```bash
   # テストが失敗することを確認
   nr test -- --testNamePattern="Auth Token"
   # Expected: Test failure (Red Phase)
   ```
</testdesigner_phase>

<implementer_phase>
**Implementer Mode 💡 - Green Phase (テストを通す最小実装)**

1. **実装タスク**:
   - `<testdesigner_phase>`で作成したテストを確認
   - テストを通すための最小限の実装
   - すべてのテストが通ることを確認

2. **最小実装の原則**:
   - **YAGNI**: 今必要でない機能は実装しない
   - **最小コード**: テストを通すために必要な最小限のコードのみ
   - **動作優先**: この段階では綺麗さより動作を優先

3. **実装後のコミット**:
   ```bash
   # TDDサイクルごとにコミット
   git_commit "[TDD-Red] Add failing tests for token validation" "test/*"
   git_commit "[TDD-Green] Implement token expiration check" "src/*"
   ```

4. **テスト成功の確認**:
   ```bash
   # すべてのテストが通ることを確認
   nr test
   # Expected: All tests passing (Green Phase)
   ```
</implementer_phase>

<refactorer_phase>
**Refactorer Mode 🔧 - Refactor Phase (コード品質の向上)**

1. **リファクタリングタスク**:
   - `<implementer_phase>`の実装をリファクタリング
   - 重複の除去
   - 可読性の向上
   - パフォーマンスの最適化（必要な場合）

2. **リファクタリング原則**:
   - **ALWAYS**: テストが通る状態を維持
   - **NEVER**: 機能を変更しない
   - **MUST**: 各変更後にテストを実行

3. **リファクタリングチェックリスト**:
   - [ ] 変数名・関数名は明確か
   - [ ] 重複したコードはないか
   - [ ] 単一責任の原則を守っているか
   - [ ] テストは引き続き通るか

4. **リファクタリング後の確認**:
   ```bash
   # リファクタリング後もテストが通ることを確認
   echo "🧪 Running tests after refactoring..."
   run_tests "$PROJECT_TYPE"
   
   # コミット
   git_commit "[TDD-Refactor] Improve code quality and readability"
   ```
</refactorer_phase>

<tdd_completion>
**TDDサイクル完了処理**

1. **サイクルサマリー**:
   ```bash
   echo "📊 TDD Cycle Summary"
   echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   echo "✅ Red Phase: Tests written first"
   echo "✅ Green Phase: Minimal implementation done"
   echo "✅ Refactor Phase: Code quality improved"
   echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
   ```

2. **成果物の確認**:
   - すべてのテストが通ることを再確認
   - コードカバレッジの確認
   - ドキュメントの更新確認

3. **次のサイクルへ**:
   - 追加のバグや機能があれば新しいTDDサイクルを開始
   - **IMPORTANT**: 各サイクルは独立して実行
</tdd_completion>

## 実装スクリプト構造

```bash
#!/bin/bash
source .claude/scripts/role-utils.sh
source .claude/scripts/worktree-utils.sh

# 環境検証
verify_environment || exit 1

# オプション解析
parse_workflow_options "$@"

# タスク開始
echo "🚀 Starting TDD Development"
echo "Task: $TASK_DESCRIPTION"

# <bughunter_phase>の実行
switch_role "BugHunter" "バグの原因調査・要件の明確化"
# ... Bug Hunter実装 ...

# <testdesigner_phase>の実行 (Red Phase)
switch_role "TestDesigner" "失敗するテストの作成 (Red Phase)"
# ... Test Designer実装 ...

# <implementer_phase>の実行 (Green Phase)
switch_role "Implementer" "テストを通す最小実装 (Green Phase)"
# ... Implementer実装 ...

# <refactorer_phase>の実行 (Refactor Phase)
switch_role "Refactorer" "コード品質の向上 (Refactor Phase)"
# ... Refactorer実装 ...

# <tdd_completion>の実行
generate_task_summary "$TASK_DESCRIPTION"
```

<generated_artifacts>
すべての成果物は `./tmp/` ディレクトリに保存されます：

| ファイル | 説明 |
|---------|------|
| `{timestamp}-bughunter-report.md` | バグ調査結果・要件定義 |
| `{timestamp}-testdesigner-report.md` | テストケース設計書（Red Phase） |
| `{timestamp}-implementer-report.md` | 実装内容の記録（Green Phase） |
| `{timestamp}-refactorer-report.md` | リファクタリング内容（Refactor Phase） |
| `{timestamp}-task-summary.md` | TDDサイクル全体のサマリー |
| `latest-*-report.md` | 各役割の最新レポートへのリンク |
</generated_artifacts>

<tdd_principles>
**TDD原則の遵守**

このワークフローは以下のTDD原則を厳守します：

1. **Red**: 最初に失敗するテストを書く
   - **MUST**: 実装前にテストを作成
   - **MUST**: テストが失敗することを確認

2. **Green**: テストを通す最小限の実装
   - **MUST**: すべてのテストが通ることを確認
   - **NEVER**: 必要以上の実装をしない

3. **Refactor**: テストが通る状態を保ちながらコードを改善
   - **ALWAYS**: リファクタリング中もテストを実行
   - **NEVER**: 機能を変更しない
</tdd_principles>

<project_specific_considerations>
**プロジェクトタイプ別の考慮事項**

1. **JavaScript/TypeScript**:
   ```bash
   # テストフレームワーク: Jest, Mocha, Vitest
   nr test -- --watch  # ウォッチモードで開発
   ```

2. **Python**:
   ```bash
   # テストフレームワーク: pytest, unittest
   pytest -v  # 詳細な出力
   pytest --cov  # カバレッジ確認
   ```

3. **Go**:
   ```bash
   # 標準のtestingパッケージ
   go test -v ./...  # 詳細な出力
   go test -cover  # カバレッジ確認
   ```
</project_specific_considerations>

<troubleshooting>
**トラブルシューティング**

1. **テストが通らない**:
   - `./tmp/latest-implementer-report.md` を確認
   - 実装が正しいか検証
   - テスト自体に問題がないか確認

2. **リファクタリング後にテストが失敗**:
   - `git diff` で変更内容を確認
   - ロジックを変えていないか確認
   - 小さなステップで戻す

3. **どこまでリファクタリングすべきか**:
   - テストが通る範囲で実施
   - 可読性と保守性を優先
   - パフォーマンスは必要な場合のみ
</troubleshooting>

<comparison_with_legacy>
**従来版との違い**

| 機能 | 従来版 | TDD役割進化型 |
|------|--------|--------------|
| フォーカス | 汎用的 | TDDサイクル特化 |
| 役割数 | 4 | 4（TDD特化） |
| テスト作成 | 実装後 | 実装前（Red Phase） |
| コミット戦略 | まとめて | Red-Green-Refactor毎 |
</comparison_with_legacy>

<important_notes>
**注意事項**

- テストファーストを厳守します
- 各フェーズは明確に分離されています
- リファクタリング時もテストの成功を維持します
- 成果物はすべて `./tmp/` に保存されます
- **ALWAYS**: Red → Green → Refactor の順序を守る
- **NEVER**: テストなしでコードを書かない
- **MUST**: 各フェーズでテストを実行して確認
</important_notes>