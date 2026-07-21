#!/usr/bin/env bash
# Pure, network-free assertions against a single GitHub issue JSON document.
#
# This script never calls the GitHub API. It only reads the JSON file given
# as its argument, so it can be exercised against both a real `gh api`
# response (see scripts/verify-managed-queue-issue.sh) and synthetic
# fixtures (see scripts/fixtures/*.json and scripts/test-assert-managed-issue-body.sh)
# without any network access or token.
#
# Usage: assert-managed-issue-body.sh <issue.json>
#
# Expected issue.json shape (see scripts/verify-managed-queue-issue.sh for
# how a real `gh api` issue response is normalized to this shape):
#   {
#     "number": <integer>,
#     "state": "open" | "closed",
#     "title": <string>,
#     "body": <string>,
#     "updatedAt": <string>
#   }
#
# Checks performed:
#   1. `number` is a positive integer.
#   2. `state` is exactly "open".
#   3. `title` is exactly "ADR ARB Queue".
#   4. The exact first line of `body` (any of \r\n, \n, \r as the line
#      break, matching adrkit's own marker-discovery rule) is exactly
#      `<!-- adrkit-managed-queue-issue -->`.
#   5. The body's Queue Items overview table has a row for each of
#      `0013`, `0014`, `0015`, and each row's Tier column shows the
#      expected fixed tier label for that ADR (auto/async/arb — these are
#      data facts from the corpus, not date-dependent).
#   6. Each of those three rows has an SLA State column value that is a
#      member of the closed adrkit SlaState enum. The *specific* value
#      (overdue/due/within-sla/...) is intentionally NOT pinned here,
#      because this workflow always runs with the default `--as-of`
#      (today, at dispatch time) rather than the fixed evidence date used
#      by scripts/validate-queue.sh — so the exact state legitimately
#      drifts over time as real dates pass the fixed reviewBy/deadline
#      values baked into docs/adr/0013-0015. A recognized enum value is
#      the correct invariant to assert on every dispatch.
#   7. The `0015` overview row shows `3/3` in the Approvals column (this
#      is a corpus data fact — all three deciders have approved — not
#      date-dependent, so it IS pinned exactly).
#   8. The body does not contain a `## Corpus Findings` section, and its
#      summary line reports `0 corpus finding(s)` — this corpus is schema-
#      valid, so no corpus findings section should ever be rendered.
set -euo pipefail

MARKER='<!-- adrkit-managed-queue-issue -->'
EXPECTED_TITLE='ADR ARB Queue'
VALID_SLA_STATES='decided escalated overdue due within-sla missing-sla not-queued'

ISSUE_JSON="${1:-}"
if [[ -z "${ISSUE_JSON}" || ! -f "${ISSUE_JSON}" ]]; then
  echo "Usage: assert-managed-issue-body.sh <issue.json>" >&2
  exit 2
fi

FAILURES=0
check() {
  # $1 = 0 for pass, nonzero for fail; $2 = human-readable message
  if [[ "$1" -eq 0 ]]; then
    echo "ok:   $2"
  else
    echo "FAIL: $2" >&2
    FAILURES=$((FAILURES + 1))
  fi
}

BODY_FILE="$(mktemp)"
trap 'rm -f "${BODY_FILE}"' EXIT
jq -r '.body' "${ISSUE_JSON}" > "${BODY_FILE}"

NUMBER="$(jq -r '.number' "${ISSUE_JSON}")"
STATE="$(jq -r '.state' "${ISSUE_JSON}")"
TITLE="$(jq -r '.title' "${ISSUE_JSON}")"

if [[ "${NUMBER}" =~ ^[1-9][0-9]*$ ]]; then st=0; else st=1; fi
check "${st}" "issue number is a positive integer (got '${NUMBER}')"

if [[ "${STATE}" == "open" ]]; then st=0; else st=1; fi
check "${st}" "issue state is 'open' (got '${STATE}')"

if [[ "${TITLE}" == "${EXPECTED_TITLE}" ]]; then st=0; else st=1; fi
check "${st}" "issue title is exactly '${EXPECTED_TITLE}' (got '${TITLE}')"

# First line per adrkit's own marker-discovery rule: split on \r\n, \n, or
# \r. Extracted via jq (already required by this script), NOT awk with a
# regex RS -- mawk (the default `awk` on many ubuntu-latest images) does
# not reliably support multi-character/regex record separators, which
# could otherwise silently treat the whole body as "the first line" and
# both fail this check and dump the entire body into CI logs.
FIRST_LINE="$(jq -r '(.body // "") | split("\r\n")[0] | split("\n")[0] | split("\r")[0]' "${ISSUE_JSON}")"
if [[ "${FIRST_LINE}" == "${MARKER}" ]]; then st=0; else st=1; fi
check "${st}" "body's exact first line is the marker (got '${FIRST_LINE}')"

# Fixed (date-independent) tier expectations from the docs/adr/0013-0015
# corpus. A `case` helper (not `declare -A`) so this also runs correctly
# under the Bash 3.2 that macOS ships as its default system `bash`, which
# has no associative-array support.
expected_tier_label() {
  case "$1" in
    "0013") echo "auto (expedited routing; human acceptance required)" ;;
    "0014") echo "async (asynchronous human review)" ;;
    "0015") echo "arb (ARB human review)" ;;
  esac
}

for id in 0013 0014 0015; do
  ROW="$(grep -E "^\| [0-9]+ \| \`${id}\` \|" "${BODY_FILE}" || true)"
  if [[ -z "${ROW}" ]]; then
    check 1 "overview table has a row for \`${id}\`"
    continue
  fi
  check 0 "overview table has a row for \`${id}\`"

  EXPECTED_LABEL="$(expected_tier_label "${id}")"
  TIER_CELL="$(awk -F'|' '{sub(/^ +/,"",$5); sub(/ +$/,"",$5); print $5}' <<< "${ROW}")"
  if [[ "${TIER_CELL}" == "${EXPECTED_LABEL}" ]]; then st=0; else st=1; fi
  check "${st}" "\`${id}\` Tier column is '${EXPECTED_LABEL}' (got '${TIER_CELL}')"

  SLA_CELL="$(awk -F'|' '{sub(/^ +/,"",$6); sub(/ +$/,"",$6); print $6}' <<< "${ROW}")"
  if [[ " ${VALID_SLA_STATES} " == *" ${SLA_CELL} "* ]]; then st=0; else st=1; fi
  check "${st}" "\`${id}\` SLA State column ('${SLA_CELL}') is a recognized SlaState value"

  if [[ "${id}" == "0015" ]]; then
    APPROVALS_CELL="$(awk -F'|' '{sub(/^ +/,"",$8); sub(/ +$/,"",$8); print $8}' <<< "${ROW}")"
    if [[ "${APPROVALS_CELL}" == "3/3" ]]; then st=0; else st=1; fi
    check "${st}" "\`0015\` Approvals column is '3/3' (full quorum met; got '${APPROVALS_CELL}')"
  fi
done

if grep -q '^## Corpus Findings' "${BODY_FILE}"; then st=1; else st=0; fi
check "${st}" "body has no '## Corpus Findings' section"

if grep -q '0 corpus finding(s)' "${BODY_FILE}"; then st=0; else st=1; fi
check "${st}" "body summary line reports '0 corpus finding(s)'"

echo ""
if [[ "${FAILURES}" -gt 0 ]]; then
  echo "assert-managed-issue-body FAILED: ${FAILURES} assertion(s) did not hold." >&2
  exit 1
fi
echo "assert-managed-issue-body OK."
