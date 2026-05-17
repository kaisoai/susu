#!/bin/bash
# Workflow 4: anansi gathers GitHub context → irie checks with it
#
# Tests: Full anansi → irie pipeline on a real GitHub issue
# Uses a real Expensify issue from SWE-Lancer
#
# REQUIRES: gh CLI authenticated

set -e
ANANSI="python3 /Users/dramdass/work/anansi/anansi.py"
WORK_DIR=$(mktemp -d)
echo "=== Workflow 4: anansi → irie Pipeline ==="
echo "Working dir: $WORK_DIR"

# Step 1: anansi gathers context from a real GitHub issue
echo "--- Step 1: anansi gathering context ---"
$ANANSI gh Expensify/App#15193 -o "$WORK_DIR/context"
echo ""

# Step 2: A proposal to evaluate (correct one from SWE-Lancer)
cat > "$WORK_DIR/proposal.md" << 'EOF'
## Proposal

Root cause: Code blocks inherit formatting styles (bold, italic) from
parent markdown elements (# headers, * bold).

Both frontend and backend issues:
- Frontend: <h1> wraps <pre> tags
- Backend: strips differently for bold vs header

Fix:
1. Override CSS for pre elements: fontWeight and fontSize normal
2. Modify heading regex to stop before <pre> tags
3. Handles #, *, and _ formatting consistently

This addresses the reported bug and prevents similar issues with
other formatting + code block combinations.
EOF

# Step 3: irie checks the proposal with anansi-gathered context
echo "--- Step 3: irie check with full context ---"
irie check "$WORK_DIR/proposal.md" "$WORK_DIR/context/" --json 2>/dev/null

echo ""
echo "EXPECTED: High score — proposal addresses the root cause identified in the thread"
echo "NOTE: anansi gathered the full discussion thread including reviewer feedback"
echo "      that identified which approaches work and which don't."
echo "=== Done ==="
rm -rf "$WORK_DIR"
