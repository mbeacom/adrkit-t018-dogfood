#!/usr/bin/env bash
# Validates adrkit's inbound `@adr` source-marker behavior against this
# repository's real corpus and a checked-in fixture set.
#
# Markers are the headline feature of adrkit v0.5.0/v0.6.0 and were the largest
# gap in this repository's coverage: before this script, no file here declared a
# marker at all, so marker-to-record resolution, the `declared by` edge, the
# dangling/foreign-log findings, and the measured scan extent were all
# structurally present and functionally unexercised.
#
# Like scripts/validate-queue.sh and scripts/validate-mcp.sh, this is owner-run
# technical validation, not specs/007-arb-queue SC-004 / T048 evidence. See
# README.md ("Status boundary").
#
# What it does:
#   1. Builds adrkit at the exact pinned commit (or reuses a prebuilt CLI via
#      ADR_CLI, so a caller that already built one does not pay for it twice).
#   2. Cross-checks that pin against scripts/validate-queue.sh.
#   3. Captures `adr explain --json` for each fixture and `adr check --json`
#      for the batch, into a temporary directory.
#   4. Delegates every correctness decision to scripts/assert-markers.mjs.
#   5. With --self-test, perturbs each fixture in a throwaway copy and requires
#      the matching assertion to FAIL, so no assertion is credited as coverage
#      without having been observed failing.
#
# Nothing here writes to the corpus, to src/, or to fixtures/, and nothing is
# committed. The only network access is the pinned shallow fetch in step 1,
# which is skipped entirely when ADR_CLI is supplied.
set -euo pipefail

# Kept in sync with scripts/validate-queue.sh; the cross-check below fails the
# build if they drift. See README.md ("Pinned adrkit commit") — never a branch
# or tag.
ADRKIT_REF="c5dc677f55c492056184c01252d9f812919c80f9"
ADRKIT_REPO="${ADRKIT_REPO:-https://github.com/mbeacom/adrkit.git}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SELF_TEST=0
[[ "${1:-}" == "--self-test" ]] && SELF_TEST=1

WORKDIR="$(mktemp -d)"
cleanup() { rm -rf "${WORKDIR}"; }
trap cleanup EXIT

echo "==> Cross-checking the adrkit pin against scripts/validate-queue.sh"
QUEUE_REF="$(sed -n 's/^ADRKIT_REF="\([0-9a-f]\{40\}\)"$/\1/p' \
  "${REPO_ROOT}/scripts/validate-queue.sh" | head -n 1)"
if [[ -z "${QUEUE_REF}" ]]; then
  echo "error: could not extract ADRKIT_REF from scripts/validate-queue.sh" >&2
  exit 1
fi
if [[ "${QUEUE_REF}" != "${ADRKIT_REF}" ]]; then
  echo "error: adrkit pin disagreement between validation scripts" >&2
  echo "  validate-markers.sh: ${ADRKIT_REF}" >&2
  echo "  validate-queue.sh:   ${QUEUE_REF}" >&2
  exit 1
fi
echo "both validation scripts pin ${ADRKIT_REF}"

if [[ -n "${ADR_CLI:-}" ]]; then
  echo ""
  echo "==> Using the prebuilt adrkit CLI at ${ADR_CLI}"
  if [[ ! -f "${ADR_CLI}" ]]; then
    echo "error: ADR_CLI=${ADR_CLI} does not exist" >&2
    exit 1
  fi
else
  echo ""
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
  echo "==> Building adrkit"
  (cd "${WORKDIR}/adrkit" && bun install --frozen-lockfile >/dev/null && bun run build >/dev/null)
  ADR_CLI="${WORKDIR}/adrkit/packages/cli/dist/index.js"
fi

