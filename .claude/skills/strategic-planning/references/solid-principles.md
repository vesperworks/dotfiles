# SOLID Principles Deep Dive

## Overview

SOLID principles provide a foundation for maintainable, scalable software design. This guide provides detailed evaluation criteria for each principle.

## Single Responsibility Principle (SRP)

### Definition
A class/module should have only one reason to change - one responsibility.

### Evaluation Questions
1. Can you describe the module's responsibility in one sentence?
2. How many different types of changes might affect this module?
3. Are there multiple actors/stakeholders that might request changes?

### Red Flags
- Module name contains "And", "Or", "Manager"
- Multiple unrelated public methods
- Changes for different features require modifying same module

### Good Practice Example
```typescript
// BAD: Multiple responsibilities
class UserService {
  validateUser(user) { ... }
  saveUser(user) { ... }
  sendWelcomeEmail(user) { ... }
  generateReport(user) { ... }
}

// GOOD: Single responsibility
class UserValidator {
  validate(user) { ... }
}

class UserRepository {
  save(user) { ... }
}

class EmailService {
  sendWelcomeEmail(user) { ... }
}

class UserReportGenerator {
  generate(user) { ... }
}
```

## Open/Closed Principle (OCP)

### Definition
Software entities should be open for extension but closed for modification.

### Evaluation Questions
1. Can new features be added without modifying existing code?
2. Are extension points well-defined and documented?
3. Does the design use abstraction effectively?

### Red Flags
- Frequent modifications to existing classes for new features
- Large switch/if-else chains for behavior selection
- Lack of interfaces or abstract base classes

### Good Practice Example
```typescript
// BAD: Requires modification for new payment methods
class PaymentProcessor {
  process(payment, method) {
    if (method === 'credit') { ... }
    else if (method === 'paypal') { ... }
    // Need to modify for new methods
  }
}

// GOOD: Open for extension
interface PaymentMethod {
  process(amount: number): Promise<boolean>;
}

class CreditCardPayment implements PaymentMethod { ... }
class PayPalPayment implements PaymentMethod { ... }
class BitcoinPayment implements PaymentMethod { ... } // New without modification
```

## Liskov Substitution Principle (LSP)

### Definition
Subtypes must be substitutable for their base types without affecting correctness.

### Evaluation Questions
1. Can derived classes be used wherever base class is expected?
2. Do derived classes honor the contracts of base classes?
3. Are there unexpected exceptions or behaviors in derived classes?

### Red Flags
- Derived class throws exceptions not thrown by base
- Derived class has stricter preconditions
- Derived class has weaker postconditions
- Empty implementations of base class methods

### Good Practice Example
```typescript
// BAD: Violates LSP
class Bird {
  fly() { ... }
}

class Penguin extends Bird {
  fly() {
    throw new Error("Penguins can't fly"); // Violates LSP
  }
}

// GOOD: Respects LSP
interface Bird {
  move(): void;
}

class FlyingBird implements Bird {
  move() { this.fly(); }
  fly() { ... }
}

class Penguin implements Bird {
  move() { this.swim(); }
  swim() { ... }
}
```

## Interface Segregation Principle (ISP)

### Definition
Clients should not be forced to depend on interfaces they don't use.

### Evaluation Questions
1. Are interfaces focused and cohesive?
2. Do implementing classes use all interface methods?
3. Are there "fat interfaces" with many unrelated methods?

### Red Flags
- Large interfaces with many methods
- Classes implementing interfaces with empty/stub methods
- Clients depending on more methods than they use

### Good Practice Example
```typescript
// BAD: Fat interface
interface Worker {
  work(): void;
  eat(): void;
  sleep(): void;
}

class Robot implements Worker {
  work() { ... }
  eat() { /* Robots don't eat */ }
  sleep() { /* Robots don't sleep */ }
}

// GOOD: Segregated interfaces
interface Workable {
  work(): void;
}

interface Eatable {
  eat(): void;
}

interface Sleepable {
  sleep(): void;
}

class Human implements Workable, Eatable, Sleepable { ... }
class Robot implements Workable { ... }
```

## Dependency Inversion Principle (DIP)

### Definition
High-level modules should not depend on low-level modules. Both should depend on abstractions.

### Evaluation Questions
1. Do high-level modules depend on abstractions rather than concrete implementations?
2. Are dependencies injected rather than instantiated directly?
3. Is there a clear separation between abstraction and implementation?

### Red Flags
- Direct instantiation of dependencies using `new`
- Tight coupling between layers
- Difficulty testing due to hard-coded dependencies

### Good Practice Example
```typescript
// BAD: High-level depends on low-level
class OrderService {
  private emailService = new EmailService(); // Direct dependency

  processOrder(order) {
    // ...
    this.emailService.send(order.email, "Order processed");
  }
}

// GOOD: Depend on abstractions
interface NotificationService {
  send(recipient: string, message: string): Promise<void>;
}

class EmailService implements NotificationService { ... }
class SMSService implements NotificationService { ... }

class OrderService {
  constructor(private notificationService: NotificationService) {} // Injected

  processOrder(order) {
    // ...
    this.notificationService.send(order.contact, "Order processed");
  }
}
```

## Evaluation Checklist

Use this checklist when reviewing designs:

### SRP
- [ ] Each module has one clear responsibility
- [ ] Module name accurately reflects its purpose
- [ ] Changes from different sources don't affect same module

### OCP
- [ ] New features can be added without modifying existing code
- [ ] Extension points are well-defined
- [ ] Abstraction is used effectively

### LSP
- [ ] Derived classes are substitutable for base classes
- [ ] Contracts are honored
- [ ] No unexpected behaviors or exceptions

### ISP
- [ ] Interfaces are focused and cohesive
- [ ] No empty interface implementations
- [ ] Clients use all interface methods

### DIP
- [ ] Dependencies are abstracted
- [ ] Dependencies are injected
- [ ] High-level and low-level modules both depend on abstractions

## Integration with Requirements Architecture

When creating requirements, always consider:
1. How will the design adhere to SOLID principles?
2. What extension points are needed for future requirements?
3. How can we minimize coupling and maximize cohesion?
4. Are abstractions defined at appropriate boundaries?

## References

- Clean Architecture by Robert C. Martin
- Design Patterns: Elements of Reusable Object-Oriented Software
- Agile Software Development, Principles, Patterns, and Practices
