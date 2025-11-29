# Test Patterns for TDD

## Test Design Principles

### F.I.R.S.T Principles

- **Fast**: Tests should run quickly
- **Independent**: No dependencies between tests
- **Repeatable**: Same results every time
- **Self-validating**: Pass/fail without manual inspection
- **Timely**: Written before or with the code

## Behavior-Based Testing

### Given-When-Then Structure

```javascript
describe('ShoppingCart', () => {
  describe('when adding items', () => {
    test('should increase total for single item', () => {
      // Given
      const cart = new ShoppingCart();
      const item = { id: '1', price: 100 };

      // When
      cart.addItem(item);

      // Then
      expect(cart.total).toBe(100);
    });

    test('should accumulate totals for multiple items', () => {
      // Given
      const cart = new ShoppingCart();

      // When
      cart.addItem({ id: '1', price: 100 });
      cart.addItem({ id: '2', price: 200 });

      // Then
      expect(cart.total).toBe(300);
    });
  });
});
```

## Testing Strategies by Type

### Pure Functions

```javascript
// Easy to test - same input always produces same output
function add(a, b) {
  return a + b;
}

test('add returns sum of two numbers', () => {
  expect(add(2, 3)).toBe(5);
});
```

### Functions with Side Effects

```javascript
// Inject dependencies for testability
class OrderService {
  constructor(repository, emailService) {
    this.repository = repository;
    this.emailService = emailService;
  }

  async createOrder(orderData) {
    const order = await this.repository.save(orderData);
    await this.emailService.sendConfirmation(order);
    return order;
  }
}

test('createOrder sends confirmation email', async () => {
  const mockRepo = { save: jest.fn().mockResolvedValue({ id: '1' }) };
  const mockEmail = { sendConfirmation: jest.fn() };
  const service = new OrderService(mockRepo, mockEmail);

  await service.createOrder({ product: 'Test' });

  expect(mockEmail.sendConfirmation).toHaveBeenCalled();
});
```

### Async Operations

```javascript
// Testing async/await
test('fetches user data', async () => {
  const user = await userService.getUser('123');
  expect(user.id).toBe('123');
});

// Testing error rejection
test('throws error for non-existent user', async () => {
  await expect(userService.getUser('invalid'))
    .rejects.toThrow('User not found');
});
```

## Test Organization

### Test File Structure

```
tests/
├── unit/
│   ├── services/
│   │   └── userService.test.js
│   └── utils/
│       └── validators.test.js
├── integration/
│   └── api/
│       └── users.test.js
└── e2e/
    └── auth.test.js
```

### Naming Conventions

```javascript
// Describe what is being tested
describe('UserService', () => {
  // Describe the method/action
  describe('createUser', () => {
    // Describe the expected behavior
    test('should create user with valid data', () => {});
    test('should throw error for duplicate email', () => {});
  });
});
```

## Edge Case Testing

### Boundary Values

```javascript
test.each([
  { input: 0, expected: 'zero' },
  { input: 1, expected: 'positive' },
  { input: -1, expected: 'negative' },
  { input: Number.MAX_VALUE, expected: 'positive' },
  { input: Number.MIN_VALUE, expected: 'negative' },
])('classifyNumber($input) returns $expected', ({ input, expected }) => {
  expect(classifyNumber(input)).toBe(expected);
});
```

### Error Conditions

```javascript
describe('error handling', () => {
  test('handles null input', () => {
    expect(() => processData(null)).toThrow();
  });

  test('handles undefined input', () => {
    expect(() => processData(undefined)).toThrow();
  });

  test('handles empty string', () => {
    expect(() => processData('')).toThrow();
  });
});
```
