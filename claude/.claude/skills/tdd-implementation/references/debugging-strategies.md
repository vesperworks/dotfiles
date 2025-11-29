# Debugging Strategies (Integrated from error-debugger)

## Overview

Systematic debugging approaches integrated from the former error-debugger agent.

## Root Cause Analysis

### Step 1: Reproduce the Error

```javascript
// Create minimal reproduction
test('reproduces the bug', () => {
  const input = { /* minimal failing input */ };
  expect(() => processData(input)).toThrow('Expected error');
});
```

### Step 2: Analyze Stack Trace

Key information to extract:
- Error message and type
- File and line number
- Call stack sequence
- Variable values at failure

### Step 3: Isolate the Problem

```javascript
// Narrow down scope
describe('isolating bug', () => {
  test('step 1 works', () => { /* passes */ });
  test('step 2 works', () => { /* passes */ });
  test('step 3 fails', () => { /* FAILS - bug is here */ });
});
```

## Common Error Patterns

### TypeError: Cannot read property 'x' of undefined

**Cause**: Accessing property on undefined/null value

**Solution**:
```javascript
// Bad
const name = user.profile.name;

// Good
const name = user?.profile?.name ?? 'Unknown';
```

### Async/Await Errors

**Cause**: Missing await or unhandled promise rejection

**Solution**:
```javascript
// Bad
function getData() {
  return fetchData(); // Missing await
}

// Good
async function getData() {
  return await fetchData();
}
```

### State Mutation Bugs

**Cause**: Unintended side effects

**Solution**:
```javascript
// Bad
function addItem(array, item) {
  array.push(item);
  return array;
}

// Good
function addItem(array, item) {
  return [...array, item];
}
```

## Debugging Tools

### Strategic Logging

```javascript
function debugProcess(data) {
  console.log('[DEBUG] Input:', JSON.stringify(data, null, 2));

  const result = processStep1(data);
  console.log('[DEBUG] After step 1:', result);

  const final = processStep2(result);
  console.log('[DEBUG] Final result:', final);

  return final;
}
```

### Breakpoint Placement

1. Place breakpoint at error line
2. Step backward to find cause
3. Inspect variable values

### Test Isolation

```bash
# Run single test
nr test -- --grep "specific test name"

# Run with verbose output
nr test -- --verbose
```

## Error Recovery Patterns

### Graceful Degradation

```javascript
async function fetchUserWithFallback(userId) {
  try {
    return await fetchUser(userId);
  } catch (error) {
    console.error('Fetch failed, using cache:', error.message);
    return getCachedUser(userId);
  }
}
```

### Retry with Backoff

```javascript
async function retryWithBackoff(fn, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await delay(Math.pow(2, i) * 1000);
    }
  }
}
```
