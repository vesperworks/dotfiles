# マルチエージェントワークフローXML定義言語仕様

## 概要

マルチエージェントワークフローを宣言的に定義するためのXMLベース定義言語。これにより、各コマンド（multi-tdd.md、multi-feature.md、multi-refactor.md）を100行以下のテンプレートに圧縮し、実行ロジックはすべてworktree-utils.shに移動する。

## 1. 基本構造

```xml
<workflow_definition version="1.0">
  <metadata>
    <workflow_type>tdd|feature|refactoring</workflow_type>
    <task_description>$TASK_DESCRIPTION</task_description>
    <created_at>$TIMESTAMP</created_at>
  </metadata>

  <claudecode_constraints>
    <!-- ClaudeCodeのアクセス制限を1箇所で定義 -->
    <constraint type="directory_access">
      ClaudeCodeは直接worktreeディレクトリに移動できません。
      - ファイル読み取り: Read $WORKTREE_PATH/ファイル名
      - ファイル書き込み: Write $WORKTREE_PATH/ファイル名
      - ファイル編集: Edit $WORKTREE_PATH/ファイル名
    </constraint>
  </claudecode_constraints>

  <quality_gates>
    <gate phase="all" enforcement="MUST">
      <requirement priority="CRITICAL">All existing tests must pass</requirement>
      <requirement priority="ALWAYS">Code coverage >= 80%</requirement>
      <requirement priority="ALWAYS">Security validation passed</requirement>
    </gate>
  </quality_gates>

  <phases>
    <phase name="explore" order="1">
      <objectives>
        <objective>現在のコードベースを調査・分析</objective>
        <objective>問題の根本原因を特定</objective>
      </objectives>
      <agent_prompt>$EXPLORER_PROMPT</agent_prompt>
      <implementation>
        run_phase "explore" "$WORKTREE_PATH" "$TASK_DESCRIPTION"
      </implementation>
      <output>
        <file>report/$FEATURE_NAME/phase-results/explore-results.md</file>
        <commit_tag>EXPLORE</commit_tag>
      </output>
    </phase>
  </phases>
</workflow_definition>
```

## 2. ワークフロータイプ別構造

### 2.1 TDDワークフロー

```xml
<tdd_workflow>
  <test_strategy>
    <principle enforcement="ALWAYS">Test First Development</principle>
    <principle enforcement="NEVER">Implementation before tests</principle>
  </test_strategy>

  <file_structure>
    <tests>test/$FEATURE_NAME/unit/</tests>
    <implementation>src/$FEATURE_NAME/</implementation>
    <reports>report/$FEATURE_NAME/</reports>
  </file_structure>

  <tdd_cycle>
    <red_phase>
      <objective>失敗するテストを先に作成</objective>
      <quality_gate enforcement="MUST">
        <requirement>テストが失敗することを確認</requirement>
        <requirement>テストが要件を正確に表現</requirement>
      </quality_gate>
      <commit_tag>TDD-RED</commit_tag>
    </red_phase>

    <green_phase>
      <objective>テストを通す最小実装</objective>
      <quality_gate enforcement="MUST">
        <requirement>全テストがパス</requirement>
        <requirement>最小限のコードで実装</requirement>
      </quality_gate>
      <commit_tag>TDD-GREEN</commit_tag>
    </green_phase>

    <refactor_phase>
      <objective>コード品質向上</objective>
      <quality_gate enforcement="MUST">
        <requirement>テストが継続的にパス</requirement>
        <requirement>コード複雑度の削減</requirement>
      </quality_gate>
      <commit_tag>TDD-REFACTOR</commit_tag>
    </refactor_phase>
  </tdd_cycle>
</tdd_workflow>
```

### 2.2 機能開発ワークフロー

```xml
<feature_development_workflow>
  <development_strategy>
    <principle enforcement="ALWAYS">Incremental development with tests</principle>
    <principle enforcement="NEVER">Deploy untested features</principle>
  </development_strategy>

  <phases>
    <phase name="explore" order="1">
      <quality_gate>
        <requirement priority="MUST">Complete domain understanding</requirement>
        <requirement priority="MUST">Clear requirements definition</requirement>
      </quality_gate>
    </phase>

    <phase name="design" order="2">
      <quality_gate>
        <requirement priority="MUST">API contracts defined</requirement>
        <requirement priority="MUST">Data models validated</requirement>
      </quality_gate>
    </phase>

    <phase name="implement" order="3">
      <quality_gate>
        <requirement priority="ALWAYS">Unit tests coverage >= 80%</requirement>
        <requirement priority="ALWAYS">Integration tests passed</requirement>
      </quality_gate>
    </phase>

    <phase name="verify" order="4">
      <quality_gate>
        <requirement priority="CRITICAL">No security vulnerabilities</requirement>
        <requirement priority="MUST">Performance benchmarks met</requirement>
      </quality_gate>
    </phase>
  </phases>
</feature_development_workflow>
```

### 2.3 リファクタリングワークフロー

```xml
<refactoring_workflow>
  <refactoring_principles>
    <principle enforcement="ALWAYS">Maintain existing behavior</principle>
    <principle enforcement="NEVER">Break backward compatibility without migration plan</principle>
    <principle enforcement="MUST">Incremental changes with validation</principle>
  </refactoring_principles>

  <refactoring_patterns>
    <pattern name="extract_method">
      <when>Method length > 20 lines</when>
      <action>Extract to smaller focused methods</action>
    </pattern>
    <pattern name="rename">
      <when>Unclear naming</when>
      <action>Use descriptive names</action>
    </pattern>
    <pattern name="simplify">
      <when>Complex conditional logic</when>
      <action>Use guard clauses or strategy pattern</action>
    </pattern>
  </refactoring_patterns>

  <quality_metrics>
    <metric name="complexity" target="20% reduction"/>
    <metric name="performance" target="10% improvement"/>
    <metric name="test_coverage" target="maintain or improve"/>
  </quality_metrics>
</refactoring_workflow>
```

