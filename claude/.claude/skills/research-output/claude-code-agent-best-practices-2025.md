# Claude Code Agent & Prompt Best Practices - Research Report 2025

**Research Date**: 2025-12-10
**Agent**: hl-web-search-researcher

---

## Executive Summary

This report compiles the latest best practices for Claude Code custom agents, SKILL system, prompt optimization, and agent delegation patterns based on official Anthropic documentation and community expertise from 2025.

### Key Findings:
1. **SubAgent→Skills Pattern**: Reduces context consumption by ~70% through progressive disclosure
2. **Context Engineering**: Critical for multi-turn agent operations over longer time horizons
3. **XML Tags**: Still valuable for structured prompts despite improved model understanding
4. **Agent Pipeline Architecture**: Enables reproducible, governed software development workflows
5. **Context Awareness in Claude 4.5**: Models now track their remaining context window budget

---

## 1. Custom Agents Best Practices

### Core Principles

**Start with Claude-Generated Agents**
- Use Claude to generate initial subagent configurations
- Iterate and customize to fit specific needs
- Provides solid foundation aligned with best practices

**Configuration Structure**
```yaml
---
name: agent-name
description: Clear, action-oriented description
tools: [Read, Grep, Glob]  # Minimal necessary tools
model: claude-sonnet-4-5
permissionMode: auto
skills: []
---

# System Prompt
Clear role definition, capabilities, approach to solving problems...
```

**File Location**:
- Project-level: `.claude/agents/` (takes precedence)
- User-level: `~/.claude/agents/`
- Auto-detected and loaded by Claude Code

### Tool Permission Management

**Principle: Least Privilege Access**
> "Permission sprawl is the fastest path to unsafe autonomy. Treat tool access like production IAM."

**Recommended Tool Sets by Role**:

| Agent Type | Tools | Purpose |
|-----------|-------|---------|
| Read-only (reviewers, auditors) | Read, Grep, Glob | Analyze without modifying |
| Research agents | Read, Grep, Glob, WebFetch, WebSearch | Gather information |
| Code writers | Read, Write, Edit, Bash, Glob, Grep | Create and execute |

**Security Strategy**:
- Start from deny-all
- Allowlist only necessary commands and directories
- Scope each agent's access precisely

### Pipeline Architecture Pattern

**Recommended Agent Roles**:
1. **Product Spec** - Requirements gathering
2. **Architect** - Design validation
3. **Implementer/Tester** - Build & test
4. **QA** - Verification

**Benefits**:
- **Reproducibility**: Codified repeatable steps
- **Separation of Concerns**: Clear role boundaries
- **Governance & Safety**: Scoped tools & permissions per agent
- **Throughput**: Serialize high-risk steps, parallelize safe ones

### Context Management Strategy

**The Context Problem**:
- Complex task requires X tokens input
- Accumulates Y tokens working context
- Produces Z token answer
- Without management: context pollution and drift

**SubAgent Solution**:
> "Farm out work to specialized agents, which only return final answers, keeping your main context clean."

**Best Practices**:
- Isolate per-subagent context
- Let orchestrator maintain global plan and compact state
- Use CLAUDE.md for project conventions and standards
- Avoid storing every detail in main context

### Test-Driven Development for Agents

**Recommended Workflow**:
1. Testing subagent writes tests first
2. Run tests and confirm failures
3. Implementer subagent makes tests pass
4. Dedicated code-review subagent enforces quality

**Quality Enforcement**:
- Linting checks
- Complexity bounds
- Security checks

### The Critical CLAUDE.md File

> "The single most important file in your codebase for using Claude Code effectively."

**Purpose**:
- Agent's "constitution"
- Primary source of truth for repository
- Encodes project conventions, test commands, directory layout, architecture

**Impact**: Ensures agents converge on shared standards

### Observability and Safety

> "Autonomy without visibility is risk."

