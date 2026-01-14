#!/bin/bash
# security-utils.sh - Shared Security Validation Library
#
# Usage: source security-utils.sh
#
# This file provides common security validation functions for .klaude/ scripts.
# Design principle: Minimal, focused validation for actual threat vectors.
#
# Reference: OWASP Command Injection (CWE-78)
# Created: 2025-12-28 (PRP-013)

set -euo pipefail

# ============================================================
# Input Sanitization
# ============================================================

# Sanitize string for safe shell usage
# Removes shell metacharacters: $ ` ; | & ( ) { } [ ] < > \ " '
# Preserves: alphanumeric, space, newline, common punctuation
# Usage: safe=$(sanitize_string "$input" [max_length])
sanitize_string() {
  local input="$1"
  local max_length="${2:-4096}"

  [[ -z "$input" ]] && return 0

  # Truncate if too long
  if [[ ${#input} -gt $max_length ]]; then
    input="${input:0:$max_length}"
  fi

  # Keep only safe characters (including newline for multiline content)
  printf '%s' "$input" | tr -cd '[:alnum:] _.,:/@#\n-'
}

# Sanitize log entry (prevent log injection)
# Removes: ANSI escapes, control characters, normalizes newlines
# Usage: safe_log=$(sanitize_log "$message")
sanitize_log() {
  local input="$1"

  printf '%s' "$input" |
    sed 's/\x1b\[[0-9;]*[a-zA-Z]//g' |
    tr -cd '[:print:]' |
    tr '\n' ' ' |
    head -c 4096
}

# Mask sensitive data in strings (for logging)
# Usage: masked=$(mask_sensitive "$command")
mask_sensitive() {
  local input="$1"

  printf '%s' "$input" | sed -E '
    s/(token|password|secret|api[_-]?key|auth)=[^[:space:]]*/\1=***REDACTED***/gi
    s/(Authorization:[[:space:]]*)(Bearer[[:space:]]+)?[^[:space:]]*/\1***REDACTED***/gi
    s/(ghp_|gho_|ghs_|ghr_)[a-zA-Z0-9]+/***GITHUB_TOKEN***/g
  '
}

# ============================================================
# Input Validation
# ============================================================

# Validate path is safe (no traversal)
# Usage: validate_path "/some/path" && echo "safe"
validate_path() {
  local path="$1"

  [[ -z "$path" ]] && return 1
  [[ "$path" == *".."* ]] && return 1

  return 0
}

# Validate GitHub repository format (owner/repo)
# Usage: validate_repo "owner/repo" && echo "valid"
validate_repo() {
  local repo="$1"
  [[ "$repo" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]]
}

# Validate positive integer
# Usage: validate_number "123" && echo "valid"
validate_number() {
  local num="$1"
  [[ "$num" =~ ^[0-9]+$ ]]
}

# Validate ISO8601 date (YYYY-MM-DD)
# Usage: validate_date "2025-12-28" && echo "valid"
validate_date() {
  local date="$1"
  [[ "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]
}

# Validate labels format (alphanumeric, dash, underscore, colon, comma)
# Usage: validate_labels "bug,priority:high" && echo "valid"
validate_labels() {
  local labels="$1"
  [[ -z "$labels" ]] && return 0
  [[ "$labels" =~ ^[a-zA-Z0-9_:,\ -]+$ ]]
}

# Validate issue type against allowed values
# Usage: validate_issue_type "task" && echo "valid"
validate_issue_type() {
  local type="$1"
  [[ -z "$type" ]] && return 0
  [[ "$type" =~ ^(task|bug|feature|epic|story|enhancement|documentation)$ ]]
}
