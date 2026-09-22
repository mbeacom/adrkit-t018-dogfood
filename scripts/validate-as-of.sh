#!/usr/bin/env bash
# Validates `adr explain --as-of <date|ref>` (ADR-0039) against this
# repository's real corpus, extended with fixtures that make the temporal
# rules observable — the corpus as it stood before this script could only
# exercise "accepted record governs" and "record did not exist yet", never
# the window *closing*, which is the entire feature. See ADR-0039 action
# item 5 and README.md ("As-of validation").
#
# This is rung-2 evidence per ADR-0014, not rung-3 external validation: it
# runs from this maintainer-owned, isolated reference repository against a
# pinned adrkit commit, self-verifies its own expectations, and includes
# fail-closed cases. It is not "externally validated" or "production-ready".
#
# What it does:
#   1. Builds adrkit at the exact pinned v0.14.0 commit (or reuses a prebuilt
#      CLI via ADR_CLI, so a caller that already built one does not pay for
#      it twice).
#   2. Captures `adr explain --json` for every as-of scenario against this
#      repository's real corpus (docs/adr/0016-0022, src/temporal/**).
#   3. Builds an isolated, throwaway git repository with pinned committer
#      dates to exercise `--as-of <ref>`, a date-shaped tag, and the
#      "not a git repository" fail-closed case, without touching this
#      repository's own history or tag namespace.
#   4. Captures the four fail-closed scenarios (invalid date, timezone-less
#      datetime, unresolvable ref, outside a git repository), asserting
#      `git status --porcelain` is empty and stdout is empty after each.
#   5. Delegates every correctness decision to scripts/assert-as-of.mjs.
#   6. With --self-test, perturbs the corpus fixtures in a throwaway copy and
#      requires the matching assertions to FAIL, so no assertion is credited
#      as coverage without having been observed failing (ADR-0016).
#
# This script does NOT join the ADRKIT_REF cross-check that
# validate-queue.sh/validate-markers.sh/validate-mcp.sh/validate-badge-reports.sh
# share, because it deliberately pins a newer commit (v0.14.0, 4886dd6) than
# those scripts do (v0.13.0, 3e40675) — `--as-of` does not exist at their pin.
# See README.md ("Two adrkit pins in this repository") for why that is a
# recorded, temporary divergence rather than an oversight.
#
# Nothing here writes to docs/adr, src/, or fixtures/, and nothing is
# committed. The only network access is the pinned shallow fetch in step 1,
# skipped entirely when ADR_CLI is supplied.
set -euo pipefail

# Pin: exact adrkit commit dogfooded by this validation. This is the commit
# behind adrkit's `v0.14.0` release tag, the first to ship
# `adr explain --as-of` (ADR-0039). Never a moving branch or tag — see
# README.md ("Why a SHA and never a moving ref").
ADRKIT_REF="4886dd6bb127d6aca57804a71d1c4b8548424d3b"
ADRKIT_REPO="${ADRKIT_REPO:-https://github.com/mbeacom/adrkit.git}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SELF_TEST=0
[[ "${1:-}" == "--self-test" ]] && SELF_TEST=1

WORKDIR="$(mktemp -d)"
cleanup() { rm -rf "${WORKDIR}"; }
trap cleanup EXIT

if [[ -n "${ADR_CLI:-}" ]]; then
  echo "==> Using the prebuilt adrkit CLI at ${ADR_CLI}"
  if [[ ! -f "${ADR_CLI}" ]]; then
    echo "error: ADR_CLI=${ADR_CLI} does not exist" >&2
    exit 1
  fi
  ADR_CLI="$(cd "$(dirname "${ADR_CLI}")" && pwd)/$(basename "${ADR_CLI}")"
else
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

ADR_VERSION="$(bun "${ADR_CLI}" --version)"
echo "==> adr --version: ${ADR_VERSION}"
if [[ "${ADR_VERSION}" != "0.14.0" ]]; then
  echo "error: expected adr 0.14.0 at pin ${ADRKIT_REF}, got ${ADR_VERSION}" >&2
  exit 1
