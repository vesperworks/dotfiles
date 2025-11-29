# Requirement Analysis Patterns

## Overview

Systematic patterns for analyzing and documenting requirements to ensure comprehensive feature planning.

## User Story Pattern

### Template
```
As a [user role]
I want to [perform action]
So that [achieve benefit]
```

### Acceptance Criteria
```
Given [initial context]
When [event occurs]
Then [expected outcome]
```

### Example
```
As a content creator
I want to schedule posts in advance
So that I can maintain consistent content without manual effort

Acceptance Criteria:
- Given I have a draft post
- When I set a future publish date
- Then the post is automatically published at that time
- And I receive a confirmation notification
```

## Use Case Analysis Pattern

### Structure
1. **Primary Actor**: Who initiates the use case
2. **Stakeholders**: Who has interest in the outcome
3. **Preconditions**: What must be true before execution
4. **Postconditions**: What must be true after execution
5. **Main Success Scenario**: Step-by-step happy path
6. **Extensions**: Alternative flows and error cases

### Example
```markdown
## Use Case: Process Payment

**Primary Actor**: Customer
**Stakeholders**: Customer, Merchant, Payment Gateway
**Preconditions**: Customer has items in cart, valid payment method

**Main Success Scenario**:
1. Customer initiates checkout
2. System calculates total with tax
3. Customer enters payment information
4. System validates payment details
5. System processes payment through gateway
6. System confirms payment success
7. System sends receipt to customer

**Extensions**:
3a. Payment details invalid
    3a1. System shows validation errors
    3a2. Return to step 3
5a. Payment gateway timeout
    5a1. System retries payment
    5a2. If retry fails, show error message
```

## Non-Functional Requirements Pattern

### Categories

#### Performance Requirements
- Response time targets
- Throughput requirements
- Resource usage limits
- Scalability expectations

#### Security Requirements
- Authentication requirements
- Authorization levels
- Data encryption standards
- Audit logging needs

#### Usability Requirements
- Accessibility standards (WCAG)
- User interface guidelines
- Mobile responsiveness
- Browser compatibility

#### Maintainability Requirements
- Code coverage targets
- Documentation standards
- Monitoring requirements
- Update frequency expectations

### Template
```markdown
## Non-Functional Requirements: [Feature Name]

### Performance
- **Response Time**: API responses < 200ms (p95)
- **Throughput**: Handle 1000 requests/second
- **Scalability**: Support 10x growth without architecture change

### Security
- **Authentication**: OAuth 2.0 with JWT
- **Authorization**: Role-based access control
- **Encryption**: TLS 1.3 for transit, AES-256 for storage
- **Audit**: Log all data modifications

### Usability
- **Accessibility**: WCAG 2.1 Level AA compliance
- **Responsive**: Support mobile (320px+), tablet, desktop
- **Browser**: Chrome, Firefox, Safari, Edge (latest 2 versions)
- **Language**: Support English, Spanish, Japanese

### Maintainability
- **Testing**: 80% code coverage, 100% critical path coverage
- **Documentation**: API docs, architecture diagrams, runbooks
- **Monitoring**: Error rate, latency, business metrics
- **Updates**: Security patches within 48 hours
```

## Risk Analysis Pattern

### Risk Assessment Matrix

| Risk | Probability | Impact | Severity | Mitigation |
|------|-------------|--------|----------|------------|
| Third-party API failure | Medium | High | High | Implement retry logic, circuit breaker, fallback |
| Data migration errors | Low | Critical | High | Comprehensive testing, rollback plan, data validation |
| Performance degradation | Medium | Medium | Medium | Load testing, caching strategy, monitoring |

### Risk Categories
1. **Technical Risks**: Technology limitations, integration complexity
2. **Schedule Risks**: Dependencies, resource availability
3. **Business Risks**: Market changes, competition
4. **Operational Risks**: Deployment, maintenance, support

## Dependency Mapping Pattern

### Types of Dependencies

#### Internal Dependencies
- Other features in development
- Shared components or services
- Database schema changes
- API modifications

#### External Dependencies
- Third-party services
- External APIs
- Vendor software updates
- Regulatory changes

### Documentation Template
```markdown
## Feature Dependencies: [Feature Name]

### Blocks (Must complete before this feature)
- Feature A: User authentication system
- Feature B: Payment gateway integration

### Blocked By (This feature blocks)
- Feature X: Advanced reporting (needs our data)
- Feature Y: Mobile app (needs our API)

### External Dependencies
- Stripe API v2024-01
- AWS S3 for file storage
- SendGrid for email delivery

### Assumptions
- User authentication is OAuth 2.0 based
- Payment processing latency < 3 seconds
- File storage has 99.9% availability
```

## Phased Implementation Pattern

### Phase Structure
```markdown
## Implementation Phases: [Feature Name]

### Phase 1: MVP (Week 1-2)
**Goal**: Basic functionality with core features
**Scope**:
- User can perform primary action
- Basic validation and error handling
- Essential security measures

**Out of Scope**:
- Advanced features
- Optimizations
- Comprehensive reporting

**Success Criteria**:
- Core user journey works end-to-end
- All critical acceptance criteria met
- Security review passed

### Phase 2: Enhancement (Week 3-4)
**Goal**: Improve usability and performance
**Scope**:
- Additional features from backlog
- Performance optimizations
- Enhanced error messages

### Phase 3: Polish (Week 5-6)
**Goal**: Production readiness
**Scope**:
- Comprehensive testing
- Documentation completion
- Monitoring and alerting setup
```

## Stakeholder Analysis Pattern

### Stakeholder Matrix

| Stakeholder | Interest | Influence | Engagement Strategy |
|-------------|----------|-----------|---------------------|
| End Users | High | Low | Regular feedback sessions |
| Product Manager | High | High | Weekly reviews, decisions |
| Engineering Team | Medium | High | Daily standups, technical discussions |
| Security Team | Medium | Medium | Design review, vulnerability assessment |

### Communication Plan
- **Daily**: Development team standups
- **Weekly**: Stakeholder status updates
- **Bi-weekly**: Demo and feedback sessions
- **Monthly**: Steering committee reviews

## Validation Criteria Pattern

### Definition of Done

#### Feature Level
- [ ] All acceptance criteria met
- [ ] Code reviewed and approved
- [ ] Unit tests written (80%+ coverage)
- [ ] Integration tests passed
- [ ] Security review completed
- [ ] Documentation updated
- [ ] Performance benchmarks met
- [ ] Accessibility audit passed
- [ ] User acceptance testing completed

#### Release Level
- [ ] All features in release scope completed
- [ ] Regression testing passed
- [ ] Load testing completed
- [ ] Security audit passed
- [ ] Documentation published
- [ ] Monitoring and alerting configured
- [ ] Rollback plan documented
- [ ] Stakeholder sign-off obtained

## Integration with Former Requirements-Architect

These patterns incorporate the systematic approach formerly provided by the requirements-architect agent:
- SOLID principle-based evaluation
- Comprehensive requirement clarification
- Risk-aware planning
- Phased implementation strategies

All capabilities are preserved while being more accessible through structured patterns.
