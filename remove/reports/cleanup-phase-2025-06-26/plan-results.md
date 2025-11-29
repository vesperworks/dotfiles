# Phase 3 Implementation Plan

## Executive Summary
**Objective**: Implement missing multi-agent infrastructure and validate with Phase 3 tests  
**Approach**: TDD-driven infrastructure development with incremental validation  
**Duration**: Estimated 3-4 hours  
**Priority**: Critical - blocks all multi-agent functionality

## Scope Change Notice
The original Phase 3 task assumed existing infrastructure to test. However, the exploration revealed that the multi-agent system hasn't been implemented yet. This plan addresses:
1. Building the complete `.claude` infrastructure from scratch
2. Implementing all utility functions and workflows
3. Validating through the Phase 3 test requirements

## Implementation Strategy

### Phase 1: Core Infrastructure (45 minutes)
**Priority**: HIGHEST  
**Dependencies**: None

#### 1.1 Create Directory Structure
```bash
.claude/
├── scripts/
├── commands/
├── prompts/
├── templates/
└── settings.local.json
```

#### 1.2 Implement worktree-utils.sh
**Test-First Approach**:
1. Write unit tests for each function
2. Implement functions incrementally
3. Validate with test scripts

**Core Functions**:
- `source_utils()`: Load utility functions
- `get_feature_name()`: Japanese → safe branch names
- `create_worktree()`: Create with error handling
- `cleanup_worktree()`: Safe cleanup with validation
- `check_worktree_exists()`: Existence validation
- `log_message()`: Structured logging

**Success Criteria**:
- All functions handle ClaudeCode restrictions
- Japanese parameters properly encoded
- Error cases gracefully handled

### Phase 2: Session Management (30 minutes)
**Priority**: HIGH  
**Dependencies**: Phase 1

#### 2.1 Environment Persistence
**Implementation**:
- `save_environment()`: Persist session state
- `load_environment()`: Restore session state
- `update_environment()`: Atomic updates

**Test Coverage**:
- Cross-session variable persistence
- Concurrent access handling
- File corruption recovery

#### 2.2 Phase Management
**Implementation**:
- `run_phase()`: Execute individual phases
- `check_phase_completed()`: Validation logic
- `transition_phase()`: State transitions

**Success Criteria**:
- Phases execute in correct order
- State persists between sessions
- Failures don't corrupt state

### Phase 3: Command Workflows (45 minutes)
**Priority**: HIGH  
**Dependencies**: Phase 1, 2

#### 3.1 Multi-Agent Commands
**Files to Create**:
- `.claude/commands/multi-tdd.md`
- `.claude/commands/multi-feature.md`
- `.claude/commands/multi-refactor.md`

**Implementation Pattern**:
```markdown
# Command Structure
1. Parse parameters
2. Create worktree
3. Execute agent sequence
4. Generate reports
5. Cleanup on completion
```

#### 3.2 Agent Prompts
**Files to Create**:
- `.claude/prompts/explorer.md`
- `.claude/prompts/planner.md`
- `.claude/prompts/coder.md`
- `.claude/prompts/tester.md`

**Success Criteria**:
- Clear role definitions
- Consistent output formats
- Error handling instructions

### Phase 4: Parallel Execution (30 minutes)
**Priority**: MEDIUM  
**Dependencies**: Phase 1, 2, 3

#### 4.1 Parallel Agent Utilities
**Implementation**:
- `parallel-agent-utils.sh`: Core parallel functions
- `run_parallel_agents()`: Concurrent execution
- `merge_results()`: Result aggregation

**Test Coverage**:
- Race condition handling
- Resource locking
- Result synchronization

### Phase 5: Testing & Validation (60 minutes)
**Priority**: HIGHEST  
**Dependencies**: All previous phases

#### 5.1 Phase 3 Test Implementation
**Test 1: Japanese Parameter Handling**
```bash
# Test worktree creation with Japanese descriptions
test_japanese_worktree_creation() {
    local task="認証機能のバグ修正"
    # Validate branch name sanitization
    # Verify worktree creation
    # Check file encoding
}
```

**Test 2: Sequential Phase Execution**
```bash
# Test complete workflow execution
test_sequential_phases() {
    # Explorer → Planner → Coder → Tester
    # Verify phase transitions
    # Check result files
}
```

**Test 3: Error Handling**
```bash
# Test failure scenarios
test_error_handling() {
    # Simulate phase failures
    # Verify rollback behavior
    # Check cleanup completion
}
```

**Test 4: Refactoring Completion**
```bash
# Test actual refactoring task
test_refactoring_workflow() {
    # Execute real refactoring
    # Verify code changes
    # Check commit history
}
```

#### 5.2 Integration Testing
- Run all Phase 3 tests
- Execute sample workflows
- Stress test with parallel tasks

## Risk Mitigation

### ClaudeCode Limitations
**Risk**: Cannot use `cd` commands  
**Mitigation**: 
- Use `git -C` for all git operations
- Use absolute paths for file operations
- Test all operations in ClaudeCode environment

### Session Persistence
**Risk**: Variables lost between phases  
**Mitigation**:
- Implement robust environment file management
- Add checksum validation
- Include recovery mechanisms

### Japanese Character Handling
**Risk**: Encoding issues in branch names  
**Mitigation**:
- Implement proper transliteration
- Add comprehensive character testing
- Provide fallback mechanisms

## Implementation Order

1. **Hour 1**: Core infrastructure (worktree-utils.sh)
2. **Hour 2**: Session management & phase control
3. **Hour 3**: Command workflows & agent prompts
4. **Hour 4**: Testing & validation

## Success Criteria

### Functional Requirements
- [ ] All `.claude` infrastructure files created
- [ ] Core utility functions implemented and tested
- [ ] Session persistence working across phases
- [ ] All 4 Phase 3 tests passing
- [ ] Sample workflows execute successfully

### Non-Functional Requirements
- [ ] ClaudeCode compatibility verified
- [ ] Japanese parameter handling robust
- [ ] Error messages clear and actionable
- [ ] Performance acceptable (< 5s per operation)
- [ ] Documentation complete and accurate

## Deliverables

1. **Infrastructure**:
   - Complete `.claude` directory structure
   - All utility scripts implemented
   - Command and prompt templates

2. **Tests**:
   - Unit tests for all functions
   - Integration tests for workflows
   - Phase 3 validation tests

3. **Documentation**:
   - Function documentation in scripts
   - Workflow execution examples
   - Troubleshooting guide

## Next Steps

1. **Immediate Action**: Start with worktree-utils.sh implementation
2. **Validation**: Run test-simple-verification.sh after each component
3. **Iteration**: Refine based on test results
4. **Completion**: Generate comprehensive report

## Notes

- This plan represents a significant scope expansion from the original Phase 3 task
- TDD approach ensures quality and reliability
- Incremental implementation allows for early validation
- Focus on ClaudeCode compatibility throughout