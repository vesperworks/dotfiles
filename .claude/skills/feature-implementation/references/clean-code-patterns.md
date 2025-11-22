# Clean Code Patterns

## SOLID Principles in Practice

### Single Responsibility Principle

```javascript
// Bad: Multiple responsibilities
class UserManager {
  createUser(data) { /* ... */ }
  sendEmail(user) { /* ... */ }
  generateReport(user) { /* ... */ }
}

// Good: Separate responsibilities
class UserService {
  createUser(data) { /* ... */ }
}

class EmailService {
  sendEmail(recipient, content) { /* ... */ }
}

class ReportGenerator {
  generate(data) { /* ... */ }
}
```

### Open/Closed Principle

```javascript
// Open for extension, closed for modification
interface PaymentProcessor {
  process(payment: Payment): Promise<Result>;
}

class CreditCardProcessor implements PaymentProcessor {
  async process(payment) { /* credit card logic */ }
}

class PayPalProcessor implements PaymentProcessor {
  async process(payment) { /* PayPal logic */ }
}

// Add new payment methods without modifying existing code
class CryptoProcessor implements PaymentProcessor {
  async process(payment) { /* crypto logic */ }
}
```

### Dependency Inversion Principle

```javascript
// Bad: Depends on concrete implementation
class OrderService {
  constructor() {
    this.database = new MySQLDatabase();
  }
}

// Good: Depends on abstraction
class OrderService {
  constructor(database: Database) {
    this.database = database;
  }
}
```

## Naming Conventions

### Variables

```javascript
// Bad
const d = new Date();
const arr = users.filter(u => u.active);

// Good
const currentDate = new Date();
const activeUsers = users.filter(user => user.isActive);
```

### Functions

```javascript
// Bad
function process(data) { /* ... */ }
function handleClick() { /* ... */ }

// Good
function validateUserInput(formData) { /* ... */ }
function navigateToUserProfile() { /* ... */ }
```

### Boolean Variables

```javascript
// Use prefixes: is, has, can, should
const isActive = true;
const hasPermission = false;
const canEdit = true;
const shouldRefresh = false;
```

## Function Design

### Keep Functions Small

```javascript
// Bad: Long function doing multiple things
function processOrder(order) {
  // 50+ lines of validation
  // 30+ lines of calculation
  // 20+ lines of persistence
  // 15+ lines of notification
}

// Good: Small, focused functions
function processOrder(order) {
  validateOrder(order);
  const total = calculateTotal(order);
  const savedOrder = saveOrder(order, total);
  notifyCustomer(savedOrder);
  return savedOrder;
}
```

### Limit Parameters

```javascript
// Bad: Too many parameters
function createUser(name, email, age, address, phone, role) {}

// Good: Use options object
function createUser(options: CreateUserOptions) {}

interface CreateUserOptions {
  name: string;
  email: string;
  age?: number;
  address?: Address;
  phone?: string;
  role?: UserRole;
}
```

## Error Handling

### Use Custom Errors

```javascript
class ValidationError extends Error {
  constructor(field: string, message: string) {
    super(message);
    this.name = 'ValidationError';
    this.field = field;
  }
}

class NotFoundError extends Error {
  constructor(resource: string, id: string) {
    super(`${resource} with id ${id} not found`);
    this.name = 'NotFoundError';
  }
}
```

### Fail Fast

```javascript
function processPayment(payment) {
  // Validate early
  if (!payment) throw new ValidationError('payment', 'Payment is required');
  if (!payment.amount) throw new ValidationError('amount', 'Amount is required');
  if (payment.amount <= 0) throw new ValidationError('amount', 'Amount must be positive');

  // Process after validation
  return this.paymentGateway.charge(payment);
}
```

## Code Organization

### Consistent Structure

```
src/
├── services/      # Business logic
├── repositories/  # Data access
├── controllers/   # Request handling
├── models/        # Data structures
├── utils/         # Helpers
└── config/        # Configuration
```
