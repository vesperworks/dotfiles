# SHARDED Audit Eval Rubric

## Scoring Method: E1 (Output Capture)

Non-destructive evaluation using `claude -p --print` mode.
Model output is captured without executing side-effect tools.

### Approach

```bash
claude -p --print "/command $(cat test-case.md)" \
  --allowedTools "Read,Glob,Grep,Skill" \
  > results/{phase}/{ID}_run{N}.txt
```

- `--print`: Non-interactive, single-turn output
- `--allowedTools`: Allow skill/file loading, block destructive tools (Bash, Write, Edit, Agent, WebSearch)
- Skill tool is allowed so the SHARDED loading pattern naturally occurs

### Per-Check Scoring

Each check in expected/*.json is scored:
- **PASS (1.0)**: Check fully satisfied
- **PARTIAL (0.5)**: Check partially satisfied (pattern found but incomplete)
- **FAIL (0.0)**: Check not satisfied

Final score = sum(check_score * weight) / maxScore * 100

### Quality Tiers

| Tier | Score Range | Description |
|------|-----------|-------------|
| A | 90-100% | Full format compliance |
| B | 70-89% | Minor gaps (1-2 checks missing) |
| C | 50-69% | Significant format issues |
| D | 30-49% | Major sections missing |
| F | 0-29% | Output unrecognizable as target format |

### Test Matrix

| ID | Target | Input Type | Key Checks | SHARDED Risk |
|----|--------|-----------|------------|:---:|
| I1 | vw:issue | Simple bug | Format fields | HIGH |
| I2 | vw:issue | Multi-requirement | Split logic | HIGH |
| I3 | vw:issue | Ambiguous request | Clarification tag | HIGH |
| N1 | vw:note | Basic term | Atomic Note template | HIGH |
| N2 | vw:note | Compound concept | Split/merge judgment | HIGH |
| R1 | vw:research | Clear topic | Output template | HIGH |
| P1 | vw:plan-prp | Feature request | PRP template sections | HIGH |

### Run Protocol

1. Each test case runs N=3 times minimum (N=5 preferred)
2. Fresh Claude session per run (no context carryover)
3. Same model for all runs within a phase
4. Results stored as raw text in results/{phase}/{ID}_run{N}.txt
5. Scoring done per-run, then averaged

### Comparison Protocol (RED vs GREEN)

```
RED:  Current architecture (command + skill, multi-hop)
GREEN: Unified architecture (single skill, 0-hop)

Delta = GREEN_avg - RED_avg per test case
Improvement = Delta / RED_avg * 100
```

Statistical significance: With N=5, look for consistent directional improvement across all runs, not just average.
