#!/bin/bash
# vcs-detect.sh - VCS Detection and Abstraction Library
#
# Usage: source vcs-detect.sh
#
# Provides unified VCS operations for both jj (Jujutsu) and git.
# jj is prioritized over git (colocate mode makes git also pass).
#
# Created: 2026-02-26 (PRP-017)

# Guard: only set pipefail when sourced as library (not when set -e is active in caller)
# The caller is responsible for their own error handling settings.

# ============================================================
# VCS Detection
# ============================================================

# Detect the active VCS in the current directory
# Returns: "jj" | "git" | exits with error
# jj is checked first because colocate mode makes git rev-parse succeed too
detect_vcs() {
  if jj root &>/dev/null; then
    echo "jj"
  elif git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "git"
  else
    echo "Error: Not in a VCS repository (neither jj nor git)" >&2
    return 1
  fi
}

# ============================================================
# File Status Operations
# ============================================================

# Get list of changed files (both staged and unstaged for git, all changes for jj)
# Usage: changed=$(get_changed_files)
get_changed_files() {
  local vcs
  vcs=$(detect_vcs) || return 1

  case "$vcs" in
    jj)
      jj diff --name-only 2>/dev/null
      ;;
    git)
      # Combine staged + unstaged, deduplicate
      { git diff --cached --name-only 2>/dev/null; git diff --name-only 2>/dev/null; } | sort -u
      ;;
  esac
}

# Get list of files that will be committed
# jj: all changed files (no staging concept)
# git: staged files only
# Usage: files=$(get_commit_files)
get_commit_files() {
  local vcs
  vcs=$(detect_vcs) || return 1

  case "$vcs" in
    jj)
      jj diff --name-only 2>/dev/null
      ;;
    git)
      git diff --cached --name-only 2>/dev/null
      ;;
  esac
}

# ============================================================
# Commit Operations
# ============================================================

# Stage files (noop for jj, git add for git)
# Usage: do_add file1 file2 ...
do_add() {
  local vcs
  vcs=$(detect_vcs) || return 1

  case "$vcs" in
    jj)
      # jj auto-tracks all files, no staging needed
      :
      ;;
    git)
      git add "$@"
      ;;
  esac
}

# Commit all current changes with a message
# Usage: do_commit "commit message"
do_commit() {
  local msg="$1"
  local vcs
  vcs=$(detect_vcs) || return 1

  case "$vcs" in
    jj)
      jj commit -m "$msg"
      ;;
    git)
      git commit -m "$msg"
      ;;
  esac
}

# Split specific files into a separate commit (staged commit for specific files)
# jj: uses jj split -m to extract specific files into their own commit
# git: uses git add + git commit
# Usage: do_split "commit message" file1 file2 ...
do_split() {
  local msg="$1"
  shift
  local vcs
  vcs=$(detect_vcs) || return 1

  case "$vcs" in
    jj)
      jj split -m "$msg" -- "$@"
      ;;
    git)
      git add "$@"
      git commit -m "$msg"
      ;;
  esac
}

# Set description on current working copy commit (jj only)
# Usage: do_describe "message"
do_describe() {
  local msg="$1"
  local vcs
  vcs=$(detect_vcs) || return 1

  case "$vcs" in
    jj)
      jj describe -m "$msg"
      ;;
    git)
      echo "Warning: do_describe is not applicable for git" >&2
      return 1
      ;;
  esac
}

# Create new empty working copy commit (jj only)
# Usage: do_new
do_new() {
  local vcs
  vcs=$(detect_vcs) || return 1

  case "$vcs" in
    jj)
      jj new
      ;;
    git)
      echo "Warning: do_new is not applicable for git" >&2
      return 1
      ;;
  esac
}

# ============================================================
# Log Operations
# ============================================================

# Show recent commit log
# Usage: do_log [count]
do_log() {
  local count="${1:-5}"
  local vcs
  vcs=$(detect_vcs) || return 1

  case "$vcs" in
    jj)
      jj log -n "$count"
      ;;
    git)
      git log --oneline -"$count"
      ;;
  esac
}
