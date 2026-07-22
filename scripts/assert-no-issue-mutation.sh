#!/usr/bin/env bash
# Pure, network-free comparison of two issue snapshots produced by
# scripts/snapshot-issues.sh.
#
# Fails unless the two snapshots are byte-for-byte identical after
# canonicalization (sorted object keys, sorted by issue number) -- i.e.
# every issue's number/state/title/updatedAt/bodySha256 is completely
# unchanged between the two snapshots, and no issue was added or removed.
#
# This is the mechanical no-write proof used by
# .github/workflows/arb-queue-fail-closed.yml: it must hold true even
# though the queue Action step in that workflow is *expected* to fail. It
# proves no managed issue (or any other issue) was created, closed,
# reopened, or had its body mutated by the deliberately-failing dispatch.
#
# Usage: assert-no-issue-mutation.sh <before.json> <after.json>
set -euo pipefail

BEFORE="${1:-}"
AFTER="${2:-}"
if [[ -z "${BEFORE}" || -z "${AFTER}" || ! -f "${BEFORE}" || ! -f "${AFTER}" ]]; then
  echo "Usage: assert-no-issue-mutation.sh <before.json> <after.json>" >&2
  exit 2
fi

BEFORE_CANON="$(mktemp)"
AFTER_CANON="$(mktemp)"
DIFF_OUT="$(mktemp)"
cleanup() { rm -f "${BEFORE_CANON}" "${AFTER_CANON}" "${DIFF_OUT}"; }
trap cleanup EXIT

jq -S 'sort_by(.number)' "${BEFORE}" > "${BEFORE_CANON}"
jq -S 'sort_by(.number)' "${AFTER}" > "${AFTER_CANON}"

BEFORE_COUNT="$(jq 'length' "${BEFORE_CANON}")"
AFTER_COUNT="$(jq 'length' "${AFTER_CANON}")"

FAILURES=0
check() {
  if [[ "$1" -eq 0 ]]; then
    echo "ok:   $2"
  else
    echo "FAIL: $2" >&2
    FAILURES=$((FAILURES + 1))
  fi
}

if [[ "${BEFORE_COUNT}" -eq "${AFTER_COUNT}" ]]; then st=0; else st=1; fi
check "${st}" "issue count unchanged (before=${BEFORE_COUNT}, after=${AFTER_COUNT})"

if diff -u "${BEFORE_CANON}" "${AFTER_CANON}" > "${DIFF_OUT}"; then st=0; else st=1; fi
check "${st}" "before/after issue snapshots are byte-for-byte identical (number, state, title, updatedAt, bodySha256 for every issue)"
if [[ "${st}" -ne 0 ]]; then
  echo "" >&2
  echo "==> Diff (before vs after):" >&2
  cat "${DIFF_OUT}" >&2
fi

echo ""
echo "==> Evidence"
BEFORE_SHA256="$(sha256sum "${BEFORE_CANON}" | awk '{print $1}')"
AFTER_SHA256="$(sha256sum "${AFTER_CANON}" | awk '{print $1}')"
echo "before snapshot sha256 (canonicalized): ${BEFORE_SHA256}"
echo "after snapshot sha256 (canonicalized):  ${AFTER_SHA256}"
echo "issue count:                           ${AFTER_COUNT}"

if [[ "${FAILURES}" -gt 0 ]]; then
  echo ""
  echo "assert-no-issue-mutation FAILED: ${FAILURES} check(s) did not hold." >&2
  exit 1
fi
echo ""
echo "assert-no-issue-mutation OK: zero issue mutations across ${AFTER_COUNT} issue(s)."
