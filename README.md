# adrkit-t018-dogfood

Owner-run technical dogfood repository for [adrkit](https://github.com/mbeacom/adrkit):

- **Phase 3 (T018)** — external-repository validation of the `mbeacom/adrkit/packages/ci@main`
  PR-governance Action against a real corpus of `accepted` decision records
  (`docs/adr/0001`–`0012`) and a governed source subset (`src/payments/**`).
- **Phase 6 (specs/007-arb-queue)** — technical validation of the `adr queue`
  CLI, the `QueueReport` v1 contract, and the `mbeacom/adrkit/packages/ci/queue`
  managed-issue Action against a corpus of `proposed` decision records
  (`docs/adr/0013`–`0015`) spanning all three ARB routing tiers.

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
GitHub Actions workflow — is pinned to the exact merged implementation
commit for `specs/007-arb-queue`:

```
efef89b5d747ca175a1947f1ce2f4296dab54fa3
```

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
| `.github/workflows/adr.yml` | Phase 3 T018 workflow: PR-time governance via `mbeacom/adrkit/packages/ci@main`. Unchanged. |
| `.github/workflows/queue-validation.yml` | Phase 6 CI validation: builds the pinned adrkit commit from source and asserts the `QueueReport` v1 shape via `scripts/validate-queue.sh`. |
| `.github/workflows/arb-queue.yml` | Phase 6 dedicated Action workflow: creates/updates the managed ARB queue issue via `mbeacom/adrkit/packages/ci/queue@efef89b5d747ca175a1947f1ce2f4296dab54fa3`, then self-verifies the result via `scripts/verify-managed-queue-issue.sh`. |
| `scripts/validate-queue.sh` | Local/CI script: clones adrkit at the pinned commit, builds it with Bun 1.3.14, runs `adr queue`, and asserts dogfood expectations. |
| `scripts/assert-queue-report.ts` | QueueReport v1 assertions used by `validate-queue.sh`. |
| `scripts/verify-managed-queue-issue.sh` | CI-only script (needs `GH_TOKEN`): fetches the issue reported by the `arb-queue.yml` Action step's `issue-number` output, exhaustively re-discovers the managed-issue marker across OPEN+CLOSED issues to rule out duplicates, and delegates content checks to `assert-managed-issue-body.sh`. |
| `scripts/assert-managed-issue-body.sh` | Pure, network-free assertions against a single issue JSON document (marker position, title, state, tier labels, `0015` full-quorum approvals, absence of a Corpus Findings section). Used by both `verify-managed-queue-issue.sh` (real data) and `test-assert-managed-issue-body.sh` (fixtures). |
| `scripts/test-assert-managed-issue-body.sh` + `scripts/fixtures/*.json` | Local/CI unit test harness for `assert-managed-issue-body.sh`: one valid fixture and ten fixtures that each violate exactly one invariant, with no GitHub API access required. |

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
   `efef89b5d747ca175a1947f1ce2f4296dab54fa3` into a temporary directory
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
   `mbeacom/adrkit/packages/ci/queue@efef89b5d747ca175a1947f1ce2f4296dab54fa3`
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
