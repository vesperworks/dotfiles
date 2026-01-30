---
name: prp-generation
description: Generate Project Requirement Plans (PRPs) with multi-approach design evaluation. Use when the user needs to define requirements, plan features, or create implementation specifications. Supports single-mode (fast) and multi-mode (4 parallel approaches comparison using SubAgent→Skills pattern).
---

# PRP Generation Skill

## Overview

This skill helps generate comprehensive Project Requirement Plans (PRPs) with:
- Automatic detection when PRP is needed
- Single-mode: Fast PRP generation
- Multi-mode: 4 parallel approaches (Minimalist/Architect/Pragmatist/Conformist)
- **SubAgent→Skills pattern**: SubAgents reference this skill via Progressive Disclosure
- Structured evaluation and recommendation

## When to Use

- User describes a feature to implement
- User asks "how should I implement..."
- User needs requirements clarification
- Complex features requiring design decisions

## Progressive Disclosure Structure

This skill uses Progressive Disclosure for context efficiency:

- **SKILL.md** (always loaded): Overview and entry point
- **APPROACHES.md** (loaded when needed): Detailed philosophy for each approach
- **EVALUATION.md** (loaded when needed): Evaluation criteria and scoring
- **TEMPLATES.md** (loaded when needed): PRP template structure

SubAgents reference these files only when executing specific approaches.

## Invocation

This skill automatically calls the `vw-prp-orchestrator` agent to handle:
1. Mode detection (single vs multi)
2. Parallel sub-agent execution (each SubAgent references APPROACHES.md)
3. Evaluation and recommendation
4. User selection and PRP generation

## Output

### Naming Convention

**CRITICAL: All PRPs must follow `PRP-XXX-{feature-name}.md` format**

1. **Check existing PRPs**: `Glob .brain/PRPs/**/PRP-*.md`
2. **Determine next number**: highest existing number + 1
3. **Format**: `PRP-XXX` (zero-padded to 3 digits)
   - Example: PRP-008 exists → next is `PRP-009-{feature-name}.md`

### File Location

Generated PRPs are saved to `.brain/PRPs/PRP-XXX-{feature-name}.md` with:
- Evaluation summary
- Agent IDs (for resumability)
- Scoring breakdown
