---
name: test-creation
description: Test creation specialist for TDD RED phase with integrated testing capabilities (integrated from vwsub-tester). Use when creating failing tests before implementation, designing comprehensive test suites, or establishing test coverage goals. Specializes in unit test design, integration test patterns, E2E test scenarios, boundary value testing, and test-first development. Supports Jest/Vitest, pytest, and Rust test frameworks with parallel execution support.
---

# Test Creation (RED Phase)

## Core Purpose

Create comprehensive, intentionally failing tests that define expected behavior before implementation.

## Test Creation Workflow

### Step 1: Analyze Requirements

1. **Identify behaviors** - What should the code do?
2. **Define boundaries** - Edge cases and limits
3. **Plan test structure** - Unit → Integration → E2E

### Step 2: Write Failing Tests

Tests MUST fail initially (Red phase):

```javascript
describe('UserService', () => {
  // Unit test - basic functionality
  test('should create user with valid data', () => {
    const result = userService.createUser({
      name: 'Test User',
      email: 'test@example.com'
    });

    expect(result.id).toBeDefined();
    expect(result.name).toBe('Test User');
    expect(result.createdAt).toBeInstanceOf(Date);
  });

  // Edge case - validation
  test('should throw error for invalid email', () => {
    expect(() => {
      userService.createUser({ name: 'Test', email: 'invalid' });
    }).toThrow('Invalid email format');
  });

  // Edge case - duplicate handling
  test('should throw error for duplicate email', async () => {
    await userService.createUser({ name: 'User1', email: 'dup@test.com' });

    await expect(
      userService.createUser({ name: 'User2', email: 'dup@test.com' })
    ).rejects.toThrow('Email already exists');
  });
});
```

### Step 3: Verify Tests Fail

Confirm tests fail for the right reason:

```bash
# Node.js
nr test -- --watch

# Python
uv run pytest -x --tb=short

# Rust
cargo test -- --nocapture
```

## Test Categories

### Unit Tests (Priority 1)

Test individual functions/methods:

```javascript
describe('validateEmail', () => {
  test.each([
    ['valid@email.com', true],
    ['invalid', false],
    ['@missing.com', false],
    ['spaces @email.com', false],
  ])('validateEmail(%s) should return %s', (email, expected) => {
    expect(validateEmail(email)).toBe(expected);
  });
});
```

### Integration Tests (Priority 2)

Test component interactions:

```javascript
describe('UserRepository integration', () => {
  let db: TestDatabase;
  let repository: UserRepository;

  beforeEach(async () => {
    db = await TestDatabase.create();
    repository = new UserRepository(db);
  });

  afterEach(async () => {
    await db.cleanup();
  });

  test('should persist and retrieve user', async () => {
    const user = await repository.save(new User({ name: 'Test' }));
    const retrieved = await repository.findById(user.id);
    expect(retrieved).toEqual(user);
  });
});
```

### E2E Tests (Priority 3)

Test user workflows:

```javascript
describe('User registration flow', () => {
  test('should complete registration and login', async () => {
    // Register
    const response = await request(app)
      .post('/api/register')
      .send({ name: 'Test', email: 'test@example.com', password: 'secure123' });

    expect(response.status).toBe(201);

    // Login
    const loginResponse = await request(app)
      .post('/api/login')
      .send({ email: 'test@example.com', password: 'secure123' });

    expect(loginResponse.status).toBe(200);
    expect(loginResponse.body.token).toBeDefined();
  });
});
```

## Coverage Goals

| Metric | Target |
|--------|--------|
| Line coverage | 80%+ |
| Branch coverage | 75%+ |
| Function coverage | 90%+ |
| Edge cases | All identified |

## Parallel Execution Support

When working alongside Implementation Agent:

1. **Define clear specifications** - Tests serve as documentation
2. **Export test interface** - Implementation can validate against tests
3. **Report completion** - Signal when tests are ready

## Output Deliverables

Save to `./tmp/{timestamp}-test-creation-report.md`:
- Test cases created
- Coverage plan
- Edge cases identified
- Test execution results (all should fail)

## Advanced References

For detailed patterns, see:
- [Unit Test Patterns](./references/unit-test-patterns.md)
- [Integration Test Setup](./references/integration-test-setup.md)
- [E2E Test Strategies](./references/e2e-test-strategies.md)
- [Mocking Best Practices](./references/mocking-best-practices.md)