fi

# Isolate every git subprocess this script or the CLI runs from the
# developer's own global/system git config. ADR-0039's Consequences record
# that `tag.gpgSign = true` set globally hangs a git invocation on a
# passphrase prompt, and `log.showSignature = true` corrupts stdout — both
# observed by running the code, not anticipated. That hazard applies to this
# harness's own throwaway repo just as much as to a real user's.
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_SYSTEM=/dev/null

# ---------------------------------------------------------------------------
# Step 1: capture every corpus-based scenario against the real, committed
# fixtures under docs/adr/0016-0022 and src/temporal/**.
# ---------------------------------------------------------------------------
CAPTURE="${WORKDIR}/capture"
mkdir -p "${CAPTURE}"

# explain_json <slug> <path> [--as-of <value>]
explain_json() {
  local slug="$1" path="$2"
  shift 2
  (cd "${REPO_ROOT}" && bun "${ADR_CLI}" explain "${path}" --dir docs/adr --json "$@") \
    > "${CAPTURE}/${slug}.json"
}

capture_corpus_scenarios() {
  local capture="$1"
  mkdir -p "${capture}"

  # explain_json_into <slug> <path> [--as-of <value>] — capture-dir-aware variant.
  local pool="src/temporal/pool/worker-pool.ts"
  local legacy="src/temporal/legacy/restart.ts"
  local inverted="src/temporal/inverted/scheduler.ts"

  (cd "${REPO_ROOT}" && bun "${ADR_CLI}" explain "${pool}" --dir docs/adr --json) \
    > "${capture}/pool-no-flag.json"

  (cd "${REPO_ROOT}" && bun "${ADR_CLI}" explain "${pool}" --dir docs/adr --json --as-of 2025-10-31) \
    > "${capture}/pool-before-open.json"
  (cd "${REPO_ROOT}" && bun "${ADR_CLI}" explain "${pool}" --dir docs/adr --json --as-of 2025-11-01) \
    > "${capture}/pool-on-open.json"
  (cd "${REPO_ROOT}" && bun "${ADR_CLI}" explain "${pool}" --dir docs/adr --json --as-of 2026-01-31) \
    > "${capture}/pool-last-day-of-window.json"
  (cd "${REPO_ROOT}" && bun "${ADR_CLI}" explain "${pool}" --dir docs/adr --json --as-of 2026-02-01) \
    > "${capture}/pool-handover-day.json"
  (cd "${REPO_ROOT}" && bun "${ADR_CLI}" explain "${pool}" --dir docs/adr --json --as-of 2026-06-01) \
    > "${capture}/pool-during-terminal-tenure.json"

  (cd "${REPO_ROOT}" && bun "${ADR_CLI}" explain "${legacy}" --dir docs/adr --json --as-of 2026-01-01) \
    > "${capture}/legacy-after-deprecation.json"
  (cd "${REPO_ROOT}" && bun "${ADR_CLI}" explain "${legacy}" --dir docs/adr --json --as-of 2025-12-15) \
    > "${capture}/legacy-on-rejection-date.json"

  (cd "${REPO_ROOT}" && bun "${ADR_CLI}" explain "${inverted}" --dir docs/adr --as-of 2026-05-01) \
    > "${capture}/inverted-after-both-dates.stdout" 2>"${capture}/inverted-after-both-dates.stderr" || true
  (cd "${REPO_ROOT}" && bun "${ADR_CLI}" explain "${inverted}" --dir docs/adr --json --as-of 2026-05-01) \
    > "${capture}/inverted-after-both-dates.json"

  (cd "${REPO_ROOT}" && bun "${ADR_CLI}" explain "${pool}" --dir docs/adr --json) \
    > "${capture}/marker-present-tense.json"
  (cd "${REPO_ROOT}" && bun "${ADR_CLI}" explain "${pool}" --dir docs/adr --json --as-of 2025-12-01) \
    > "${capture}/marker-as-of-in-window.json"
  (cd "${REPO_ROOT}" && bun "${ADR_CLI}" explain "${pool}" --dir docs/adr --json --as-of 2026-03-01) \
    > "${capture}/marker-as-of-outside-window.json"
}

