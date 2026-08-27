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
ADRKIT_REF="2f19524f07938f1a7841b9f58bbcd1313e60a4dc"
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
  # Normalized before anything runs, because capture() cd's into the repository
  # root and into each self-test scratch root before invoking it. A relative
  # ADR_CLI would satisfy the check above and then fail to resolve from those
  # directories, which reads as a broken fixture rather than a bad argument.
  ADR_CLI="$(cd "$(dirname "${ADR_CLI}")" && pwd)/$(basename "${ADR_CLI}")"
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
  echo "Run with --self-test to additionally prove the assertions fail when violated."
  exit 0
fi

# ---------------------------------------------------------------------------
# Self-test: an assertion that has never been observed failing is not coverage.
#
# Each row is `IDS|target|perl-expression`. It perturbs ONE fixture in a
# throwaway copy of the repository and names every assertion that must fail as a
# result. The run fails if the suite still passes (the assertions are vacuous) or
# if any expected id is missing from the failure list (a different assertion is
# doing the work).
#
# IDS is a comma-separated list because some properties cannot be violated in
# isolation: shrinking the over-window fixture below the window necessarily
# falsifies the truncation flag, the two byte comparisons, and the batch
# truncated count at the same time. Listing them together is more honest than
# inventing four contrived fixtures to separate effects that are genuinely
# coupled.
#
# THREE ASSERTIONS ARE DELIBERATELY ABSENT, and are NOT claimed as falsified:
#
#   * TRUNC-3 (`scannedBytes` falls short of the window constant) survives every
#     edit to this fixture: shrinking it leaves `scannedBytes` equal to the whole
#     file, which is still under 8192. Falsifying it needs a file whose byte 8192
#     is EXACTLY a line terminator, so the cut lands on the constant — a
#     different fixture, byte-tuned, rather than an edit to this one. Recorded as
#     an observed limitation after the shrink perturbation was tried and did not
#     move it.
#   * TRUNC-4 (`fileBytes` equals the on-disk size) is a cross-check between two
#     observations of the same file. Any perturbation changes both consistently,
#     so no fixture edit can separate them. Falsifying it would require adrkit
#     to misreport the size, which is the thing being checked.
#   * SCAN-1 (candidate count) is determined by the FIXTURES list in this script,
#     not by fixture content, so a content perturbation cannot move it.
#   * SCAN-4 (absent / unreadable / out-of-tree / skipped are all zero) would
#     require deleting or chmod-ing a fixture rather than editing it. That is a
#     different perturbation kind, and asserting a set of zeros is weak coverage
#     either way; it is retained to catch spurious firing, not credited as
#     proven.
#
# One earlier attempt is recorded because it failed for an instructive reason.
# FIND-4 was first falsified by corrupting a record so `adr check` would exit
# non-zero. It does not: `check`'s exit status depends on error findings against
# CHANGED RECORDS, and the fixtures passed to it are source files, so a broken
# corpus left it at exit 0 while `explain` exited 1. FIND-4 was rewritten instead
# to assert that the dangling finding is REPORTED and the run still exits 0 with
# `ok: true`, which the dangling-ref perturbation below does falsify.
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
  # POS-4 and POS-5 travel with it: the same line declares 0015 and is the comma
  # list.
  'POS-2,POS-4,POS-5|src/platform/ledger-client.ts|s{^// \@adr 0005, 0015$}{// no marker}m'
  # Give the pattern-only decision a declaration. This is the assertion the
  # byte-compatibility claim rests on: 0012 must come back with NO `declaredBy`
  # key, not an empty one.
  'POS-3|src/platform/ledger-client.ts|s{^// \@adr 0005, 0015$}{// \@adr 0005, 0012, 0015}m'
  # Drop the comma and the list becomes a single declaration, so 0015 is no
  # longer declared at all.
  'POS-5,POS-4|src/platform/ledger-client.ts|s{^// \@adr 0005, 0015$}{// \@adr 0005 0015}m'
  # Ratify the proposal: a declared-but-proposed record moving to `governing`
  # is exactly what POS-4 exists to catch.
  'POS-4|docs/adr/0015-arb-review-order-ledger-migration.md|s{^status: proposed$}{status: accepted}m'
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
  # Same rule in the MDX dialect: turn its heading into an expression comment.
  'NEG-4|fixtures/markers/mdx-introducer.mdx|s{^# \@adr 0001$}{\{/* \@adr 0001 */\}}m'
  # Point the dangling ref at a record that exists: the warning must disappear,
  # and the scanned-ref list, the governance edges and FIND-4's
  # "reported-and-still-exited-0" pairing all move with it.
  'FIND-1,FIND-2,FIND-3,FIND-4|fixtures/markers/unresolvable.ts|s{^// \@adr 9999$}{// \@adr 0001}m'
  # Strip the log qualifier so a foreign-log ref binds to the local record of
  # the same id — the case a sloppy implementation would get wrong.
  'FIND-1,FIND-2,FIND-3|fixtures/markers/unresolvable.ts|s{^// \@adr payments:0012$}{// \@adr 0012}m'
  # Shrink the over-window fixture below the window. Truncation, both byte
  # comparisons, and the batch truncated count are one coupled property here.
  'TRUNC-1,TRUNC-2,SCAN-2,SCAN-3|fixtures/markers/over-window.ts|s{^// padding line.*$}{}mg'
  # Remove the header declaration: truncation must not be allowed to excuse
  # losing a marker that was inside the window.
  'TRUNC-5|fixtures/markers/over-window.ts|s{^// \@adr 0011$}{// no marker}m'
)

