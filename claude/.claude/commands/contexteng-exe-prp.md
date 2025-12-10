# Execute PRP with vw-dev-orchestra

PRPを読み込み、vw-dev-orchestraでTDD実装・検証ループを実行します。

## PRP File: $ARGUMENTS

## PRP検出ロジック

`$ARGUMENTS` が空の場合:
1. `PRPs/` ディレクトリ内の最新 `.md` ファイルを検出
2. 見つからない場合はエラー

`$ARGUMENTS` がある場合:
1. 指定されたパスを使用

## 実行プロセス

### Phase 1: PRP読み込み
- 指定されたPRPファイルを読み込む
- すべてのコンテキストと要件を理解する
- PRPの指示に従い、必要に応じてリサーチを拡張する
- 完全に実装するために必要なすべてのコンテキストを確保する

### Phase 2: 計画立案
- 実行前に十分に考える。すべての要件に対応する包括的な計画を作成する。
- 複雑なタスクをTodoWriteツールで小さく管理可能なステップに分解する。
- 既存コードから実装パターンを特定し、それに従う。

### Phase 3: TDD実装
- PRPのTasksをTDD（Red-Green-Refactor）で実装:
  1. **RED**: まず失敗するテストを書く
  2. **GREEN**: テストを通す最小限のコードを書く
  3. **REFACTOR**: コード品質を改善
- 各タスク完了後、次のタスクへ進む

### Phase 4: 検証
- vw-dev-reviewer と vw-dev-tester を並列で呼び出す:
  - `Task(subagent_type="vw-dev-reviewer", prompt="品質ゲート実行", run_in_background=true)`
  - `Task(subagent_type="vw-dev-tester", prompt="E2Eテスト実行", run_in_background=true)`
- 両方の完了を待ち、結果を確認

### Phase 5: デバッグループ
問題の重大度に応じて対応:
- **LOW** (Lint/Format): 自動修正 → 再検証
- **MEDIUM** (Test失敗): 自動修正（3回まで）→ ユーザー確認
- **HIGH** (Build/E2E失敗): ユーザー確認必須

### Phase 6: 完了
- すべてのチェックリスト項目が完了していることを確認
- 最終検証スイートを実行
- 完了状況を報告
- PRPを再読み込みして、すべてが実装されていることを確認

## MUST: Language Requirements
- **Think in English**: All internal reasoning and planning must be done in English
- **Communicate in Japanese**: All user-facing communication and responses must be in Japanese

Note: 検証失敗時はPRPのエラーパターンを使用して修正し、再試行する。
