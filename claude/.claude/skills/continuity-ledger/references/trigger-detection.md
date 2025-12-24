# Trigger Detection Patterns

This document details the conditional execution logic for the Continuity Ledger skill.

## Fast-Path Exit Pattern

Following the official Claude Code pattern from `real-world-examples.md`, implement quick exit when skill should not activate:

```bash
# Fast-path exit if state file doesn't exist and no explicit trigger
if [[ ! -f "$PROJECT_ROOT/CONTINUITY.md" ]]; then
  # Check if user explicitly requested continuity
  if [[ -z "$CONTINUITY_TRIGGER" ]]; then
    exit 0  # Not applicable - exit silently
  fi
fi
```

## Trigger Phrase Detection

### Explicit Trigger Phrases (High Confidence)

These phrases explicitly request session continuity:

| English | Japanese | Confidence |
|---------|----------|------------|
| "continue from last session" | "前回の続き" | High |
| "what did we do last time" | "どこまでやった" | High |
| "resume work" | "作業を再開" | High |
| "where were we" | "どこまで進んだ" | High |
| "load previous session" | "前のセッションを読み込む" | High |
| "recall our progress" | "進捗を確認" | High |

### Implicit Triggers (Medium Confidence)

These contexts suggest continuity may be helpful:

1. **Multi-step workflow initiation**
   - User starts a complex task that spans multiple sessions
   - Example: "Let's implement the authentication system" (when prior context exists)

2. **Reference to prior decisions**
   - User mentions something that was decided earlier
   - Example: "As we discussed, use JWT for auth"

3. **Session duration heuristic**
   - Long session (> 30 minutes) with significant context
   - Approaching potential context compression

## Context Analysis

### Check for Prior State

```python
def should_trigger_continuity(user_message: str, project_root: str) -> bool:
    """Determine if continuity skill should activate."""

    # Fast-path: No state file exists
    continuity_file = f"{project_root}/CONTINUITY.md"
    if not os.path.exists(continuity_file):
        # Only trigger if user explicitly requests initialization
        return has_explicit_init_request(user_message)

    # Check explicit trigger phrases
    if has_explicit_trigger_phrase(user_message):
        return True

    # Check implicit triggers
    if is_multi_step_workflow(user_message):
        return True

    return False
```

### Trigger Phrase Matching

```python
EXPLICIT_TRIGGERS = [
    r"continue\s+from\s+last\s+session",
    r"what\s+did\s+we\s+do\s+last\s+time",
    r"resume\s+work",
    r"where\s+were\s+we",
    r"前回の続き",
    r"どこまでやった",
    r"作業を再開",
    r"どこまで進んだ",
]

def has_explicit_trigger_phrase(message: str) -> bool:
    """Check if message contains explicit trigger phrase."""
    message_lower = message.lower()
    for pattern in EXPLICIT_TRIGGERS:
        if re.search(pattern, message_lower, re.IGNORECASE):
            return True
    return False
```

## Multi-Step Workflow Detection

A workflow is considered "multi-step" if:

1. **Explicit PRP reference**: Message mentions a PRP file
2. **Task list indicator**: Message includes numbered steps or checklist
3. **Scope indicator**: Words like "implement", "refactor", "migrate" with significant scope
4. **Duration indicator**: Words like "over the next few sessions", "long-term"

```python
MULTI_STEP_INDICATORS = [
    r"PRP[-/]\d+",  # PRP reference
    r"\d+\.\s+\w+",  # Numbered steps
    r"implement\s+\w+\s+system",  # System implementation
    r"refactor\s+\w+",  # Refactoring
    r"migrate\s+\w+",  # Migration
]

def is_multi_step_workflow(message: str) -> bool:
    """Check if message indicates a multi-step workflow."""
    for pattern in MULTI_STEP_INDICATORS:
        if re.search(pattern, message, re.IGNORECASE):
            return True
    return False
```

## Decision Matrix

| State File Exists | Explicit Trigger | Implicit Trigger | Action |
|-------------------|------------------|------------------|--------|
| No | No | No | Exit (fast-path) |
| No | Yes | - | Offer initialization |
| Yes | Yes | - | Load and present state |
| Yes | No | Yes | Load state (silent background) |
| Yes | No | No | Exit (not relevant) |

## Edge Cases

### New Project

When CONTINUITY.md doesn't exist:
- Don't auto-create on every session
- Only create when user explicitly requests or workflow clearly needs it
- Provide onboarding message explaining the feature

### Stale State

When CONTINUITY.md exists but is outdated (> 7 days):
- Still load but note the staleness
- Suggest review and update
- Ask if current context is still accurate

### Branch Switching

CONTINUITY.md is branch-specific:
- State may differ between branches
- Git conflicts must be resolved manually
- Consider noting the branch in session_id

## Implementation Notes

1. **Performance**: Trigger detection should be fast (< 100ms)
2. **False Positives**: Prefer false negatives over false positives
3. **User Control**: Always allow explicit override via command
4. **Logging**: Log trigger decisions for debugging (in development only)
