# Quality Gate Configuration

## Overview

Mandatory quality checks that all implementations must pass before completion.

## Biome Detection (Node.js/TypeScript)

```bash
# Biome検出: package.json依存 OR biome.json存在
if grep -q '"@biomejs/biome"' package.json 2>/dev/null || [ -f "biome.json" ]; then
  USE_BIOME=true
else
  USE_BIOME=false
fi
```

**検出条件**（いずれかを満たせばBiome使用）:
1. `package.json`に`@biomejs/biome`依存がある
2. プロジェクトルートに`biome.json`が存在する

**優先順位**: Biome > ESLint/Prettier

## Gate 1: Lint

### Node.js/TypeScript

```bash
# Biome (推奨)
nr biome:check

# ESLint (fallback)
nr lint
```

**Common Issues:**
- Unused variables
- Missing return types
- Import order violations

### Python (Ruff)

```bash
uv run ruff check .
```

**Common Issues:**
- Line too long
- Unused imports
- Missing docstrings

### Rust (Clippy)

```bash
cargo clippy -- -D warnings
```

**Common Issues:**
- Unnecessary clone
- Missing error handling
- Inefficient patterns

## Gate 2: Format

### Node.js/TypeScript

```bash
# Biome (推奨)
nr biome:check --write

# Prettier (fallback)
nr format
```

### Python

```bash
uv run ruff format .
```

### Rust

```bash
cargo fmt
```

## Gate 3: Test

### Node.js/TypeScript

```bash
# Jest
nr test

# Vitest
nr test run
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

## Gate 4: Build

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
