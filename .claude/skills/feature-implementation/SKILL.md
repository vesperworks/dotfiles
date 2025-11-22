---
name: feature-implementation
description: Feature implementation specialist for TDD GREEN phase. Use when implementing core functionality after tests are written, building production-ready code with proper error handling, or following implementation best practices. Specializes in minimal implementation patterns, input validation, error handling strategies, performance optimization, and clean code principles. Supports parallel execution with test agents for efficient development workflows.
---

# Feature Implementation (GREEN Phase)

## Core Purpose

Implement production-ready code that passes all written tests while maintaining code quality and best practices.

## Implementation Priority Order

### 1. Core Functionality First

Write minimum code to pass tests:

```javascript
// Start with simplest implementation
function createUser(userData) {
  return { id: 1, name: userData.name };
}

// Then expand based on test requirements
function createUser(userData) {
  validateUserData(userData);
  return {
    id: generateSecureId(),
    name: userData.name,
    email: userData.email,
    createdAt: new Date()
  };
}
```

### 2. Edge Cases and Error Handling

Handle boundary conditions:

```javascript
function createUser(userData) {
  // Input validation
  if (!userData?.name) {
    throw new ValidationError('Name is required');
  }
  if (!isValidEmail(userData.email)) {
    throw new ValidationError('Invalid email format');
  }

  // Core implementation
  try {
    return this.repository.save(new User(userData));
  } catch (error) {
    if (error.code === 'DUPLICATE_EMAIL') {
      throw new ConflictError('Email already exists');
    }
    throw error;
  }
}
```

### 3. Input Validation

Validate at system boundaries:

```javascript
const userSchema = z.object({
  name: z.string().min(1).max(100),
  email: z.string().email(),
  age: z.number().int().positive().optional()
});

function createUser(rawInput) {
  const userData = userSchema.parse(rawInput);
  return this.userService.create(userData);
}
```

### 4. Performance Optimization

Apply after correctness is achieved:

```javascript
// Cache expensive computations
const memoizedGetUser = memoize(async (userId) => {
  return await this.repository.findById(userId);
}, { maxAge: 60000 });

// Batch operations when possible
async function createUsers(usersData) {
  return await this.repository.bulkInsert(usersData);
}
```

## Clean Code Principles

### Single Responsibility
```javascript
// Bad: One function doing multiple things
function processUserAndSendEmail(userData) { ... }

// Good: Separate responsibilities
function createUser(userData) { ... }
function sendWelcomeEmail(user) { ... }
```

### Dependency Injection
```javascript
class UserService {
  constructor(
    private repository: UserRepository,
    private validator: UserValidator,
    private emailService: EmailService
  ) {}
}
```

### Interface Segregation
```typescript
interface UserReader {
  findById(id: string): Promise<User>;
  findByEmail(email: string): Promise<User>;
}

interface UserWriter {
  save(user: User): Promise<User>;
  delete(id: string): Promise<void>;
}
```

## Parallel Execution Support

When working alongside Test Agent:

1. **Read test specifications** - Understand expected behavior
2. **Implement incrementally** - Match test expectations
3. **Validate independently** - Run tests locally before reporting
4. **Document decisions** - Record implementation choices

## Output Deliverables

Save to `./tmp/{timestamp}-implementation-report.md`:
- Core functionality implemented
- Error handling strategies applied
- Validation rules implemented
- Performance considerations

## Advanced References

For detailed patterns, see:
- [Clean Code Patterns](./references/clean-code-patterns.md)
- [Error Handling Strategies](./references/error-handling-strategies.md)
- [Performance Optimization Guide](./references/performance-optimization.md)
