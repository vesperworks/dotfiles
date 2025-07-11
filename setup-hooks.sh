#!/bin/bash

# Setup script for Claude Code hooks
# This script copies hook files to ~/.claude/hooks/ directory

echo "🔧 Claude Code Hooks Setup"
echo "=========================="

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HOOKS_SOURCE_DIR="${SCRIPT_DIR}/.claude/hooks"
HOOKS_TARGET_DIR="${HOME}/.claude/hooks"

# Check if source hooks directory exists
if [ ! -d "$HOOKS_SOURCE_DIR" ]; then
    echo "❌ Error: Source hooks directory not found at $HOOKS_SOURCE_DIR"
    exit 1
fi

# Create target directory if it doesn't exist
echo "📁 Creating hooks directory..."
mkdir -p "$HOOKS_TARGET_DIR"

# Check for existing hooks and back them up
if [ -n "$(ls -A "$HOOKS_TARGET_DIR" 2>/dev/null)" ]; then
    BACKUP_DIR="${HOOKS_TARGET_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
    echo "📦 Backing up existing hooks to $BACKUP_DIR"
    mv "$HOOKS_TARGET_DIR" "$BACKUP_DIR"
    mkdir -p "$HOOKS_TARGET_DIR"
fi

# Copy hook files
echo "📄 Copying hook files..."
for hook_file in "$HOOKS_SOURCE_DIR"/*.sh; do
    if [ -f "$hook_file" ]; then
        filename=$(basename "$hook_file")
        echo "  - Copying $filename"
        cp "$hook_file" "$HOOKS_TARGET_DIR/$filename"
        # Make executable
        chmod +x "$HOOKS_TARGET_DIR/$filename"
    fi
done

# Verify installation
echo ""
echo "✅ Hooks installed successfully!"
echo ""
echo "📋 Installed hooks:"
ls -la "$HOOKS_TARGET_DIR"/*.sh 2>/dev/null || echo "No .sh files found"

echo ""
echo "🎯 Next steps:"
echo "  1. Verify that ~/.claude/settings.json references the correct hook paths"
echo "  2. Test the hooks by editing a file (for textlint-hook) or running a command (for notification hook)"
echo ""
echo "💡 To update hooks after making changes, run: ./update-hooks.sh"