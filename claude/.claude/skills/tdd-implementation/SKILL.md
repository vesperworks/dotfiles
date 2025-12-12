---
name: tdd-implementation
description: Test-Driven Development implementation cycle (Red-Green-Refactor) with integrated debugging capabilities (integrated from error-debugger). Use when implementing new features with comprehensive test coverage, diagnosing errors, or following TDD methodology. Specializes in unit test design, mocking strategies, error diagnosis, root cause analysis, and test-first development workflow with systematic debugging when failures occur. Supports Node.js/TypeScript, Python, and Rust projects with MCP integration for Context7 documentation. NOT for strategic requirement definition (use strategic-planning) and NOT for final release review only (use quality-assurance/vw-reviewer).
---

# TDD Implementation + Debugging

## Core Purpose

Execute Test-Driven Development cycles with integrated error diagnosis capabilities for comprehensive quality assurance.

## Red-Green-Refactor Cycle

### Step 1: Red (Write Failing Test)

1. **Define expected behavior** - Clarify what the code should do
2. **Write test first** - Create test that defines desired behavior
3. **Verify test fails** - Confirm test fails for the right reason

```javascript
// Example: Red phase
describe('UserService', () => {
  test('should create user with valid data', () => {
    const result = userService.createUser({ name: 'Test', email: 'test@example.com' });
    expect(result.id).toBeDefined();
    expect(result.name).toBe('Test');
  });
});
```

### Step 2: Green (Minimal Implementation)

1. **Write minimum code** - Just enough to pass the test
2. **No optimization yet** - Focus on correctness only
3. **Run tests** - Verify test passes

```javascript
// Example: Green phase - minimal implementation
function createUser(userData) {
  return {
    id: generateId(),
    name: userData.name,
    email: userData.email
  };
}
```

### Step 3: Refactor (Improve Code Quality)

1. **Improve code structure** - Without changing behavior
2. **Run tests again** - Ensure tests still pass
3. **Commit changes** - Atomic commits per cycle

```javascript
// Example: Refactor phase
class UserService {
  constructor(private repository: UserRepository) {}

  createUser(userData: UserData): User {
    this.validateUserData(userData);
    const user = new User(userData);
    return this.repository.save(user);
  }
}
```

### Step 4: Debug (Integrated Capability)

When tests fail unexpectedly, apply systematic debugging:

1. **Stack trace analysis** - Identify error origin
2. **Logging enhancement** - Add strategic log points
3. **Unit test isolation** - Narrow down failure scope
4. **Root cause identification** - Find underlying issue

```javascript
// Debugging approach
try {
  const result = userService.createUser(userData);
} catch (error) {
  console.error('Creation failed:', {
    error: error.message,
    stack: error.stack,
    userData: sanitize(userData)
  });
  throw error;
}
```

## Project-Specific Patterns

### Node.js/TypeScript

**Biome検出**: `@biomejs/biome`依存 または `biome.json`存在でBiome使用

- Use Jest/Vitest for testing
- `nr test` for running tests
- Biome: `nr biome:check --write` before commit
- ESLint/Prettier (fallback): `nr lint && nr format` before commit

### Python
- Use pytest for testing
- `uv run pytest` for running tests
- `uv run ruff check && uv run ruff format`

### Rust
- Use `#[cfg(test)]` module
- `cargo test` for running tests
- `cargo clippy && cargo fmt`

## Rollback / Recovery (TDD失敗時)
- Red/Green のどこで破綻したかを特定し、失敗テストを最小再現ケースとして残す
- 実装が不適切な場合は最後のコミットを `git revert`、未コミットなら `git restore` で戻し、Red から再開
- デバッグで追加したロギング・フラグは復旧後に掃除し、再発防止メモを `./.brain/report/{timestamp}-tdd.md` に追記

## Output Deliverables

Save results to `./.brain/report/{timestamp}-tdd.md`:
- Test cases created (Red phase)
- Implementation details (Green phase)
- Refactoring improvements (Refactor phase)
- Debug findings if applicable

## Advanced References

For detailed methodologies, see:
- [Red-Green-Refactor Cycle](./references/red-green-refactor.md)
- [Test Patterns](./references/test-patterns.md)
- [Debugging Strategies Integration](./references/debugging-strategies.md)
- [MCP Integration for Testing](./references/mcp-testing-integration.md)