## 3. 強調語の階層的体系

```xml
<emphasis_hierarchy>
  <level name="CRITICAL" color="red">
    <!-- システム破壊リスクがある指示 -->
    <usage>Security vulnerabilities, data loss risks</usage>
    <example>CRITICAL: Never commit secrets or API keys</example>
  </level>

  <level name="ALWAYS" color="orange">
    <!-- 必須実行項目 -->
    <usage>Required actions that must be performed</usage>
    <example>ALWAYS: Run tests before committing</example>
  </level>

  <level name="NEVER" color="red">
    <!-- 禁止事項 -->
    <usage>Actions that must be avoided</usage>
    <example>NEVER: Edit files directly in main branch</example>
  </level>

  <level name="MUST" color="yellow">
    <!-- 品質基準要件 -->
    <usage>Quality gates and standards</usage>
    <example>MUST: Maintain 80% code coverage</example>
  </level>

  <level name="IMPORTANT" color="blue">
    <!-- 重要な注意事項 -->
    <usage>Significant considerations</usage>
    <example>IMPORTANT: Consider performance impact</example>
  </level>
</emphasis_hierarchy>
```

## 4. 実行エンジン統合

### 4.1 コマンドファイルの簡潔化

```markdown
# Multi-Agent TDD Workflow

<workflow_definition version="1.0">
  <metadata>
    <workflow_type>tdd</workflow_type>
    <task_description>$ARGUMENTS</task_description>
  </metadata>
  
  <include file=".claude/workflows/tdd-workflow.xml"/>
</workflow_definition>

## 実行

```bash
# ワークフロー実行エンジンを呼び出し
execute_workflow "$WORKFLOW_DEFINITION"
```

全ての実行ロジックは `worktree-utils.sh` の `execute_workflow()` 関数が処理。
```

### 4.2 実行エンジンの責務

```bash
# worktree-utils.sh に追加する関数

execute_workflow() {
    local workflow_def="$1"
    
    # XMLパース
    local workflow_type=$(parse_xml "$workflow_def" "workflow_type")
    local phases=$(parse_xml "$workflow_def" "phases")
    
    # 各フェーズを順次実行
    for phase in $phases; do
        initialize_phase "$ENV_FILE"
        run_phase "$phase" "$WORKTREE_PATH" "$TASK_DESCRIPTION"
        commit_phase_results "$phase" "$WORKTREE_PATH"
    done
}

# 共通関数の実装
initialize_phase() {
    source .claude/scripts/worktree-utils.sh || handle_error
    load_env_file "$1" || handle_error
    verify_previous_phase || handle_error
}

commit_phase_results() {
    local phase="$1"
    local worktree="$2"
    local tag=$(get_commit_tag "$phase")
    
    git -C "$worktree" add .
    git -C "$worktree" commit -m "[$tag] $TASK_DESCRIPTION" || log_warning
}
```

## 5. 移行戦略

### 5.1 段階的移行

1. **Phase 1**: 共通関数の外部化（worktree-utils.sh）
2. **Phase 2**: XMLテンプレートの作成（.claude/workflows/）
3. **Phase 3**: 各コマンドファイルの簡潔化（100行以下）
4. **Phase 4**: 実行エンジンの完全統合

### 5.2 互換性維持

- 既存のコマンド構造を維持しながら内部実装を置換
- オプション（--keep-worktree等）は完全互換
- 段階的な移行でリスクを最小化

## 6. 期待される効果

1. **保守性向上**
   - コマンドファイル: 600行 → 100行以下
   - 重複コード: 90%削減
   - 変更時の影響範囲: 局所化

2. **理解容易性**
   - 宣言的な構造で意図が明確
   - 実行ロジックとワークフロー定義の分離
   - 一貫した構造で学習コスト削減

3. **拡張性**
   - 新しいワークフロータイプの追加が容易
   - 品質ゲートの統一管理
   - MCP連携の標準化

## 7. 実装例

### 7.1 簡潔化されたmulti-tdd.md（目標: 100行以下）

```markdown
# Multi-Agent TDD Workflow

あなたは現在、マルチエージェント TDD ワークフローのオーケストレーターです。

## 実行タスク
$ARGUMENTS

<workflow_definition version="1.0">
  <metadata>
    <workflow_type>tdd</workflow_type>
    <task_description>$ARGUMENTS</task_description>
  </metadata>
  
  <include file=".claude/workflows/tdd-definition.xml"/>
  
  <execution>
    <!-- 全ての実行ロジックはworktree-utils.shに委譲 -->
    execute_tdd_workflow "$ARGUMENTS" "$OPTIONS"
  </execution>
</workflow_definition>

## 使用例
`/project:multi-tdd "認証機能のJWT有効期限チェック不具合を修正"`

## 結果
ユーザーは指示後すぐに次のタスクに移行可能。このタスクは独立worktree内で自動完了し、PR準備まで完了。
```

これにより、各コマンドファイルは純粋なワークフロー定義となり、実行の詳細はすべて共通エンジンが処理します。