# Unit Test Patterns

## Test Structure: Arrange-Act-Assert

```javascript
test('should calculate total with discount', () => {
  // Arrange
  const items = [{ price: 100 }, { price: 200 }];
  const discount = 0.1;

  // Act
  const total = calculateTotal(items, discount);

  // Assert
  expect(total).toBe(270);
});
```

## Common Patterns

### Parameterized Tests

```javascript
test.each([
  { input: 'valid@email.com', expected: true },
  { input: 'invalid', expected: false },
  { input: '@missing.com', expected: false },
  { input: '', expected: false },
])('validateEmail($input) should return $expected', ({ input, expected }) => {
  expect(validateEmail(input)).toBe(expected);
});
```

### Testing Exceptions

```javascript
test('should throw error for invalid input', () => {
  expect(() => processData(null)).toThrow('Input cannot be null');
});

test('should throw specific error type', () => {
  expect(() => processData(null)).toThrow(ValidationError);
});
```

### Testing Async Code

```javascript
test('should fetch user data', async () => {
  const user = await userService.findById('123');
  expect(user.name).toBe('Test User');
});

test('should reject for invalid id', async () => {
  await expect(userService.findById('invalid'))
    .rejects.toThrow('User not found');
});
```

## Mocking Strategies

### Mock Functions

```javascript
const mockCallback = jest.fn();
processItems([1, 2, 3], mockCallback);

expect(mockCallback).toHaveBeenCalledTimes(3);
expect(mockCallback).toHaveBeenCalledWith(1);
```

### Mock Modules

```javascript
jest.mock('./database', () => ({
  query: jest.fn().mockResolvedValue([{ id: 1, name: 'Test' }])
}));

test('should query database', async () => {
  const result = await repository.findAll();
  expect(database.query).toHaveBeenCalled();
});
```

### Mock External Services

```javascript
beforeEach(() => {
  jest.spyOn(httpClient, 'get').mockResolvedValue({
    data: { id: 1, name: 'Test' }
  });
});

afterEach(() => {
  jest.restoreAllMocks();
});
```

## Test Isolation

### Setup and Teardown

```javascript
describe('UserService', () => {
  let service;
  let mockRepository;

  beforeEach(() => {
    mockRepository = createMockRepository();
    service = new UserService(mockRepository);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  test('should create user', async () => {
    await service.create({ name: 'Test' });
    expect(mockRepository.save).toHaveBeenCalled();
  });
});
```

## Coverage Considerations

### Branch Coverage

```javascript
// Ensure both branches are tested
function getStatus(isActive, isPremium) {
  if (isActive) {
    return isPremium ? 'premium-active' : 'active';
  }
  return 'inactive';
}

// Tests for all branches
test('returns premium-active when active and premium', () => {});
test('returns active when active but not premium', () => {});
test('returns inactive when not active', () => {});
```
