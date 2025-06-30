# multi-tdd.md / multi-refactor.md 改善実施計画

## 概要

multi-feature.mdで実施した改善内容を、他のmultiコマンドに適用するための実施計画。

## 1. multi-tdd.md 改善計画

### 1.1 共通関数への移行

#### 対象となる重複コード

- 環境設定・初期化処理（4箇所）
- Gitコミット処理（RED/GREEN/REFACTORフェーズで各1箇所）
- レポートディレクトリ作成処理
- 完了レポート生成（300-340行）

#### 追加が必要な共通関数

```bash
# worktree-utils.shに追加
commit_tdd_phase() {
    local phase_type="$1"  # RED, GREEN, REFACTOR
    local worktree_path="$2"
    local feature_name="$3"
    local task_description="$4"
    # TDD固有のコミット処理
}

setup_report_dirs() {
    local worktree_path="$1"
    local feature_name="$2"
    # レポートディレクトリ構造の作成
}
```

### 1.2 XMLタグ構造の導入

#### 全体構造

```xml
<tdd_workflow>
  <phase name="explore">...</phase>
  <phase name="plan">...</phase>
  <phase name="tdd">
    <tdd_cycle>
      <red_phase>...</red_phase>
      <green_phase>...</green_phase>
      <refactor_phase>...</refactor_phase>
    </tdd_cycle>
  </phase>
</tdd_workflow>
```

#### 各フェーズへの統一構造適用

- objectives, tools, quality_gates, implementation, outputタグの追加
- TDDサイクルを明確に構造化

### 1.3 簡潔性の改善

- 初期化処理：61行 → initialize_phase関数呼び出し（3行）
- 各フェーズの環境設定：10行 → 2行
- 完了レポート：74行 → 外部テンプレート参照

### 1.4 強調語の適用

- **ALWAYS**: テスト先行作成、段階的コミット、カバレッジ確認
- **NEVER**: 実装先行、テスト無しコミット、品質基準スキップ
- **MUST**: RED→GREEN→REFACTORの順序遵守、各フェーズ独立コミット

## 2. multi-refactor.md 改善計画

### 2.1 共通関数への移行

#### 対象となる重複コード

- 環境設定・初期化処理（各フェーズ）
- Gitコミット処理
- フェーズ前処理チェック
- 完了レポート生成

#### 追加が必要な共通関数

```bash
# worktree-utils.shに追加
verify_previous_phase() {
    local phase_name="$1"
    local worktree_path="$2"
    # 前フェーズの完了確認
}
```

### 2.2 XMLタグ構造の導入

#### 全体構造

```xml
<refactoring_workflow>
  <phase name="analysis">...</phase>
  <phase name="planning">...</phase>
  <phase name="implementation">...</phase>
  <phase name="verification">...</phase>
</refactoring_workflow>
```

#### 特有の構造

```xml
<refactoring_patterns>
  <pattern name="extract_method">...</pattern>
  <pattern name="rename">...</pattern>
  <pattern name="simplify">...</pattern>
</refactoring_patterns>

<quality_metrics>
  <metric name="complexity" target="改善目標"/>
  <metric name="performance" target="改善目標"/>
</quality_metrics>
```

### 2.3 簡潔性の改善

- 100行を超えるbashコードブロックを関数呼び出しに置換
- "ClaudeCodeアクセス制限対応"の重複説明を1箇所に集約
- worktree作業説明の重複を削除

### 2.4 強調語の適用

- **ALWAYS**: 既存テストのパス維持、段階的コミット
- **NEVER**: 未テストのリファクタリング、破壊的変更
- **MUST**: ベースラインテスト実行、後方互換性維持

## 3. 実施手順

### Phase 1: worktree-utils.sh拡張（1日）

1. TDD固有の共通関数追加
2. リファクタリング固有の共通関数追加
3. 関数のテスト実施

### Phase 2: multi-tdd.md改善（1日）

1. XMLタグ構造の導入
2. 共通関数への置換
3. TDDサイクルの構造化
4. 強調語の体系的適用

### Phase 3: multi-refactor.md改善（1日）

1. XMLタグ構造の導入
2. 共通関数への置換
3. リファクタリングパターンの構造化
4. 強調語の体系的適用

### Phase 4: 統合テスト（1日）

1. 各コマンドの動作確認
2. エラーハンドリングの検証
3. ドキュメント更新

## 4. 期待される成果

### 4.1 コード削減

- multi-tdd.md: 400行 → 200行以下（50%削減）
- multi-refactor.md: 推定300行 → 150行以下（50%削減）

### 4.2 保守性向上

- 共通処理の一元管理
- 変更時の影響範囲の局所化
- パターンの再利用性向上

### 4.3 一貫性の確保

- 全multiコマンドで統一されたXML構造
- 共通の品質ゲート管理
- 統一された強調語使用