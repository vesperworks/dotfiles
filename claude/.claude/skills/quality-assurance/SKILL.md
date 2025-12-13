---
name: quality-assurance
description: Quality assurance and test verification specialist. Use when validating implementation quality, measuring test coverage, verifying code meets standards, or performing comprehensive quality checks. Specializes in test execution validation, coverage analysis, performance metrics, security scanning, and quality gate enforcement (Lint→Format→Test→Build). Integrates with Playwright/Puppeteer MCP for E2E validation and Context7 for project-specific standards. NOT for feature ideation/requirements definition (use strategic-planning) and NOT for implementing new code (use tdd-implementation/feature-implementation).
---

# Quality Assurance

## Core Purpose

Comprehensive quality verification ensuring implementations meet all quality standards and pass mandatory quality gates.

## Quality Gate Enforcement (Mandatory)

All implementations MUST pass the quality gates in order: **Lint → Format → Test → Build**

### 統一コマンド

| プロジェクト | Check | Fix | Test | Build |
|-------------|-------|-----|------|-------|
| Node.js/TS | `nr check` | `nr check:fix` | `nr test` | `nr build` |
| Python | `uv run ruff check` | `uv run ruff check --fix` | `uv run pytest` | - |
| Rust | `cargo clippy` | `cargo clippy --fix` | `cargo test` | `cargo build` |

**詳細な設定・トラブルシューティング**: [quality-gate-config.md](./references/quality-gate-config.md) 参照

## Quality Metrics Collection

### Test Execution Summary

```markdown
## Test Results
- Total: X tests
- Passed: X
- Failed: X
- Skipped: X
- Duration: Xs
```

### Coverage Analysis

```markdown
## Coverage Report
### Code Coverage
- Lines: X%
- Branches: X%
- Functions: X%
- Statements: X%

### Feature Coverage
- [Feature 1]: ✅ Fully covered
- [Feature 2]: ⚠️ Partially covered (missing edge cases)
- [Feature 3]: ❌ Not covered
```

### Performance Metrics

```markdown
## Performance
- Initial load time: Xms
- API response time: Xms (average)
- Memory usage: XMB (peak)
```

## Issue Classification

### Critical (Immediate Action Required)
- Security vulnerabilities
- Data loss risks
- Production blockers

### High (Early Resolution Needed)
- Performance degradation
- Maintainability issues
- Test failures

### Medium (Planned Resolution)
- Code style violations
- Minor performance issues
- Documentation gaps

### Low (Improvement Suggestions)
- Style preferences
- Optional optimizations
- Future enhancements

## MCP Integration for Verification

### Playwright E2E Validation
```javascript
// Verify user workflows
await page.goto('/login');
await page.fill('[name="email"]', 'test@example.com');
await page.fill('[name="password"]', 'password');
await page.click('button[type="submit"]');
await expect(page).toHaveURL('/dashboard');
```

### Performance Testing
```javascript
// Measure page metrics
const metrics = await page.evaluate(() => ({
  loadTime: performance.timing.loadEventEnd - performance.timing.navigationStart,
  domReady: performance.timing.domContentLoadedEventEnd - performance.timing.navigationStart
}));
```

## Quality Report Template

```markdown
# Quality Assurance Report

## Summary
- **Quality Score**: X/100
- **Release Decision**: Go / No-Go
- **Date**: YYYY-MM-DD

## Quality Gate Results
| Gate | Status | Details |
|------|--------|---------|
| Lint | ✅/❌ | X issues |
| Format | ✅/❌ | X files |
| Test | ✅/❌ | X/Y passed |
| Build | ✅/❌ | Duration |

## Issues Found
### Critical
- None / [Issue description]

### High
- [Issue description]

### Medium
- [Issue description]

## Recommendations
1. [Specific recommendation]
2. [Specific recommendation]

## Next Steps
- [Action items]
```

## Rollback / Recovery (品質ゲート失敗時)
- 失敗したゲートと原因を列挙し、影響範囲と再テストに必要な修正を明示
- コードが問題の場合は該当コミットを `git revert` で戻すか、フィーチャートグルで無効化してから再検証
- レポートに再発防止策と再実行結果を追記し、Go/No-Go 判定を更新

## Output Deliverables

Save to `./.brain/report/{timestamp}-qa.md`:
- Quality gate results
- Coverage analysis
- Issues found with severity
- Recommendations
- Release decision

## Advanced References

For detailed methodologies, see:
- [Quality Gate Configuration](./references/quality-gate-config.md)
- [Coverage Best Practices](./references/coverage-best-practices.md)
- [Performance Testing Guide](./references/performance-testing.md)
- [Security Scanning Integration](./references/security-scanning.md)
