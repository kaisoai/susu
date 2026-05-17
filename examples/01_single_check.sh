#!/bin/bash
# Workflow 1: Requester posts task, executor submits, irie checks
#
# This is the simplest flow — no expert, no anansi, just check.
# Tests: irie check with inline context

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORK_DIR=$(mktemp -d)
echo "=== Workflow 1: Single Check ==="
echo "Working dir: $WORK_DIR"

# Requester's task description
TASK="Write a Python function that counts overlapping substring occurrences"

# Executor's submission (good)
cat > "$WORK_DIR/solution_good.py" << 'PYEOF'
def how_many_times(string: str, substring: str) -> int:
    count = 0
    start = 0
    while True:
        pos = string.find(substring, start)
        if pos == -1:
            break
        count += 1
        start = pos + 1
    return count
PYEOF

# Executor's submission (bad — uses str.count which doesn't handle overlaps)
cat > "$WORK_DIR/solution_bad.py" << 'PYEOF'
def how_many_times(string: str, substring: str) -> int:
    return string.count(substring)
PYEOF

echo ""
echo "--- Checking GOOD solution ---"
irie check "$WORK_DIR/solution_good.py" "$TASK" --json 2>/dev/null

echo ""
echo "--- Checking BAD solution ---"
irie check "$WORK_DIR/solution_bad.py" "$TASK" --json 2>/dev/null

echo ""
echo "EXPECTED: Good solution scores higher than bad solution"
echo "=== Done ==="
rm -rf "$WORK_DIR"
