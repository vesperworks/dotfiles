# Tech Research Integration Guide

## Overview

This guide details the integrated tech research capabilities formerly provided by the tech-domain-researcher agent, now available as part of the codebase-exploration skill.

## Integrated Capabilities

### WebSearch Integration
Use WebSearch for finding latest technology information:
- Latest framework versions
- Best practices and patterns
- Community recommendations
- Security updates and advisories

### Context7 MCP Integration
Leverage Context7 MCP for official documentation:
- Resolve library IDs from package names
- Fetch up-to-date official documentation
- Access code examples and API references
- Compare documentation versions

## Research Workflow

### Phase 1: Technology Discovery
```
1. Identify technology needs based on requirements
2. Use WebSearch to find candidate technologies
3. Filter by relevance, popularity, and maintenance status
4. Create shortlist of 2-3 candidates
```

### Phase 2: Deep Evaluation
```
1. Use Context7 to fetch official documentation
2. Evaluate API design and developer experience
3. Check ecosystem maturity (plugins, extensions, community)
4. Assess learning curve and migration complexity
```

### Phase 3: Comparative Analysis
```
1. Create feature comparison matrix
2. Evaluate pros and cons for each candidate
3. Consider project-specific constraints
4. Document decision rationale
```

### Phase 4: Proof of Concept
```
1. Implement minimal examples with top candidates
2. Measure integration complexity
3. Evaluate performance characteristics
4. Validate against requirements
```

## Research Documentation Template

```markdown
# Technology Research: [Technology Name]

## Executive Summary
- **Purpose**: Why we're researching this
- **Recommendation**: Final recommendation with confidence level
- **Timeline**: When decision needed

## Candidates Evaluated
### [Technology A]
- **Version**: Current stable version
- **Pros**: Key advantages
- **Cons**: Notable limitations
- **Use Cases**: Where it excels

### [Technology B]
- Similar structure...

## Decision Matrix
| Criteria | Weight | Tech A | Tech B | Notes |
|----------|--------|--------|--------|-------|
| Performance | High | 8/10 | 7/10 | ... |
| DX | Medium | 9/10 | 6/10 | ... |
| Ecosystem | High | 7/10 | 9/10 | ... |

## Recommendation
**Selected Technology**: [Choice]
**Rationale**: Detailed explanation
**Implementation Plan**: Next steps

## References
- Official documentation links
- Community resources
- Example implementations
```

## Integration with Codebase Exploration

The tech research capabilities seamlessly integrate with codebase exploration:
1. **Before Implementation**: Research technologies before coding
2. **During Refactoring**: Evaluate alternative approaches
3. **For Problem Solving**: Find solutions to specific challenges
4. **Technology Updates**: Stay current with ecosystem changes

## Best Practices

1. **Document Everything**: Maintain research records for future reference
2. **Use Official Sources**: Prioritize official documentation over blog posts
3. **Consider Context**: Align technology choices with project goals
4. **Validate Practically**: Always test before committing
5. **Think Long-term**: Consider maintenance and ecosystem health

## Tools Available

- **WebSearch**: For discovering trends and community feedback
- **Context7 MCP**: For official documentation and examples
- **Read**: For analyzing local documentation and examples
- **Bash**: For running proof-of-concept tests

## Former tech-domain-researcher Features

All features from the former tech-domain-researcher agent are preserved:
- Modern tech stack research
- Scaffolding tool evaluation
- Framework comparison
- Best practice identification
- Community sentiment analysis

These capabilities are now accessible through the unified codebase-exploration skill, providing a more streamlined experience.
