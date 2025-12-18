#!/bin/bash
# pm-setup-labels.sh - Bulk label creation for pm-agent
# Usage: pm-setup-labels.sh [owner/repo]
#
# Creates all labels required by the pm-agent 4-tier ticket structure.
# Idempotent: skips existing labels.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pm-utils.sh"

REPO="${1:-$(get_repo)}"

# Label definitions: name:color:description
# Type labels (SKILL.md compliant)
labels=(
  "type:epic:5319E7:マイルストーン"
  "type:feature:0052CC:機能要件"
  "type:story:00875A:ユーザーストーリー"
  "type:task:97A0AF:実装タスク"
  "type:bug:D73A4A:バグ修正"
  "priority:high:B60205:最優先"
  "priority:medium:FBCA04:通常"
  "priority:low:0E8A16:低優先度"
)

echo "Creating labels for $REPO..."
echo ""

created_count=0
skipped_count=0

for item in "${labels[@]}"; do
  IFS=':' read -r name color desc <<< "$item"
  if gh label create "$name" --color "$color" --description "$desc" --repo "$REPO" 2>/dev/null; then
    print_success "Created: $name"
    ((created_count++))
  else
    print_skip "Exists: $name"
    ((skipped_count++))
  fi
done

echo ""
echo "📊 Summary: $created_count created, $skipped_count skipped"
echo "Done!"
