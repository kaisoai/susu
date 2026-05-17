# susu examples

End-to-end workflows showing how anansi, irie, and susu work together.

These are runnable scripts that exercise the task lifecycle. They identify gaps in current tooling.

## Requirements

```bash
export ANTHROPIC_API_KEY=sk-ant-...
pip install -e /path/to/irie
# gh CLI authenticated
```

## Workflows

| Example | What it tests | Status |
|---|---|---|
| `01_single_check.sh` | Requester posts task → irie checks output | Works |
| `02_expert_refines.sh` | Expert adds context → irie re-checks (score should improve) | Works |
| `03_compare_proposals.sh` | Multiple proposals → irie compare → ranking | Works |
| `04_github_context.sh` | anansi gathers → irie checks with context | Works |
| `05_full_lifecycle.sh` | Post → anansi gather → expert refine → execute → irie verify | Partial (needs susu task management) |
