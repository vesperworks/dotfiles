# Red-Green-Refactor Cycle

## Overview

The Red-Green-Refactor cycle is the fundamental rhythm of Test-Driven Development.

## Red Phase: Write Failing Test

### Purpose
Define expected behavior before implementation exists.

### Guidelines
1. **One test at a time** - Focus on single behavior
2. **Clear naming** - Test name describes expected behavior
3. **Verify failure** - Ensure test fails for the right reason

### Example
```javascript
test('should return user by id', async () => {
  const user = await userService.findById('user-123');
  expect(user).toBeDefined();
  expect(user.id).toBe('user-123');
});
```

## Green Phase: Minimal Implementation

### Purpose
Write just enough code to make the test pass.

### Guidelines
1. **No optimization** - Correctness over performance
2. **Hardcode if needed** - Start simple, generalize later
3. **Run test frequently** - Fast feedback loop

### Example
```javascript
// Start simple
async findById(id) {
  return { id, name: 'Test User' };
}

// Then implement properly
async findById(id) {
  return this.repository.findOne({ where: { id } });
}
```

## Refactor Phase: Improve Quality

### Purpose
Improve code structure without changing behavior.

### Guidelines
1. **All tests pass** - Never break existing tests
2. **Small steps** - One refactoring at a time
3. **Commit frequently** - Track changes

### Common Refactorings
- Extract method
- Rename variable
- Remove duplication
- Introduce design pattern

## Anti-Patterns to Avoid

### Testing Implementation Details
```javascript
// Bad: Tests internal state
expect(service._internalCache.size).toBe(5);

// Good: Tests observable behavior
expect(service.getCachedItems()).toHaveLength(5);
```

### Skipping the Red Phase
Always verify your test fails before implementing.

### Over-Engineering in Green Phase
Keep it simple - refactor later.
