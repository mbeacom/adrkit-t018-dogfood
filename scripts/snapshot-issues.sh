#!/usr/bin/env bash
# Snapshots every issue (OPEN+CLOSED, excluding pull requests) in this
# repository as a deterministic JSON projection: number, state, title,
# updatedAt, and a SHA-256 digest of the body (never the raw body itself, to
# keep snapshots small/sanitized and avoid duplicating issue content across
# two files).
#
# Used by .github/workflows/arb-queue-fail-closed.yml to build the
# mechanical no-write proof: this script is run once immediately BEFORE and
# once immediately AFTER the deliberately-failing queue Action step, and
# scripts/assert-no-issue-mutation.sh compares the two snapshots for exact
# equality. This snapshots ALL issues in the repository (not just the one
# known managed-queue issue, #3 as of this writing) so the proof also covers
# "no *other* issue was created/closed/reopened/mutated either" -- not only
# "the known managed issue is untouched".
#
# Requires: gh (GitHub CLI) and jq -- both preinstalled on the
# actions/runner-images ubuntu-latest image. GH_TOKEN must be set; this
# repository always uses the default ${{ github.token }}, never a PAT.
#
# The GH_TOKEN value itself is never echoed, interpolated into a printed
# command, or written to a file by this script -- `gh api` reads it directly
# from the environment.
set -euo pipefail

REPO="${GITHUB_REPOSITORY:-}"
if [[ -z "${REPO}" ]]; then
  echo "error: GITHUB_REPOSITORY is not set (expected 'owner/repo')" >&2
  exit 2
fi

OUT="${1:-}"
if [[ -z "${OUT}" ]]; then
  echo "Usage: snapshot-issues.sh <output.json>" >&2
  exit 2
fi

RAW="$(mktemp)"
RECORDS="$(mktemp)"
cleanup() { rm -f "${RAW}" "${RECORDS}"; }
trap cleanup EXIT

echo "==> Fetching all issues (OPEN+CLOSED, excluding pull requests) from ${REPO}" >&2
# See scripts/verify-managed-queue-issue.sh for why --jq must emit a stream
# of objects (not a wrapped array) here: `gh api --paginate` applies --jq
# per page and concatenates the raw results, so a wrapped array would break
# once the issue list spans more than one page.
gh api --paginate "repos/${REPO}/issues?state=all&per_page=100" \
  --jq '.[] | select(has("pull_request") | not) | {number: .number, state: .state, title: .title, updatedAt: .updated_at, body: (.body // "")}' \
  > "${RAW}"

: > "${RECORDS}"
while IFS= read -r line; do
  [[ -z "${line}" ]] && continue
  NUM="$(jq -r '.number' <<<"${line}")"
  STATE="$(jq -r '.state' <<<"${line}")"
  TITLE="$(jq -r '.title' <<<"${line}")"
  UPDATED="$(jq -r '.updatedAt' <<<"${line}")"
  BODY_SHA="$(jq -r '.body' <<<"${line}" | sha256sum | awk '{print $1}')"
  jq -n \
    --argjson number "${NUM}" \
    --arg state "${STATE}" \
    --arg title "${TITLE}" \
    --arg updatedAt "${UPDATED}" \
    --arg bodySha256 "${BODY_SHA}" \
    '{number: $number, state: $state, title: $title, updatedAt: $updatedAt, bodySha256: $bodySha256}' \
    >> "${RECORDS}"
done < "${RAW}"

jq -s 'sort_by(.number)' "${RECORDS}" > "${OUT}"

COUNT="$(jq 'length' "${OUT}")"
echo "==> Snapshot written to ${OUT} (${COUNT} issue(s))" >&2
