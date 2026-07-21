#!/usr/bin/env bash
# Verifies, using only the default GITHUB_TOKEN (no PAT/secret), that a
# single dispatch of .github/workflows/arb-queue.yml produced exactly one
# well-formed managed ARB queue issue matching the Action's own
# `issue-number` output. Run as a CI step right after the
# `mbeacom/adrkit/packages/ci/queue@<pin>` step, with:
#
#   env:
#     GH_TOKEN: ${{ github.token }}
#     ISSUE_NUMBER: ${{ steps.queue.outputs.issue-number }}
#
# This script owns the network-dependent parts only: resolving the
# repository, fetching the issue the Action reported, and exhaustively
# discovering the managed-issue marker across OPEN and CLOSED issues to
# detect duplicates. All body/metadata-content assertions are delegated
# to the pure, network-free scripts/assert-managed-issue-body.sh, which
# is the same script exercised locally (no token, no network) by
# scripts/test-assert-managed-issue-body.sh against fixtures.
#
# Requires: gh (GitHub CLI) and jq -- both preinstalled on the
# actions/runner-images ubuntu-latest image, so no extra setup step is
# needed in the workflow for this verification.
#
# The GH_TOKEN value itself is never echoed, interpolated into a printed
# command, or written to a file by this script -- `gh api` reads it
# directly from the environment.
set -euo pipefail

MARKER='<!-- adrkit-managed-queue-issue -->'
REPO="${GITHUB_REPOSITORY:-}"

if [[ -z "${REPO}" ]]; then
  echo "error: GITHUB_REPOSITORY is not set (expected 'owner/repo')" >&2
  exit 2
fi

if [[ -z "${ISSUE_NUMBER:-}" || ! "${ISSUE_NUMBER}" =~ ^[1-9][0-9]*$ ]]; then
  echo "error: ISSUE_NUMBER ('${ISSUE_NUMBER:-}') is not a positive integer; the Action's issue-number output is missing or invalid" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISSUE_JSON="$(mktemp)"
ALL_ISSUES_JSON="$(mktemp)"
cleanup() { rm -f "${ISSUE_JSON}" "${ALL_ISSUES_JSON}"; }
trap cleanup EXIT

echo "==> Fetching issue #${ISSUE_NUMBER} from ${REPO}"
gh api "repos/${REPO}/issues/${ISSUE_NUMBER}" \
  --jq '{number: .number, state: .state, title: .title, body: .body, updatedAt: .updated_at}' \
  > "${ISSUE_JSON}"

echo "==> Exhaustive marker discovery across OPEN and CLOSED issues (excluding pull requests)"
# `gh api --paginate` applies --jq per page and concatenates the raw
# results, so each page must emit a stream of objects (NOT a wrapped
# array) or ALL_ISSUES_JSON would contain multiple sibling JSON arrays
# once the issue list spans more than one page (>100 issues). Downstream
# reads use `jq -s`/`jq -rs` to slurp the (possibly multi-page) stream
# back into a single array before filtering/counting.
gh api --paginate "repos/${REPO}/issues?state=all&per_page=100" \
  --jq '.[] | select(has("pull_request") | not) | {number: .number, body: .body}' \
  > "${ALL_ISSUES_JSON}"

# Mirrors adrkit's own discovery rule: an issue is "managed" iff the exact
# first line of its body (any of \r\n, \n, \r) equals the marker.
MANAGED_NUMBERS="$(jq -rs --arg marker "${MARKER}" '
  [.[] | select(
    ((.body // "") | split("\r\n")[0] | split("\n")[0] | split("\r")[0]) == $marker
  ) | .number] | sort | @csv
' "${ALL_ISSUES_JSON}")"

MANAGED_COUNT="$(jq -rs --arg marker "${MARKER}" '
  [.[] | select(
    ((.body // "") | split("\r\n")[0] | split("\n")[0] | split("\r")[0]) == $marker
  )] | length
' "${ALL_ISSUES_JSON}")"

FAILURES=0
check() {
  if [[ "$1" -eq 0 ]]; then
    echo "ok:   $2"
  else
    echo "FAIL: $2" >&2
    FAILURES=$((FAILURES + 1))
  fi
}

if [[ "${MANAGED_COUNT}" -eq 1 ]]; then st=0; else st=1; fi
check "${st}" "exactly one issue carries the managed-queue marker across OPEN+CLOSED issues (found ${MANAGED_COUNT}: ${MANAGED_NUMBERS})"

if [[ "${MANAGED_COUNT}" -eq 1 ]]; then
  SOLE_MANAGED_NUMBER="$(echo "${MANAGED_NUMBERS}" | tr -d '"')"
  if [[ "${SOLE_MANAGED_NUMBER}" == "${ISSUE_NUMBER}" ]]; then st=0; else st=1; fi
  check "${st}" "the sole managed issue (#${SOLE_MANAGED_NUMBER}) matches the Action's issue-number output (#${ISSUE_NUMBER})"
fi

echo ""
echo "==> Delegating body/metadata assertions to assert-managed-issue-body.sh"
if ! "${REPO_ROOT}/scripts/assert-managed-issue-body.sh" "${ISSUE_JSON}"; then
  FAILURES=$((FAILURES + 1))
fi

echo ""
echo "==> Evidence"
EVIDENCE_NUMBER="$(jq -r '.number' "${ISSUE_JSON}")"
EVIDENCE_UPDATED_AT="$(jq -r '.updatedAt' "${ISSUE_JSON}")"
EVIDENCE_BODY_SHA256="$(jq -r '.body' "${ISSUE_JSON}" | sha256sum | awk '{print $1}')"
echo "issue number:   ${EVIDENCE_NUMBER}"
echo "body sha256:    ${EVIDENCE_BODY_SHA256}"
echo "updated at:     ${EVIDENCE_UPDATED_AT}"

if [[ "${FAILURES}" -gt 0 ]]; then
  echo ""
  echo "verify-managed-queue-issue FAILED: ${FAILURES} check group(s) did not hold." >&2
  exit 1
fi
echo ""
echo "verify-managed-queue-issue OK."
