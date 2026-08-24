#!/usr/bin/env bash
# Validates the Phase 6 ARB operations queue behavior of this repository's
# docs/adr corpus against a pinned adrkit commit.
#
# This script is deliberately NOT a substitute for specs/007-arb-queue SC-004 /
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

# Pin: exact adrkit commit dogfooded by this repository. This is the commit
# behind adrkit's `v0.9.0` release tag. It supersedes
# d9ce9e18fbe95525b4e3b2780bfe33352a5ab7f2 (`v0.8.0`), which superseded
# e3155eaaf200c9ed7f3ea572d91f0bd4c11c35cc (`v0.7.0`), which superseded
# c5dc677f55c492056184c01252d9f812919c80f9 (`v0.6.0`), which superseded
# c3dff3a7a9c3df44233809423eb59a3505fcf6f5 (`v0.4.0`), which superseded
# bbe63e017274f173dbb40eeaceccd17df346b32b, which in turn superseded
# 896391cc385798f7f08c5694f70acaf0342789e9.
#
# The queue Action source, `action.yml`, and `dist/queue-action.js` did not
# change across `d9ce9e18...e66b43dd`; the only `packages/ci/` movement is the
# separate governing-decisions bundle. Queue-adjacent source did move:
# `resolveAsOf` moved from the CLI into `@adrkit/core` as a published consumer
# contract, and the CLI now imports it. The resolver's behavior and the queue
# report contract are intended to remain unchanged.
#
# That intended stability is re-verified rather than inferred. See README.md
# ("Re-validation against `e66b43dd`") for what was actually re-run and what
# was not.
#
# Do NOT change this to a branch name or tag — see README.md ("Pinned adrkit
# commit"). adrkit also publishes a moving `v0` major tag that currently points
# at this same commit; it is useful for DISCOVERING the current SHA, but
# adopting it as the pin would destroy the immutability this repository exists
# to demonstrate.
ADRKIT_REF="e66b43dd87d49648a7b28630fa9ecfff65225f2e"
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
cleanup() { [[ -d "${WORKDIR:-}" ]] && rm -rf "${WORKDIR}"; }
trap cleanup EXIT

echo "==> Fetching adrkit at pinned commit ${ADRKIT_REF} (shallow, no full clone)"
mkdir -p "${WORKDIR}/adrkit"
git -C "${WORKDIR}/adrkit" init --quiet
git -C "${WORKDIR}/adrkit" remote add origin "${ADRKIT_REPO}"
git -C "${WORKDIR}/adrkit" fetch --quiet --depth 1 origin "${ADRKIT_REF}"
git -C "${WORKDIR}/adrkit" checkout --quiet FETCH_HEAD
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

# Record the binary's self-reported version alongside the pinned SHA. Before
# adrkit bbe63e01 (mbeacom/adrkit#42) `adr --version` was an unknown command
# that exited 2, so the SHA was the only available provenance. Asserting exit 0
# and non-empty output here keeps that fix from silently regressing, without
# pinning the literal version string — a legitimate upstream version bump
# should not break this repository's CI.
echo "==> Recording adr --version (regression check for mbeacom/adrkit#42)"
if ! ADR_VERSION="$(bun "${ADR_CLI}" --version)"; then
  echo "error: 'adr --version' exited non-zero; mbeacom/adrkit#42 has regressed" >&2
  exit 1
fi
if [[ -z "${ADR_VERSION//[[:space:]]/}" ]]; then
  echo "error: 'adr --version' exited 0 but printed nothing" >&2
  exit 1
fi
echo "adr --version: ${ADR_VERSION}"

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
echo "Queue validation complete: adrkit@${ADRKIT_REF} (adr ${ADR_VERSION}), as-of ${AS_OF}."