echo ""
echo "==> Capturing as-of scenarios against the real corpus"
capture_corpus_scenarios "${CAPTURE}"

# ---------------------------------------------------------------------------
# Step 2: isolated throwaway git repository for ref resolution and the
# "not a git repository" fail-closed case. Never the dogfood repository's own
# history or tag namespace — a tag named `2026-03-01` here would pollute this
# repository's tag list and would not exist on a fresh CI clone anyway.
# ---------------------------------------------------------------------------
GITPROBE="${WORKDIR}/gitprobe"
mkdir -p "${GITPROBE}/docs/adr" "${GITPROBE}/src/temporal/pool"
# All three chain records: 0017's supersededBy points at 0018, and a
# dangling-supersededBy error would gate `explain` before any temporal code
# runs (ADR-0039) — copying 0016/0017 alone would make this fixture invalid.
cp "${REPO_ROOT}/docs/adr/0016-adopt-connection-pooling-for-temporal-workers.md" "${GITPROBE}/docs/adr/"
cp "${REPO_ROOT}/docs/adr/0017-adopt-managed-connection-pool-service-for-temporal-workers.md" "${GITPROBE}/docs/adr/"
cp "${REPO_ROOT}/docs/adr/0018-adopt-vendor-pgbouncer-for-temporal-workers.md" "${GITPROBE}/docs/adr/"
cp "${REPO_ROOT}/src/temporal/pool/worker-pool.ts" "${GITPROBE}/src/temporal/pool/"

(
  cd "${GITPROBE}"
  git init --quiet -b main
  git config user.email "dogfood@example.invalid"
  git config user.name "adrkit dogfood"
  git config commit.gpgsign false
  git config tag.gpgSign false
  git add -A
  GIT_COMMITTER_DATE="2025-11-01T12:00:00Z" GIT_AUTHOR_DATE="2025-11-01T12:00:00Z" \
    git commit --quiet -m "seed at 0016's opening date"
  # A tag literally named like a date. ADR-0039's stated precedence is the
  # date grammar FIRST, so `--as-of 2026-03-01` below must resolve as a date
  # and never touch this tag, even though it resolves to a real commit.
  git tag "2026-03-01"
)

echo ""
echo "==> Capturing git-ref resolution scenarios (isolated throwaway repository)"
(cd "${GITPROBE}" && bun "${ADR_CLI}" explain src/temporal/pool/worker-pool.ts --dir docs/adr --json --as-of HEAD) \
  > "${CAPTURE}/ref-committer-date.json"
(cd "${GITPROBE}" && bun "${ADR_CLI}" explain src/temporal/pool/worker-pool.ts --dir docs/adr --json --as-of "2026-03-01") \
  > "${CAPTURE}/date-shaped-tag-resolves-as-date.json"

# Sanity: the committer date this harness pinned really is what got resolved.
RESOLVED_COMMITTED_AT="$(node -e "console.log(require('${CAPTURE}/ref-committer-date.json').asOf.committedAt)")"
if [[ "${RESOLVED_COMMITTED_AT}" != "2025-11-01T12:00:00Z" ]]; then
  echo "error: --as-of HEAD resolved committedAt ${RESOLVED_COMMITTED_AT}, expected 2025-11-01T12:00:00Z" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Step 3: fail-closed scenarios. Each must exit 2, print nothing to stdout,
# and mutate nothing. git status --porcelain is asserted empty before AND
# after every case, in both the real repository and the throwaway one.
# ---------------------------------------------------------------------------
echo ""
echo "==> Capturing fail-closed scenarios"

STATUS_BEFORE="$(cd "${REPO_ROOT}" && git status --porcelain)"

