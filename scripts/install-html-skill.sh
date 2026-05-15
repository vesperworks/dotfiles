#!/bin/bash
# /html SKILL を ~/.claude/skills/html/ に symlink で配置する
# 既存の stow パッケージとファイル単位 symlink 形式（--no-folding 互換）

set -euo pipefail

DOTFILES_HTML="$HOME/dotfiles/claude/.claude/skills/html"
TARGET_DIR="$HOME/.claude/skills/html"

if [ ! -d "$DOTFILES_HTML" ]; then
	echo "[ERR] source not found: $DOTFILES_HTML" >&2
	exit 1
fi

mkdir -p "$TARGET_DIR/references"

# SKILL.md (~/.claude/skills/html → ../../../dotfiles/...)
ln -sf ../../../dotfiles/claude/.claude/skills/html/SKILL.md "$TARGET_DIR/SKILL.md"

# references/*.md (~/.claude/skills/html/references → ../../../../dotfiles/...)
for f in design-system.md status-template.md diagram-template.md annotate-template.md review-template.md; do
	ln -sf "../../../../dotfiles/claude/.claude/skills/html/references/$f" "$TARGET_DIR/references/$f"
done

echo "[OK] /html SKILL installed at $TARGET_DIR"
ls -la "$TARGET_DIR" "$TARGET_DIR/references"
