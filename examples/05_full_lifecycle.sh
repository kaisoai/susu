#!/bin/bash
# Workflow 5: Full task lifecycle — post → gather → refine → execute → verify
#
# This is the complete susu flow. Identifies all gaps.
#
# GAPS IDENTIFIED (what needs to be built):
#   1. susu task management (create task, track state, store artifacts)
#   2. anansi expert interview (agent asks questions, generates rubric)
#   3. irie --rubric from expert-generated TOML (works but no generation UX)
#   4. susu payment/settlement (skip for now)
#   5. susu reputation tracking (Bradley-Terry, skip for now)
#   6. Context source tagging (automated vs expert vs requester provenance)
#   7. Rubric versioning + provenance tracking (who added each criterion)

set -e
ANANSI="python3 /Users/dramdass/work/anansi/anansi.py"
WORK_DIR=$(mktemp -d)
echo "=== Workflow 5: Full Task Lifecycle ==="
echo "Working dir: $WORK_DIR"

#──────────────────────────────────────
# PHASE 1: POST — Requester creates task
#──────────────────────────────────────
echo "--- Phase 1: REQUESTER posts task ---"
mkdir -p "$WORK_DIR/task/context/requester"

cat > "$WORK_DIR/task/context/requester/spec.md" << 'EOF'
# Task: Fix code block formatting bug

Code blocks inside markdown headers show bold text temporarily.
Steps: type `# ```test``` ` — text flickers bold then reverts.
Must fix for web and mobile platforms.
Budget: $4,000
EOF

echo "  Task posted: Fix code block formatting bug (\$4,000)"

#──────────────────────────────────────
# PHASE 2: GATHER — anansi enriches context
#──────────────────────────────────────
echo ""
echo "--- Phase 2: ANANSI gathers context ---"
$ANANSI gh Expensify/App#15193 -o "$WORK_DIR/task/context/github"
echo "  Context gathered from GitHub"

#──────────────────────────────────────
# PHASE 2b: REFINE — Expert adds context
# GAP: This should be an anansi interview, not manual file creation
#──────────────────────────────────────
echo ""
echo "--- Phase 2b: EXPERT refines task ---"
mkdir -p "$WORK_DIR/task/context/expert"

cat > "$WORK_DIR/task/context/expert/refinement.md" << 'EOF'
Expert notes (source: senior frontend engineer):

- The issue affects ALL formatting + code block combinations, not just headers
- Both frontend AND backend parsing need to change
- CSS-only fixes are incomplete — they mask the flicker but don't fix the root cause
- The regex for heading parsing needs to stop before <pre> tags
- Proposal by @allroundexperts was tested and found to not work for all cases
- Solution must handle: # + code, * + code, _ + code consistently
EOF

# GAP: Should generate rubric.toml from expert conversation
cat > "$WORK_DIR/task/rubric.toml" << 'EOF'
[rubric]
name = "code-block-formatting-fix"
description = "Fix code block formatting inside markdown elements"

[[criteria]]
name = "root_cause"
weight = 1.0
description = "Correctly identifies frontend/backend parsing mismatch as root cause"

[[criteria]]
name = "comprehensive_fix"
weight = 0.9
description = "Addresses all formatting types (headers, bold, italic) not just the reported case"

[[criteria]]
name = "both_sides"
weight = 0.8
description = "Proposes changes to both frontend and backend, not just one"

[[criteria]]
name = "regression_safety"
weight = 0.6
description = "Fix does not break existing markdown rendering"

[[criteria]]
name = "implementable"
weight = 0.5
description = "Clear enough to implement without further clarification"
EOF

echo "  Expert refinement added (5 criteria in rubric)"

#──────────────────────────────────────
# PHASE 3: EXECUTE — Proposals submitted
#──────────────────────────────────────
echo ""
echo "--- Phase 3: EXECUTORS submit proposals ---"
mkdir -p "$WORK_DIR/task/submissions"

# Proposal A — narrow fix
cat > "$WORK_DIR/task/submissions/proposal_narrow.md" << 'EOF'
## Proposal: Regex Fix

Change heading regex to not wrap code blocks:
/^# +(?! )((?:(?!<pre>).)+)\s*/gm

This prevents headers from wrapping code blocks on the frontend.
EOF

# Proposal B — comprehensive fix (mirrors the actual winning proposal)
cat > "$WORK_DIR/task/submissions/proposal_comprehensive.md" << 'EOF'
## Proposal: Comprehensive Fix

Root cause: Code blocks inherit formatting from parent markdown elements.
Both frontend and backend issues exist.

Fix:
1. Custom pre styles in HTMLEngineProvider: fontWeight and fontSize normal
   This overrides bold/italic inheritance for code blocks
2. Modify heading regex: /^# +(?! )((?:(?!<pre>).)+)\s*/gm
   Stops h1 wrapping before code blocks
3. Backend: preserve frontend HTML for bold/italic + code combinations

Handles: # + code, * + code, _ + code consistently.
Tested in offline mode — no flicker.
EOF

echo "  2 proposals submitted"

#──────────────────────────────────────
# PHASE 4: VERIFY — irie scores with full context + rubric
#──────────────────────────────────────
echo ""
echo "--- Phase 4: IRIE verifies proposals ---"
echo ""

echo "  Comparing proposals with expert rubric + full context..."
irie compare \
    "$WORK_DIR/task/submissions/proposal_narrow.md" \
    "$WORK_DIR/task/submissions/proposal_comprehensive.md" \
    -c "$WORK_DIR/task/context/requester/spec.md" \
    -c "$WORK_DIR/task/context/expert/refinement.md" \
    --json 2>/dev/null

# Also check each individually against the rubric
echo ""
echo "  Checking narrow proposal with rubric..."
irie check "$WORK_DIR/task/submissions/proposal_narrow.md" \
    "$WORK_DIR/task/context/" \
    --rubric "$WORK_DIR/task/rubric.toml" \
    --json 2>/dev/null

echo ""
echo "  Checking comprehensive proposal with rubric..."
irie check "$WORK_DIR/task/submissions/proposal_comprehensive.md" \
    "$WORK_DIR/task/context/" \
    --rubric "$WORK_DIR/task/rubric.toml" \
    --json 2>/dev/null

#──────────────────────────────────────
# PHASE 5: SETTLE
#──────────────────────────────────────
echo ""
echo "--- Phase 5: SETTLEMENT ---"
echo "  GAP: Payment not implemented"
echo "  GAP: Reputation update not implemented"
echo "  GAP: Rubric provenance tracking not implemented"

echo ""
echo "=== GAPS IDENTIFIED ==="
echo "  1. susu task management (create/track/store)"
echo "  2. anansi expert interview agent (conversation → rubric.toml)"
echo "  3. Context source tagging (provenance: automated vs expert vs requester)"
echo "  4. Rubric generation from expert context (anansi → rubric.toml)"
echo "  5. Rubric versioning + provenance (who added each criterion, when)"
echo "  6. susu payment/settlement"
echo "  7. susu reputation (Bradley-Terry)"
echo "  8. irie context weighting by source trust"
echo "=== Done ==="
rm -rf "$WORK_DIR"
