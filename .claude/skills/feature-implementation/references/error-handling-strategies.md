# Error Handling Strategies

## Error Categories

### Operational Errors

Expected errors that can be handled gracefully:
- Invalid user input
- Network timeouts
- Resource not found
- Permission denied

### Programming Errors

Bugs that should be fixed in code:
- TypeError, ReferenceError
- Assertion failures
- Missing required configuration

## Handling Patterns

### Try-Catch with Specific Handling

```javascript
async function fetchUserData(userId) {
  try {
    const user = await userRepository.findById(userId);
    return user;
  } catch (error) {
    if (error instanceof NotFoundError) {
      // Handle not found specifically
      return null;
    }
    if (error instanceof NetworkError) {
      // Retry or use cached data
      return getCachedUser(userId);
    }
    // Re-throw unexpected errors
    throw error;
  }
}
```

### Result Pattern (No Exceptions)

```typescript
type Result<T, E> = { ok: true; value: T } | { ok: false; error: E };

function parseJSON<T>(json: string): Result<T, Error> {
  try {
    return { ok: true, value: JSON.parse(json) };
  } catch (error) {
    return { ok: false, error: error as Error };
  }
}

// Usage
const result = parseJSON<User>(jsonString);
if (result.ok) {
  console.log(result.value.name);
} else {
  console.error('Parse failed:', result.error.message);
}
```

### Error Boundaries (React)

```jsx
class ErrorBoundary extends React.Component {
  state = { hasError: false, error: null };

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    logErrorToService(error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return <ErrorFallback error={this.state.error} />;
    }
    return this.props.children;
  }
}
```

## Async Error Handling

### Promise Chains

```javascript
fetchUser(userId)
  .then(user => fetchOrders(user.id))
  .then(orders => processOrders(orders))
  .catch(error => {
    // Handle any error in the chain
    console.error('Pipeline failed:', error);
    throw error;
  });
```

### Async/Await

```javascript
async function processUserOrders(userId) {
  try {
    const user = await fetchUser(userId);
    const orders = await fetchOrders(user.id);
    return await processOrders(orders);
  } catch (error) {
    handleError(error);
    throw error;
  }
}
```

### Parallel Operations

```javascript
async function fetchAllData() {
  const results = await Promise.allSettled([
    fetchUsers(),
    fetchProducts(),
    fetchOrders()
  ]);

  const errors = results
    .filter(r => r.status === 'rejected')
    .map(r => r.reason);

  if (errors.length > 0) {
    console.warn('Some requests failed:', errors);
  }

  return results
    .filter(r => r.status === 'fulfilled')
    .map(r => r.value);
}
```

## Logging Best Practices

### Structured Logging

```javascript
function logError(error, context = {}) {
  console.error(JSON.stringify({
    timestamp: new Date().toISOString(),
    level: 'ERROR',
    message: error.message,
    stack: error.stack,
    ...context
  }));
}

// Usage
try {
  await processOrder(order);
} catch (error) {
  logError(error, {
    orderId: order.id,
    userId: order.userId,
    action: 'processOrder'
  });
  throw error;
}
```

### Log Levels

| Level | Use Case |
|-------|----------|
| ERROR | Failures requiring attention |
| WARN | Recoverable issues |
| INFO | Normal operations |
| DEBUG | Development details |

## User-Friendly Messages

```javascript
function getUserFriendlyMessage(error) {
  const messages = {
    'ValidationError': 'Please check your input and try again.',
    'NotFoundError': 'The requested item could not be found.',
    'NetworkError': 'Connection failed. Please check your internet.',
    'AuthenticationError': 'Please log in to continue.',
  };

  return messages[error.name] || 'Something went wrong. Please try again.';
}
```