run_fail_closed() {
  local slug="$1" cwd="$2"
  shift 2
  local exit_code=0
  (cd "${cwd}" && bun "${ADR_CLI}" "$@") \
    > "${CAPTURE}/${slug}.stdout" 2> "${CAPTURE}/${slug}.stderr" || exit_code=$?
  printf '%s' "${exit_code}" > "${CAPTURE}/${slug}.exit"
}

run_fail_closed fail-invalid-date "${REPO_ROOT}" \
  explain src/temporal/pool/worker-pool.ts --dir docs/adr --as-of "2026-02-30"
run_fail_closed fail-tzless "${REPO_ROOT}" \
  explain src/temporal/pool/worker-pool.ts --dir docs/adr --as-of "2026-03-01T00:00:00"
run_fail_closed fail-no-such-ref "${REPO_ROOT}" \
  explain src/temporal/pool/worker-pool.ts --dir docs/adr --as-of "no-such-ref"

# A directory that is genuinely not inside any git repository. Verified, not
# assumed: a tmp dir under macOS/Linux CI runners is not itself a repo, but a
# parent directory could theoretically be one in an unusual environment.
NOGIT="${WORKDIR}/nogit"
mkdir -p "${NOGIT}/docs/adr" "${NOGIT}/src/temporal/pool"
cp "${REPO_ROOT}/docs/adr/0016-adopt-connection-pooling-for-temporal-workers.md" "${NOGIT}/docs/adr/"
cp "${REPO_ROOT}/docs/adr/0017-adopt-managed-connection-pool-service-for-temporal-workers.md" "${NOGIT}/docs/adr/"
cp "${REPO_ROOT}/docs/adr/0018-adopt-vendor-pgbouncer-for-temporal-workers.md" "${NOGIT}/docs/adr/"
cp "${REPO_ROOT}/src/temporal/pool/worker-pool.ts" "${NOGIT}/src/temporal/pool/"
if (cd "${NOGIT}" && git rev-parse --show-toplevel) >/dev/null 2>&1; then
  echo "error: ${NOGIT} is unexpectedly inside a git repository; cannot exercise the not-a-git-repository case" >&2
  exit 1
fi
run_fail_closed fail-outside-git-repo "${NOGIT}" \
  explain src/temporal/pool/worker-pool.ts --dir docs/adr --as-of "deadbeef"

STATUS_AFTER="$(cd "${REPO_ROOT}" && git status --porcelain)"
if [[ "${STATUS_BEFORE}" != "${STATUS_AFTER}" ]]; then
  echo "error: git status --porcelain changed across the fail-closed scenarios" >&2
  echo "--- before ---" >&2
  echo "${STATUS_BEFORE}" >&2
  echo "--- after ---" >&2
  echo "${STATUS_AFTER}" >&2
  exit 1
fi
echo "git status --porcelain unchanged across all fail-closed scenarios"

# ---------------------------------------------------------------------------
# Step 4: delegate every correctness decision to assert-as-of.mjs.
# ---------------------------------------------------------------------------
echo ""
echo "==> Asserting expected vs. observed"
node "${REPO_ROOT}/scripts/assert-as-of.mjs" "${CAPTURE}"

if (( SELF_TEST == 0 )); then
  echo ""
  echo "As-of validation complete: adrkit@${ADRKIT_REF} (adr ${ADR_VERSION})."
  echo "Run with --self-test to additionally prove the assertions fail when violated."
  exit 0
fi

