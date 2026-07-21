#!/usr/bin/env bash
# Local, network-free unit test harness for scripts/assert-managed-issue-body.sh.
#
# Runs the pure assertion script against scripts/fixtures/good.json (must
# pass) and every scripts/fixtures/bad-*.json fixture (each must fail,
# because each one deliberately violates exactly one invariant). No
# GitHub API access, no token, no network — this validates the parser
# logic in isolation from scripts/verify-managed-queue-issue.sh, which is
# the only script in this repository that actually talks to GitHub.
#
# Usage: scripts/test-assert-managed-issue-body.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSERT_SCRIPT="${REPO_ROOT}/scripts/assert-managed-issue-body.sh"
FIXTURES_DIR="${REPO_ROOT}/scripts/fixtures"

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

echo "==> good.json must pass"
if "${ASSERT_SCRIPT}" "${FIXTURES_DIR}/good.json" > /tmp/assert-managed-issue-good.$$.log 2>&1; then
  report 0 "good.json is accepted"
else
  report 1 "good.json is accepted (unexpected failure; see /tmp/assert-managed-issue-good.$$.log)"
  cat /tmp/assert-managed-issue-good.$$.log >&2
fi
rm -f /tmp/assert-managed-issue-good.$$.log

echo ""
echo "==> every bad-*.json fixture must fail"
shopt -s nullglob
for fixture in "${FIXTURES_DIR}"/bad-*.json; do
  name="$(basename "${fixture}")"
  if "${ASSERT_SCRIPT}" "${fixture}" > /dev/null 2>&1; then
    report 1 "${name} is rejected (it unexpectedly passed)"
  else
    report 0 "${name} is rejected"
  fi
done

echo ""
if [[ "${FAILURES}" -gt 0 ]]; then
  echo "test-assert-managed-issue-body FAILED: ${FAILURES} case(s) did not behave as expected." >&2
  exit 1
fi
echo "test-assert-managed-issue-body OK: fixture parser behaves correctly on every case."
