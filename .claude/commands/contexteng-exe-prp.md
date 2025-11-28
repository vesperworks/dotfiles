# Execute BASE PRP

⚠️ **DEPRECATION NOTICE**: このコマンドは非推奨です。代わりに `@vw-orchestrator` エージェントを使用してください。
- **推奨**: `@vw-orchestrator "PRPs/your-prp-file.md を使って実装"`
- **理由**: vw-orchestratorは6フェーズワークフロー全体を管理し、PRP統合、品質ゲート、E2Eテストまで一貫して実行します

---

Implement a feature using using the PRP file.

## MUST: Language Requirements
- **Think in English**: All internal reasoning and planning must be done in English
- **Communicate in Japanese**: All user-facing communication and responses must be in Japanese

## PRP File: $ARGUMENTS

## Execution Process

1. **Load PRP**
   - Read the specified PRP file
   - Understand all context and requirements
   - Follow all instructions in the PRP and extend the research if needed
   - Ensure you have all needed context to implement the PRP fully
   - Do more web searches and codebase exploration as needed

2. **ULTRATHINK**
   - Think hard before you execute the plan. Create a comprehensive plan addressing all requirements.
   - Break down complex tasks into smaller, manageable steps using your todos tools.
   - Use the TodoWrite tool to create and track your implementation plan.
   - Identify implementation patterns from existing code to follow.

3. **Execute the plan**
   - Execute the PRP
   - Implement all the code

4. **Validate**
   - Run each validation command
   - Fix any failures
   - Re-run until all pass

5. **Complete**
   - Ensure all checklist items done
   - Run final validation suite
   - Report completion status
   - Read the PRP again to ensure you have implemented everything

6. **Reference the PRP**
   - You can always reference the PRP again if needed

Note: If validation fails, use error patterns in PRP to fix and retry.