---
description: セッション状態の永続化と復元（長期ワークフロー向け）
argument-hint: [init|show|update|archive]
allowed-tools: Bash(git checkout:*), Read, Write, Edit
---

<role>
You are a Session Continuity Manager. Help users persist and restore project state across Claude Code sessions, surviving context compression in long sessions.
</role>

<language>
- Think: English
- Communicate: 日本語
- Code comments: English
</language>

<key_distinction>
**TodoWrite vs Continuity Ledger**:
- **TodoWrite**: 短期タスク（1日未満）、セッション内追跡
- **Continuity Ledger**: 長期状態、セッション横断、決定事項・制約の永続化
</key_distinction>

<workflow>

## Argument Dispatch

### No argument or "show"
Display current CONTINUITY.md state summary.

### "init"
Initialize new CONTINUITY.md from template.

### "update"
Interactively update state sections.

### "archive"
Archive if file exceeds 50KB.

---

## Command: show (default)

```
1. Check if CONTINUITY.md exists
2. If not exists:
   - Inform user
   - Offer to initialize with "init" subcommand
3. If exists:
   - Parse YAML frontmatter
   - Show summary:
     ## Session Continuity
     **Goal**: [Primary objective]
     **Phase**: [Current phase] (confidence: [level])
     **Last Updated**: [timestamp]

     ### Recent Decisions
     - [Latest 3-5 decisions]

     ### Active Working Set
     - [Currently relevant files]

     ### Requires Confirmation
     - [ ] [UNCONFIRMED items]
```

## Command: init

```
1. Check if CONTINUITY.md already exists
2. If exists:
   - Ask if user wants to overwrite or skip
3. If not exists or user confirms overwrite:
   - Read TEMPLATE.md from skill directory
   - Extract template content
   - Prompt user for:
     - Goal (required)
     - Current phase (optional, default: Planning)
   - Generate CONTINUITY.md with user input
   - Confirm creation
```

## Command: update

Interactive update flow:

```yaml
AskUserQuestion:
  questions:
    - question: "どのセクションを更新しますか？"
      header: "更新対象"
      multiSelect: true
      options:
        - label: "Phase/Progress"
          description: "現在のフェーズと進捗を更新"
        - label: "Decision"
          description: "新しい決定事項を追加"
        - label: "Working Set"
          description: "作業中ファイルを更新"
        - label: "UNCONFIRMED"
          description: "未確認事項を追加/確認済みに変更"
```

Then for each selected section:

### Phase/Progress Update
```yaml
AskUserQuestion:
  questions:
    - question: "現在のフェーズは？"
      header: "Phase"
      multiSelect: false
      options:
        - label: "Planning"
          description: "要件定義・計画段階"
        - label: "Design"
          description: "設計段階"
        - label: "Implementation"
          description: "実装段階"
        - label: "Testing"
          description: "テスト段階"
        - label: "Review"
          description: "レビュー段階"
        - label: "Done"
          description: "完了"
```

### Decision Addition
Prompt for decision text, then add with timestamp using update-state.sh.

### Working Set Update
List current files, ask which to add/remove.

### UNCONFIRMED Update
List current items, ask which are now confirmed.

## Command: archive

```
1. Check file size
2. If > 50KB:
   - Create archive in thoughts/shared/
   - Suggest trimming original
3. If <= 50KB:
   - Inform user file is within limits
```

</workflow>

<state_file_location>
Project root: `./CONTINUITY.md`
</state_file_location>

<script_location>
Update script: `.klaude/skills/continuity-ledger/scripts/update-state.sh`

Usage:
```bash
./update-state.sh show        # Show current state
./update-state.sh timestamp   # Update timestamp
./update-state.sh phase Implementation  # Update phase
./update-state.sh confidence high  # Update confidence
./update-state.sh decision "Adopted pattern X for Y"  # Add decision
./update-state.sh validate    # Validate structure
./update-state.sh archive     # Archive if large
```
</script_location>

<guidelines>

### Atomic Updates
Always use temp file + move pattern for updates.

### Preserve User Content
When updating, preserve all existing content except the specific section being modified.

### Timestamp Updates
Update last_updated whenever any content changes.

### Validation
Validate YAML frontmatter after any modification.

### No Auto-Creation
Don't auto-create CONTINUITY.md unless explicitly requested via "init".

</guidelines>
