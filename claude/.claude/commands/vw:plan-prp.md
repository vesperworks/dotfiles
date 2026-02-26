---
description: Generate PRP (Project Requirement Prompt) with optional multi-approach evaluation using SubAgent→Skills pattern
argument-hint: [feature-name]
allowed-tools: Task, AskUserQuestion
---

# Generate PRP

## Feature: $ARGUMENTS

Call vw-prp-orchestrator to generate PRP for the specified feature.

The orchestrator will:
1. Detect mode (single vs multi)
2. Generate PRP(s) using appropriate approach(es) with **SubAgent→Skills pattern**
3. Each SubAgent references prp-generation Skill for Progressive Disclosure
4. Evaluate and recommend if multi-mode
5. Save final PRP to .brain/PRPs/{feature-name}.md

@vw-prp-orchestrator, please generate PRP for: $ARGUMENTS

Context files to reference:
- INITIAL.md
- CLAUDE.md