# ---------------------------------------------------------------------------
# Self-test: an assertion that has never been observed failing is not
# coverage (ADR-0016). Each row perturbs ONE fixture in a throwaway copy of
# the corpus and names every assertion that must fail as a result.
# ---------------------------------------------------------------------------
PERTURBATIONS=(
  # Shift 0016's own date past 0017's — 0016 becomes an inverted window
  # (opens after its own successor) rather than simply "later". It is never
  # governing at any of the boundary dates and is notYetRecorded, not
  # history, on the old handover day. BOUND-5/6/DISAGREE-1 are unaffected:
  # they assert properties of 0017 (unperturbed) and of 0016's PRESENT-tense
  # bucket (also unperturbed by a date change alone), so they are correctly
  # left off this list rather than over-claimed.
  'BOUND-2,BOUND-3,BOUND-4,DISAGREE-2|docs/adr/0016-adopt-connection-pooling-for-temporal-workers.md|s{^date: 2025-11-01$}{date: 2026-03-01}m'
  # Repoint 0016's successor at the chain terminal directly: the
  # immediate-not-terminal assertion (CHAIN-1) must catch this.
  'CHAIN-1|docs/adr/0016-adopt-connection-pooling-for-temporal-workers.md|s{^supersededBy: "0017"$}{supersededBy: "0018"}m'
  # Turn 0019 from deprecated into accepted: it must stop being undetermined.
  'DEP-1,DEP-2,DEP-3|docs/adr/0019-deprecate-manual-temporal-worker-restarts.md|s{^status: deprecated$}{status: accepted}m'
  # Turn 0020 from rejected into accepted: it must stop being history-only.
  'REJ-1,REJ-2,REJ-3|docs/adr/0020-reject-single-global-temporal-worker-pool.md|s{^status: rejected$}{status: accepted}m'
  # Fix the inversion: date 0022 after 0021. 0021 remains history and never
  # governing either way (INV-1/INV-2 hold regardless — a superseded record
  # with a validly-closed window is still not governing after its own
  # window ends), so only the inverted-window finding and its rendering are
  # exclusively tied to the inversion itself.
  'INV-3,INV-5|docs/adr/0022-adopt-round-robin-worker-scheduling-for-temporal-tasks.md|s{^date: 2026-03-01$}{date: 2026-05-01}m'
  # Remove the inbound marker entirely. MARK-1/MARK-4 assert the finding
  # FIRES and are falsified (no marker means never stale). MARK-2 asserts
  # the finding is ABSENT and is left off this list on purpose: with no
  # marker at all, "stale-marker is absent" stays vacuously true, so this
  # perturbation cannot falsify it — a different edit (naming an
  # always-accurate record) would be needed for that, and is not attempted
  # here because the marker fixture already carries the property it exists
  # to test (suppression), which the corpus-scenario assertions confirm.
  'MARK-1,MARK-4|src/temporal/pool/worker-pool.ts|s{^// \@adr 0016$}{// no marker}m'
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
  cp -R "${REPO_ROOT}/docs" "${REPO_ROOT}/src" "${scratch}/"
  perl -0pi -e "${expr}" "${scratch}/${target}"

  if diff -q "${REPO_ROOT}/${target}" "${scratch}/${target}" >/dev/null; then
    echo "FAIL ${expect_ids}  perturbation did not modify ${target} (the self-test itself is broken)"
    SELF_FAILURES=$((SELF_FAILURES + 1))
    continue
  fi

  scratch_capture="${scratch}/capture"
  # Reuse the same capture routine against the perturbed tree by temporarily
  # rebinding REPO_ROOT for this iteration only.
  (
    REPO_ROOT="${scratch}"
    capture_corpus_scenarios "${scratch_capture}"
  )
  # capture_corpus_scenarios above ran in a subshell with REPO_ROOT rebound;
  # the function itself reads REPO_ROOT from its enclosing scope, so redefine
  # it inline here instead of relying on the subshell export.
  (
    cd "${scratch}"
    bun "${ADR_CLI}" explain src/temporal/pool/worker-pool.ts --dir docs/adr --json \
      > "${scratch_capture}/pool-no-flag.json"
    bun "${ADR_CLI}" explain src/temporal/pool/worker-pool.ts --dir docs/adr --json --as-of 2025-10-31 \
      > "${scratch_capture}/pool-before-open.json"
    bun "${ADR_CLI}" explain src/temporal/pool/worker-pool.ts --dir docs/adr --json --as-of 2025-11-01 \
      > "${scratch_capture}/pool-on-open.json"
    bun "${ADR_CLI}" explain src/temporal/pool/worker-pool.ts --dir docs/adr --json --as-of 2026-01-31 \
      > "${scratch_capture}/pool-last-day-of-window.json"
    bun "${ADR_CLI}" explain src/temporal/pool/worker-pool.ts --dir docs/adr --json --as-of 2026-02-01 \
      > "${scratch_capture}/pool-handover-day.json"
    bun "${ADR_CLI}" explain src/temporal/pool/worker-pool.ts --dir docs/adr --json --as-of 2026-06-01 \
      > "${scratch_capture}/pool-during-terminal-tenure.json"
    bun "${ADR_CLI}" explain src/temporal/legacy/restart.ts --dir docs/adr --json --as-of 2026-01-01 \
      > "${scratch_capture}/legacy-after-deprecation.json"
    bun "${ADR_CLI}" explain src/temporal/legacy/restart.ts --dir docs/adr --json --as-of 2025-12-15 \
      > "${scratch_capture}/legacy-on-rejection-date.json"
    bun "${ADR_CLI}" explain src/temporal/inverted/scheduler.ts --dir docs/adr --as-of 2026-05-01 \
      > "${scratch_capture}/inverted-after-both-dates.stdout" 2>"${scratch_capture}/inverted-after-both-dates.stderr" || true
    bun "${ADR_CLI}" explain src/temporal/inverted/scheduler.ts --dir docs/adr --json --as-of 2026-05-01 \
      > "${scratch_capture}/inverted-after-both-dates.json"
    bun "${ADR_CLI}" explain src/temporal/pool/worker-pool.ts --dir docs/adr --json \
      > "${scratch_capture}/marker-present-tense.json"
    bun "${ADR_CLI}" explain src/temporal/pool/worker-pool.ts --dir docs/adr --json --as-of 2025-12-01 \
      > "${scratch_capture}/marker-as-of-in-window.json"
    bun "${ADR_CLI}" explain src/temporal/pool/worker-pool.ts --dir docs/adr --json --as-of 2026-03-01 \
      > "${scratch_capture}/marker-as-of-outside-window.json"
  )
  # Fail-closed and git-ref captures are untouched by these corpus
  # perturbations; reuse the originals so assert-as-of.mjs has a complete set.
  for extra in ref-committer-date date-shaped-tag-resolves-as-date \
    fail-invalid-date fail-tzless fail-no-such-ref fail-outside-git-repo; do
    for ext in json exit stdout stderr; do
      [[ -f "${CAPTURE}/${extra}.${ext}" ]] && cp "${CAPTURE}/${extra}.${ext}" "${scratch_capture}/"
    done
  done

  if out="$(node "${REPO_ROOT}/scripts/assert-as-of.mjs" "${scratch_capture}" 2>&1)"; then
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

FALSIFIED_UNIQUE="$(tr ' ' '\n' <<< "${FALSIFIED}" | sed '/^$/d' | sort -u)"
FALSIFIED_COUNT="$(wc -l <<< "${FALSIFIED_UNIQUE}" | tr -d ' ')"
TOTAL_COUNT="$(node "${REPO_ROOT}/scripts/assert-as-of.mjs" "${CAPTURE}" | grep -cE '^(ok  |FAIL) ')"

echo ""
if (( SELF_FAILURES > 0 )); then
  echo "As-of self-test FAILED: ${SELF_FAILURES} perturbation(s) did not behave as required."
  exit 1
fi
echo "As-of self-test OK: ${#PERTURBATIONS[@]} perturbations falsified ${FALSIFIED_COUNT} of ${TOTAL_COUNT} assertions."
echo "not falsified by construction: SHAPE-*, REF-*, FAIL-* (fixed by the git/fail-closed harness, not by corpus content), CHAIN-3/4/5, BOUND-1/1b/5/6, DISAGREE-1, INV-1/2, MARK-2 (each holds under every perturbation attempted; see comments above PERTURBATIONS)"
echo ""
echo "As-of validation complete: adrkit@${ADRKIT_REF} (adr ${ADR_VERSION})."