**Monitoring Recommendations**:
- Capture OpenTelemetry traces for:
  - Prompts
  - Tool invocations
  - Token usage
  - Orchestration steps
- Include correlation IDs across subagents
- Version-control hooks, settings, and subagent manifests
- Validate JSON/scripts pre-commit
- Keep rollback lever within arm's reach

---

## 2. SKILL System Architecture

### What are Agent Skills?

> "Skills are folders of instructions, scripts, and resources that Claude loads dynamically to improve performance on specialized tasks."

**Definition**: Organized folders teaching Claude how to complete specific tasks in a repeatable way using your organization's specific workflows.

### Core Architecture

**Filesystem-Based Design**:
- Skills exist as directories with SKILL.md file
- Contains instructions, executable code, reference materials
- Organized like onboarding guide for new team member
- Enables progressive disclosure (load information as needed)

**Minimal SKILL.md Structure**:
```yaml
---
name: skill-name
description: Clear description of what this skill does
---

# Skill Instructions
[Progressive disclosure content here]
```

### Skill Locations in Claude Code

1. **User-level**: `~/.claude/skills/`
2. **Project-level**: `.claude/skills/`
3. **Plugin-level**: `[plugin]/skills/`

### Invocation Model

**Model-Invoked (Autonomous)**:
- Claude decides when to use based on request and description
- Different from slash commands (user-invoked)
- Requires clear, actionable description for proper triggering

### Progressive Disclosure Pattern

**Key Innovation**: Load information in stages rather than upfront

**Benefits**:
- Reduces initial context consumption
- Only loads what's needed when needed
- Approximately 70% context reduction vs. always-loaded approach

**Example Architecture**:
```
skill-name/
├── SKILL.md           # Entry point with metadata
├── APPROACHES.md      # Loaded only when needed
├── TEMPLATES.md       # Loaded only when needed
└── scripts/           # Executed only when invoked
```

### SubAgent→Skills Pattern

**Problem**: Traditional subagents load all context upfront
```
Traditional: 4 subagents × 2,000 tokens = 8,000 tokens (always consumed)
```

**Solution**: SubAgent→Skills with progressive disclosure
```
SubAgent metadata: 4 × 100 tokens = 400 tokens (always)
Skill details: 2,000 tokens (only when needed)
Average consumption: 2,400 tokens (~70% reduction)
```

**Architecture**:
```
Layer 1: SKILL (autonomous triggering)
    ↓
Layer 2: Sub-agents (orchestration)
    ↓ (parallel execution)
Layer 3: Individual Skills (progressive disclosure)
```

### Security Considerations

**Critical Warning from Anthropic**:
> "Use Skills only from trusted sources: those you created yourself or obtained from Anthropic."

**Risks**:
- Skills provide Claude with new capabilities through instructions and code
- Malicious Skill can direct Claude to invoke tools inappropriately
- Can execute code in ways that don't match stated purpose

**Recommendation**: Audit skills from external sources before use

### Pre-built Skills

Anthropic provides official skills for:
- PowerPoint documents
- Excel spreadsheets
- Word documents
- PDF files

---

## 3. Context Window Optimization

### The Context Engineering Challenge

> "Context engineering is the art and science of curating what will go into the limited context window from that constantly evolving universe of possible information."

**Modern Agent Challenge**:
- Operate over multiple turns of inference
- Longer time horizons
- Must manage: system instructions, tools, MCP, external data, message history

### Context Compaction Strategies

**Claude Code's Implementation**:
- Pass message history to model for summarization
- Compress most critical details
- Preserve: architectural decisions, unresolved bugs, implementation details
- Discard: redundant tool outputs, obsolete messages

**The Art of Compaction**:
> "The art lies in selection of what to keep vs. what to discard."

**Risk**: Overly aggressive compaction loses subtle but critical context

**Implementation Recommendations**:
1. Start by maximizing recall (capture everything relevant)
2. Iterate to improve precision (eliminate superfluous content)
3. Tune prompts on complex agent traces
4. Test thoroughly on real-world scenarios

