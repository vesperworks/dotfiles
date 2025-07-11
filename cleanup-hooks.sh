#!/bin/bash

# Cleanup script for Claude Code hooks
# This script removes hooks from ~/.claude/hooks/ directory

echo "🧹 Claude Code Hooks Cleanup"
echo "============================"

HOOKS_TARGET_DIR="${HOME}/.claude/hooks"

# Check if hooks directory exists
if [ ! -d "$HOOKS_TARGET_DIR" ]; then
    echo "❌ No hooks directory found at $HOOKS_TARGET_DIR"
    exit 0
fi

# List current hooks
echo "📋 Current hooks:"
ls -la "$HOOKS_TARGET_DIR"/*.sh 2>/dev/null || echo "No .sh files found"

# Confirm deletion
echo ""
read -p "⚠️  Are you sure you want to remove all hooks? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cleanup cancelled"
    exit 0
fi

# Backup before deletion
BACKUP_DIR="${HOOKS_TARGET_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
echo "📦 Creating backup at $BACKUP_DIR"
cp -r "$HOOKS_TARGET_DIR" "$BACKUP_DIR"

# Remove hook files
echo "🗑️  Removing hook files..."
rm -f "$HOOKS_TARGET_DIR"/*.sh

# Check if directory is empty and remove if so
if [ -z "$(ls -A "$HOOKS_TARGET_DIR" 2>/dev/null)" ]; then
    echo "📁 Removing empty hooks directory..."
    rmdir "$HOOKS_TARGET_DIR"
fi

echo ""
echo "✅ Hooks cleaned up successfully!"
echo "💡 Backup saved at: $BACKUP_DIR"
echo ""
echo "To reinstall hooks, run: ./setup-hooks.sh"