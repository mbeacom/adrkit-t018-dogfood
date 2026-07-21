#!/usr/bin/env bash
# Validates the Phase 6 ARB operations queue behavior of this repository's
# docs/adr corpus against a pinned adrkit commit.
#
# This script is deliberately NOT a substitute for spec/007-arb-queue SC-004 /
# T048: it runs from an owner-controlled clone of adrkit against an
# owner-controlled corpus, so it validates technical behavior only. See
# README.md ("Status boundary — this is NOT SC-004 evidence") for the full
# non-SC-004 status statement.
#
# What it does:
#   1. Clones adrkit at the exact pinned commit (never a moving branch/tag).
#   2. Installs dependencies with a frozen lockfile using Bun 1.3.14.
#   3. Builds the workspace.
#   4. Runs `adr queue --dir docs/adr --as-of <fixed date> --format json`
#      against this repository's corpus.
#   5. Asserts the QueueReport v1 shape and the deterministic dogfood
#      expectations (3 tiers, overdue + due presence, approvals/objections,
#      zero corpus findings) via scripts/assert-queue-report.ts.
#   6. Prints the markdown rendering for human review.
#
# Generated reports are written to a temporary directory and are never
# committed to this repository.
set -euo pipefail

# Pin: exact merged adrkit commit for specs/007-arb-queue (Phase 6 ARB queue).
# Do NOT change this to a branch name or tag — see README.md ("Pinned adrkit
# commit").
ADRKIT_REF="efef89b5d747ca175a1947f1ce2f4296dab54fa3"
ADRKIT_REPO="${ADRKIT_REPO:-https://github.com/mbeacom/adrkit.git}"
EXPECTED_BUN_VERSION="1.3.14"

# Fixed --as-of date for deterministic SLA-state evidence (overdue/due).
# This is intentionally a hardcoded calendar date, not `date -u +%F`, so that
# every re-run of this script (today or years from now) reproduces the same
# QueueReport. See docs/adr/0014-*.md and docs/adr/0015-*.md for the fixed
# review deadlines this date is chosen to exercise.
AS_OF="${ADR_QUEUE_AS_OF:-2026-07-21}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Checking Bun toolchain"
if ! command -v bun >/dev/null 2>&1; then
  echo "error: bun is required (expected ${EXPECTED_BUN_VERSION}); see https://bun.sh" >&2
  exit 1
fi
INSTALLED_BUN_VERSION="$(bun --version)"
if [[ "${INSTALLED_BUN_VERSION}" != "${EXPECTED_BUN_VERSION}" ]]; then
  echo "warning: expected bun ${EXPECTED_BUN_VERSION}, found ${INSTALLED_BUN_VERSION}; continuing anyway" >&2
fi

WORKDIR="$(mktemp -d)"
cleanup() { rm -rf "${WORKDIR}"; }
trap cleanup EXIT

echo "==> Cloning adrkit and checking out pinned commit ${ADRKIT_REF}"
git clone --quiet "${ADRKIT_REPO}" "${WORKDIR}/adrkit"
git -C "${WORKDIR}/adrkit" checkout --quiet "${ADRKIT_REF}"
RESOLVED_SHA="$(git -C "${WORKDIR}/adrkit" rev-parse HEAD)"
if [[ "${RESOLVED_SHA}" != "${ADRKIT_REF}" ]]; then
  echo "error: resolved commit ${RESOLVED_SHA} does not match pinned ref ${ADRKIT_REF}" >&2
  exit 1
fi

echo "==> Installing adrkit dependencies (frozen lockfile)"
(cd "${WORKDIR}/adrkit" && bun install --frozen-lockfile)

echo "==> Building adrkit"
(cd "${WORKDIR}/adrkit" && bun run build)

ADR_CLI="${WORKDIR}/adrkit/packages/cli/dist/index.js"
REPORT_JSON="${WORKDIR}/queue-report.json"

echo "==> Running: adr queue --dir docs/adr --as-of ${AS_OF} --format json"
bun "${ADR_CLI}" queue \
  --dir "${REPO_ROOT}/docs/adr" \
  --as-of "${AS_OF}" \
  --format json > "${REPORT_JSON}"

echo "==> Validating QueueReport v1 against dogfood expectations"
bun "${REPO_ROOT}/scripts/assert-queue-report.ts" "${REPORT_JSON}" "${AS_OF}"

echo ""
echo "==> Markdown rendering (for review only; not committed to this repository)"
bun "${ADR_CLI}" queue \
  --dir "${REPO_ROOT}/docs/adr" \
  --as-of "${AS_OF}" \
  --format markdown

echo ""
echo "==> adr lint --dir docs/adr"
bun "${ADR_CLI}" lint --dir "${REPO_ROOT}/docs/adr"

echo ""
echo "Queue validation complete: adrkit@${ADRKIT_REF}, as-of ${AS_OF}."