echo ""
echo "==> Self-test: proving each assertion fails when its property is violated"
SELF_FAILURES=0
FALSIFIED=""
for row in "${PERTURBATIONS[@]}"; do
  IFS='|' read -r expect_ids target expr <<< "${row}"
  scratch="${WORKDIR}/self/${expect_ids//,/-}"
  rm -rf "${scratch}"
  mkdir -p "${scratch}"
  # Copy only what the capture reads, so the perturbed tree is cheap.
  cp -R "${REPO_ROOT}/docs" "${REPO_ROOT}/src" "${REPO_ROOT}/fixtures" "${scratch}/"
  perl -0pi -e "${expr}" "${scratch}/${target}"

  if diff -q "${REPO_ROOT}/${target}" "${scratch}/${target}" >/dev/null; then
    echo "FAIL ${expect_ids}  perturbation did not modify ${target} (the self-test itself is broken)"
    SELF_FAILURES=$((SELF_FAILURES + 1))
    continue
  fi

  capture "${scratch}" "${scratch}/capture"
  if out="$(node "${REPO_ROOT}/scripts/assert-markers.mjs" "${scratch}/capture" 2>&1)"; then
    echo "FAIL ${expect_ids}  suite still passed after violating the property (assertion is vacuous)"
    SELF_FAILURES=$((SELF_FAILURES + 1))
    continue
  fi

  missing=""
  IFS=',' read -ra ids <<< "${expect_ids}"
  for id in "${ids[@]}"; do
    grep -q "^failing:.*\b${id}\b" <<< "${out}" || missing="${missing} ${id}"
  done
  if [[ -n "${missing}" ]]; then
    echo "FAIL ${expect_ids}  suite failed, but not on:${missing}"
    echo "${out}" | grep '^failing:' || true
    SELF_FAILURES=$((SELF_FAILURES + 1))
    continue
  fi

  echo "ok   ${expect_ids}  observed failing when violated (${target})"
  FALSIFIED="${FALSIFIED} ${expect_ids//,/ }"
done

# Report coverage as a fraction of the suite rather than as a bare pass. A
# self-test that silently stopped covering half the assertions would otherwise
# still print "OK", which is the failure mode this whole file exists to avoid.
FALSIFIED_UNIQUE="$(tr ' ' '\n' <<< "${FALSIFIED}" | sed '/^$/d' | sort -u)"
FALSIFIED_COUNT="$(wc -l <<< "${FALSIFIED_UNIQUE}" | tr -d ' ')"
TOTAL_COUNT="$(node "${REPO_ROOT}/scripts/assert-markers.mjs" "${WORKDIR}/capture" \
  | grep -cE '^(ok  |FAIL) ')"

echo ""
if (( SELF_FAILURES > 0 )); then
  echo "Marker self-test FAILED: ${SELF_FAILURES} perturbation(s) did not behave as required."
  exit 1
fi
echo "Marker self-test OK: ${#PERTURBATIONS[@]} perturbations falsified ${FALSIFIED_COUNT} of ${TOTAL_COUNT} assertions."
echo "not falsified by construction (see the PERTURBATIONS header): TRUNC-3, TRUNC-4, SCAN-1, SCAN-4"
echo ""
echo "Marker validation complete: adrkit@${ADRKIT_REF}, ${#FIXTURES[@]} fixtures."
