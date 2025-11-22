# Quality Gate Configuration

## Overview

Mandatory quality checks that all implementations must pass before completion.

## Gate 1: Lint

### Node.js/TypeScript (ESLint + Biome)

```bash
# ESLint
nr lint

# Or Biome
nr biome check
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
# Prettier
nr format

# Or Biome
nr biome format --write
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