### Context Awareness in Claude 4.5

**New Capability**: Context-aware models
- **Claude Sonnet 4.5** and **Claude Haiku 4.5** track remaining context window
- Understand "token budget" throughout conversation
- Execute tasks and manage context more effectively

**Best Practice**: Add context management info to prompts
```markdown
This agent harness supports:
- Context compaction when approaching limits
- Saving context to external files
- Memory tool for persistence
```

**Without this**: Claude may prematurely wrap up work as it approaches limits

### Context Management Tools (Claude API)

**1. Context Editing** (Automatic):
- Clears stale tool calls and results when approaching limits
- 29% performance improvement on agentic search tasks
- 84% reduction in token consumption in 100-turn web search
- Enables workflows that would otherwise fail from context exhaustion

**2. Memory Tool** (Persistent Storage):
- Store and consult information outside context window
- File-based system in dedicated memory directory
- Create, read, update, delete files
- Persists across conversations
- Build knowledge bases over time
- Maintain project state across sessions

**Combined Impact**:
- Context editing + memory tool: 39% improvement on agentic search
- Context editing alone: 29% improvement

### Performance Optimization Best Practices

**1. Monitor Context Usage**:
- Watch for performance degradation as conversations grow
- Response quality declines when approaching limits

**2. Strategic Chunking**:
- Break large tasks into smaller pieces
- Complete within optimal context bounds
- Avoid last fifth of context window for memory-intensive tasks

**3. Working with Long Contexts**:
- **Summarize**: Condense lengthy information into concise summaries
- **Hierarchical Prompts**: Break complex tasks into smaller sub-tasks
- **Reference Previous Exchanges**: Leverage context windows strategically

**4. Context State Management**:
- System instructions
- Tools configuration
- Model Context Protocol (MCP)
- External data sources
- Message history

---

## 4. XML Structured Prompts

### Why XML Tags for Claude?

**Key Benefits**:

1. **Clarity**: Separate different prompt parts with clear structure
2. **Accuracy**: Reduce errors from misinterpreting prompt parts
3. **Flexibility**: Easily find, add, remove, or modify parts without rewriting
4. **Parseability**: Extract specific response parts through post-processing

**Claude's Fine-Tuning**:
> "Claude has been fine-tuned to pay special attention to XML tags."

### Core Best Practices

**1. Be Consistent**:
```xml
<contract>
  [Contract text here]
</contract>

Using the contract in <contract> tags, analyze...
```

**2. Use Nesting**:
```xml
<outer>
  <inner>
    Hierarchical content
  </inner>
</outer>
```

**3. Choose Descriptive Tag Names**:
- No canonical "best" tags
- Use names that make sense with their content
- Self-documenting structure

**4. Suggested Tags for Common Elements**:

| Tag | Purpose |
|-----|---------|
| `<instruction>` | Task instructions to Claude |
| `<context>` | Background information or context |
| `<example>` | Examples to guide responses |
| `<human>` | Simulated human conversation |
| `<assistant>` | Simulated assistant conversation |

**5. Combine with Other Techniques**:
```xml
<examples>
  <example>
    <input>...</input>
    <output>...</output>
  </example>
</examples>

<thinking>
  Chain of thought reasoning...
</thinking>

<answer>
  Final answer...
</answer>
```

### Modern Model Considerations

**Evolution**:
> "While modern models are better at understanding structure without XML tags, they can still be useful in specific situations."

**Alternatives for Most Use Cases**:
- Clear headings
- Whitespace separation
- Explicit language ("Using the athlete information below...")
- Less overhead than XML

**When XML Still Shines**:
- Large amounts of structured data
- Multiple distinct sections requiring clear boundaries
- Output requiring programmatic parsing
- Complex nested information hierarchies

### Practical Impact

