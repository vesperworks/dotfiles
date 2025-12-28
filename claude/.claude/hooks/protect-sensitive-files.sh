#!/bin/bash

# protect-sensitive-files.sh - 機密ファイルの編集をブロック
# PreToolUse hook for Write|Edit|MultiEdit tools
#
# Exit codes:
#   0 - Allow file operation
#   2 - Block operation (sensitive file detected)

set -euo pipefail

# Read JSON input from stdin
input=$(cat)

# Extract file_path from tool_input
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

if [ -z "$file_path" ]; then
    exit 0
fi

# Sensitive file patterns to protect
# Using basename and directory checks for flexibility
sensitive_patterns=(
    # Environment files
    '.env'
    '.env.local'
    '.env.production'
    '.env.development'
    '.env.*'

    # Credential files
    'credentials.json'
    'service-account.json'
    'secrets.json'
    'secrets.yaml'
    'secrets.yml'

    # SSH keys
    'id_rsa'
    'id_ed25519'
    'id_ecdsa'
    'id_dsa'
    '*.pem'
    '*.key'

    # Git internals
    '.git/config'
    '.git/credentials'

    # Lock files (prevent accidental modification)
    'package-lock.json'
    'yarn.lock'
    'pnpm-lock.yaml'
    'Gemfile.lock'
    'poetry.lock'
    'Cargo.lock'

    # AWS/Cloud credentials
    '.aws/credentials'
    '.aws/config'
    '.gcloud/'
    '.kube/config'

    # Database configs
    'database.yml'
    'db.json'
)

# Get basename for pattern matching
basename=$(basename "$file_path")

# Check each sensitive pattern
for pattern in "${sensitive_patterns[@]}"; do
    # Check if pattern contains wildcard
    if [[ "$pattern" == *"*"* ]]; then
        # Use glob-style matching
        if [[ "$basename" == $pattern ]] || [[ "$file_path" == *"$pattern"* ]]; then
            echo "🔒 保護されたファイルです: $file_path" >&2
            echo "   パターン: $pattern" >&2
            exit 2
        fi
    else
        # Exact match or path contains pattern
        if [[ "$basename" == "$pattern" ]] || [[ "$file_path" == *"$pattern"* ]]; then
            echo "🔒 保護されたファイルです: $file_path" >&2
            echo "   パターン: $pattern" >&2
            exit 2
        fi
    fi
done

# Check for path traversal attempts
if [[ "$file_path" == *".."* ]]; then
    echo "⚠️ パストラバーサルを検出: $file_path" >&2
    exit 2
fi

# File is safe to modify
exit 0
