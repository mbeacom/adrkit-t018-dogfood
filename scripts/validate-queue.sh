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
# behind adrkit's `v0.4.0` release tag. It supersedes
# bbe63e017274f173dbb40eeaceccd17df346b32b, which in turn superseded
# 896391cc385798f7f08c5694f70acaf0342789e9.
#
# No Action source changed across this repin: `packages/ci/src/` and
# `packages/ci/queue/action.yml` are byte-identical to the previous pin. The
# only changed files under packages/ci/ are the two committed bundles
# (dist/index.js, dist/queue-action.js), `package.json`, and a new
# test/bundle-scope.test.ts. The bundles moved because bundled dependencies
# moved beneath them — notably the @actions/core ^1 -> ^3 and @actions/github
# ^6 -> ^9 major bumps in packages/ci/package.json. That is a weaker claim
# than a source change, so the corpus-load fail-closed boundary was re-probed
# directly against the regenerated bundle rather than inferred — see README.md
# ("Fail-closed evidence").
#
# Do NOT change this to a branch name or tag — see README.md ("Pinned adrkit
# commit"). adrkit also publishes a moving `v0` major tag that currently points
# at this same commit; it is useful for DISCOVERING the current SHA, but
# adopting it as the pin would destroy the immutability this repository exists
# to demonstrate.
ADRKIT_REF="c3dff3a7a9c3df44233809423eb59a3505fcf6f5"
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