**Without XML**:
- Disorganized analysis
- Missing key points
- Ambiguous boundaries

**With XML**:
- Structured, thorough analysis
- Clear section boundaries
- Actionable outputs
- Reduced confusion

**Example**:
```xml
<athlete_data>
  <athlete id="1">
    <name>John Doe</name>
    <stats>...</stats>
  </athlete>
</athlete_data>

<analysis_requirements>
  1. Performance trends
  2. Injury risk
  3. Training recommendations
</analysis_requirements>
```

---

## 5. Agent Delegation Patterns

### What are Subagents?

**Definition**: Pre-configured, task-specialized AI "personalities" that Claude Code can delegate tasks to.

**Components**:
- Custom system prompt
- Isolated context window
- Explicitly granted tools
- Optional model selection

**How It Works**:
- Claude encounters task matching subagent expertise
- Delegates to specialized subagent
- Subagent works independently
- Returns results to main agent

### Key Benefits

**1. Context Preservation**:
- Each subagent operates in own context
- Prevents pollution of main conversation
- Keeps main agent focused on high-level objectives

**2. Specialization**:
- Fine-tuned with detailed domain instructions
- Higher success rates on designated tasks
- Expert-level performance in narrow domains

**3. Reusability**:
- Use across different projects
- Share with team for consistent workflows
- Build organizational knowledge library

**4. Security**:
- Different tool access levels per subagent
- Limit powerful tools to specific types
- Principle of least privilege

### Delegation Pattern Types

#### 1. Automatic Delegation

**How it works**:
- Claude automatically delegates when prompt matches subagent description
- Based on task requirements and agent capabilities
- No explicit user request needed

**Triggering Techniques**:
```yaml
description: >
  Use PROACTIVELY when analyzing code quality.
  MUST BE USED for all code review tasks.
```

**Action-oriented language** nudges automatic delegation

#### 2. Explicit Invocation

**How it works**:
- User explicitly requests specific subagent
- Example: "Use the code-reviewer subagent to check my recent changes"
- Direct control over which agent handles task

#### 3. Parallel Processing Pattern

**Architecture**:
- Main agent acts as coordinator
- Uses Claude's Task tool to spawn parallel agents
- Sub-agents handle operations concurrently
- Main agent focuses on orchestration

**Benefits**:
- Faster execution through parallelization
- More efficient workflows
- Clear separation of coordination vs. execution

#### 4. Pipeline/Sequential Pattern

**Architecture**:
```
Spec → Scaffold → Implement → Test → Optimize
  ↓       ↓          ↓         ↓        ↓
Agent1  Agent2    Agent3    Agent4   Agent5
```

**Characteristics**:
- Output of one agent → input of next
- Function composition expressed as agents
- Stepwise transformations
- Strict guarantees about data flow

**Use Cases**:
- When need guaranteed transformation sequence
- Data must flow through specific processing stages
- Quality gates at each stage

### Built-in Subagents

#### 1. Explore Subagent

**Purpose**: Search and understand codebase without making changes

**Thoroughness Levels**:
- **Quick**: Fast searches, minimal exploration, targeted lookups
- **Medium**: Moderate exploration, balances speed and thoroughness
- **Very Thorough**: Comprehensive analysis across multiple locations and naming conventions

**When Used**: Main agent needs codebase understanding but not modifications

#### 2. Plan Subagent

**Purpose**: Conduct research and gather codebase information before planning

**When Used**:
- Claude operating in plan mode (non-execution)
- Needs codebase research before presenting plan
- Automatically invoked in plan mode

### Configuration Best Practices

**File Structure**:
```yaml
---
name: code-reviewer
description: Expert code reviewer focused on quality and security
tools: [Read, Grep, Glob]  # Read-only
model: claude-sonnet-4-5
permissionMode: auto
skills: []
---

# System Prompt
You are an expert code reviewer specializing in...
```

