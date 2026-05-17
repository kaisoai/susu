#!/bin/bash
# Workflow 3: Compare competing proposals — tournament mode
#
# Tests: irie compare with multiple proposals + context
# Simulates the SWE-Lancer use case

set -e
WORK_DIR=$(mktemp -d)
echo "=== Workflow 3: Compare Proposals ==="
echo "Working dir: $WORK_DIR"

# The task
cat > "$WORK_DIR/task.md" << 'EOF'
## Bug Report

Code blocks inside headers (#) show bold text temporarily, then revert.

Steps to reproduce:
1. Open a chat
2. Type: # ```test```
3. Text appears bold, then normal after sync

Expected: code blocks should not be bold
Actual: temporary bold flicker

Root cause: Frontend wraps <pre> inside <h1>, backend strips it out.
EOF

# Proposal A — focused regex fix
cat > "$WORK_DIR/proposal_a.md" << 'EOF'
## Proposal A

Root cause: Frontend parses # + code block differently than backend.

Fix: Change the heading regex to ignore content after <pre> tags.
New regex: /^# +(?! )((?:(?!<pre>).)+)\s*/gm

This prevents <h1> from wrapping code blocks on the frontend,
matching backend behavior.
EOF

# Proposal B — CSS-only fix (incomplete)
cat > "$WORK_DIR/proposal_b.md" << 'EOF'
## Proposal B

Root cause: CSS inheritance causes code blocks to inherit bold from headers.

Fix: Add CSS override for pre elements:
pre { font-weight: normal !important; }

This prevents the visual flicker.
EOF

# Proposal C — comprehensive fix (both frontend and backend)
cat > "$WORK_DIR/proposal_c.md" << 'EOF'
## Proposal C

Root cause: Two issues — frontend wraps <pre> inside <h1>, AND
backend strips it differently for bold/italic formatting.

Fix:
1. Override CSS for pre elements to prevent inheriting font-weight
2. Modify heading regex to stop before <pre> tags
3. Handle both # headers AND * bold formatting consistently
4. Both frontend and backend changes needed

This handles the reported bug AND prevents similar issues with
italic and strikethrough formatting around code blocks.
EOF

echo "--- Comparing 3 proposals ---"
irie compare "$WORK_DIR/proposal_a.md" "$WORK_DIR/proposal_b.md" "$WORK_DIR/proposal_c.md" \
    -c "$WORK_DIR/task.md" --json 2>/dev/null

echo ""
echo "EXPECTED: Proposal C ranked first (comprehensive), A second (correct but narrow), B last (incomplete)"
echo "=== Done ==="
rm -rf "$WORK_DIR"
