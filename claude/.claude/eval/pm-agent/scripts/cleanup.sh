#!/bin/bash
# cleanup.sh - E2Eテスト後のクリーンアップ
#
# 使用方法:
#   ./eval/pm-agent/scripts/cleanup.sh --repo <owner/repo> --project <N> --owner <login>
#
# 説明:
#   テスト用リポジトリの Issue、Projects items、ラベルを削除する。

set -euo pipefail

REPO=""
PROJECT_NUM=""
PROJECT_OWNER="@me"

usage() {
  echo "使用方法: $0 --repo <owner/repo> --project <N> [--owner <login>]"
  echo ""
  echo "オプション:"
  echo "  --repo <owner/repo>   テスト用リポジトリ"
  echo "  --project <N>         Projects 番号"
  echo "  --owner <login>       Projects オーナー（デフォルト: @me）"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --project) PROJECT_NUM="$2"; shift 2 ;;
    --owner) PROJECT_OWNER="$2"; shift 2 ;;
    *) usage ;;
  esac
done

[[ -z "$REPO" ]] && { echo "エラー: --repo は必須です"; usage; }
[[ -z "$PROJECT_NUM" ]] && { echo "エラー: --project は必須です"; usage; }

echo "🧹 クリーンアップ開始"
echo "  リポジトリ: ${REPO}"
echo "  Project: ${PROJECT_NUM} (owner: ${PROJECT_OWNER})"
echo ""

# 1. 全Issueを削除
echo "📝 Issue の削除..."
ISSUES=$(gh issue list --repo "$REPO" --state all --json number --jq '.[].number' 2>/dev/null || echo "")
if [[ -n "$ISSUES" ]]; then
  echo "$ISSUES" | while read -r num; do
    gh issue delete "$num" --repo "$REPO" --yes 2>/dev/null && echo "  ✅ #${num} 削除" || echo "  ⚠️ #${num} 削除失敗"
  done
else
  echo "  (Issueなし)"
fi

# 2. Projects items を削除
echo ""
echo "📋 Projects items の削除..."
ITEMS=$(gh project item-list "$PROJECT_NUM" --owner "$PROJECT_OWNER" --format json 2>/dev/null | jq -r '.items[].id' 2>/dev/null || echo "")
if [[ -n "$ITEMS" ]]; then
  echo "$ITEMS" | while read -r id; do
    gh project item-delete "$PROJECT_NUM" --owner "$PROJECT_OWNER" --id "$id" 2>/dev/null && echo "  ✅ ${id} 削除" || echo "  ⚠️ ${id} 削除失敗"
  done
else
  echo "  (itemsなし)"
fi

# 3. type:* ラベルを削除
echo ""
echo "🏷️ type:* ラベルの削除..."
LABELS=$(gh label list --repo "$REPO" --json name --jq '.[].name' 2>/dev/null | grep "^type:" || echo "")
if [[ -n "$LABELS" ]]; then
  echo "$LABELS" | while read -r label; do
    gh label delete "$label" --repo "$REPO" --yes 2>/dev/null && echo "  ✅ ${label} 削除" || echo "  ⚠️ ${label} 削除失敗"
  done
else
  echo "  (type:*ラベルなし)"
fi

# 4. Milestone を削除
echo ""
echo "🏁 Milestone の削除..."
MILESTONES=$(gh api "repos/$REPO/milestones" --jq '.[].number' 2>/dev/null || echo "")
if [[ -n "$MILESTONES" ]]; then
  echo "$MILESTONES" | while read -r ms; do
    gh api "repos/$REPO/milestones/$ms" -X DELETE 2>/dev/null && echo "  ✅ Milestone #${ms} 削除" || echo "  ⚠️ Milestone #${ms} 削除失敗"
  done
else
  echo "  (Milestoneなし)"
fi

echo ""
echo "✅ クリーンアップ完了"