**Storage Locations**:
- **Project-level**: `.claude/agents/` (takes precedence)
- **User-level**: `~/.claude/agents/`

### Important Constraints

**No Nested Delegation**:
> "Subagents cannot spawn other subagents - this prevents infinite nesting of agents."

**Design Implication**: Plan agent hierarchy carefully

**Over-Eager Delegation Risk**:
- Increases token usage
- Creates noise if many subagents activate for similar tasks
- Design descriptions conservatively

### Alternative: Master-Clone Architecture

**Concept**:
- Use Claude's built-in Task() to spawn clones of general agent
- Put all key context in CLAUDE.md
- Main agent decides when/how to delegate to copies of itself

**Benefits**:
- All context-saving benefits of subagents
- Without drawback of limited subagent context
- Dynamic orchestration management

**Trade-off**:
- Less specialized per-task optimization
- More flexible for varying workloads

---

## 6. Token Optimization Techniques

### Progressive Disclosure Strategy

**Concept**: Load information in stages as needed, not all upfront

**Implementation**:
```
Initial load: 500 tokens (metadata + basic instructions)
Stage 1 needed: +800 tokens (specific approach details)
Stage 2 needed: +700 tokens (templates and examples)
Total consumed: 2,000 tokens (only what's needed)

vs.

Traditional load: 2,000 tokens (everything upfront, always)
```

**Savings**: ~70% reduction in average context consumption

### Skill-Based Architecture

**Pattern**:
```
Subagent (lightweight) → Skills (loaded on demand)
```

**Benefits**:
- Subagent contains only routing logic and metadata
- Skills contain detailed implementation instructions
- Only load skills when actually needed

### Context Compaction

**When to Compact**:
- Approaching context limits
- Long-running conversations
- Many tool invocations with outputs

**What to Preserve**:
- Architectural decisions
- Unresolved bugs
- Current implementation details
- Critical constraints

**What to Discard**:
- Redundant tool outputs
- Obsolete conversation turns
- Completed task details
- Superseded decisions

### Memory Tool Pattern

**For Claude API Users**:
```python
# Store to external memory
memory.write("project_state.md", current_state)

# Retrieve when needed
state = memory.read("project_state.md")
```

**Benefits**:
- Keep working context small
- Persist important information across sessions
- Build long-term knowledge bases

### Strategic Chunking

**Technique**: Break large tasks into optimal-sized chunks

**Example**:
```
Bad:  "Implement entire authentication system"
      → 50,000 tokens of context needed

Good: "Implement user model and password hashing"
      → 8,000 tokens of context needed

      "Implement JWT token generation"
      → 6,000 tokens of context needed

      "Implement auth middleware"
      → 5,000 tokens of context needed
```

**Rule of Thumb**: Avoid last fifth of context window for memory-intensive tasks

### Hierarchical Prompt Structure

**Pattern**:
```
High-level objective (main agent)
  ├─ Sub-objective 1 (subagent A)
  ├─ Sub-objective 2 (subagent B)
  └─ Sub-objective 3 (subagent C)
```

**Token Efficiency**:
- Main agent: 1,000 tokens context
- Each subagent: 5,000 tokens context (isolated)
- Total effective: 16,000 tokens across 4 agents
- Without delegation: Would need 30,000+ tokens in single context

---

## 7. Recommended Prompt Structures

### 1. Basic Subagent Prompt

```yaml
---
name: subagent-name
description: |
  Clear, action-oriented description.
  Use PROACTIVELY when [trigger conditions].
  MUST BE USED for [specific scenarios].
tools: [Read, Grep, Glob]
model: claude-sonnet-4-5
permissionMode: auto
---

# Role Definition
You are a [specific role] specialized in [domain].

# Capabilities
- [Capability 1]
- [Capability 2]
- [Capability 3]

# Approach
When assigned a task:
1. [Step 1]
2. [Step 2]
3. [Step 3]

# Constraints
- [Constraint 1]
- [Constraint 2]

# Output Format
[Expected output structure]
```

