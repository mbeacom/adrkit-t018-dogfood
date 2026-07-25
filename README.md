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
  the time of the `896391cc` repin. It found four defects, all of which were
  filed upstream and have since been fixed. See
  [Full CLI + MCP surface dogfood](#full-cli--mcp-surface-dogfood-2026-07-25)
  for what works and the resolved defect record.
- **Re-validation and repin to `bbe63e01` (2026-07-25)** — the four defects
  above were re-checked from the outside against the fixed commit before this
  repository was repinned to it. See
  [Re-validation against `bbe63e01`](#re-validation-against-bbe63e01-2026-07-25).

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
bbe63e017274f173dbb40eeaceccd17df346b32b
```

This is the tip of adrkit `main` as of 2026-07-25: the squash-merge of PR
[mbeacom/adrkit#45](https://github.com/mbeacom/adrkit/pull/45), which closes
the four defects ([#39](https://github.com/mbeacom/adrkit/issues/39)–[#42](https://github.com/mbeacom/adrkit/issues/42))
that this repository's own dogfood run found. It supersedes the previous pin
`896391cc385798f7f08c5694f70acaf0342789e9`, which in turn superseded
`efef89b5d747ca175a1947f1ce2f4296dab54fa3` (the `specs/007-arb-queue` merge
commit).

**Unlike the previous repin, this one does change code under test.** The
`efef89b5` → `896391cc` repin could be justified by `git diff … --
packages/ci/` being empty; that justification does **not** carry over here.
Observed directly in a clone of adrkit at both commits:

```console
$ git diff --name-status 896391cc..bbe63e01 -- packages/ci/
M	packages/ci/dist/index.js
M	packages/ci/dist/queue-action.js
M	packages/ci/src/comment.ts
M	packages/ci/test/action.test.ts
M	packages/ci/test/comment-render.test.ts
M	packages/ci/test/selectivity.test.ts
```

Both committed Action bundles were regenerated and the PR-comment renderer
changed. `action.yml` is unchanged (`git diff … -- 'packages/ci/**/action.yml'`
is empty), so the Action's input/output contract is the same. The range is a
single commit (`bbe63e0 fix: close the four dogfood defects (#39, #40, #41,
#42) (#45)`).

What that means for the evidence in this document, re-verified rather than
assumed:

| Surface | Across `896391cc` → `bbe63e01` |
|---|---|
| `adr queue --format json` / `--format markdown` | **byte-identical** (SHA-256 `716e21b7…` / `fbcd4d5f…`), corpus fingerprint unchanged at `1664c5af…` |
| `adr lint --dir docs/adr` | **byte-identical** — still `checked 15 records, 0 errors, 0 warnings` |
| `adr graph --format json` | **byte-identical** |
| `adr check` / `adr explain` | **changed, deliberately** — see [status-aware governance](#status-aware-governance-changes-what-check-and-explain-report) below |
| queue Action fail-closed boundary | **re-probed against the regenerated bundle**, not inferred — see [Fail-closed evidence](#fail-closed-evidence-invalid-input-no-write) |

Every assertion in `scripts/assert-queue-report.ts` reproduces identically
under the new pin, and the `--as-of 2026-07-21` `overdue`/`due` states did not
move.

This is a full 40-character commit SHA, never a moving branch or tag. Do not
change any pin in this repository to `@main`, `@v0`, or any other ref without
re-running the full validation procedure below and updating this document.
(The pre-existing Phase 3 `packages/ci@main` reference in
[`.github/workflows/adr.yml`](.github/workflows/adr.yml) predates this pinning
requirement and is left untouched from Phase 3; it governs PRs against this
repository, not the ARB queue. Because it is unpinned, it picks up the
status-aware comment renderer from `bbe63e01` automatically — see
[Live governance comment](#live-governance-comment-status-aware) below.)

### Status-aware governance changes what `check` and `explain` report

This is the one intentional behavior change this repin introduces against this
repository's own corpus (`0001`–`0012` `accepted`, `0013`–`0015` `proposed`).
Under `896391cc`, `adr explain src/payments/api/handler.ts` reported `0001`,
`0002` and `0014` alike, with no status shown. Under `bbe63e01`:

```console
$ adr explain src/payments/api/handler.ts --dir docs/adr
Decisions governing src/payments/api/handler.ts:
  0001  [accepted] Govern the payments source boundary
    via path: src/payments/**
  0002  [accepted] Govern the payments API boundary
    via path: src/payments/api/**
Active proposals (not yet binding):
  0014  [proposed] Introduce asynchronous cache invalidation for payments settlement events
    via path: src/payments/**
```

`0014` is `proposed`, so it is correctly no longer reported as governing.
`adr check` makes the same split and its summary line now reads
`checked: 2 governing, 1 active proposals, 0 historical, …` where it
previously read `checked: 3 governing, …`.

## Repository layout

| Path | Purpose |
|------|---------|
| `docs/adr/0001`–`0012` | Phase 3 T018 corpus: `accepted` records governing `src/payments/**` and other component boundaries. Preserved as-is. |
| `docs/adr/0013`–`0015` | Phase 6 ARB queue corpus: `proposed` records exercising the `auto`, `async`, and `arb` routing tiers with deterministic SLA state, approvals, objections, and quorum. |
| `src/payments/api/handler.ts` | Governed source subset from Phase 3 T018, exercised by the `adr.yml` PR-governance workflow. |
| `fixtures/fail-closed-invalid-corpus-dir` | Checked-in invalid-input fixture: a plain **file** (not a directory) used as the `dir` input to the queue Action in `arb-queue-fail-closed.yml`, to deterministically trigger adrkit's corpus-load `ENOTDIR` failure before any GitHub write. |
| `.github/workflows/adr.yml` | Phase 3 T018 workflow: PR-time governance via `mbeacom/adrkit/packages/ci@main`. Deliberately unpinned (see "Pinned adrkit commit"), so as of `bbe63e01` it renders the **status-aware** PR comment — only `accepted` records appear under "Decisions governing this change", with active proposals and history in their own sections. |
| `.github/workflows/queue-validation.yml` | Phase 6 CI validation: builds the pinned adrkit commit from source and asserts the `QueueReport` v1 shape via `scripts/validate-queue.sh`; also runs both network-free unit test harnesses. |
| `.github/workflows/arb-queue.yml` | Phase 6 dedicated Action workflow: creates/updates the managed ARB queue issue via `mbeacom/adrkit/packages/ci/queue@bbe63e017274f173dbb40eeaceccd17df346b32b`, then self-verifies the result via `scripts/verify-managed-queue-issue.sh`. |
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
   `bbe63e017274f173dbb40eeaceccd17df346b32b` into a temporary directory
   (never a branch or tag).
2. Installs dependencies with `bun install --frozen-lockfile` using
   **Bun 1.3.14**.
3. Builds the workspace with `bun run build`.
4. Records the binary's self-reported version (`adr --version`, currently
   `0.2.0`) alongside the pinned SHA, and fails if it exits non-zero or
   prints nothing. Before `bbe63e01` this was impossible — `adr --version`
   was an unknown command that exited 2
   ([mbeacom/adrkit#42](https://github.com/mbeacom/adrkit/issues/42)) — so
   the commit SHA was the only provenance available. This check deliberately
   does **not** assert the literal string `0.2.0`: a legitimate upstream
   version bump should not break this repository's CI, whereas losing
   `--version` entirely should.
5. Runs:
   ```bash
   adr queue --dir docs/adr --as-of 2026-07-21 --format json
   ```
6. Asserts the `QueueReport` v1 shape and dogfood expectations via
   `scripts/assert-queue-report.ts`:
   - `version === "1"`
   - zero corpus findings (fully schema-valid corpus)
   - at least 3 proposed items
   - all three tiers (`auto`, `async`, `arb`) represented
   - at least one `overdue` item and at least one `due` item
   - at least one item with both approvals and objections
   - every item has at least one routing target (decider)
7. Prints the Markdown rendering and `adr lint` output for human review.

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
   `mbeacom/adrkit/packages/ci/queue@bbe63e017274f173dbb40eeaceccd17df346b32b`
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
inside `lintCorpus`, hitting exactly that first boundary.

Because `bbe63e01` regenerated `packages/ci/dist/queue-action.js`, this
boundary was **re-probed directly against the new bundle** rather than
carried forward from the previous pin. Running the old and new committed
bundles side by side produces byte-identical output:

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
auth/network error further down. The `896391cc` and `bbe63e01` bundles were
run one after the other against the same fixture and produced the identical
message and exit code above, so the regenerated bundle preserves the
boundary. That is an observation, not an inference from an unchanged file.

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
   `mbeacom/adrkit/packages/ci/queue@bbe63e017274f173dbb40eeaceccd17df346b32b`
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

> **Note on currency.** The most recent *live* dispatch below ran under the
> previous pin `896391cc`. `arb-queue-fail-closed.yml` is
> `workflow_dispatch`-only, and the workflow file on `main` must carry the new
> pin before a dispatch can exercise it, so a live `bbe63e01` dispatch is a
> follow-up to this repin rather than a precondition of it. What *has* been
> re-verified for `bbe63e01` is the boundary itself, probed locally against
> the regenerated `dist/queue-action.js` bundle (see above). Treat the live
> table below as evidence for the `896391cc` bundle and the local probe as
> evidence for the `bbe63e01` bundle, until this section is refreshed with a
> new run id.

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
pin, which was the expected result at the time: `packages/ci/` is unchanged
between `efef89b5` and `896391cc`, so the fail-closed boundary was literally
the same compiled code. **That argument no longer applies to the current
pin** — `bbe63e01` regenerated `dist/queue-action.js` — which is precisely
why the boundary was re-probed against the new bundle directly rather than
assumed. The message and exit code turned out to be identical anyway, but
that is now a measured result rather than a corollary of an unchanged file.

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
| `adr lint` | 15 records, 0 errors, 0 warnings, exit 0. **Still true at `bbe63e01`** — byte-identical output, despite the new `corpus-file-skipped` warning added by [#41](https://github.com/mbeacom/adrkit/issues/41). |
| `adr graph` | `--format dot` and `--format json` both render 15 nodes. This corpus declares no `supersedes`/`relatesTo` links, so **edge rendering is not covered** by this run. `--format json` is byte-identical at `bbe63e01`. |
| `adr explain` | Correctly resolves overlapping + nested `affects`. Ungoverned paths report cleanly. **Output changed at `bbe63e01`**: `src/payments/api/handler.ts` now reports `0001` and `0002` as governing and `0014` as an active proposal, rather than all three alike — see [Status-aware governance](#status-aware-governance-changes-what-check-and-explain-report). |
| `adr check` | Same resolution as `explain`, plus changed-record handling. At `bbe63e01`, `--json` emits `ok`, `changedFiles`, `changedRecords`, `findings`, the retained `governedBy` (now the full union, each entry carrying `status` and `bucket`), and the three new status buckets `governing`, `activeProposals`, and `history`. |
| `adr new` | Scaffolds a discoverable, lint-clean record with an opinionated template. IDs increment monotonically and a repeated title is disambiguated by ID prefix rather than overwriting. |
| `adr migrate --from madr` | One-way and non-destructive; `--dry-run` leaves files byte-identical; re-running reports `unchanged` (idempotent). At `bbe63e01` it also parses MADR 2.x and Nygard dialects, warns when a written record would be undiscoverable, and offers opt-in `--rename` — see the resolved defects 2 and 3 below. |
| `adr evaluate` | All eleven Pass 0 rules run offline. `0015` (`one-way-door`) yields `routing: escalate [one-way-door]`; `0014` yields `expiry-sane: fail (info) — expiry-sane.past-or-equal`, consistent with the queue's `overdue` state for the same record. Absent snapshot backing reports `inert`, never a fabricated pass/fail. |
| `adr queue` | Covered in detail above. Byte-identical at `bbe63e01`. |
| `adr --help` / `--version` | Added at `bbe63e01` (resolved defect 4). `adr --version` prints `0.2.0` and is now recorded by `scripts/validate-queue.sh` on every run. |
| `@adrkit/mcp` | **Original `896391cc` run only, not re-covered at `bbe63e01` except as noted.** All four tools (`search_decisions`, `get_decision`, `get_decision_context`, `list_superseded`) exercised over stdio JSON-RPC across 22 calls — happy paths, not-found, pagination cursors, and invalid input. No functional defects. Path arguments reject absolute and `..` paths before touching the filesystem. Read-only/local-only boundary held: no write/network/`child_process` imports in the server or the core functions it calls; `lsof` on the running process showed zero network sockets; corpus mtimes and `git status` were unchanged after the run. At `bbe63e01`, **only `get_decision_context` was re-driven** — see [MCP re-coverage](#mcp-re-coverage-get_decision_context-only). |
| Determinism | `adr queue --format json` and `adr evaluate --json` each produced a single distinct SHA-256 across three consecutive runs. |

### Defects found — all four now fixed

These were adrkit issues, not issues with this repository. They are retained
here as the evidence trail: this repository is where they were observed, each
was filed upstream, and each was subsequently fixed. **All four are closed as
completed and shipped in `bbe63e01`** (PR
[mbeacom/adrkit#45](https://github.com/mbeacom/adrkit/pull/45)).

Each reproduction below is preserved as originally written, followed by what
was re-observed against `bbe63e01` on 2026-07-25. The re-verification drove the
real `adr` binary built from source at the new pin, on the same synthetic
`/tmp` corpora, exactly as the original run did — it is not a reading of the
upstream changelog.

| # | Upstream issue | Summary | Status |
|---|---|---|---|
| 1 | [mbeacom/adrkit#39](https://github.com/mbeacom/adrkit/issues/39) | `check`/`explain`/CI Action report non-`accepted` records as governing | **Fixed** in `bbe63e01`; re-verified here |
| 2 | [mbeacom/adrkit#40](https://github.com/mbeacom/adrkit/issues/40) | `migrate --from madr` reads `status` only from YAML frontmatter | **Fixed** in `bbe63e01`; re-verified here |
| 3 | [mbeacom/adrkit#41](https://github.com/mbeacom/adrkit/issues/41) | `migrate` can write records discovery cannot see | **Fixed** in `bbe63e01`; re-verified here |
| 4 | [mbeacom/adrkit#42](https://github.com/mbeacom/adrkit/issues/42) | `adr --help`/`--version`/`help` unrecognized, exit 2 | **Fixed** in `bbe63e01`; re-verified here |

The re-validation run that confirmed these also filed two further findings —
[#50](https://github.com/mbeacom/adrkit/issues/50) and
[#51](https://github.com/mbeacom/adrkit/issues/51) — neither of which is a
regression from `bbe63e01`. See
[Two things this run found that are not fixed](#two-things-this-run-found-that-are-not-fixed).

**1. `adr check` / `adr explain` / the PR-governance Action treated every
status as governing.** ([#39](https://github.com/mbeacom/adrkit/issues/39) —
**fixed in `bbe63e01`**)

*As originally observed at `896391cc`:* a `rejected`, `superseded`, or
`deprecated` record that matches a changed path was reported as governing
that change, with no status shown and no way to filter. Reproduced on a
synthetic corpus with one record per status, all matching `src/api/**`;
feeding the resulting `CheckOutcome` through the shipped Action's own exported
`renderComment` produced a PR comment listing "Rejected record", "Superseded
record" and "Deprecated record" under **Decisions governing this change**,
formatted identically to the accepted one. The `governedBy` entries exposed
only `recordId`, `title`, and `firedMatchers`, so a downstream consumer could
not distinguish them either.

This was an internal inconsistency rather than a deliberate design stance:
the MCP server's `get_decision_context` — the same conceptual operation —
*was already* status-aware, returning `status` on every entry and bucketing
`accepted` into `governing`, `draft`/`proposed` into `activeProposals`, and
`rejected`/`superseded`/`deprecated` into `history`.

*Re-verified at `bbe63e01`.* The same six-status synthetic corpus was rebuilt
and driven through both pins. `adr check` now reports:

```console
$ adr check src/api/route.ts --dir docs/adr
Decisions governing this change:
  0003  [accepted] Accepted record
    via path: src/api/**
Active proposals touching this change (not yet binding):
  0001  [draft] Draft record
    via path: src/api/**
  0002  [proposed] Proposed record
    via path: src/api/**
Historical records that once covered this change (not binding):
  0004  [rejected] Rejected record
    via path: src/api/**
  0005  [superseded] Superseded record (superseded by 0003)
    via path: src/api/**
  0006  [deprecated] Deprecated record
    via path: src/api/**
checked: 1 governing, 2 active proposals, 3 historical, 0 changed records, 0 changed-record errors
```

Feeding that `CheckOutcome` through the shipped Action's exported
`renderComment` — the same method used to demonstrate the original defect —
now yields only `0003` under **Decisions governing this change**, with
draft/proposed under "Active proposals touching this change" and
rejected/superseded/deprecated under "Historical records that once covered
this change", each annotated with its status and, for `0005`, "superseded by
**0003**".

The internal inconsistency is closed from both directions: MCP's
`get_decision_context` returned the identical bucketing on *both* pins
(`governing=[0003]`, `activeProposals=[0001,0002]`,
`history=[0004,0005,0006]`), and `adr check --json` now agrees with it
exactly. `governedBy` is retained as the full union for back-compat, with
`status` and `bucket` added to each entry.

A corpus where nothing `accepted` matches was also checked, since it is a new
code path: `adr check` prints "No accepted decisions govern the changed
files." and `renderComment` renders "No **accepted** decisions govern the
changed files. Records below matched but do not bind this change." Both are
correct.

**2. `adr migrate --from madr` only read `status` from YAML frontmatter.**
([#40](https://github.com/mbeacom/adrkit/issues/40) — **fixed in
`bbe63e01`**)

*As originally observed at `896391cc`,* a controlled three-way comparison, one
MADR dialect each, all declaring `accepted`:

| Source form | Imported status at `896391cc` | Imported status at `bbe63e01` |
|---|---|---|
| MADR 3.x YAML frontmatter (`status: accepted`) | `accepted` ✅ | `accepted` ✅ |
| MADR 2.x header bullet (`* Status: accepted`) | `proposed` ⚠️ | `accepted` ✅ |
| Nygard section (`## Status` / `accepted`) | `proposed` ⚠️ | `accepted` ✅ |

The two failures emitted only `warn import-status-unrecognized ... "MADR
status is missing"` and the command still exited 0. Migrating a real MADR 2.x
corpus would therefore silently relabel every accepted decision as `proposed`
— which, combined with `adr queue`, would flood the ARB queue with items that
were already decided years ago. The same root cause wrote `date: 1970-01-01`
when the source date was only present as a `* Date:` bullet.

*Re-verified at `bbe63e01`* by re-running the identical three-file corpus
through both builds. All three dialects now import as `accepted`, and the
`import-status-unrecognized` warnings are gone. The date behavior is fixed as
described and distinguishes the two cases correctly:

- a `* Date: 2026-03-02` bullet now imports as `date: 2026-03-02` (it was
  `1970-01-01`);
- a source that genuinely declares no date anywhere still gets the
  `1970-01-01` placeholder, but now says so, via the new
  `warn import-date-missing … "MADR source declares no date; using
  '1970-01-01' as a placeholder — backfill the real decision date"`.

The `superseded by <ref>` mapping was also checked, since it is conditional:
`* Status: superseded by 0001` where `0001` resolves in the id space the run
writes imports as `status: superseded` + `supersededBy: "0001"`, whereas
`* Status: superseded by 9999` (dangling) conservatively falls back to
`proposed` with `import-status-unrecognized` rather than writing a record that
would fail the schema's "`superseded` requires `supersededBy`" rule.

**3. `adr migrate` could write records the rest of the toolchain cannot
see.** ([#41](https://github.com/mbeacom/adrkit/issues/41) — **fixed in
`bbe63e01`**)

*As originally observed at `896391cc`:* migration writes in place under the
original filename, but corpus discovery requires
`RECORD_FILE_PATTERN = /^[0-9]{4,}-.+\.md$/`. Migrating `docs/adr/b-bullet.md`
produced a valid adrkit record that `adr lint` then reported as
`checked 0 records`, exit 0, with no warning — invisible to `lint`, `graph`,
`check`, `explain`, and `queue`. Copying the identical file to
`0002-b-bullet.md` made it `checked 1 records`, isolating the filename as the
sole cause. Migration already assigns each record an `id`, so it had the
information needed to name the file correctly.

*Re-verified at `bbe63e01`* on a corpus of two misnamed top-level files plus
one nested two directories deep. In-place migration remains the default per
ADR-0008 — no file is moved unless asked — but it is no longer silent.
`migrate` now emits one `import-undiscoverable` warning per affected record,
with the message distinguishing the two causes:

```
warn import-undiscoverable 0001 path: Migrated record is not discoverable: its filename does not match <id>-<slug>.md …
warn import-undiscoverable 0003 path: Migrated record is not discoverable: it is in a subdirectory of the corpus, and discovery reads only the top level …
```

and `adr lint` no longer reports `checked 0 records, 0 errors, 0 warnings`
into the void — it reports `checked 0 records, 0 errors, 3 warnings` with a
`corpus-file-skipped` warning naming each skipped file, including the one
nested at depth two.

The new opt-in `adr migrate --from madr --rename` renames as it writes
(`a-alpha.md -> 0001-alpha-decision.md`), after which `adr lint` reports
`checked 2 records`. The nested file is deliberately *not* auto-moved by
`--rename` — renaming would not have made it discoverable — and it keeps
warning until it is moved by hand. `--rename` does not exist at `896391cc`
(exit 2, `Unknown option '--rename'`), confirming it is new.

**4. `adr --help`, `adr --version`, and `adr help` were not recognized.**
([#42](https://github.com/mbeacom/adrkit/issues/42) — **fixed in
`bbe63e01`**)

*As originally observed at `896391cc`:* all three printed `Unknown command`
and exited 2. Usage text was printed, so the command was discoverable, but
`--help` exiting non-zero breaks the common convention and any wrapper that
shells out to it.

*Re-verified at `bbe63e01`* across the full invocation matrix, on both pins:

| Invocation | `896391cc` | `bbe63e01` |
|---|---|---|
| `adr --help` | exit 2, stderr | exit 0, stdout |
| `adr -h` | exit 2, stderr | exit 0, stdout |
| `adr help` | exit 2, stderr | exit 0, stdout |
| `adr help lint` | exit 2, stderr | exit 0, stdout (per-command usage) |
| `adr help queue` | exit 2, stderr | exit 0, stdout (per-command usage) |
| `adr lint --help` | exit 2, stderr | exit 0, stdout |
| `adr queue --help` | exit 0, stdout | exit 0, stdout |
| `adr --version` | exit 2, stderr | exit 0, stdout — `0.2.0` |
| `adr -V` | exit 2, stderr | exit 0, stdout — `0.2.0` |
| `adr bogus-command` | exit 2, stderr | exit 2, stderr (unchanged, correct) |

Unknown commands still print usage to stderr and exit 2, so the fix did not
turn a real error into a silent success. `adr queue --help` already worked at
`896391cc` — the old behavior was inconsistent between subcommands, and is now
uniform.

Because `adr --version` exists, `scripts/validate-queue.sh` now records it
next to the pinned SHA on every run. Before this fix, the commit SHA was the
only provenance the harness could report.

### Scope and limitations

This is maintainer-run technical dogfooding on one machine (macOS, Bun
1.3.14, Node 22) plus the four live GitHub Actions runs linked above. It is
**not** `specs/007-arb-queue` SC-004 / T048 evidence — see the status
boundary at the top of this document. Graph edge rendering, the adapters
workspace, and Passes 1–3 of the evaluator were not exercised.

## Re-validation against `bbe63e01` (2026-07-25)

The repin from `896391cc` to `bbe63e01` was gated on re-validating this
repository against the new commit *before* changing any pin. This section
records what that run did and what it found, including the parts that are not
clean.

### Method

Both commits were cloned and built from source with Bun 1.3.14 (macOS arm64,
Node 22) into separate temporary directories, and the resulting `adr` binaries
were driven side by side against (a) this repository's real 15-record corpus,
read-only, and (b) purpose-built synthetic corpora under `/tmp` for everything
that writes. `docs/adr/**` here was never mutated. Sequence:

1. `./scripts/validate-queue.sh` was run **unmodified at the old pin** first,
   to establish a passing baseline, together with
   `scripts/test-assert-managed-issue-body.sh` and
   `scripts/test-assert-no-issue-mutation.sh`. All passed.
2. Every observable output was captured from both builds and compared by
   SHA-256.
3. Each of the four fixes was reproduced from the outside on synthetic
   corpora, driving the real binary — the same method that originally found
   them, not a reading of the upstream diff.
4. Only then were the pins changed, and `./scripts/validate-queue.sh` re-run
   end-to-end at the new pin.

### The QueueReport reproduced identically

`adr queue --dir docs/adr --as-of 2026-07-21 --format json` is byte-identical
across the two pins (SHA-256 `716e21b7…`), as is the Markdown rendering
(`fbcd4d5f…`), the corpus fingerprint (`1664c5af…`), `adr lint` output, and
`adr graph --format json`. The hardcoded `--as-of 2026-07-21` `overdue`/`due`
states did not move. Every assertion in `scripts/assert-queue-report.ts`
passes at both pins. Diffing the two full `validate-queue.sh` transcripts
leaves only build metrics (bundle sizes, module counts, timings) and the pin
and version lines themselves.

The only intentional behavior change against this corpus is `adr check` /
`adr explain`, documented under
[Status-aware governance](#status-aware-governance-changes-what-check-and-explain-report).

### MCP re-coverage (`get_decision_context` only)

MCP deserves separate treatment here because it was the one surface that was
*already correct* going into this fix. [#39](https://github.com/mbeacom/adrkit/issues/39)
was framed as "MCP is status-aware, the CLI is not", and the fix resolved that
by routing both through a shared `decisionBucketFor` in `@adrkit/core` — which
means `packages/mcp/src/tools/get-decision-context.ts` was edited in the
process. The risk is therefore asymmetric: the change could have fixed the CLI
while perturbing the surface that already worked.

It did not. `get_decision_context` was driven over stdio JSON-RPC against the
same six-status synthetic corpus used for resolved defect 1, at **both** pins:

| Pin | `governing` | `activeProposals` | `history` |
|---|---|---|---|
| `896391cc` | `0003` `[accepted]` | `0001` `[draft]`, `0002` `[proposed]` | `0004` `[rejected]`, `0005` `[superseded]`, `0006` `[deprecated]` |
| `bbe63e01` | `0003` `[accepted]` | `0001` `[draft]`, `0002` `[proposed]` | `0004` `[rejected]`, `0005` `[superseded]`, `0006` `[deprecated]` |

Identical across pins, and `adr check --json` at `bbe63e01` returns the same
three buckets with the same members. So the shared function fixed the CLI
without moving MCP, and the two surfaces now agree where they previously
diverged — which is the actual claim [#39](https://github.com/mbeacom/adrkit/issues/39)
was making.

**Scope caveat.** Only `get_decision_context` was re-driven at `bbe63e01`. The
other three tools (`search_decisions`, `get_decision`, `list_superseded`), the
22-call sweep, the path-traversal rejection checks, and the read-only /
local-only boundary evidence (`lsof`, mtimes, `git status`) are all from the
original `896391cc` run and were **not** repeated. Nothing in the `bbe63e01`
diff touches those paths, but that is an inference from the diff, not an
observation — do not read the "What works" table's `@adrkit/mcp` row as
re-verified at the current pin.

### The new warnings are not noisy against a realistic corpus

[#41](https://github.com/mbeacom/adrkit/issues/41) added a
`corpus-file-skipped` lint warning, which is the kind of change that can
regress a clean corpus into a noisy one. This was treated as a hypothesis to
falsify rather than a safe assumption — all 15 records here are top-level and
correctly named, so the warning *should* not fire, but "should" was not good
enough. Falsification attempt: `adr lint` on this repository's corpus is
byte-identical across the pins, still
`checked 15 records, 0 errors, 0 warnings`. The hypothesis held.

It was also checked against the conventions real ADR directories carry.
A corpus containing `README.md`, `template.md` and `index.md` alongside one
real record produces `checked 1 records, 0 errors, 0 warnings` at both pins:
those names are on an explicit non-record allowlist
(`readme.md`, `index.md`, `contributing.md`, `template.md`, plus
`0000-template.md`), so the warning fires on plausibly-misnamed records rather
than on every stray markdown file. `corpus-file-skipped` is `warn`, not
`error`, and `adr lint` still exits 0.

`corpus-file-skipped` also does **not** appear in `adr queue`'s
`corpusFindings`, so it cannot cause the managed-issue Action to render a
Corpus Findings section or to fail a run — this repository's
`scripts/assert-managed-issue-body.sh` "no Corpus Findings section" assertion
is unaffected.

### Two things this run found that are not fixed

Neither is a regression introduced by `bbe63e01`, and neither blocks the
repin. Both are reported here rather than omitted, because the point of this
repository is to report what it observes, and both were filed upstream with
reproductions the same way #39–#42 were.

1. **MADR 2.x `* Deciders:` header bullets are still not parsed.**
   ([mbeacom/adrkit#50](https://github.com/mbeacom/adrkit/issues/50)) The
   [#40](https://github.com/mbeacom/adrkit/issues/40) fix taught the importer
   to read `* Status:` and `* Date:` header bullets, but not `* Deciders:`. A
   source declaring `* Deciders: @mbeacom` imports with `deciders: []` at
   *both* pins — so this is pre-existing, not new. It is newly *visible*,
   though: now that such a record correctly imports as `accepted`, the
   importer emits `info import-incomplete … "Imported accepted decision has no
   deciders; … should be backfilled when known"` — advice to go find
   information that was present in the source file all along. Same class of
   bug as #40, one field over.
2. **`adr queue` skips undiscoverable records as silently as `lint` used to.**
   ([mbeacom/adrkit#51](https://github.com/mbeacom/adrkit/issues/51))
   [#41](https://github.com/mbeacom/adrkit/issues/41) added
   `corpus-file-skipped` to `lint`, but a corpus whose records are all
   misnamed or nested still reports `totalItems=0, totalCorpusFindings=0` from
   `adr queue`, rendering `*No proposed records found.*` — which reads as
   "your queue is empty" rather than "I could not see your records". A
   consumer who runs only the queue Action — which is exactly what
   `arb-queue.yml` here does — would not learn that its corpus is invisible.
   Verified against a single `proposed` `arb`-tier record: undiscoverable
   filename gives `totalItems=0`, the byte-identical file renamed to
   `0001-…md` gives `totalItems=1`. This is arguably outside #41's stated
   scope (`lint` + `migrate`), which is why it is recorded as an observation
   rather than a claimed defect in the fix.

   **Forward dependency for the next repin.** Fixing
   [#51](https://github.com/mbeacom/adrkit/issues/51) would change what the
   managed queue issue renders for a corpus with skipped files, and this
   repository asserts on that. Two things here are coupled to the current
   behavior: `scripts/assert-managed-issue-body.sh` asserts the **absence** of
   a `## Corpus Findings` section and that the summary reports
   `0 corpus finding(s)`, and `scripts/assert-queue-report.ts` asserts
   `totalCorpusFindings === 0` with an empty `corpusFindings` array. Those
   assertions hold today and would continue to hold for *this* corpus, which
   has no skipped files — but they are written as blanket invariants, not
   scoped to "no skipped files", so they encode an assumption that a #51 fix
   would invalidate for consumers generally. The upstream maintainer has
   flagged that `CorpusFinding.severity` is currently a `'error'` literal
   rather than a union, so surfacing a `warn`-severity finding there widens a
   frozen v1 contract. Whoever performs the next repin should re-read both
   assertion scripts before assuming they still express the intended
   invariant.

### What was re-verified here vs. taken on trust

**Re-verified by running the binary at `bbe63e01`:** all four defect fixes
(#39–#42) via the reproductions above; QueueReport/lint/graph byte-identity;
the status bucketing agreeing across `adr check`, `adr explain`, the Action's
`renderComment`, and MCP `get_decision_context`; the `corpus-file-skipped`
allowlist behavior; the `superseded by <ref>` resolution rule; the
help/version invocation matrix; and the corpus-load fail-closed boundary on
the regenerated `dist/queue-action.js` bundle.

**Taken on trust, not independently verified:** that PR
[mbeacom/adrkit#45](https://github.com/mbeacom/adrkit/pull/45) is the sole
source of these changes and that issues #39–#42 are closed as completed; the
internal claim that a single shared `decisionBucketFor` in `@adrkit/core` is
what every surface routes through (the *behavior* was verified to agree across
four surfaces, but agreement is evidence of a shared implementation, not proof
of one); the `@adrkit/mcp` coverage other than `get_decision_context` — see
the scope caveat under [MCP re-coverage](#mcp-re-coverage-get_decision_context-only);
and adrkit's own test suite, which was not run as part of this validation.

### Live governance comment (status-aware)

`.github/workflows/adr.yml` uses `mbeacom/adrkit/packages/ci@main`, unpinned,
so it picks up the status-aware comment renderer from `bbe63e01` without any
change to this repository. The pull request that carried this repin
([#8](https://github.com/mbeacom/adrkit-t018-dogfood/pull/8)) also touches
`src/payments/api/handler.ts` — a path governed by `0001` and `0002`
(`accepted`) and matched by `0014` (`proposed`) — specifically so the
governance Action posts a real, status-bucketed comment rather than a trivial
one.

Observed on that PR, posted by `github-actions[bot]` and updated in place by
each subsequent push:

```markdown
<!-- adrkit:ci -->

### Decisions governing this change

- **0001** — Govern the payments source boundary
  - via `path`: `src/payments/**`
- **0002** — Govern the payments API boundary
  - via `path`: `src/payments/api/**`

#### Active proposals touching this change

These are not yet ratified and do not bind this change:
- **0014** — Introduce asynchronous cache invalidation for payments settlement events _(proposed)_
  - via `path`: `src/payments/**`
```

The comment body was byte-identical across all four of the PR's commits
(governance runs
[`30163165966`](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/30163165966),
[`30163223377`](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/30163223377),
[`30163283104`](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/30163283104),
[`30163595945`](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/30163595945)
— all `success`), including across the commit that changed
`src/payments/api/handler.ts` from adding an export to adding only a comment.
That is the expected result: the governing set is a function of which *files*
changed, not of what changed inside them, and the Action updates its own
comment in place by marker rather than posting a new one each run.

This is the live end-to-end counterpart to the local `renderComment`
reproduction under resolved defect 1, and it matches that local prediction
exactly. Under `896391cc` the same change would have listed `0014` alongside
`0001` and `0002` under **Decisions governing this change**, unlabelled.

The companion `queue-validation.yml` run
([`30163165953`](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/30163165953),
conclusion `success`) confirms the repin in CI as well as locally:

```
==> Fetching adrkit at pinned commit bbe63e017274f173dbb40eeaceccd17df346b32b (shallow, no full clone)
==> Recording adr --version (regression check for mbeacom/adrkit#42)
adr --version: 0.2.0
Queue validation OK: 3 proposed item(s), 0 corpus findings, all tiers represented.
checked 15 records, 0 errors, 0 warnings
Queue validation complete: adrkit@bbe63e017274f173dbb40eeaceccd17df346b32b (adr 0.2.0), as-of 2026-07-21.
```

### Limitations of this re-validation

One machine, one operating system, one Bun version. The synthetic corpora are
small and purpose-built to isolate each fix; they are not a substitute for a
real third-party MADR corpus. `arb-queue.yml` and `arb-queue-fail-closed.yml`
are `workflow_dispatch`-only and had not been dispatched under the new pin at
the time of writing — the fail-closed boundary was re-probed locally against
the regenerated bundle instead, and the live governance comment above came
from `adr.yml`, which is `pull_request`-triggered. adrkit's own test suite was
not run. As with everything else in this repository, none of this is
`specs/007-arb-queue` SC-004 / T048 evidence: see the status boundary at the
top of this document. Re-validating a fix does not make this repository
independent of the maintainer who wrote it.
