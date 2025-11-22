# MCP Integration Patterns

## Overview

Model Context Protocol (MCP) integration enables enhanced codebase exploration through external tools and services.

## Available MCP Tools

### Context7 Integration

Context7 provides up-to-date library documentation access.

#### resolve-library-id

Resolves package names to Context7-compatible library IDs.

```javascript
// Usage
mcp__context7__resolve-library-id({
  libraryName: "react"
})

// Returns library ID for documentation lookup
```

#### get-library-docs

Fetches documentation for resolved libraries.

```javascript
// Usage
mcp__context7__get-library-docs({
  context7CompatibleLibraryID: "/facebook/react",
  topic: "hooks"  // Optional: focus on specific topic
})
```

### Playwright MCP (Browser Automation)

For E2E testing and web application exploration.

```javascript
// Navigation
mcp__playwright-server__browser_navigate({ url: "http://localhost:3000" })

// Page snapshot (accessibility tree)
mcp__playwright-server__browser_snapshot()

// Element interaction
mcp__playwright-server__browser_click({ element: "Login button", ref: "btn-login" })
```

## Integration Patterns

### Pattern 1: Library Research Flow

```
1. WebSearch → Find latest library information
2. resolve-library-id → Get Context7 ID
3. get-library-docs → Fetch official documentation
4. Analyze → Compare with codebase patterns
```

### Pattern 2: Codebase + Docs Correlation

```
1. Grep/Glob → Find library usage in codebase
2. Read → Understand current implementation
3. get-library-docs → Check official best practices
4. Report → Identify gaps or improvements
```

### Pattern 3: E2E Exploration

```
1. browser_navigate → Access application
2. browser_snapshot → Capture current state
3. Analyze → Compare with expected behavior
4. Report → Document findings
```

## Best Practices

1. **Always resolve library ID first** before fetching docs
2. **Use topic parameter** to focus documentation retrieval
3. **Cache results** when exploring multiple aspects of same library
4. **Combine sources** - WebSearch for latest news, Context7 for official docs
5. **Validate MCP availability** before relying on external tools

## Error Handling

```javascript
// Check MCP tool availability
try {
  const result = await mcp__context7__resolve-library-id({ libraryName: "unknown" });
} catch (error) {
  // Fall back to WebSearch or manual documentation
  console.log("MCP unavailable, using fallback");
}
```

## Related References

- [Tech Research Integration](./tech-research-integration.md)
- [Advanced Analysis Methods](./advanced-analysis-methods.md)