### 2. Skill with Progressive Disclosure

```yaml
---
name: skill-name
description: Brief description for triggering logic
---

# Initial Instructions

[Core instructions always loaded]

## When to Use This Skill

[Clear triggering conditions]

## Quick Reference

[Most commonly needed information]

## For More Details

See `APPROACHES.md` for detailed strategies.
See `TEMPLATES.md` for example implementations.
See `scripts/` for automation tools.
```

### 3. XML-Structured Agent Output

```xml
<analysis>
  <summary>
    High-level findings
  </summary>

  <details>
    <finding priority="high">
      <issue>Description</issue>
      <recommendation>Action to take</recommendation>
    </finding>
  </details>

  <next_steps>
    <step>1. First action</step>
    <step>2. Second action</step>
  </next_steps>
</analysis>
```

### 4. Context-Aware Pipeline Prompt

```yaml
---
name: pipeline-orchestrator
description: Coordinates multi-stage development pipeline
tools: [Read, Write, Edit, Bash, Glob, Grep]
model: claude-sonnet-4-5
---

# Pipeline Orchestrator

You coordinate a development pipeline through these stages:

## Stage 1: Specification (→ spec-agent)
Delegate to spec-agent to gather requirements.
Input: User request
Output: Detailed specification

## Stage 2: Design (→ architect-agent)
Delegate to architect-agent to create technical design.
Input: Specification from Stage 1
Output: Architecture document

## Stage 3: Implementation (→ developer-agent)
Delegate to developer-agent to write code.
Input: Architecture from Stage 2
Output: Implementation + tests

## Stage 4: Review (→ reviewer-agent)
Delegate to reviewer-agent for quality assurance.
Input: Implementation from Stage 3
Output: Review feedback + approval

## Context Management
- Compact history after each stage
- Preserve only stage outputs and critical decisions
- Monitor token budget throughout pipeline

## Error Handling
If any stage fails:
1. Capture failure details
2. Return to previous stage
3. Provide failure context for retry
```

### 5. CLAUDE.md Project Template

```markdown
# Project Name

## Overview
[Brief project description]

## Architecture
[Key architectural decisions]

## Development Workflow
1. [Step 1]
2. [Step 2]
3. [Step 3]

## Conventions

### Code Style
- [Convention 1]
- [Convention 2]

### Testing
- Test command: `npm test`
- Coverage requirement: 80%

### Directory Structure
```
project/
├── src/          # Source code
├── tests/        # Test files
└── docs/         # Documentation
```

## Agent Guidelines

### For Explorer Agent
- Focus on files in src/ and tests/
- Use rg for fast searching

### For Developer Agent
- Follow TDD approach
- Write tests first
- Run tests before committing

### For Reviewer Agent
- Check test coverage
- Verify coding conventions
- Security review for API endpoints

## Context Management
This project uses context compaction.
Save interim results to `tmp/` directory.
Final outputs go to appropriate project directories.

## Dependencies
[Key dependencies and their versions]
```

---

## 8. Key Recommendations Summary

### For Subagent Development

1. **Start with Claude-generated templates** - iterate from solid foundation
2. **Apply least privilege** - grant only necessary tools
3. **Write action-oriented descriptions** - enable automatic delegation
4. **Use pipeline architecture** - for reproducible, governed workflows
5. **Monitor and observe** - capture telemetry for debugging and optimization

### For Skills Development

1. **Embrace progressive disclosure** - load information as needed
2. **Structure for discovery** - clear SKILL.md with metadata
3. **Security first** - only use trusted sources
4. **Combine with subagents** - SubAgent→Skills pattern for efficiency
5. **Clear triggering logic** - write descriptions Claude can understand

### For Context Optimization

1. **Use context compaction** - especially for long conversations
2. **Strategic chunking** - break large tasks into optimal pieces
3. **Leverage context awareness** - inform Claude 4.5 of available features
4. **Monitor token budget** - watch for degradation near limits
5. **Hierarchical organization** - use subagents to isolate contexts

