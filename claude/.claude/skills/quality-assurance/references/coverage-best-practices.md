# Coverage Best Practices

## Coverage Types

### Line Coverage

Measures which lines were executed:

```javascript
function calculatePrice(quantity, unitPrice, discount) {
  let total = quantity * unitPrice;  // Line 1
  if (discount > 0) {                // Line 2
    total = total * (1 - discount);  // Line 3 - need test with discount
  }
  return total;                      // Line 4
}
```

### Branch Coverage

Measures which conditional paths were taken:

```javascript
// Two branches: discount > 0 (true/false)
function calculatePrice(quantity, unitPrice, discount) {
  let total = quantity * unitPrice;
  if (discount > 0) {      // Branch 1: true
    total *= (1 - discount);
  }                        // Branch 2: false (implicit else)
  return total;
}

// Tests for full branch coverage
test('applies discount when positive', () => {
  expect(calculatePrice(10, 100, 0.1)).toBe(900);
});

test('no discount when zero', () => {
  expect(calculatePrice(10, 100, 0)).toBe(1000);
});
```

### Function Coverage

Measures which functions were called:

```javascript
// All exported functions should have at least one test
export function create() { }  // ✓ Tested
export function read() { }    // ✓ Tested
export function update() { }  // ✓ Tested
export function delete() { }  // ✗ Not tested - reduce coverage
```

## Coverage Targets

### Recommended Minimums

| Type | Target | Critical Code |
|------|--------|---------------|
| Line | 80% | 90% |
| Branch | 75% | 85% |
| Function | 90% | 95% |
| Statement | 80% | 90% |

### Configuration

```javascript
// jest.config.js
module.exports = {
  coverageThreshold: {
    global: {
      branches: 75,
      functions: 90,
      lines: 80,
      statements: 80
    },
    './src/critical/': {
      branches: 85,
      functions: 95,
      lines: 90,
      statements: 90
    }
  }
};
```

## Quality Over Quantity

### Good Coverage

Tests meaningful behavior:

```javascript
test('user creation validates required fields', () => {
  expect(() => createUser({})).toThrow('Name is required');
  expect(() => createUser({ name: 'Test' })).toThrow('Email is required');
});

test('user creation handles valid input', () => {
  const user = createUser({ name: 'Test', email: 'test@example.com' });
  expect(user.id).toBeDefined();
});
```

### Bad Coverage (Gaming Metrics)

```javascript
// This increases coverage but tests nothing useful
test('function exists', () => {
  expect(createUser).toBeDefined();
});

// This executes code without verifying behavior
test('runs without error', () => {
  createUser({ name: 'Test', email: 'test@example.com' });
  // No assertions!
});
```

## Identifying Gaps

### Uncovered Code Analysis

```bash
# Generate coverage report
nr test --coverage

# View HTML report
open coverage/lcov-report/index.html
```

### Common Gaps

1. **Error handlers** - Often missed
2. **Edge cases** - Boundary conditions
3. **Async paths** - Promise rejections
4. **Switch defaults** - Default case in switch

### Filling Gaps Strategically

```javascript
// Prioritize testing:
// 1. Business-critical paths
// 2. Error-prone code
// 3. Complex logic
// 4. Recently changed code

// Don't obsess over:
// - Simple getters/setters
// - Generated code
// - Third-party wrapper code
```

## Excluding from Coverage

### Config-Based Exclusions

```javascript
// jest.config.js
module.exports = {
  coveragePathIgnorePatterns: [
    '/node_modules/',
    '/__tests__/',
    '/generated/',
    '\\.d\\.ts$'
  ]
};
```

### Inline Exclusions

```javascript
/* istanbul ignore next */
function debugOnlyFunction() {
  // Not counted in coverage
}

/* istanbul ignore if */
if (process.env.NODE_ENV === 'development') {
  enableDevTools();
}
```

## Continuous Integration

```yaml
# CI pipeline
test:
  script:
    - npm run test:coverage
  coverage: /All files[^|]*\|[^|]*\s+([\d\.]+)/
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura-coverage.xml
```
