#!/bin/bash

# Update script for Claude Code hooks
# This script updates existing hooks in ~/.claude/hooks/ directory

echo "🔄 Claude Code Hooks Update"
echo "==========================="

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HOOKS_SOURCE_DIR="${SCRIPT_DIR}/.claude/hooks"
HOOKS_TARGET_DIR="${HOME}/.claude/hooks"

# Check if source hooks directory exists
if [ ! -d "$HOOKS_SOURCE_DIR" ]; then
    echo "❌ Error: Source hooks directory not found at $HOOKS_SOURCE_DIR"
    exit 1
fi

# Check if target hooks directory exists
if [ ! -d "$HOOKS_TARGET_DIR" ]; then
    echo "❌ Error: Target hooks directory not found at $HOOKS_TARGET_DIR"
    echo "💡 Run ./setup-hooks.sh first to initialize hooks"
    exit 1
fi

# Update hook files
echo "📄 Updating hook files..."
updated_count=0

for hook_file in "$HOOKS_SOURCE_DIR"/*.sh; do
    if [ -f "$hook_file" ]; then
        filename=$(basename "$hook_file")
        target_file="$HOOKS_TARGET_DIR/$filename"
        
        # Check if file exists and has changed
        if [ -f "$target_file" ]; then
            if ! cmp -s "$hook_file" "$target_file"; then
                echo "  - Updating $filename"
                cp "$hook_file" "$target_file"
                chmod +x "$target_file"
                ((updated_count++))
            else
                echo "  - $filename is already up to date"
            fi
        else
            echo "  - Installing new hook: $filename"
            cp "$hook_file" "$target_file"
            chmod +x "$target_file"
            ((updated_count++))
        fi
    fi
done

# Summary
echo ""
if [ $updated_count -eq 0 ]; then
    echo "✅ All hooks are already up to date!"
else
    echo "✅ Updated $updated_count hook(s) successfully!"
fi

echo ""
echo "📋 Current hooks:"
ls -la "$HOOKS_TARGET_DIR"/*.sh 2>/dev/null || echo "No .sh files found"