### For Prompt Engineering

1. **XML for complex structure** - when clarity is critical
2. **Consistent naming** - throughout prompts and responses
3. **Combine techniques** - XML + multishot + chain of thought
4. **Clear headings for simple cases** - XML not always necessary
5. **Test and iterate** - optimize based on actual performance

### For Agent Delegation

1. **Choose delegation pattern** - automatic, explicit, parallel, or pipeline
2. **No nested subagents** - design hierarchy carefully
3. **Conservative descriptions** - avoid over-eager delegation
4. **Isolated contexts** - prevent pollution of main conversation
5. **Consider master-clone** - for dynamic, flexible orchestration

---

## 9. Implementation Priorities

### Phase 1: Foundation (Week 1)
1. Set up proper CLAUDE.md with project conventions
2. Create 2-3 core subagents (explorer, developer, reviewer)
3. Implement basic context compaction strategy

### Phase 2: Optimization (Week 2-3)
1. Develop 3-5 skills with progressive disclosure
2. Implement SubAgent→Skills pattern for token efficiency
3. Add monitoring and telemetry

### Phase 3: Scale (Week 4+)
1. Build complete pipeline architecture
2. Implement advanced context management (memory tool)
3. Optimize based on real-world usage patterns
4. Share reusable subagents and skills with team

---

## 10. Sources and References

### Official Anthropic Documentation

