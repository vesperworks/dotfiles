# Statement of Work (SOW) - 改訂版2
## 役割進化型multi-系コマンドリデザイン（./tmp/統一版）

### プロジェクト概要

**プロジェクト名**: 役割進化型ワークフローへの移行  
**期間**: 3-4日  
**目的**: worktreeとccmanager役割分担を廃止し、シンプルで直感的なワークフローを実現  
**重要**: すべての中間成果物は`./tmp/`ディレクトリに保存

### 📁 ディレクトリ構造

```
project/
├── .claude/
│   ├── commands/          # コマンド定義
│   │   ├── multi-feature.md
│   │   ├── multi-tdd.md
│   │   └── multi-refactor.md
│   └── scripts/           # ユーティリティ
│       └── role-utils.sh  # 新規作成
└── tmp/                   # すべての中間成果物
    ├── {timestamp}-explorer-report.md
    ├── {timestamp}-analysis-report.md
    ├── {timestamp}-design-doc.md
    ├── {timestamp}-implementation-log.md
    ├── {timestamp}-review-report.md
    └── {timestamp}-task-summary.md
```

### 中間成果物の管理

#### 1. ファイル命名規則
```bash
# タイムスタンプ形式: YYYYMMDD-HHMMSS
# 例: ./tmp/20250111-143022-explorer-report.md

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT_PATH="./tmp/${TIMESTAMP}-${ROLE}-report.md"
```

#### 2. 各役割の成果物

| 役割 | 成果物パス | 内容 |
|------|-----------|------|
| Explorer | `./tmp/{timestamp}-explorer-report.md` | 調査結果、既存実装の分析 |
| Analyst | `./tmp/{timestamp}-analysis-report.md` | 影響範囲、リスク分析 |
| Designer | `./tmp/{timestamp}-design-doc.md` | 設計書、インターフェース定義 |
| Developer | `./tmp/{timestamp}-implementation-log.md` | 実装内容、変更履歴 |
| Reviewer | `./tmp/{timestamp}-review-report.md` | レビュー結果、品質チェック |
| Summary | `./tmp/{timestamp}-task-summary.md` | タスク全体のサマリー |

### 実装詳細

#### role-utils.sh の主要関数

```bash
#!/bin/bash
# role-utils.sh - 役割進化型ワークフロー用ユーティリティ

# tmpディレクトリの確保
ensure_tmp_dir() {
    mkdir -p ./tmp
    echo "✅ Ensured ./tmp directory exists"
}

# 成果物の保存（./tmp/に統一）
save_artifact() {
    local role="$1"
    local content="$2"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local filepath="./tmp/${timestamp}-${role,,}-report.md"
    
    ensure_tmp_dir
    echo "$content" > "$filepath"
    echo "📄 Saved: $filepath"
    
    # 最新のリンクも作成（参照しやすくするため）
    ln -sf "${timestamp}-${role,,}-report.md" "./tmp/latest-${role,,}-report.md"
}

# 前の役割の成果物を読み込み
load_previous_artifact() {
    local role="$1"
    local filepath="./tmp/latest-${role,,}-report.md"
    
    if [[ -f "$filepath" ]]; then
        cat "$filepath"
    else
        echo ""
    fi
}

# タスクサマリーの生成
generate_task_summary() {
    local task_description="$1"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local summary_path="./tmp/${timestamp}-task-summary.md"
    
    ensure_tmp_dir
    
    cat > "$summary_path" << EOF
# Task Summary
**Task**: $task_description
**Date**: $(date)

## Artifacts Generated
$(ls -la ./tmp/*-report.md 2>/dev/null | tail -5)

## Next Steps
- Review all reports in ./tmp/
- Commit changes if satisfied
- Clean up ./tmp/ after completion
EOF
    
    echo "📋 Task summary saved: $summary_path"
}

# ./tmp/のクリーンアップ（オプション）
cleanup_tmp() {
    local days_old="${1:-7}"
    echo "🧹 Cleaning up files older than $days_old days in ./tmp/..."
    find ./tmp -name "*-report.md" -mtime +$days_old -delete 2>/dev/null
}
```

### コマンド実装例

#### multi-feature.md での ./tmp/ 使用

```bash
#!/bin/bash
TASK_DESCRIPTION="$@"

# Explorer Phase
echo "🔍 Starting Explorer phase..."
# ユーザーが調査を実行
read -p "Save exploration results? (y/n) " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    save_artifact "explorer" "$EXPLORATION_RESULTS"
fi

# Analyst Phase  
echo "📊 Starting Analyst phase..."
# 前の成果物を参照
PREVIOUS=$(load_previous_artifact "explorer")
echo "Previous exploration: ${PREVIOUS:0:100}..."
# ユーザーが分析を実行
save_artifact "analyst" "$ANALYSIS_RESULTS"

# ... 以降も同様にすべて./tmp/に保存 ...

# 完了時
generate_task_summary "$TASK_DESCRIPTION"
echo "✅ All artifacts saved in ./tmp/"
```

### ./tmp/ ディレクトリの利点

1. **一元管理**: すべての中間成果物が1箇所に
2. **.gitignore対応**: `./tmp/`は通常gitignoreされている
3. **クリーンアップ容易**: `rm -rf ./tmp/*-report.md`で一括削除
4. **参照性**: タイムスタンプ付きで履歴管理
5. **ポータビリティ**: プロジェクトルート相対パス

### 移行時の注意事項

1. **既存ファイルの移動**
   - 現在散在している`*-report.md`を`./tmp/`へ移動
   - 移行スクリプトを提供

2. **エラーハンドリング**
   ```bash
   if [[ ! -d "./tmp" ]]; then
       echo "⚠️  Creating ./tmp directory..."
       mkdir -p ./tmp
   fi
   ```

3. **定期的なクリーンアップ**
   ```bash
   # 週次でのクリーンアップ推奨
   /multi-feature --cleanup-tmp 7
   ```

### タイムライン（./tmp/対応版）

```
Day 1: 基盤作成
  - role-utils.sh 作成（./tmp/管理機能含む）
  - ensure_tmp_dir()実装
  - save_artifact()の./tmp/統一

Day 2-3: コマンド実装
  - すべての成果物パスを./tmp/に変更
  - load_previous_artifact()で連携
  - generate_task_summary()実装

Day 4: 仕上げ
  - ./tmp/クリーンアップ機能
  - ドキュメントで./tmp/使用を明記
  - サンプル実行で./tmp/動作確認
```

### 成功基準（./tmp/関連）

1. **すべての中間成果物が./tmp/に保存される**
2. **タイムスタンプによる履歴管理が機能**
3. **latest-*リンクで最新ファイルに簡単アクセス**
4. **クリーンアップコマンドが正常動作**
5. **既存の作業ディレクトリを汚さない**

---
作成日: 2025年1月11日  
更新: ./tmp/統一版として改訂