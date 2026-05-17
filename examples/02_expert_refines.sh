#!/bin/bash
# Workflow 2: Expert context improves scoring accuracy
#
# Tests: irie check with vs without expert context
# Shows that expert refinement (context addition) changes outcomes
#
# GAP IDENTIFIED: No way to provide a rubric.toml from expert yet.
#                 Currently expert context is just more context files.
#                 Need: anansi interview → rubric.toml generation

set -e
WORK_DIR=$(mktemp -d)
echo "=== Workflow 2: Expert Refines Task ==="
echo "Working dir: $WORK_DIR"

TASK="Fix the authentication bug in the login endpoint"

# A tricky submission — looks correct but uses deprecated auth
cat > "$WORK_DIR/submission.py" << 'PYEOF'
import requests

def login(username, password):
    """Authenticate user against the API."""
    response = requests.post(
        "https://api.example.com/v2/auth",
        headers={"X-API-Key": "sk-legacy-key-123"},
        json={"username": username, "password": password}
    )
    return response.json().get("token")
PYEOF

# Check WITHOUT expert context
echo "--- Without expert context ---"
irie check "$WORK_DIR/submission.py" "$TASK" --json 2>/dev/null
echo ""

# Expert provides context refinement
mkdir -p "$WORK_DIR/expert"
cat > "$WORK_DIR/expert/refinement.md" << 'EOF'
IMPORTANT: The API migrated to v3 in March 2026.
- v2 endpoints are deprecated and will be removed June 2026
- X-API-Key auth is replaced by OAuth2 bearer tokens
- The correct endpoint is /v3/oauth/token
- Any solution using v2 or API keys is WRONG regardless of whether it "works"
EOF

# Check WITH expert context
echo "--- With expert context ---"
irie check "$WORK_DIR/submission.py" "$TASK" "$WORK_DIR/expert/" --json 2>/dev/null

echo ""
echo "EXPECTED: Score drops with expert context (solution uses deprecated v2 + API keys)"
echo ""
echo "GAP: Expert context is just files. Need anansi interview agent to generate"
echo "     rubric.toml from expert conversation."
echo "=== Done ==="
rm -rf "$WORK_DIR"