# slug:path — the fixture set. `handler` and `ledger-client` are real source
# files under src/ (so the governance Action scans them on every pull request
# that touches them); the rest are inert fixtures that exist only to be scanned.
FIXTURES=(
  "handler:src/payments/api/handler.ts"
  "ledger-client:src/platform/ledger-client.ts"
  "not-a-marker:fixtures/markers/not-a-marker.ts"
  "fenced-examples:fixtures/markers/fenced-examples.ts"
  "markdown-introducers:fixtures/markers/markdown-introducers.md"
  "mdx-introducer:fixtures/markers/mdx-introducer.mdx"
  "unresolvable:fixtures/markers/unresolvable.ts"
  "over-window:fixtures/markers/over-window.ts"
)

# Capture every surface the assertions read, from one tree, into one directory.
capture() {
  local root="$1" out="$2"
  mkdir -p "${out}"

  local paths=()
  for entry in "${FIXTURES[@]}"; do
    local slug="${entry%%:*}" path="${entry#*:}"
    (cd "${root}" && bun "${ADR_CLI}" explain "${path}" --dir docs/adr --json) \
      > "${out}/${slug}.json"
    # handler.ts is deliberately excluded from the batch `check` below: it is
    # the one fixture whose governance comes from a pattern, and including it
    # would make SCAN-1's candidate count depend on it rather than on the
    # marker fixture set.
    [[ "${slug}" == "handler" ]] || paths+=("${path}")
  done

  wc -c < "${root}/fixtures/markers/over-window.ts" | tr -d ' ' \
    > "${out}/over-window-size.txt"

  # The fixture text itself, so assertions can be written against the CONTENT of
  # a declaring line rather than its line number. A positional assertion would
  # break on any unrelated edit to a fixture's leading comment, and would say
  # nothing about which of several marker-looking lines actually declared.
  for entry in "${FIXTURES[@]}"; do
    local slug="${entry%%:*}" path="${entry#*:}"
    cp "${root}/${path}" "${out}/${slug}.source"
  done

  local rc=0
  (cd "${root}" && bun "${ADR_CLI}" check "${paths[@]}" --dir docs/adr --json) \
    > "${out}/check.json" || rc=$?
  printf '%s' "${rc}" > "${out}/check-exit.txt"
}

echo ""
echo "==> Capturing marker surfaces against the real corpus"
capture "${REPO_ROOT}" "${WORKDIR}/capture"

echo ""
echo "==> Asserting expected vs. observed"
node "${REPO_ROOT}/scripts/assert-markers.mjs" "${WORKDIR}/capture"

if (( SELF_TEST == 0 )); then
  echo ""
  echo "Marker validation complete: adrkit@${ADRKIT_REF}, ${#FIXTURES[@]} fixtures."
  echo "Run with --self-test to additionally prove each assertion fails when violated."
  exit 0
fi

