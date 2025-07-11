#!/bin/bash

# Claude Code Linter Hook - Run project linter on modified files
FILE_PATH="$1"

# Skip if no file path provided
if [ -z "$FILE_PATH" ]; then
    echo "No file path provided, skipping linter check"
    exit 0
fi

# Find project root by looking for package.json
PROJECT_ROOT="$(dirname "$FILE_PATH")"
while [ "$PROJECT_ROOT" != "/" ]; do
    if [ -f "$PROJECT_ROOT/package.json" ]; then
        break
    fi
    PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done

# Check if package.json exists
if [ ! -f "$PROJECT_ROOT/package.json" ]; then
    echo "No package.json found, skipping linter check"
    exit 0
fi

# Check if lint script exists
if ! grep -q '"lint"' "$PROJECT_ROOT/package.json"; then
    echo "No lint script found in package.json, skipping linter check"
    exit 0
fi

# Run lint command
echo "Running linter in $PROJECT_ROOT..."
cd "$PROJECT_ROOT" && nr lint

# Try to auto-fix if lint:fix script exists
if grep -q '"lint:fix"' "$PROJECT_ROOT/package.json"; then
    echo "Running auto-fix..."
    nr lint:fix
fi