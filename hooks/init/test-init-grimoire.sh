#!/usr/bin/env bash
# test-init-grimoire.sh — Run init-grimoire.sh tests in an Alpine container via podman.
# Usage: bash hooks/test-init-grimoire.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INIT_SCRIPT="$SCRIPT_DIR/init-grimoire.sh"

if [ ! -f "$INIT_SCRIPT" ]; then
  echo "FAIL: init-grimoire.sh not found at $INIT_SCRIPT" >&2
  exit 1
fi

PASS=0
FAIL=0

run_test() {
  local name="$1"
  shift
  if "$@"; then
    echo "PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $name"
    FAIL=$((FAIL + 1))
  fi
}

# --------------------------------------------------------------------------
# Test 1: Fresh install
# --------------------------------------------------------------------------
test_fresh_install() {
  podman run --rm \
    -v "$INIT_SCRIPT:/test/init-grimoire.sh:ro" \
    -e GRIMOIRE_HOME=/tmp/test-grimoire \
    docker.io/alpine:latest sh -c '
      apk add --quiet --no-progress bash >/dev/null 2>&1
      bash /test/init-grimoire.sh

      # Assert directories exist
      for d in \
        /tmp/test-grimoire/librarian/library \
        /tmp/test-grimoire/librarian/cache \
        /tmp/test-grimoire/sigils/archived \
        /tmp/test-grimoire/knowledge; do
        [ -d "$d" ] || { echo "missing dir: $d" >&2; exit 1; }
      done

      # Assert libraries.yaml exists with correct content
      [ -f /tmp/test-grimoire/librarian/library/libraries.yaml ] || { echo "missing libraries.yaml" >&2; exit 1; }
      content=$(cat /tmp/test-grimoire/librarian/library/libraries.yaml)
      [ "$content" = "libraries: {}" ] || { echo "unexpected libraries.yaml content: $content" >&2; exit 1; }
    '
}

# --------------------------------------------------------------------------
# Test 2: Idempotency — run twice, same result
# --------------------------------------------------------------------------
test_idempotency() {
  podman run --rm \
    -v "$INIT_SCRIPT:/test/init-grimoire.sh:ro" \
    -e GRIMOIRE_HOME=/tmp/test-grimoire \
    docker.io/alpine:latest sh -c '
      apk add --quiet --no-progress bash >/dev/null 2>&1

      bash /test/init-grimoire.sh
      find /tmp/test-grimoire -type f -o -type d | sort > /tmp/state1

      bash /test/init-grimoire.sh
      rc=$?
      find /tmp/test-grimoire -type f -o -type d | sort > /tmp/state2

      [ "$rc" -eq 0 ] || { echo "second run exited $rc" >&2; exit 1; }
      diff /tmp/state1 /tmp/state2 || { echo "filesystem changed on second run" >&2; exit 1; }
    '
}

# --------------------------------------------------------------------------
# Test 3: libraries.yaml preservation — existing content not overwritten
# --------------------------------------------------------------------------
test_yaml_preservation() {
  podman run --rm \
    -v "$INIT_SCRIPT:/test/init-grimoire.sh:ro" \
    -e GRIMOIRE_HOME=/tmp/test-grimoire \
    docker.io/alpine:latest sh -c '
      apk add --quiet --no-progress bash >/dev/null 2>&1

      mkdir -p /tmp/test-grimoire/librarian/library
      cat > /tmp/test-grimoire/librarian/library/libraries.yaml << "YAML"
libraries:
  my-library:
    type: git
    source: https://github.com/example/repo.git
YAML

      bash /test/init-grimoire.sh

      grep -q "my-library" /tmp/test-grimoire/librarian/library/libraries.yaml \
        || { echo "libraries.yaml was overwritten" >&2; exit 1; }
    '
}

# --------------------------------------------------------------------------
# Test 4: Failure handling — read-only parent causes exit 2
# --------------------------------------------------------------------------
test_failure_handling() {
  podman run --rm \
    -v "$INIT_SCRIPT:/test/init-grimoire.sh:ro" \
    -e GRIMOIRE_HOME=/tmp/readonly/grimoire \
    docker.io/alpine:latest sh -c '
      apk add --quiet --no-progress bash >/dev/null 2>&1
      adduser -D testuser

      mkdir -p /tmp/readonly
      chmod 555 /tmp/readonly

      su testuser -s /bin/bash -c "GRIMOIRE_HOME=/tmp/readonly/grimoire bash /test/init-grimoire.sh" 2>/dev/null
      rc=$?
      [ "$rc" -eq 2 ] || { echo "expected exit 2, got $rc" >&2; exit 1; }
    '
}

# --------------------------------------------------------------------------
# Run all tests
# --------------------------------------------------------------------------
run_test "fresh install"          test_fresh_install
run_test "idempotency"            test_idempotency
run_test "yaml preservation"      test_yaml_preservation
run_test "failure handling"       test_failure_handling

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
