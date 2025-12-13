# Quality Gate Configuration

## Overview

Mandatory quality checks that all implementations must pass before completion.

**実行順序**: Lint → Format → Test → Build（途中失敗でも全ゲート実行）

## 統一コマンド（package.json scripts）

各プロジェクトで以下の scripts を設定することで、ツールに依存しない統一コマンドを実現:

```json
{
  "scripts": {
    "check": "biome check . || (eslint . && prettier --check .)",
    "check:fix": "biome check --write . || (eslint --fix . && prettier --write .)",
    "test": "vitest run",
    "build": "tsc"
  }
}
```

## Gate 1: Lint + Format (Check)

### Node.js/TypeScript

```bash
nr check      # Lint + Format 確認
nr check:fix  # 自動修正
```

**Common Issues:**
- Unused variables
- Missing return types
- Import order violations
- Inconsistent formatting

### Python (Ruff)

```bash
uv run ruff check .
uv run ruff format --check .
```

### Rust (Clippy + Fmt)

```bash
cargo clippy -- -D warnings
cargo fmt --check
```

## Gate 2: Test

### Node.js/TypeScript

```bash
nr test
```

**Required Metrics:**
- All tests pass
- Coverage > 80%
- No skipped tests in CI

### Python

```bash
uv run pytest --cov=src --cov-fail-under=80
```

### Rust

```bash
cargo test --all-features
```

## Gate 3: Build

### Node.js/TypeScript

```bash
nr build
```

**Verification:**
- No TypeScript errors
- Bundle size within limits
- Assets generated correctly

### Rust

```bash
cargo build --release
```

## Automated Pipeline

```yaml
# Example CI configuration
quality-gates:
  steps:
    - name: Lint
      run: nr lint

    - name: Format Check
      run: nr format:check

    - name: Test
      run: nr test --coverage

    - name: Build
      run: nr build
```

## Failure Handling

### Gate Failure Actions

| Gate | On Failure | Resolution |
|------|------------|------------|
| Lint | Block merge | Fix violations |
| Format | Auto-fix | Run formatter |
| Test | Block merge | Fix tests |
| Build | Block merge | Fix build errors |

### Emergency Bypass

Only with explicit approval and documented reason:

```bash
# Document bypass reason
git commit -m "Emergency: bypass lint due to [reason]

Approved by: [approver]
Ticket: [ticket-number]"
```

## Quality Score Calculation

```
Score = (Lint Pass × 25) + (Format Pass × 25) + (Test Pass × 30) + (Build Pass × 20)

100 = All gates pass
0 = No gates pass
```
