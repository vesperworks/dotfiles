#!/bin/bash
set -euo pipefail

# Smart Commit Script
# Usage: smart-commit.sh [context]
# Supports both jj (Jujutsu) and git via vcs-detect.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=vcs-detect.sh
source "$SCRIPT_DIR/vcs-detect.sh"

smart_commit() {
  local vcs
  vcs=$(detect_vcs) || {
    echo "Error: Not in a VCS repository" >&2
    return 1
  }

  local context="${1:-}"
  local timestamp
  timestamp=$(date +%Y%m%d-%H%M%S)
  local msg_file="./.brain/commits/msg-$timestamp.txt"

  # .brain/commitsディレクトリ作成（エラーハンドリング付き）
  mkdir -p ./.brain/commits || {
    echo "Error: Failed to create ./.brain/commits directory" >&2
    return 1
  }

  # 変更内容を取得・分析
  local changed_files
  changed_files=$(get_changed_files)

  if [[ -z "$changed_files" ]]; then
    echo "No changes to commit"
    return 0
  fi

  # 変更タイプを判定
  local type="chore"
  case "$vcs" in
    jj)
      # jj: jj diff --name-only の出力から判定
      if echo "$changed_files" | grep -q "\.md$"; then
        type="docs"
      elif echo "$changed_files" | grep -q "test"; then
        type="test"
      else
        type="feat"
      fi
      ;;
    git)
      local status
      status=$(git status --porcelain)
      if echo "$status" | grep -q "^A "; then
        type="feat"
      elif echo "$status" | grep -q "^M "; then
        type="fix"
      elif echo "$changed_files" | grep -q "\.md$"; then
        type="docs"
      elif echo "$changed_files" | grep -q "test"; then
        type="test"
      fi
      ;;
  esac

  # メッセージ生成
  local subject
  subject=$(echo "$changed_files" | head -1 | xargs basename 2>/dev/null | cut -c1-40)
  [[ -z "$subject" ]] && subject="miscellaneous changes"

  echo "$type: update $subject" > "$msg_file"

  # 引数があれば詳細として追加
  [[ -n "$context" ]] && echo -e "\n$context" >> "$msg_file"

  local commit_msg
  commit_msg=$(cat "$msg_file")

  # コミット実行（VCS分岐）
  case "$vcs" in
    jj)
      # jj: ステージング不要、直接コミット
      if ! jj commit -m "$commit_msg"; then
        echo "Error: jj commit failed" >&2
        return 1
      fi
      ;;
    git)
      if ! git add -A; then
        echo "Error: git add failed" >&2
        return 1
      fi
      if ! git commit -F "$msg_file"; then
        echo "Error: git commit failed" >&2
        return 1
      fi
      ;;
  esac

  echo "Committed ($vcs) with message saved to: $msg_file"
}

# 直接実行時
smart_commit "$@"
