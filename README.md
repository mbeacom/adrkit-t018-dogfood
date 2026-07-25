# adrkit-t018-dogfood

Owner-run technical dogfood repository for [adrkit](https://github.com/mbeacom/adrkit):

- **Phase 3 (T018)** — external-repository validation of the `mbeacom/adrkit/packages/ci@main`
  PR-governance Action against a real corpus of `accepted` decision records
  (`docs/adr/0001`–`0012`) and a governed source subset (`src/payments/**`).
- **Phase 6 (specs/007-arb-queue)** — technical validation of the `adr queue`
  CLI, the `QueueReport` v1 contract, and the `mbeacom/adrkit/packages/ci/queue`
  managed-issue Action against a corpus of `proposed` decision records
  (`docs/adr/0013`–`0015`) spanning all three ARB routing tiers.
- **Full CLI + MCP surface dogfood (2026-07-25)** — a one-off, wider run
  covering every `adr` subcommand and the `@adrkit/mcp` server, performed at
  the time of the `896391cc` repin. See
  [Full CLI + MCP surface dogfood](#full-cli--mcp-surface-dogfood-2026-07-25)
  for what works and the four defects it found.

## ⚠️ Status boundary — this is NOT SC-004 evidence

This repository is owned and operated by the adrkit maintainer (`@mbeacom`).
It demonstrates that the ARB queue kernel, CLI, and GitHub Action behave
correctly against a real, schema-valid corpus outside the `adrkit` repo
itself. **It must not be cited as satisfying `specs/007-arb-queue` SC-004 /
T048** ("validated with a team that isn't yours"), because there is no
independent, non-maintainer-owned team operating this queue. SC-004/T048
requires validation by a genuinely external team; that remains open and is
tracked separately in the `adrkit` repository.

## Pinned adrkit commit

All adrkit usage in this repository — the validation script and the
GitHub Actions workflows — is pinned to an exact 40-character adrkit commit:

```
896391cc385798f7f08c5694f70acaf0342789e9
```

This is the tip of adrkit `main` as of 2026-07-25. It supersedes the previous
pin `efef89b5d747ca175a1947f1ce2f4296dab54fa3` (the `specs/007-arb-queue`
merge commit). The repin was made to dogfood the current tip of adrkit rather
than a now-historical commit.

**The repin changes the provenance of this evidence, not the behavior under
test.** `git diff efef89b5..896391cc -- packages/ci/` is empty — the queue
Action's `action.yml` and its committed `dist/queue-action.js` are
byte-identical across the two commits. Across all of `packages/`, the only
change is one CLI test file (`packages/cli/test/lint.test.ts`); the remaining
50 commits are documentation and spec work. Every assertion in
`scripts/assert-queue-report.ts` reproduces byte-identically under the new pin.

This is a full 40-character commit SHA, never a moving branch or tag. Do not
change any pin in this repository to `@main`, `@v0`, or any other ref without
re-running the full validation procedure below and updating this document.
(The pre-existing Phase 3 `packages/ci@main` reference in
[`.github/workflows/adr.yml`](.github/workflows/adr.yml) predates this pinning
requirement and is left untouched from Phase 3; it governs PRs against this
repository, not the ARB queue.)

## Repository layout

| Path | Purpose |
|------|---------|
| `docs/adr/0001`–`0012` | Phase 3 T018 corpus: `accepted` records governing `src/payments/**` and other component boundaries. Preserved as-is. |
| `docs/adr/0013`–`0015` | Phase 6 ARB queue corpus: `proposed` records exercising the `auto`, `async`, and `arb` routing tiers with deterministic SLA state, approvals, objections, and quorum. |
| `src/payments/api/handler.ts` | Governed source subset from Phase 3 T018, exercised by the `adr.yml` PR-governance workflow. |
| `fixtures/fail-closed-invalid-corpus-dir` | Checked-in invalid-input fixture: a plain **file** (not a directory) used as the `dir` input to the queue Action in `arb-queue-fail-closed.yml`, to deterministically trigger adrkit's corpus-load `ENOTDIR` failure before any GitHub write. |
| `.github/workflows/adr.yml` | Phase 3 T018 workflow: PR-time governance via `mbeacom/adrkit/packages/ci@main`. Unchanged. |
| `.github/workflows/queue-validation.yml` | Phase 6 CI validation: builds the pinned adrkit commit from source and asserts the `QueueReport` v1 shape via `scripts/validate-queue.sh`; also runs both network-free unit test harnesses. |
| `.github/workflows/arb-queue.yml` | Phase 6 dedicated Action workflow: creates/updates the managed ARB queue issue via `mbeacom/adrkit/packages/ci/queue@896391cc385798f7f08c5694f70acaf0342789e9`, then self-verifies the result via `scripts/verify-managed-queue-issue.sh`. |
| `.github/workflows/arb-queue-fail-closed.yml` | Phase 6 **fail-closed** Action workflow: dispatches the same pinned queue Action against a deliberately invalid `dir` input, asserts the step failed before any write, and mechanically proves zero issue mutation via before/after snapshots. See "Fail-closed evidence" below. |
| `scripts/validate-queue.sh` | Local/CI script: clones adrkit at the pinned commit, builds it with Bun 1.3.14, runs `adr queue`, and asserts dogfood expectations. |
| `scripts/assert-queue-report.ts` | QueueReport v1 assertions used by `validate-queue.sh`. |
| `scripts/verify-managed-queue-issue.sh` | CI-only script (needs `GH_TOKEN`): fetches the issue reported by the `arb-queue.yml` Action step's `issue-number` output, exhaustively re-discovers the managed-issue marker across OPEN+CLOSED issues to rule out duplicates, and delegates content checks to `assert-managed-issue-body.sh`. |
| `scripts/assert-managed-issue-body.sh` | Pure, network-free assertions against a single issue JSON document (marker position, title, state, tier labels, `0015` full-quorum approvals, absence of a Corpus Findings section). Used by both `verify-managed-queue-issue.sh` (real data) and `test-assert-managed-issue-body.sh` (fixtures). |
| `scripts/test-assert-managed-issue-body.sh` + `scripts/fixtures/{good,bad-*}.json` | Local/CI unit test harness for `assert-managed-issue-body.sh`: one valid fixture and ten fixtures that each violate exactly one invariant, with no GitHub API access required. |
| `scripts/snapshot-issues.sh` | CI-only script (needs `GH_TOKEN`): snapshots every issue (OPEN+CLOSED, excluding pull requests) as `{number, state, title, updatedAt, bodySha256}`. Run once before and once after the fail-closed Action dispatch. |
| `scripts/assert-no-issue-mutation.sh` | Pure, network-free comparison of two snapshots produced by `snapshot-issues.sh`; fails unless they are byte-for-byte identical after canonicalization. Used by both `arb-queue-fail-closed.yml` (real data) and `test-assert-no-issue-mutation.sh` (fixtures). |
| `scripts/test-assert-no-issue-mutation.sh` + `scripts/fixtures/mutation-*.json` | Local/CI unit test harness for `assert-no-issue-mutation.sh`: an identical (reordered) pair that must pass, and four pairs that each violate exactly one invariant (body changed, state changed, issue added, issue removed), with no GitHub API access required. |

## The Phase 6 ARB queue corpus

`docs/adr/0013`–`0015` are schema-valid `proposed` records, one per routing
tier:

| ID | Tier | Reversibility | Deterministic SLA state (as of `2026-07-21`) | Notes |
|----|------|----------------|-----------------------------------------------|-------|
| `0013` | `auto` | `two-way-door` | `within-sla` | Auto tier requires `two-way-door` (or `unknown`) reversibility — `one-way-door` + `auto` is a schema-level corpus error (`one-way-door-disallows-auto`) and is deliberately avoided here. |
| `0014` | `async` | `two-way-door` | `overdue` (fixed `reviewBy: 2026-06-01`) | Carries **both** an approval (`1` of quorum `2`) and an unresolved objection — exercises the combined approvals+objections queue rendering. |
| `0015` | `arb` | `one-way-door` | `due` (`queuedAt: 2026-07-10` + `slaDays: 11` = `2026-07-21`) | Quorum of `3`, all three approvals recorded (quorum met); `status` remains `proposed` pending a separate decision/status PR. `arb` tier permits `one-way-door`. |

All three fixed dates (`reviewBy: 2026-06-01` on `0014`, and the `queuedAt`/`slaDays`
combination on `0015` that resolves to `2026-07-21`) are hardcoded, not
computed from the current date. Re-running the validation with
`--as-of 2026-07-21` reproduces byte-identical `overdue`/`due` states forever,
regardless of when the script is actually executed.

## Running the validation locally or in CI

```bash
./scripts/validate-queue.sh
```

This script:

1. Clones `mbeacom/adrkit` and checks out the pinned commit
   `896391cc385798f7f08c5694f70acaf0342789e9` into a temporary directory
   (never a branch or tag).
2. Installs dependencies with `bun install --frozen-lockfile` using
   **Bun 1.3.14**.
3. Builds the workspace with `bun run build`.
4. Runs:
   ```bash
   adr queue --dir docs/adr --as-of 2026-07-21 --format json
   ```
5. Asserts the `QueueReport` v1 shape and dogfood expectations via
   `scripts/assert-queue-report.ts`:
   - `version === "1"`
   - zero corpus findings (fully schema-valid corpus)
   - at least 3 proposed items
   - all three tiers (`auto`, `async`, `arb`) represented
   - at least one `overdue` item and at least one `due` item
   - at least one item with both approvals and objections
   - every item has at least one routing target (decider)
6. Prints the Markdown rendering and `adr lint` output for human review.

No generated report is committed to this repository — the temporary working
directory (clone, build output, JSON report) is deleted on exit. The CI
workflow [`queue-validation.yml`](.github/workflows/queue-validation.yml) runs
the same script on every pull request, on push to `main`, and on
`workflow_dispatch`, so the report is reviewable in the job log without
polluting the corpus with generated artifacts.

## The managed queue issue (`arb-queue.yml`)

[`arb-queue.yml`](.github/workflows/arb-queue.yml) is a manually-triggered
(`workflow_dispatch`) workflow with two steps:

1. `id: queue` runs the packaged
   `mbeacom/adrkit/packages/ci/queue@896391cc385798f7f08c5694f70acaf0342789e9`
   Action against `docs/adr`, producing an `issue-number` output.
2. A verification step runs `scripts/verify-managed-queue-issue.sh` with
   `GH_TOKEN: ${{ github.token }}` and
   `ISSUE_NUMBER: ${{ steps.queue.outputs.issue-number }}`, so every dispatch
   checks its own output rather than only trusting that the Action exited 0.

The job requires only `contents: read` (for checkout) and `issues: write` —
no personal access token or repository secret, and `GH_TOKEN` is scoped to
the verification step only (it is not set at the job or workflow level).

Expected behavior on each run:

- The Action searches all open **and** closed issues for exactly one whose
  body's first line is the marker `<!-- adrkit-managed-queue-issue -->`.
- **First run**: no managed issue exists yet, so the Action creates a new
  issue titled **"ADR ARB Queue"** with the marker as the first line of the
  body, followed by the rendered Markdown queue report (currently 3 items:
  `0013` auto, `0014` async, `0015` arb — see the corpus table above for
  their data-driven facts; the exact SLA state per item is date-dependent
  since this workflow always uses the default `--as-of`, today).
- **Subsequent runs**: the Action finds the one managed issue by marker and
  updates its body in place (reopening it first, atomically, if it was
  closed). The issue number and title are stable across runs; only the body
  content changes to reflect the current queue state.
- The run fails (non-zero exit) only if the corpus contains schema/error
  findings, if there is a title conflict with an unmanaged issue also titled
  "ADR ARB Queue", or if more than one issue carries the marker. None of
  these conditions exist in this repository's corpus today (0 corpus
  findings, as validated by `scripts/validate-queue.sh`).

This workflow is **not** run automatically on every push — it is
`workflow_dispatch`-only, so triggering it (and observing the resulting
issue) is an explicit, auditable action taken by a repository maintainer.

### Self-verification

The `Verify managed queue issue` step makes every dispatch check its own
result rather than relying solely on the Action's own exit code. Using only
`${{ github.token }}`, `scripts/verify-managed-queue-issue.sh`:

1. Confirms the Action's `issue-number` output is a positive integer.
2. Fetches that issue via `gh api` and confirms it is `open` and titled
   exactly `ADR ARB Queue`.
3. Confirms the exact first line of the body is the marker
   `<!-- adrkit-managed-queue-issue -->`.
4. Confirms the body's overview table has a row for each of `0013`, `0014`,
   `0015`, each showing its fixed (date-independent) tier label, a
   recognized `SlaState` enum value, and — specifically for `0015` — the
   `3/3` full-quorum approvals recorded in this corpus. It also confirms
   there is no `## Corpus Findings` section and the summary line reports
   `0 corpus finding(s)`.
5. Independently re-runs the exhaustive marker-discovery algorithm across
   **all** OPEN and CLOSED issues (paginated, pull requests excluded) and
   asserts exactly one issue carries the marker, and that its number equals
   the Action's `issue-number` output — catching duplicate-managed-issue
   regressions that the Action's own single-run exit code could miss.
6. Prints the issue number, a SHA-256 digest of the body, and its
   `updatedAt` timestamp to the job log as reviewable evidence — without
   ever printing, interpolating, or otherwise leaking the token itself.

The content assertions (step 4) are implemented in the pure, network-free
`scripts/assert-managed-issue-body.sh`, which takes a single issue JSON
document and never calls the GitHub API. That separation lets the same
assertion logic run in two contexts:

- **Against real data** — `scripts/verify-managed-queue-issue.sh` calls it
  with the issue fetched from `gh api` (used in CI).
- **Against fixtures** — `scripts/test-assert-managed-issue-body.sh` calls
  it with `scripts/fixtures/good.json` (must pass) and ten
  `scripts/fixtures/bad-*.json` files, each deliberately violating exactly
  one invariant (closed state, wrong title, non-integer issue number,
  marker not on the first line, marker missing, a missing corpus item, an
  unexpected tier label, partial approvals, an unrecognized SLA state, or a
  present Corpus Findings section) and expected to fail. Run it locally or
  in CI with no token and no network:

  ```bash
  ./scripts/test-assert-managed-issue-body.sh
  ```

  This runs automatically in [`queue-validation.yml`](.github/workflows/queue-validation.yml)
  on every pull request, push to `main`, and `workflow_dispatch`.

As with everything else in this repository, `verify-managed-queue-issue.sh`
is technical, owner-run evidence that the queue kernel/CLI/Action behave
correctly — it is not, and does not claim to be, `specs/007-arb-queue`
SC-004/T048 evidence. See the status boundary above.

## Fail-closed evidence (invalid input, no write)

Every other workflow in this repository exercises the queue Action against a
**valid** corpus. This section is the missing complement: proof that the
real, packaged, pinned `mbeacom/adrkit/packages/ci/queue` Action **fails
closed** on a deterministic invalid input — a real consumer-facing GitHub
Action run, not a local script or fixture-only CI check — and that the
failure happens strictly before any GitHub write.

### Why a bad `dir` input, specifically

Reading adrkit's own source at the pinned commit
(`packages/ci/src/queue-action-entrypoint.ts`) shows two very different
failure boundaries:

- **Corpus *content* errors** (e.g. a malformed ADR's frontmatter) are
  collected as `Finding`s, not thrown. `publishQueueReport` in
  `packages/ci/src/queue-issue.ts` **writes the managed issue first, then
  fails** if there are error-severity findings ("The write always happens
  first so the managed issue reflects the current corpus health."). This is
  the `arb-queue.yml` failure path described in its own docs above — it is
  a real failure mode, but it is not a *no-write* failure mode, so it
  cannot serve as fail-closed-with-zero-writes evidence.
- **Corpus *load* errors** — the `dir` input cannot even be read as a
  directory — are thrown by `expandRecordInputs`/`discoverAdrFiles` and
  caught by the entrypoint's outermost `try`/`catch`, which calls
  `core.setFailed(...)` and returns **before `getOctokit` is ever
  constructed**: "A corpus-load failure fails the run BEFORE any GitHub
  client is constructed." No Octokit client means no possible GitHub API
  call of any kind, by construction — not just by convention.

[`fixtures/fail-closed-invalid-corpus-dir`](fixtures/fail-closed-invalid-corpus-dir)
is a plain regular **file**, not a directory. Passing its path as the
Action's `dir` input makes Node's `readdir()` throw `ENOTDIR` synchronously
inside `lintCorpus`, hitting exactly that first boundary. This was verified
directly against the pinned commit's compiled output before wiring up the
workflow:

```
$ env INPUT_DIR="/tmp/fail-closed-test/fixture-file" INPUT_TOKEN="fake-token-not-used" \
    GITHUB_REPOSITORY="octocat/hello-world" GITHUB_WORKSPACE="$(pwd)" \
    node packages/ci/dist/queue-action.js; echo "EXIT CODE: $?"
::error::adrkit queue: could not load the ADR corpus at '/tmp/fail-closed-test/fixture-file': ENOTDIR: not a directory, scandir '/tmp/fail-closed-test/fixture-file'
EXIT CODE: 1
```

The Action exits non-zero immediately (no network round trip's worth of
latency) with a message tied precisely to the corpus-load `catch` block,
confirming the failure occurs at that boundary and not, e.g., from an
auth/network error further down.

### The workflow: `arb-queue-fail-closed.yml`

[`arb-queue-fail-closed.yml`](.github/workflows/arb-queue-fail-closed.yml)
is a manually-triggered (`workflow_dispatch`) workflow, using only the
default `${{ github.token }}` (no PAT, no repository secret) with the same
least-privilege permissions as `arb-queue.yml` (`contents: read`,
`issues: write` — `issues: write` is granted so that if the Action ever
*did* reach the point of attempting a write, it would not be blocked by a
missing scope; that would make any observed failure ambiguous between
"invalid input" and "insufficient permission"):

1. **Snapshot before** — `scripts/snapshot-issues.sh` records every issue in
   the repository (OPEN + CLOSED, pull requests excluded) as
   `{number, state, title, updatedAt, bodySha256}`.
2. **Run the Action** (`continue-on-error: true`) against
   `dir: fixtures/fail-closed-invalid-corpus-dir` — the same pinned
   `mbeacom/adrkit/packages/ci/queue@896391cc385798f7f08c5694f70acaf0342789e9`
   used by `arb-queue.yml`, pointed at the invalid fixture instead of
   `docs/adr`.
3. **Snapshot after** — the same script, run again.
4. **Assert the step failed as expected** — the workflow step itself fails
   unless `steps.queue.outcome == 'failure'` (so this workflow only reports
   success when the Action's failure actually occurred; if the Action were
   ever fixed to no longer reject this input, this workflow would start
   failing rather than silently passing) — and additionally asserts the
   Action produced **no** `issue-number` output at all.
5. **Assert zero mutation** — `scripts/assert-no-issue-mutation.sh` compares
   the before/after snapshots and fails unless every issue's
   number/state/title/updatedAt/bodySha256 is byte-for-byte identical (not
   merely "the count didn't change"). This is deliberately scoped over
   **all** issues in the repository, not only the known managed queue issue
   (`#3` as of this writing), so it also rules out an unrelated issue being
   created, closed, reopened, or edited.
6. Both sanitized snapshots (no raw secrets/tokens; the body is a SHA-256
   digest, never the literal text) are uploaded as a workflow artifact for
   durable, reviewable evidence.

Both new scripts have a pure, network-free local/CI unit test harness with
synthetic fixtures — `scripts/test-assert-no-issue-mutation.sh` against
`scripts/fixtures/mutation-*.json` — run automatically in
[`queue-validation.yml`](.github/workflows/queue-validation.yml) alongside
the existing `test-assert-managed-issue-body.sh`.

### Expected vs. observed (most recent live dispatch)

| Field | Expected | Observed |
|-------|----------|----------|
| Pinned adrkit ref | `896391cc385798f7f08c5694f70acaf0342789e9` | `896391cc385798f7f08c5694f70acaf0342789e9` (confirmed via the run's own action-download log line: `Download action repository 'mbeacom/adrkit@896391cc385798f7f08c5694f70acaf0342789e9'`) |
| Fixture | `fixtures/fail-closed-invalid-corpus-dir` (plain file, not a directory) | (unchanged) |
| `queue` step outcome | `failure` | `failure` |
| `queue` step `issue-number` output | (empty/unset) | (empty/unset) |
| Issue mutation | zero (before/after snapshot hashes equal) | zero — hashes equal, issue count unchanged at 1 |
| Workflow conclusion | `success` (workflow succeeds *because* the expected failure + zero-write proof both held) | `success` |

**Live run:** `30159430259` —
<https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/30159430259>
— branch `mbeacom-supreme-disco` (PR #7, the repin to `896391cc`) —
conclusion: `success`. The `queue` step's own error output was:

```
##[error]adrkit queue: could not load the ADR corpus at 'fixtures/fail-closed-invalid-corpus-dir': ENOTDIR: not a directory, scandir '/home/runner/work/adrkit-t018-dogfood/adrkit-t018-dogfood/fixtures/fail-closed-invalid-corpus-dir'
```

Before/after snapshot SHA-256 (canonicalized):
`a6eef1edbd86f1acb441af6be587baf51ea25259ae2b4e776088b502db2a57b7` for
both before and after (equal ⇒ zero mutation across `1` issue(s), the
same `#3` managed queue issue, `updatedAt` unchanged).

The error message is byte-identical to the one produced under the previous
pin, which is the expected result: `packages/ci/` is unchanged between
`efef89b5` and `896391cc`, so the fail-closed boundary is literally the same
compiled code.

**Previous dispatch (superseded, retained for provenance):** run
`29920390292` —
<https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/29920390292>
— commit `2d7f6063b1d0d93f453138cf24a2bcd81aa287a6` (the `main` merge commit
for PR #6) — conclusion: `success`, using the older pin
`efef89b5d747ca175a1947f1ce2f4296dab54fa3`. Its before/after snapshot
SHA-256 was `9b15bda8a202ec4bb9539f920ceb47f96b2844a4b46232c2a3a4465e579802d9`
and its uploaded evidence artifact SHA-256 was
`15e3c042fbda394a579de560756d51ea1ca075031df5d1b458ffd2f8006cb966`.
Runner: `ubuntu-24.04` (image `20260714.240.1`, Actions runner `2.336.0`);
`GITHUB_TOKEN` permissions were exactly `contents: read`, `issues: write`,
`metadata: read` with secret source `Actions` (no PAT or
repository/organization secret involved). Action versions:
`actions/checkout@v4`, `actions/upload-artifact@v4`. The snapshot digest
differs from the current run only because issue `#3`'s body (and therefore
its `bodySha256`) legitimately changed in between, when `arb-queue.yml` was
re-dispatched and updated the managed issue.

**Limitations:** this demonstrates the Action's own fail-closed behavior on
one deterministic invalid-input class (an unreadable `dir`), using only the
default `GITHUB_TOKEN`, in this maintainer-owned repository. Like the rest
of this repository (see the status boundary above), it is **not**
`specs/007-arb-queue` SC-004/T048 evidence — it does not involve an
independent, non-maintainer-owned team — and it does not attempt to
enumerate every possible invalid-input class the Action might encounter.

## Full CLI + MCP surface dogfood (2026-07-25)

Everything above exercises the **ARB queue** slice of adrkit. This section
records a one-off, wider dogfood run performed at the time of the
`896391cc` repin, covering every `adr` subcommand and the `@adrkit/mcp`
server. It is a point-in-time report, not a CI-enforced gate — only the
queue checks above run automatically.

Method: adrkit was cloned at `896391cc385798f7f08c5694f70acaf0342789e9`,
built with Bun 1.3.14, and driven against (a) this repository's real
15-record corpus and (b) purpose-built synthetic corpora under `/tmp` so
the governed corpus here was never mutated.

### What works

| Surface | Result |
|---|---|
| `adr lint` | 15 records, 0 errors, 0 warnings, exit 0. |
| `adr graph` | `--format dot` and `--format json` both render 15 nodes. This corpus declares no `supersedes`/`relatesTo` links, so **edge rendering is not covered** by this run. |
| `adr explain` | Correctly resolves overlapping + nested `affects`: `src/payments/api/handler.ts` returns `0001` (`src/payments/**`), `0002` (`src/payments/api/**`) and `0014`. Ungoverned paths report cleanly. |
| `adr check` | Same resolution as `explain`, plus changed-record handling; `--json` emits `ok`, `changedFiles`, `governedBy`, `changedRecords`, `findings`. |
| `adr new` | Scaffolds a discoverable, lint-clean record with an opinionated template. IDs increment monotonically and a repeated title is disambiguated by ID prefix rather than overwriting. |
| `adr migrate --from madr` | One-way and non-destructive; `--dry-run` leaves files byte-identical; re-running reports `unchanged` (idempotent). But see defect 2 below. |
| `adr evaluate` | All eleven Pass 0 rules run offline. `0015` (`one-way-door`) yields `routing: escalate [one-way-door]`; `0014` yields `expiry-sane: fail (info) — expiry-sane.past-or-equal`, consistent with the queue's `overdue` state for the same record. Absent snapshot backing reports `inert`, never a fabricated pass/fail. |
| `adr queue` | Covered in detail above. |
| `@adrkit/mcp` | All four tools (`search_decisions`, `get_decision`, `get_decision_context`, `list_superseded`) exercised over stdio JSON-RPC across 22 calls — happy paths, not-found, pagination cursors, and invalid input. No functional defects. Path arguments reject absolute and `..` paths before touching the filesystem. Read-only/local-only boundary held: no write/network/`child_process` imports in the server or the core functions it calls; `lsof` on the running process showed zero network sockets; corpus mtimes and `git status` were unchanged after the run. |
| Determinism | `adr queue --format json` and `adr evaluate --json` each produced a single distinct SHA-256 across three consecutive runs. |

### Defects found

These are adrkit issues, not issues with this repository. They are recorded
here because this repository is where they were observed.

**1. `adr check` / `adr explain` / the PR-governance Action treat every
status as governing.** A `rejected`, `superseded`, or `deprecated` record
that matches a changed path is reported as governing that change, with no
status shown and no way to filter. Reproduced on a synthetic corpus with one
record per status, all matching `src/api/**`; feeding the resulting
`CheckOutcome` through the shipped Action's own exported `renderComment`
produces a PR comment listing "Rejected record", "Superseded record" and
"Deprecated record" under **Decisions governing this change**, formatted
identically to the accepted one. The `governedBy` entries expose only
`recordId`, `title`, and `firedMatchers`, so a downstream consumer cannot
distinguish them either.

This is an internal inconsistency rather than a deliberate design stance:
the MCP server's `get_decision_context` — the same conceptual operation —
*is* status-aware, returning `status` on every entry and bucketing
`accepted` into `governing`, `draft`/`proposed` into `activeProposals`, and
`rejected`/`superseded`/`deprecated` into `history`.

**2. `adr migrate --from madr` only reads `status` from YAML frontmatter.**
Controlled three-way comparison, one MADR dialect each, all declaring
`accepted`:

| Source form | Imported status |
|---|---|
| MADR 3.x YAML frontmatter (`status: accepted`) | `accepted` ✅ |
| MADR 2.x header bullet (`* Status: accepted`) | `proposed` ⚠️ |
| Nygard section (`## Status` / `accepted`) | `proposed` ⚠️ |

The two failures emit only `warn import-status-unrecognized ... "MADR status
is missing"` and the command still exits 0. Migrating a real MADR 2.x corpus
would therefore silently relabel every accepted decision as `proposed` —
which, combined with `adr queue`, would flood the ARB queue with items that
were already decided years ago. The same root cause writes `date:
1970-01-01` when the source date is only present as a `* Date:` bullet.

**3. `adr migrate` can write records the rest of the toolchain cannot
see.** Migration writes in place under the original filename, but corpus
discovery requires `RECORD_FILE_PATTERN = /^[0-9]{4,}-.+\.md$/`. Migrating
`docs/adr/b-bullet.md` produces a valid adrkit record that `adr lint` then
reports as `checked 0 records`, exit 0, with no warning — invisible to
`lint`, `graph`, `check`, `explain`, and `queue`. Copying the identical file
to `0002-b-bullet.md` makes it `checked 1 records`, isolating the filename
as the sole cause. Migration already assigns each record an `id`, so it has
the information needed to name the file correctly.

**4. `adr --help`, `adr --version`, and `adr help` are not recognized.** All
three print `Unknown command` and exit 2. Usage text is printed, so the
command is discoverable, but `--help` exiting non-zero breaks the common
convention and any wrapper that shells out to it.

### Scope and limitations

This is maintainer-run technical dogfooding on one machine (macOS, Bun
1.3.14, Node 22) plus the four live GitHub Actions runs linked above. It is
**not** `specs/007-arb-queue` SC-004 / T048 evidence — see the status
boundary at the top of this document. Graph edge rendering, the adapters
workspace, and Passes 1–3 of the evaluator were not exercised.
