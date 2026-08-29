#!/usr/bin/env bash
# Reproducible runner for the keeper Lua test suites.
#
# Boots the keeper-test harness (keeper/test) with the module test.env sourced
# and drives the wippy.test CLI runner (`wippy run test <id>`). Test-typed
# entries are dropped from the published registry by keeper/wippy.yaml's
# exclude_meta.type=[test]; the CLI cannot express clearing that list
# (`--set exclude_meta.type=` sets an empty scalar, not an empty list, and the
# entries stay excluded), so the exclusion block is stripped from wippy.yaml for
# the run and restored on exit via a trap; a pristine copy at
# keeper/wippy.yaml.orig heals runs interrupted after the in-place write.
# git is never touched.
#
# Usage: ./test.sh [suite_id ...]   (default: keeper.hub:test)
set -euo pipefail

WIPPY="${WIPPY:-wippy}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$REPO_ROOT/keeper/test"
WIPPY_YAML="$REPO_ROOT/keeper/wippy.yaml"
TEST_ENV="$TEST_DIR/.wippy/test.env"

SUITES=("$@")
if [ ${#SUITES[@]} -eq 0 ]; then
    SUITES=("keeper.hub:test")
fi

# The pristine copy lives next to the tracked file so a crashed run leaves a
# durable marker. Its presence on start means a previous run died after the
# in-place write: restore it before doing anything else.
YAML_ORIG="$WIPPY_YAML.orig"
if [ -f "$YAML_ORIG" ]; then
    echo ">> healing wippy.yaml from a previous interrupted run"
    cp "$YAML_ORIG" "$WIPPY_YAML"
    rm -f "$YAML_ORIG"
fi

cp "$WIPPY_YAML" "$YAML_ORIG"
restore_yaml() {
    if [ -f "$YAML_ORIG" ]; then
        cp "$YAML_ORIG" "$WIPPY_YAML"
        rm -f "$YAML_ORIG"
    fi
}
trap restore_yaml EXIT

# Strip the `exclude_meta:\n  type:\n    - test` block so test entries load.
# The block must match byte-for-byte, appear exactly once, and carry nothing
# else under exclude_meta; otherwise abort without touching the file.
python3 - "$WIPPY_YAML" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
block = "exclude_meta:\n  type:\n    - test\n"
if s.count("exclude_meta:") != 1:
    sys.exit("test.sh: expected exactly one exclude_meta key in %s" % p)
if s.count(block) != 1:
    sys.exit("test.sh: exclude_meta block in %s does not match the expected exact form" % p)
idx = s.index(block)
rest = s[idx + len(block):]
# Everything under exclude_meta ends at the next top-level key. Skipping only
# the first trailing line lets blank or comment lines hide later indented
# entries, so scan every line until one starts at column zero.
for line in rest.split("\n"):
    if line == "" or line.lstrip().startswith("#"):
        continue
    if line[:1] in (" ", "\t", "-"):
        sys.exit("test.sh: exclude_meta in %s carries entries beyond the expected block" % p)
    break
open(p, "w").write(s[:idx] + rest)
PY

if [ -f "$TEST_ENV" ]; then
    set -a
    # shellcheck disable=SC1090
    . "$TEST_ENV"
    set +a
fi

overall=0
strip_ansi() { sed 's/\x1b\[[0-9;?]*[a-zA-Z]//g'; }

for suite in "${SUITES[@]}"; do
    echo "=================================================================="
    echo "  suite: $suite"
    echo "=================================================================="
    # The runner exits nonzero on failing suites; the capture must not abort
    # the script under set -e/pipefail before the output is echoed.
    out="$(cd "$TEST_DIR" && "$WIPPY" test test "$suite" 2>&1 | strip_ansi)" || true
    echo "$out"

    # The runner ends with an uppercase banner line ("  PASSED ..." / "  FAILED
    # ...") that is authoritative. Match it case-sensitively and anchored so
    # neither test names containing "failed" nor in-progress "34/77" frames are
    # mistaken for a result.
    fail=0
    if echo "$out" | grep -qi "no tests found"; then fail=1; fi
    if echo "$out" | grep -qE "^[[:space:]]*FAILED([[:space:]]|$)"; then fail=1; fi
    if ! echo "$out" | grep -qE "^[[:space:]]*PASSED([[:space:]]|$)"; then fail=1; fi

    if [ "$fail" -ne 0 ]; then
        echo ">> $suite: FAILED"
        overall=1
    else
        echo ">> $suite: PASSED"
    fi
done

echo "=================================================================="
if [ "$overall" -ne 0 ]; then
    echo "RESULT: FAILED"
else
    echo "RESULT: PASSED"
fi
exit "$overall"
