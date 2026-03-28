#!/bin/bash
# vcs-detect.sh - VCS Detection and Abstraction Library
#
# Usage:
#   source vcs-detect.sh          # as library (functions available in caller)
#   vcs-detect.sh <func> [args]   # direct execution (e.g. vcs-detect.sh detect_vcs)
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
# Bookmark / Branch Operations
# ============================================================

# Create a new bookmark/branch at a revision
# Usage: do_bookmark_create "feat/claude" [@-]
do_bookmark_create() {
  local name="$1"
  local rev="${2:-@}"
  local vcs
  vcs=$(detect_vcs) || return 1

  case "$vcs" in
    jj)
      jj bookmark create "$name" -r "$rev"
      ;;
    git)
      git branch "$name" "${rev:-HEAD}"
      ;;
  esac
}

# Move a bookmark/branch to a revision
# Usage: do_bookmark_set "feat/claude" @-
do_bookmark_set() {
  local name="$1"
  local rev="${2:-@}"
  local vcs
  vcs=$(detect_vcs) || return 1

  case "$vcs" in
    jj)
      jj bookmark set "$name" -r "$rev"
      ;;
    git)
      git branch -f "$name" "${rev:-HEAD}"
      ;;
  esac
}

# Check if a bookmark/branch exists
# Usage: if bookmark_exists "feat/claude"; then ...
bookmark_exists() {
  local name="$1"
  local vcs
  vcs=$(detect_vcs) || return 1

  case "$vcs" in
    jj)
      jj bookmark list --names-only 2>/dev/null | grep -qx "$name"
      ;;
    git)
      git show-ref --verify --quiet "refs/heads/$name"
      ;;
  esac
}

# Create a new working copy from a specific parent
# Usage: do_new_from main
do_new_from() {
  local parent="${1:-}"
  local vcs
  vcs=$(detect_vcs) || return 1

  case "$vcs" in
    jj)
      if [[ -n "$parent" ]]; then
        jj new "$parent"
      else
        jj new
      fi
      ;;
    git)
      if [[ -n "$parent" ]]; then
        git checkout "$parent"
      fi
      ;;
  esac
}

# Restore files from a specific revision into current WC
# Usage: do_restore_from <rev> file1 file2 ...
do_restore_from() {
  local from_rev="$1"
  shift
  local vcs
  vcs=$(detect_vcs) || return 1

  case "$vcs" in
    jj)
      jj restore --from "$from_rev" -- "$@"
      ;;
    git)
      git checkout "$from_rev" -- "$@"
      ;;
  esac
}

# Get current change_id (jj) or HEAD commit hash (git)
# Usage: current_rev=$(get_current_rev)
get_current_rev() {
  local vcs
  vcs=$(detect_vcs) || return 1

  case "$vcs" in
    jj)
      jj log -r @ --no-graph -T 'change_id.short()' 2>/dev/null
      ;;
    git)
      git rev-parse --short HEAD 2>/dev/null
      ;;
  esac
}

# Abandon a specific revision (jj only, noop for git)
# Usage: do_abandon <change_id>
do_abandon() {
  local rev="$1"
  local vcs
  vcs=$(detect_vcs) || return 1

  case "$vcs" in
    jj)
      jj abandon "$rev"
      ;;
    git)
      # git has no equivalent; caller handles cleanup
      :
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
