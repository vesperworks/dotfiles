# multi-feature.md リファクタリング実施内容

## 概要

multi-feature.mdファイルにおいて、XMLタグ構造の統一化とDRY原則を適用した。共通処理をworktree-utils.shに外部化し、コードの重複を削減した。

## 1. 基本構造の変更

### 1.1 XMLタグ構造の統一

各フェーズに以下の統一されたXML構造を適用した：

```xml
<phase name="フェーズ名">
  <objectives>
    - 目的1
    - 目的2
  </objectives>
  
  <tools>
    - ツール1
    - ツール2
  </tools>
  
  <quality_gates>
    - 品質基準1
    - 品質基準2
  </quality_gates>
  
  <implementation>
    <!-- 実装内容 -->
  </implementation>
  
  <output>
    - 出力1
    - 出力2
  </output>
</phase>
```

## 2. 共通関数の外部化

### 2.1 worktree-utils.shへの関数追加

以下の2つの関数を新規追加した：

```bash
# フェーズ初期化共通関数
initialize_phase() {
    local env_file="${1:-}"
    local phase_name="${2:-Unknown}"
    
    source .claude/scripts/worktree-utils.sh || {
        log_error "worktree-utils.sh not found"
        return 1
    }
    
    if ! load_env_file "$env_file"; then
        log_error "Failed to load environment file"
        return 1
    fi
    
    log_info "Phase initialized: $phase_name"
    return 0
}

# フェーズ結果のコミット共通関数
commit_phase_results() {
    local phase_tag="$1"
    local worktree_path="$2"
    local file_path="$3"
    local commit_message="$4"
    local optional_paths="${5:-}"
    # 実装内容（省略）
}
```

## 3. 重複コードの削除

### 3.1 環境設定処理の共通化

5箇所で重複していた以下のコード：

```bash
# 変更前（各フェーズで重複）
source .claude/scripts/worktree-utils.sh || {
    echo "Error: worktree-utils.sh not found"
    exit 1
}
if ! load_env_file "${ENV_FILE:-}"; then
    echo "Error: Failed to load environment file"
    exit 1
fi
```

以下に置換：

```bash
# 変更後
initialize_phase "$ENV_FILE" "フェーズ名"
```

### 3.2 コミット処理の共通化

各フェーズで重複していたコミット処理を共通関数呼び出しに置換：

```bash
# 変更後の例
commit_phase_results "EXPLORE" "$WORKTREE_PATH" \
    "$WORKTREE_PATH/report/$FEATURE_NAME/phase-results/explore-results.md" \
    "Feature analysis complete: $ARGUMENTS"
```

## 4. 強調語の体系化

### 4.1 使用した強調語

以下の4種類の強調語を体系的に使用：

- **ALWAYS**: 必須実行項目（テスト実行、コミット前の検証）
- **NEVER**: 禁止事項（未テストコードのコミット、main直接編集）
- **MUST**: 品質基準要件（カバレッジ80%以上、セキュリティ検証）
- **IMPORTANT**: 重要な注意事項

## 5. コード圧縮の結果

### 5.1 worktree作成セクション

```
変更前: 61行
変更後: 20行（67%削減）
```

### 5.2 完了レポート生成

```
変更前: 74行の埋め込みヒアドキュメント
変更後: 30行の関数定義（59%削減）
```

## 6. 実施した変更の効果

### 6.1 保守性の向上

- 共通処理の一元管理により、変更時の影響範囲が局所化
- DRY原則により、修正箇所が削減

### 6.2 可読性の向上

- XMLタグ構造により、各フェーズの構成要素が明確化
- 強調語の体系的使用により、重要度が視覚的に判別可能

### 6.3 拡張性の確保

- 共通関数により、新しいフェーズの追加が容易
- 統一されたXML構造により、パターンの再利用が可能