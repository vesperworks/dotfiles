---
name: vw:websearch
allowed-tools: Bash(gemini:*)
description: 'Deep web search via Gemini CLI for conceptual explanations and background research'
---

## Gemini Web Search (Deep Conceptual Search)

**Purpose**: Use Gemini CLI for in-depth conceptual explanations and background research.

### When to Use This Tool

Use `/vw:websearch` instead of WebSearch when you need:
- **Deep conceptual explanations** (e.g., "What is event-driven architecture?")
- **Background context** (e.g., "Why was React created?")
- **Comparative analysis** (e.g., "Differences between REST and GraphQL")
- **Technology trends** (e.g., "State of async Rust in 2025")

### When NOT to Use This Tool

Use WebSearch (built-in) instead when you need:
- **Verifiable facts with source URLs**
- **Official documentation links**
- **Specific version information**
- **Citations for reports or articles**

### Usage

```
/vw:websearch "概念や技術の背景を知りたいクエリ"
```

### How It Works

1. Receive command like `/vw:websearch [arguments]`
2. Extract 2-3 focused keywords from the query
3. Execute: `gemini -p 'google_web_search: [keywords]'`

### Characteristics

| Aspect | Gemini CLI | WebSearch (built-in) |
|--------|-----------|---------------------|
| **Strength** | Deep analysis, context | Source URLs, verification |
| **Output** | Natural language explanation | Structured with links |
| **Best for** | Understanding concepts | Fact-checking, citations |

### Example

```bash
# Good use case - conceptual understanding
/vw:websearch "Why did JavaScript add async/await"

# Better with WebSearch - need source links
# Use WebSearch for: "Next.js 15 release notes"
```
