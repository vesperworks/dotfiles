# Integration Test Setup

## Test Environment Configuration

### Database Setup

```javascript
// test/setup/database.js
import { TestDatabase } from './test-database';

let testDb;

beforeAll(async () => {
  testDb = await TestDatabase.create();
});

afterAll(async () => {
  await testDb.destroy();
});

beforeEach(async () => {
  await testDb.reset();
});

export { testDb };
```

### Test Database Options

```javascript
// Option 1: In-memory SQLite
const testDb = new Database(':memory:');

// Option 2: Docker container
const container = await new PostgreSQLContainer()
  .withDatabase('test')
  .start();

// Option 3: Test schema in existing database
const testDb = await database.connect({
  schema: `test_${Date.now()}`
});
```

## API Integration Tests

### HTTP Client Setup

```javascript
import request from 'supertest';
import { app } from '../src/app';

describe('User API', () => {
  test('POST /users creates new user', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({
        name: 'Test User',
        email: 'test@example.com'
      })
      .expect(201);

    expect(response.body.id).toBeDefined();
    expect(response.body.name).toBe('Test User');
  });

  test('GET /users/:id returns user', async () => {
    // Setup: Create user first
    const createResponse = await request(app)
      .post('/api/users')
      .send({ name: 'Test', email: 'test@example.com' });

    // Test: Retrieve user
    const response = await request(app)
      .get(`/api/users/${createResponse.body.id}`)
      .expect(200);

    expect(response.body.name).toBe('Test');
  });
});
```

### Authentication in Tests

```javascript
describe('Protected API', () => {
  let authToken;

  beforeAll(async () => {
    // Get auth token for tests
    const loginResponse = await request(app)
      .post('/api/login')
      .send({ email: 'test@example.com', password: 'password' });

    authToken = loginResponse.body.token;
  });

  test('returns data for authenticated request', async () => {
    const response = await request(app)
      .get('/api/protected')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    expect(response.body.data).toBeDefined();
  });

  test('returns 401 for unauthenticated request', async () => {
    await request(app)
      .get('/api/protected')
      .expect(401);
  });
});
```

## Service Integration Tests

### External Service Mocking

```javascript
import nock from 'nock';

describe('PaymentService', () => {
  beforeEach(() => {
    // Mock Stripe API
    nock('https://api.stripe.com')
      .post('/v1/charges')
      .reply(200, {
        id: 'ch_test_123',
        status: 'succeeded'
      });
  });

  afterEach(() => {
    nock.cleanAll();
  });

  test('processes payment successfully', async () => {
    const result = await paymentService.charge({
      amount: 1000,
      currency: 'usd',
      source: 'tok_test'
    });

    expect(result.status).toBe('succeeded');
  });
});
```

### Database Transaction Tests

```javascript
describe('OrderService with transactions', () => {
  test('rolls back on failure', async () => {
    const initialBalance = await walletService.getBalance(userId);

    try {
      await orderService.createOrder({
        userId,
        items: [{ id: 'invalid', quantity: 1 }]
      });
    } catch (error) {
      // Expected to fail
    }

    // Balance should remain unchanged
    const finalBalance = await walletService.getBalance(userId);
    expect(finalBalance).toBe(initialBalance);
  });
});
```

## Test Data Management

### Fixtures

```javascript
// test/fixtures/users.js
export const testUsers = {
  admin: {
    id: 'user-admin',
    name: 'Admin User',
    email: 'admin@example.com',
    role: 'admin'
  },
  regular: {
    id: 'user-regular',
    name: 'Regular User',
    email: 'user@example.com',
    role: 'user'
  }
};
```

### Factories

```javascript
// test/factories/user.factory.js
import { faker } from '@faker-js/faker';

export function createUser(overrides = {}) {
  return {
    id: faker.string.uuid(),
    name: faker.person.fullName(),
    email: faker.internet.email(),
    createdAt: new Date(),
    ...overrides
  };
}

// Usage
const user = createUser({ role: 'admin' });
```