# ---------------------------------------------------------------------------
# Self-test: an assertion that has never been observed failing is not coverage.
#
# Each row perturbs ONE fixture in a throwaway copy of the repository and names
# the assertion that must fail as a result. The run fails if the suite still
# passes (the assertion is vacuous) or if it fails without naming the expected
# id (the assertion is not the one doing the work).
#
# perl -0pi is used rather than sed -i for portability between GNU and BSD.
# ---------------------------------------------------------------------------
PERTURBATIONS=(
  # Single-quoted on purpose: these expressions contain backticks (the fence
  # fixture) and `$` anchors, both of which bash would otherwise interpret.
  # perl sees `\@` as a literal `@`, which stops it interpolating `@adr` as an
  # array in the pattern.
  #
  # Turn the merge case into a marker-only case: if POS-1 did not really check
  # that BOTH edges are present, removing the pattern edge would go unnoticed.
  'POS-1|docs/adr/0014-async-review-payments-settlement-cache-invalidation.md|s{src/payments/\*\*}{src/nowhere/**}'
  # Remove the inbound declaration and POS-2's empty-matcher signature vanishes.
  'POS-2|src/platform/ledger-client.ts|s{^// \@adr 0005, 0015$}{// no marker}m'
  # Give the pattern-only decision a declaration; POS-3's control must notice.
  'POS-3|src/platform/ledger-client.ts|s{^// \@adr 0005, 0015$}{// \@adr 0005, 0012, 0015}m'
  # Drop the comma and the list becomes a single declaration.
  'POS-5|src/platform/ledger-client.ts|s{^// \@adr 0005, 0015$}{// \@adr 0005 0015}m'
  # Neutralize the block-comment introducer.
  'POS-6|fixtures/markers/not-a-marker.ts|s{^ \* \@adr 0001}{ x \@adr 0001}m'
  # Remove the one real declaration from the fenced fixture.
  'POS-7|fixtures/markers/fenced-examples.ts|s{^// \@adr 0002$}{// no marker}m'
  # Remove the HTML comment markdown genuinely hides.
  'POS-8|fixtures/markers/markdown-introducers.md|s{^<!-- \@adr 0003 -->$}{no marker}m'
  # Remove the MDX expression comment.
  'POS-9|fixtures/markers/mdx-introducer.mdx|s{^\{/\* \@adr 0004 \*/\}$}{no marker}m'
  # Promote a decoy to a real dedicated-line marker: NEG-1 pins the declaring
  # line's introducer, so a second line resolving must be caught. The prose
  # decoy is used rather than the trailing one because it contains no quotes.
  'NEG-1|fixtures/markers/not-a-marker.ts|s{^  // Discussing \@adr 0001.*$}{  // \@adr 0001}m'
  # Delete the first opening fence so its example stops being fenced.
  'NEG-2|fixtures/markers/fenced-examples.ts|s{^```$}{}m'
  # Make a markdown heading into an HTML comment.
  'NEG-3|fixtures/markers/markdown-introducers.md|s{^# \@adr 0001$}{<!-- \@adr 0001 -->}m'
  # Point the dangling ref at a record that exists: the warning must disappear.
  'FIND-1|fixtures/markers/unresolvable.ts|s{^// \@adr 9999$}{// \@adr 0001}m'
  # Shrink the over-window fixture below the window: truncation must stop.
  'TRUNC-1|fixtures/markers/over-window.ts|s{^// padding line.*$}{}mg'
)

echo ""
echo "==> Self-test: proving each assertion fails when its property is violated"
SELF_FAILURES=0
for row in "${PERTURBATIONS[@]}"; do
  IFS='|' read -r expect_id target expr <<< "${row}"
  scratch="${WORKDIR}/self/${expect_id}"
  mkdir -p "${scratch}"
  # Copy only what the capture reads, so the perturbed tree is cheap.
  cp -R "${REPO_ROOT}/docs" "${REPO_ROOT}/src" "${REPO_ROOT}/fixtures" "${scratch}/"
  perl -0pi -e "${expr}" "${scratch}/${target}"

  if diff -q "${REPO_ROOT}/${target}" "${scratch}/${target}" >/dev/null; then
    echo "FAIL ${expect_id}  perturbation did not modify ${target} (the self-test itself is broken)"
    SELF_FAILURES=$((SELF_FAILURES + 1))
    continue
  fi

  capture "${scratch}" "${scratch}/capture"
  if out="$(node "${REPO_ROOT}/scripts/assert-markers.mjs" "${scratch}/capture" 2>&1)"; then
    echo "FAIL ${expect_id}  suite still passed after violating the property (assertion is vacuous)"
    SELF_FAILURES=$((SELF_FAILURES + 1))
  elif ! grep -q "^failing:.*\b${expect_id}\b" <<< "${out}"; then
    echo "FAIL ${expect_id}  suite failed, but not on ${expect_id}"
    echo "${out}" | grep '^failing:' || true
    SELF_FAILURES=$((SELF_FAILURES + 1))
  else
    echo "ok   ${expect_id}  observed failing when violated (${target})"
  fi
done

echo ""
if (( SELF_FAILURES > 0 )); then
  echo "Marker self-test FAILED: ${SELF_FAILURES} assertion(s) were not observed failing."
  exit 1
fi
echo "Marker self-test OK: ${#PERTURBATIONS[@]} assertions each observed failing when violated."
echo ""
echo "Marker validation complete: adrkit@${ADRKIT_REF}, ${#FIXTURES[@]} fixtures."