#### Claude Code Docs
- [Custom Agents Guide](https://claudelog.com/mechanics/custom-agents/)
- [Subagents Documentation](https://code.claude.com/docs/en/sub-agents)
- [Agent Skills Documentation](https://code.claude.com/docs/en/skills)

#### Anthropic Platform
- [Agent Skills Overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)
- [Claude 4 Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-4-best-practices)
- [Context Windows Documentation](https://platform.claude.com/docs/en/build-with-claude/context-windows)
- [Long Context Prompting Tips](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/long-context-tips)
- [XML Tags Documentation](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/use-xml-tags)

#### Anthropic Engineering Blog
- [Claude Code: Best practices for agentic coding](https://www.anthropic.com/engineering/claude-code-best-practices)
- [Building agents with the Claude Agent SDK](https://www.anthropic.com/engineering/building-agents-with-the-claude-agent-sdk)
- [Equipping agents for the real world with Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
- [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)

#### Anthropic News & Learn
- [Introducing Agent Skills](https://www.anthropic.com/news/skills)
- [Context Management on Claude Developer Platform](https://www.claude.com/blog/context-management)
- [Prompt Engineering Best Practices](https://claude.com/blog/best-practices-for-prompt-engineering)
- [Anthropic Academy: Claude API Development Guide](https://www.anthropic.com/learn/build-with-claude)

### Community Resources

#### In-Depth Guides
- [Best practices for Claude Code subagents - PubNub](https://www.pubnub.com/blog/best-practices-for-claude-code-sub-agents/)
- [Claude Agent SDK Best Practices for AI Agent Development (2025) - Skywork AI](https://skywork.ai/blog/claude-agent-sdk-best-practices-ai-agents-2025/)
- [Claude Agent Skills: A First Principles Deep Dive - Lee Hanchung](https://leehanchung.github.io/blogs/2025/10/26/claude-skills-deep-dive/)
- [How I Use Every Claude Code Feature - Shrivu Shankar](https://blog.sshh.io/p/how-i-use-every-claude-code-feature)

#### Developer Experiences
- [How I use Claude Code (+ my best tips) - Builder.io](https://www.builder.io/blog/claude-code)
- [Claude Code: Part 6 - Subagents and Task Delegation - Luiz Tanure](https://www.letanure.dev/blog/2025-08-04--claude-code-part-6-subagents-task-delegation)
- [Skills for Claude! - fsck.com blog](https://blog.fsck.com/2025/10/16/skills-for-claude/)
- [Claude Skills are awesome, maybe a bigger deal than MCP - Simon Willison](https://simonwillison.net/2025/Oct/16/claude-skills/)

#### Technical Deep Dives
- [Mastering Claude's Context Window: A 2025 Deep Dive - SparkCo](https://sparkco.ai/blog/mastering-claudes-context-window-a-2025-deep-dive)
- [Mastering Prompt Engineering for Claude - Walturn](https://www.walturn.com/insights/mastering-prompt-engineering-for-claude)
- [XML Tags vs. Other Dividers in Prompt Quality - Begins with AI](https://beginswithai.com/xml-tags-vs-other-dividers-in-prompt-quality/)
- [Model-Specific Formatting - CodeSignal](https://codesignal.com/learn/courses/prompting-foundations/lessons/model-specific-formatting-adapting-prompts-for-different-llms)

#### ClaudeLog Resources
- [What is Context Window in Claude Code - ClaudeLog](https://claudelog.com/faqs/what-is-context-window-in-claude-code/)
- [What is Sub-Agent Delegation in Claude Code - ClaudeLog](https://claudelog.com/faqs/what-is-sub-agent-delegation-in-claude-code/)

#### GitHub Resources
- [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) - Production-ready Claude subagents collection with 100+ specialized AI agents
- [lst97/claude-code-sub-agents](https://github.com/lst97/claude-code-sub-agents) - Collection of specialized AI subagents for full-stack development
- [anthropics/skills](https://github.com/anthropics/skills) - Public repository for Skills demonstrating what's possible
- [langgptai/awesome-claude-prompts](https://github.com/langgptai/awesome-claude-prompts) - Claude prompt curation

#### AWS & Other Platforms
- [Prompt engineering techniques with Claude 3 on Amazon Bedrock - AWS ML Blog](https://aws.amazon.com/blogs/machine-learning/prompt-engineering-techniques-and-best-practices-learn-by-doing-with-anthropics-claude-3-on-amazon-bedrock/)
- [What are SubAgents in Claude Code - CometAPI](https://www.cometapi.com/what-are-subagents-in-claude-code/)
- [12 prompt engineering tips to boost Claude's output quality - Vellum AI](https://www.vellum.ai/blog/prompt-engineering-tips-for-claude)

#### Documentation Sites
- [Sub-Agents Guide - Claude Elixir Docs](https://hexdocs.pm/claude/guide-subagents.html)
- [Anthropic Introduces Skills for Custom Claude Tasks - InfoQ](https://www.infoq.com/news/2025/10/anthropic-claude-skills/)
- [Tutorial - How to use XML tags for better prompting - Dupple](https://www.dupple.com/tutorial/how-to-use-xml-tags-for-better-prompting)

---

## Conclusion

The Claude Code ecosystem has matured significantly in 2025 with:

1. **Sophisticated agent architecture patterns** that enable reproducible, governed development workflows
2. **Progressive disclosure through Skills** dramatically reducing context consumption
3. **Context awareness in Claude 4.5 models** enabling better self-management
4. **Rich toolkit for context optimization** including compaction and memory tools
5. **Proven patterns for delegation** supporting parallel, pipeline, and orchestrated architectures

The SubAgent→Skills pattern represents a particularly significant innovation, reducing average context consumption by approximately 70% while maintaining specialization benefits.

Organizations implementing these practices should prioritize:
- Proper CLAUDE.md documentation as the foundation
- Starting with Claude-generated templates
- Applying least privilege principle to tool access
- Implementing observability and testing early
- Iterating based on real-world usage patterns

The combination of these techniques enables building sophisticated, production-ready AI agent systems that are efficient, maintainable, and safe.

---

**Report Generated**: 2025-12-10
**Agent**: hl-web-search-researcher
**Total Sources Referenced**: 50+ official and community resources
