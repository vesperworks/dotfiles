#!/bin/bash
set -euo pipefail

# Smart Commit Script
# Usage: smart-commit.sh [context]

smart_commit() {
  # Gitリポジトリ検証
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "❌ Error: Not in a git repository"
    return 1
  fi

  local context="$1"
  local timestamp=$(date +%Y%m%d-%H%M%S)
  local msg_file="./tmp/commit-msg-$timestamp.txt"

  # tmpディレクトリ作成（エラーハンドリング付き）
  mkdir -p ./tmp || {
    echo "❌ Error: Failed to create ./tmp directory"
    return 1
  }
  
  # 変更内容を取得・分析
  local status=$(git status --porcelain)
  local diff_files=$(git diff --name-only --cached && git diff --name-only)
  
  # 変更タイプを判定
  local type="chore"
  if echo "$status" | grep -q "^A "; then 
    type="feat"
  elif echo "$status" | grep -q "^M "; then 
    type="fix"
  elif echo "$diff_files" | grep -q "\.md$"; then 
    type="docs"
  elif echo "$diff_files" | grep -q "test"; then 
    type="test"
  fi
  
  # メッセージ生成
  local subject=$(echo "$diff_files" | head -1 | xargs basename 2>/dev/null | cut -c1-40)
  [[ -z "$subject" ]] && subject="miscellaneous changes"
  
  echo "$type: update $subject" > "$msg_file"
  
  # 引数があれば詳細として追加
  [[ -n "$context" ]] && echo -e "\n$context" >> "$msg_file"

  # コミット実行（エラーハンドリング付き）
  if ! git add -A; then
    echo "❌ Error: git add failed"
    return 1
  fi

  if ! git commit -F "$msg_file"; then
    echo "❌ Error: git commit failed"
    return 1
  fi

  echo "✅ Committed with message saved to: $msg_file"
}

# 直接実行時
smart_commit "$@"