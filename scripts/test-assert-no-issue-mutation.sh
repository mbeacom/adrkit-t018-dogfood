#!/usr/bin/env bash
# Local, network-free unit test harness for scripts/assert-no-issue-mutation.sh.
#
# Runs the pure comparison script against scripts/fixtures/mutation-before.json
# paired with:
#   - mutation-after-identical.json (same issues, different array order) --
#     must PASS, proving the comparison is order-independent (canonicalized
#     by issue number) rather than a naive positional diff.
#   - every mutation-after-*.json other than -identical -- each deliberately
#     differs from mutation-before.json in exactly one way (body changed,
#     state changed, an issue was added, an issue was removed) and must FAIL.
#
# No GitHub API access, no token, no network -- this validates the
# comparison logic in isolation from scripts/snapshot-issues.sh, which is
# the only script in this pair that actually talks to GitHub.
#
# Usage: scripts/test-assert-no-issue-mutation.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSERT_SCRIPT="${REPO_ROOT}/scripts/assert-no-issue-mutation.sh"
FIXTURES_DIR="${REPO_ROOT}/scripts/fixtures"
BEFORE="${FIXTURES_DIR}/mutation-before.json"

FAILURES=0
report() {
  # $1 = 0 for pass, nonzero for fail; $2 = message
  if [[ "$1" -eq 0 ]]; then
    echo "ok:   $2"
  else
    echo "FAIL: $2" >&2
    FAILURES=$((FAILURES + 1))
  fi
}

echo "==> mutation-before.json vs mutation-after-identical.json must PASS (order-independent)"
IDENTICAL_LOG="$(mktemp)"
if "${ASSERT_SCRIPT}" "${BEFORE}" "${FIXTURES_DIR}/mutation-after-identical.json" > "${IDENTICAL_LOG}" 2>&1; then
  report 0 "mutation-after-identical.json is accepted as an unmutated snapshot"
else
  report 1 "mutation-after-identical.json is accepted as an unmutated snapshot (unexpected failure; see below)"
  cat "${IDENTICAL_LOG}" >&2
fi
rm -f "${IDENTICAL_LOG}"

echo ""
echo "==> mutation-before.json vs every other mutation-after-*.json must FAIL"
shopt -s nullglob
for fixture in "${FIXTURES_DIR}"/mutation-after-*.json; do
  name="$(basename "${fixture}")"
  [[ "${name}" == "mutation-after-identical.json" ]] && continue
  if "${ASSERT_SCRIPT}" "${BEFORE}" "${fixture}" > /dev/null 2>&1; then
    report 1 "${name} is rejected as a mutated snapshot (it unexpectedly passed)"
  else
    report 0 "${name} is rejected as a mutated snapshot"
  fi
done

echo ""
if [[ "${FAILURES}" -gt 0 ]]; then
  echo "test-assert-no-issue-mutation FAILED: ${FAILURES} case(s) did not behave as expected." >&2
  exit 1
fi
echo "test-assert-no-issue-mutation OK: comparison logic behaves correctly on every case."
