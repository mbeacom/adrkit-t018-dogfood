# adrkit-t018-dogfood

[![ADRs](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Fmbeacom%2Fadrkit-t018-dogfood%2Fmain%2F.adrkit%2Flint.json&query=%24.checked&label=ADRs&color=cb492d)](./docs/adr)
[![ARB queue](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2Fmbeacom%2Fadrkit-t018-dogfood%2Fmain%2F.adrkit%2Fqueue.json&query=%24.totalItems&label=ARB%20queue&suffix=%20pending&color=cb492d)](./docs/adr)

Both badges are adrkit's own recipe ([ADR-0025](https://github.com/mbeacom/adrkit/blob/e3155eaaf200c9ed7f3ea572d91f0bd4c11c35cc/docs/adr/0025-ship-badges-as-recipes-over-existing-output.md),
[guide](https://adrkit.dev/badges/)) over JSON this repository publishes about
**its own** corpus — not adrkit's. They read `$.checked` and `$.totalItems` from
[`.adrkit/lint.json`](.adrkit/lint.json) and [`.adrkit/queue.json`](.adrkit/queue.json),
which are committed and asserted current by
[`scripts/validate-badge-reports.sh`](scripts/validate-badge-reports.sh). See
[Corpus badges](#corpus-badges) for what they do and do not claim.

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
- **Repin to `c3dff3a7` / adrkit `v0.4.0` (2026-08-08)** — no Action source
  changed across that one; the committed bundles moved only because bundled
  dependencies did, so the fail-closed boundary was re-probed rather than
  inferred. See
  [Re-validation against `c3dff3a7`](#re-validation-against-c3dff3a7-adrkit-v040-2026-08-08).
- **Repin to `e3155eaa` / adrkit `v0.7.0` (2026-08-12)** — the current pin. Action
  source changed in the surface this repository watches most closely: the
  governance Action now identifies its own PR comment by the strongest author
  evidence the token allows (adrkit ADR-0026), so a push to an open PR should
  update the existing comment instead of adding a new one. That behavior is
  **read from the upstream record and diff, not observed here**. All four
  validation scripts were re-run locally and pass; the `workflow_dispatch`
  evidence is carried forward, not reproduced. The run also found that
  `corpusFingerprint` changes with the process working directory for a
  byte-identical corpus. See
  [Re-validation against `e3155eaa`](#re-validation-against-e3155eaa-adrkit-v070-2026-08-12).
- **Corpus badges (2026-08-12)** — the two badges above are adrkit `v0.7.0`'s
  badge recipe (ADR-0025), pointed at JSON this repository publishes about its
  own corpus rather than at adrkit's. The reports are committed and asserted
  current by CI instead of being refreshed by a write-capable bot. See
  [Corpus badges](#corpus-badges).
- **Repin to `c5dc677f` / adrkit `v0.6.0` (2026-08-11)** — the first repin in a
  while that changes **Action source**, not just bundles:
  `packages/ci/src/` gained inbound `@adr` marker scanning (v0.5.0) and swapped
  several `localeCompare` sorts for code-unit comparisons (v0.6.0). Both
  `check --json` and `explain --json` grew fields against this repository's own
  governed file, and the governance Action performed the first marker scan ever
  observed here — which falsified a coverage claim written earlier in the same
  change. See
  [Re-validation against `c5dc677f`](#re-validation-against-c5dc677f-adrkit-v060-2026-08-11).
- **Marker coverage (2026-08-11)** — the gap that repin opened is closed in the
  same change. Two source files now declare inbound `@adr` markers and six
  fixtures pin the rules around them, asserted by
  [`scripts/validate-markers.sh`](scripts/validate-markers.sh) (26 assertions)
  and re-run in CI. 22 of the 26 were **observed failing** under a perturbation
  before being credited as coverage; the other four are named with the reason a
  fixture edit cannot violate them. See
  [Marker coverage](#marker-coverage-was-the-gap-this-repin-opened-and-it-is-now-closed).
- **MCP server for coding agents (2026-08-09)** — a pinned, integrity-verified
  `@adrkit/mcp` configuration is checked in for Copilot cloud agent, Copilot code
  review, Copilot CLI, and VS Code, and validated in CI against this
  repository's corpus (56 assertions). The cloud-agent setting itself is UI state
  on GitHub.com and must be applied by hand, so **no agent tool invocation has
  been observed yet** — this is a prepared and validated configuration, not
  evidence of agent use. See
  [MCP server for agents](#mcp-server-for-agents).

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
e3155eaaf200c9ed7f3ea572d91f0bd4c11c35cc
```

This is the commit behind adrkit's **`v0.7.0`** release tag, verified by
dereferencing the annotated tag rather than trusting the release page:

```console
$ gh api repos/mbeacom/adrkit/git/ref/tags/v0.7.0 --jq '.object.type, .object.sha'
tag
90a4c6b1e91c0a9f05ebb748a3d0a997a28d30f2
$ gh api repos/mbeacom/adrkit/git/tags/90a4c6b1e91c0a9f05ebb748a3d0a997a28d30f2 --jq '.object.sha'
e3155eaaf200c9ed7f3ea572d91f0bd4c11c35cc
```

It supersedes `c5dc677f55c492056184c01252d9f812919c80f9` (`v0.6.0`), which
superseded `c3dff3a7a9c3df44233809423eb59a3505fcf6f5` (`v0.4.0`), which
superseded `bbe63e017274f173dbb40eeaceccd17df346b32b`, which superseded
`896391cc385798f7f08c5694f70acaf0342789e9`, which in turn superseded
`efef89b5d747ca175a1947f1ce2f4296dab54fa3` (the `specs/007-arb-queue` merge
commit).

**adrkit now also publishes a moving `v0` major tag, and this repository
deliberately does not use it.** It currently points at exactly this commit:

```console
$ gh api repos/mbeacom/adrkit/git/ref/tags/v0 --jq '.object.type, .object.sha'
commit
e3155eaaf200c9ed7f3ea572d91f0bd4c11c35cc
```

That makes `v0` genuinely useful for *discovering* the current SHA — it is how
this repin was found. But adopting `@v0` as the pin would destroy the property
this repository exists to demonstrate: the tag is mutable, so a future adrkit
release would silently change what this repository runs, with no diff, no
review, and no way to tell after the fact which code produced a given piece of
evidence. Discovery and pinning are different jobs. Use `v0` for the first and
a 40-character SHA for the second.

### What changed across `c3dff3a7` → `c5dc677f`

**Action source changed.** This is a stronger claim than the previous repin had
to defend, and it inverts that one's argument: last time the bundles moved while
`packages/ci/src/` stood still, so the burden was to show a rebundle alone could
be trusted. This time the source itself moved. Observed directly in clones of
adrkit at both commits:

```console
$ diff -rq c3dff3a7/packages/ci/src c5dc677f/packages/ci/src
Files .../src/action.ts and .../src/action.ts differ
Files .../src/changed-files.ts and .../src/changed-files.ts differ
Files .../src/comment.ts and .../src/comment.ts differ
Files .../src/index.ts and .../src/index.ts differ
```

`packages/ci/queue/action.yml` is still byte-identical across the two pins
(SHA-256 `9e71b551…` at both — the same digest recorded at the previous two
pins), so the Action's input/output contract is unchanged even though its
implementation is not.

Both committed bundles were regenerated, and unlike the previous repin the
cause is visible in source rather than only in dependencies:

| Bundle | `c3dff3a7` | `c5dc677f` |
|---|---|---|
| `packages/ci/dist/queue-action.js` | 1,735,304 bytes | 1,735,334 bytes |
| `packages/ci/dist/index.js` | 1,791,318 bytes | 1,807,680 bytes |

The two upstream releases spanned by this range are what account for that:

- **`v0.5.0`** wired inbound `@adr` markers into `adr check` and the
  governing-decisions Action. `runAction` now pre-scans changed files for
  `@adr <id>` comment lines before calling the pure `checkChanges`, renders
  marker-derived edges as `declared by`, and logs a marker-scan summary.
  `extractChanges` grew a `markerFiles` list that excludes removed files and a
  rename's previous path. Markers never influence exit status.
- **`v0.6.0`** replaced `localeCompare` with code-unit comparison in several
  `check --json` determinism-contract sorts, and made `adr explain --json`
  report the *measured* marker scan extent rather than restating the 8192-byte
  window constant.

Note the scope limit adrkit states for the sort fix and this repository has not
independently verified: the three sorts under `packages/core/src/affects/**`
still use `localeCompare` and are excluded from the ordering guard. A clean
guard run upstream therefore means "no scanned module reaches for
`localeCompare`", not "`check --json` is locale-independent end to end". This
repository observed byte-identical `queue` output across the repin (below), but
that is a single-locale observation, not a cross-locale one.

What that means for the evidence in this document, re-verified rather than
assumed — every row below was produced by building both pins from source and
running them against this repository's real corpus:

| Surface | Across `c3dff3a7` → `c5dc677f` |
|---|---|
| `packages/ci/src/**` | **changed** — 4 files (`action.ts`, `changed-files.ts`, `comment.ts`, `index.ts`) |
| `packages/ci/queue/action.yml` | **byte-identical** (SHA-256 `9e71b551…`) |
| `packages/ci/dist/queue-action.js` | **regenerated** — 1,735,304 → 1,735,334 bytes, driven by source this time |
| `packages/ci/dist/index.js` | **regenerated** — 1,791,318 → 1,807,680 bytes |
| `adr queue --format json` / `--format markdown` | **byte-identical** (SHA-256 `716e21b7…` / `fbcd4d5f…`, the same digests recorded at the previous pin) |
| `adr lint --dir docs/adr` | **byte-identical** — still `checked 15 records, 0 errors, 0 warnings` |
| `adr graph --format json` | **byte-identical** |
| `adr check --json` | **widened, additively** — a new `markerScan` object; every pre-existing field unchanged |
| `adr check` human output | **one new line** — `marker scan: 1 scanned, 0 absent, 0 unreadable, 0 out-of-tree, 0 truncated, 0 skipped` |
| `adr explain --json` | **widened, but positionally** — `scannedBytes` / `fileBytes` **inserted between** `windowBytes` and `truncated`, not appended |
| `adr --version` | **changed** — `0.4.0` → `0.6.0`; recorded, deliberately not asserted |
| `QueueReport` v1 contract | **unchanged** — `report.version` is still `"1"` |
| queue Action fail-closed boundary | **re-probed against the regenerated bundle** — see [Fail-closed evidence](#fail-closed-evidence-invalid-input-no-write) |

All 13 assertions in `scripts/assert-queue-report.ts` reproduce identically
under the new pin, and the `--as-of 2026-07-21` `overdue`/`due` states did not
move.

### The previous repin, `bbe63e01` → `c3dff3a7` (historical)

Retained because it is dated evidence about a different range, not a
description of the current pin. **No Action source changed across that one.**
Observed at the time:

```console
$ diff -rq bbe63e01/packages/ci/src c3dff3a7/packages/ci/src
(no output — identical)

$ diff -rq bbe63e01/packages/ci c3dff3a7/packages/ci
Files .../dist/index.js and .../dist/index.js differ
Files .../dist/queue-action.js and .../dist/queue-action.js differ
Files .../package.json and .../package.json differ
Only in c3dff3a7/packages/ci/test: bundle-scope.test.ts
```

The two committed bundles moved because bundled *dependencies* moved beneath
them. The visible cause was in `packages/ci/package.json`:

```diff
-    "@actions/core": "^1.11.1",
-    "@actions/github": "^6.0.1",
+    "@actions/core": "^3.0.1",
+    "@actions/github": "^9.1.1",
```

Two major-version bumps of the GitHub Actions toolkit, bundled directly into
`dist/queue-action.js`. Nothing in this repository could see inside that bundle
diff, and "the source didn't change" was therefore *not* sufficient grounds to
carry the previous pin's evidence forward — the compiled artifact that actually
ran in CI was different. The bundle shrank from 1,753,353 to 1,735,304 bytes
(`dist/index.js`: 1,810,568 → 1,791,318). That is exactly why the fail-closed
boundary was re-probed by execution rather than inferred from an unchanged file,
and the same reasoning is applied again at the current pin.

At that repin, `adr --version` moved `0.2.0` → `0.4.0`, and the `QueueReport` v1
contract widened compatibly — `CorpusFinding.severity` became
`"error" | "warn"` while `report.version` stayed `"1"`. See
[The QueueReport contract widened](#the-queuereport-contract-widened-compatibly).

### Why a SHA and never a moving ref

This is a full 40-character commit SHA, never a moving branch or tag. Do not
change any pin in this repository to `@main`, `@v0`, or any other ref without
re-running the full validation procedure below and updating this document.

A concrete instance of why, observed while verifying an upstream record during
the `bbe63e01` run: fetching a file from GitHub's contents API by **branch ref**
(`?ref=<branch>`) returned a stale revision — a `200` with plausible, coherent
content and nothing to indicate it was behind the branch head. Re-fetching the
same path by **explicit commit SHA** returned the current 10,944-byte revision
where the branch ref had served 10,384 bytes. The stale read was
indistinguishable from a current one, and acting on it would have produced a
confident, wrong conclusion. That is the same failure this pinning rule guards
against, in a different mechanism: a moving ref can answer successfully and
still not be showing you what you think you asked for.

(The pre-existing Phase 3 `packages/ci@main` reference in
[`.github/workflows/adr.yml`](.github/workflows/adr.yml) predates this pinning
requirement and is left untouched from Phase 3; it governs PRs against this
repository, not the ARB queue. Because it is unpinned, it picks up the
status-aware comment renderer that landed in `bbe63e01` automatically — see
[Live governance comment](#live-governance-comment-status-aware) below.)

### Status-aware governance changes what `check` and `explain` report

This was the one intentional behavior change the **`896391cc` → `bbe63e01`**
repin introduced against this repository's own corpus (`0001`–`0012`
`accepted`, `0013`–`0015` `proposed`). It is unchanged at the current
`c3dff3a7` pin and is recorded here as the historical record of that
transition. Under `896391cc`, `adr explain src/payments/api/handler.ts`
reported `0001`, `0002` and `0014` alike, with no status shown. From
`bbe63e01` onward:

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
| `src/payments/api/handler.ts` | Governed source subset from Phase 3 T018, exercised by the `adr.yml` PR-governance workflow. Also declares `@adr 0014` — the *merge* marker case, where one decision is reached by both a pattern and an inbound declaration. |
| `src/platform/ledger-client.ts` | Marker-only governance fixture: declares `@adr 0005, 0015`, neither of which names `src/platform/**` in `affects`, so both come back with an empty `firedMatchers`. See "Marker coverage". |
| `fixtures/markers/**` | Six checked-in marker fixtures covering the accepted introducers, the marker-looking lines that must **not** declare (trailing, string literal, prose, fenced examples, markdown's reduced introducer set), the two unresolvable forms, and an over-window file that forces a truncated scan. |
| `fixtures/fail-closed-invalid-corpus-dir` | Checked-in invalid-input fixture: a plain **file** (not a directory) used as the `dir` input to the queue Action in `arb-queue-fail-closed.yml`, to deterministically trigger adrkit's corpus-load `ENOTDIR` failure before any GitHub write. |
| `.github/workflows/adr.yml` | Phase 3 T018 workflow: PR-time governance via `mbeacom/adrkit/packages/ci@main`. Deliberately unpinned (see "Pinned adrkit commit"), so since `bbe63e01` it renders the **status-aware** PR comment — only `accepted` records appear under "Decisions governing this change", with active proposals and history in their own sections. |
| `.github/workflows/queue-validation.yml` | Phase 6 CI validation: builds the pinned adrkit commit from source and asserts the `QueueReport` v1 shape via `scripts/validate-queue.sh`; asserts the committed badge reports are current via `scripts/validate-badge-reports.sh`; also runs both network-free unit test harnesses. |
| `.github/workflows/arb-queue.yml` | Phase 6 dedicated Action workflow: creates/updates the managed ARB queue issue via `mbeacom/adrkit/packages/ci/queue@e3155eaaf200c9ed7f3ea572d91f0bd4c11c35cc`, then self-verifies the result via `scripts/verify-managed-queue-issue.sh`. |
| `.github/workflows/arb-queue-fail-closed.yml` | Phase 6 **fail-closed** Action workflow: dispatches the same pinned queue Action against a deliberately invalid `dir` input, asserts the step failed before any write, and mechanically proves zero issue mutation via before/after snapshots. See "Fail-closed evidence" below. |
| `scripts/validate-queue.sh` | Local/CI script: clones adrkit at the pinned commit, builds it with Bun 1.3.14, runs `adr queue`, and asserts dogfood expectations. |
| `scripts/assert-queue-report.ts` | QueueReport v1 assertions used by `validate-queue.sh`. |
| `scripts/verify-managed-queue-issue.sh` | CI-only script (needs `GH_TOKEN`): fetches the issue reported by the `arb-queue.yml` Action step's `issue-number` output, exhaustively re-discovers the managed-issue marker across OPEN+CLOSED issues to rule out duplicates, and delegates content checks to `assert-managed-issue-body.sh`. |
| `scripts/assert-managed-issue-body.sh` | Pure, network-free assertions against a single issue JSON document (marker position, title, state, tier labels, `0015` full-quorum approvals, absence of a Corpus Findings section). Used by both `verify-managed-queue-issue.sh` (real data) and `test-assert-managed-issue-body.sh` (fixtures). |
| `scripts/test-assert-managed-issue-body.sh` + `scripts/fixtures/{good,bad-*}.json` | Local/CI unit test harness for `assert-managed-issue-body.sh`: one valid fixture and ten fixtures that each violate exactly one invariant, with no GitHub API access required. |
| `scripts/snapshot-issues.sh` | CI-only script (needs `GH_TOKEN`): snapshots every issue (OPEN+CLOSED, excluding pull requests) as `{number, state, title, updatedAt, bodySha256}`. Run once before and once after the fail-closed Action dispatch. |
| `scripts/assert-no-issue-mutation.sh` | Pure, network-free comparison of two snapshots produced by `snapshot-issues.sh`; fails unless they are byte-for-byte identical after canonicalization. Used by both `arb-queue-fail-closed.yml` (real data) and `test-assert-no-issue-mutation.sh` (fixtures). |
| `scripts/test-assert-no-issue-mutation.sh` + `scripts/fixtures/mutation-*.json` | Local/CI unit test harness for `assert-no-issue-mutation.sh`: an identical (reordered) pair that must pass, and four pairs that each violate exactly one invariant (body changed, state changed, issue added, issue removed), with no GitHub API access required. |
| `.github/workflows/spec-kit-extension.yml` | **Spec Kit extension** rung-2 validation: installs `@adrkit/spec-kit` from its published, sha256-pinned release asset into a real Spec Kit project, at each upstream version where that install path works (`0.14.4`, `0.15.1`), and runs `scripts/validate-spec-kit-extension.sh`. Runs on PR, on `main`, weekly, and on demand. |
| `scripts/validate-spec-kit-extension.sh` | Self-verifying, fail-closed assertions for the Spec Kit extension: install and rendering, the hook contract, packaging hygiene, behavior against this repo's real corpus, zero mutation, and four consumer-facing failure modes that must produce no side effect. 41 assertions per upstream version. |
| `.github/copilot-mcp-config.json` | **Canonical** MCP configuration for Copilot cloud agent and Copilot code review. Not read at runtime by anything — the live setting is UI state on GitHub.com — but version-controlled so it is reviewable and attributable to a commit. See "MCP server for agents". |
| `.vscode/mcp.json`, `.copilot/mcp-config.json` | The same server for VS Code and Copilot CLI, in those clients' schemas. Kept in agreement with the canonical config by `scripts/assert-mcp-config.mjs`. |
| `.github/copilot-instructions.md` | Repository instructions for coding agents: query the MCP rather than grepping the corpus, report MCP defects instead of routing around them, and honor this repository's evidence and pin discipline. |
| `.github/workflows/mcp-validation.yml` | MCP validation: runs `scripts/validate-mcp.sh` on PR, on `main`, weekly, and on demand. The weekly run exists because an npm package is a moving target in a way a commit SHA is not. |
| `.github/workflows/copilot-setup-steps.yml` | Prepares Copilot cloud agent's environment so the MCP server can start: pins Node 22, warms the npm cache with the pinned version, and re-verifies its `sha512`. A precaution, not verified agent behavior — see "MCP server for agents". |
| `scripts/validate-mcp.sh` | Verifies the pinned `@adrkit/mcp` tarball's `sha512`, proves its `src/` is byte-identical to `packages/mcp/src` at the pinned adrkit commit, asserts config agreement, drives the server over stdio JSON-RPC, and asserts the corpus was not mutated. |
| `scripts/assert-mcp-config.mjs` | Network-free assertions that the three checked-in MCP configs and the Copilot setup-steps workflow agree with each other and with the pin (28 assertions). |
| `scripts/assert-mcp-surface.mjs` | stdio JSON-RPC assertions against the verified server install: four-tool surface, read-only annotations, governance resolution, nested-matcher discrimination, input rejection, and stdout protocol hygiene (28 assertions). |
| `.github/workflows/marker-validation.yml` | Marker validation: runs `scripts/validate-markers.sh --self-test` on PR, on `main`, weekly, and on demand. The `--self-test` pass is why it runs in CI rather than by hand — it fails the run if an assertion has become vacuous. |
| `scripts/validate-markers.sh` | Captures `adr explain --json` per marker fixture plus one batch `adr check --json` against the pinned adrkit build, cross-checks the pin against `validate-queue.sh`, and delegates every correctness decision to `assert-markers.mjs`. `--self-test` perturbs each fixture and requires the matching assertion to fail. |
| `scripts/assert-markers.mjs` | Pure, network-free assertions over those captures: 26 checks across marker resolution, the negative cases, the unresolvable findings, the measured truncation extent, and the batch `markerScan`. |
| `.adrkit/lint.json`, `.adrkit/queue.json` | Verbatim `adr lint --json` and `adr queue --format json` output for this corpus, committed as the source the README badges read. Generated at the pinned commit with the same fixed `--as-of` the queue evidence uses. Not hand-edited — regenerate rather than patch. See "Corpus badges". |
| `scripts/validate-badge-reports.sh` | Regenerates both badge reports at the pinned commit and requires them to be byte-identical to the committed files, then asserts the two fields the badge URLs dereference are integers and the lint report is finding-free (5 assertions). Cross-checks both the adrkit pin and the `--as-of` date against `validate-queue.sh`. |

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
   `e3155eaaf200c9ed7f3ea572d91f0bd4c11c35cc` into a temporary directory
   (never a branch or tag).
2. Installs dependencies with `bun install --frozen-lockfile` using
   **Bun 1.3.14**.
3. Builds the workspace with `bun run build`.
4. Records the binary's self-reported version (`adr --version`, currently
   `0.6.0`) alongside the pinned SHA, and fails if it exits non-zero or
   prints nothing. Before `bbe63e01` this was impossible — `adr --version`
   was an unknown command that exited 2
   ([mbeacom/adrkit#42](https://github.com/mbeacom/adrkit/issues/42)) — so
   the commit SHA was the only provenance available. This check deliberately
   does **not** assert the literal version string: a legitimate upstream
   version bump should not break this repository's CI, whereas losing
   `--version` entirely should. That design has now paid off twice — the
   version moved `0.2.0` → `0.4.0` and then `0.4.0` → `0.6.0`, and the check
   passed unchanged both times, recording the new value without any edit to
   the script.
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

## MCP server for agents

adrkit ships a local, read-only MCP server (`@adrkit/mcp`) that exposes this
repository's decision corpus to coding agents over stdio. This repository checks
in configurations for **Copilot cloud agent**, **Copilot code review**, **Copilot
CLI**, and **VS Code**, so an agent working here can ask what governs a file
instead of inferring it by reading Markdown.

The concrete gain today is the validation, not the agent behavior. The MCP
surface was previously exercised only in one-off manual runs (see
[Full CLI + MCP surface dogfood](#full-cli--mcp-surface-dogfood-2026-07-25)),
whose coverage caveats were a standing gap; `scripts/validate-mcp.sh` converts
those one-off observations into CI-enforced assertions that run on every pull
request. Whether agents then actually *use* the server is a separate claim, and
one this repository cannot yet make — see
[What this does not establish](#what-this-does-not-establish).

### The cloud-agent configuration is UI state, and that is a problem

The repository-level MCP configuration read by Copilot cloud agent and Copilot
code review lives in **Settings → Copilot → MCP servers** on GitHub.com. There
is no repository file that sets it and no REST endpoint that reads or writes it
— `repos/{owner}/{repo}/copilot/mcp/config` and the adjacent paths all 404.

That is a genuine gap in this repository's normal discipline: everything else
here is pinned, diffable, and attributable to a commit, and this one setting is
not. It cannot be closed from inside the repository, so it is narrowed instead:

- [`.github/copilot-mcp-config.json`](.github/copilot-mcp-config.json) is the
  **canonical** configuration — the exact payload that should be pasted into the
  settings page. Nothing reads it at runtime. It exists so the intended setting
  is reviewable, diffable, and attributable, and so a drift between what is
  configured and what was agreed is a reviewable change rather than invisible.
- CI cannot assert that the live setting matches it. **Do not read a green
  `mcp-validation` run as evidence that the cloud-agent setting is correct** —
  it is evidence that everything the setting depends on is correct.

Applying it is a manual step: copy the `mcpServers` object (dropping the
`$comment` keys, which are documentation and not part of the schema) into the
settings page and save.

### What is pinned, and why npm is acceptable here

Every other adrkit reference in this repository is a 40-character commit SHA.
The MCP server is launched by `npx` from npm, which is a weaker identity: a
version number is a *name*, and the pin discipline in
[Pinned adrkit commit](#pinned-adrkit-commit) is about *content*. Two things
close that gap:

1. **The tarball is content-pinned.** `scripts/validate-mcp.sh` records the
   registry's `sha512` integrity for `@adrkit/mcp@0.7.0` and verifies the
   downloaded tarball against it before anything else happens. This is the npm
   analogue of `ADRKIT_EXT_SHA256` in the Spec Kit workflow.

2. **The tarball is tied to the pinned commit.** `@adrkit/mcp` ships its own
   `src/` (its `package.json` `files` includes it), so the published package can
   be diffed directly against the commit this repository pins. Observed:

   ```console
   $ diff -r package/src fromgit/packages/mcp/src && echo IDENTICAL
   IDENTICAL
   ```

   where `package/` is the extracted `@adrkit/mcp@0.7.0` tarball and `fromgit/`
   is `git archive e3155eaaf200c9ed7f3ea572d91f0bd4c11c35cc packages/mcp/src`.

   This is the assertion that licenses using npm for MCP at all. Without it,
   "the MCP server agents use matches the adrkit commit this repository pins"
   would be an assumption — and it is not a safe one in general: npm
   `@adrkit/mcp@0.2.0` was published **2026-07-20**, five days *before* the
   `bbe63e01` pin whose whole point was fixing
   [#39](https://github.com/mbeacom/adrkit/issues/39), a defect in shared code
   that `packages/mcp/src/tools/get-decision-context.ts` calls. The npm channel
   and the commit pin move on different axes, so their agreement is checked, not
   assumed. At the current pin they agree.

   **Two scope caveats, both material.**

   *Only `src/` is compared.* The `dist/` the server actually executes is a build
   artifact and is not byte-reproducible from a `git archive`, so it is not
   diffed. It is covered indirectly: the `sha512` pins it against silent
   replacement, and the behavioral assertions below run against that real
   published `dist`. Weaker than the source comparison, and stated as such.

   *Only `@adrkit/mcp` itself is pinned.* The server imports `@adrkit/core`,
   `@modelcontextprotocol/server`, and `zod`, and those are resolved by npm at
   install time from ranges — there is no lockfile here, so the executed
   dependency closure is not content-pinned. This matters more than it might
   look: `@adrkit/core` is where the shared `decisionBucketFor` lives, so
   governance behavior is partly determined by code this repository does not pin.
   What that leaves is a narrower claim than "the whole server matches the pinned
   commit", and the narrower claim is the one made here: **the `@adrkit/mcp`
   package is pinned and matches the pinned commit; its dependencies are not.**
   The behavioral assertions are what cover the rest, empirically rather than by
   provenance — they run against whatever closure npm actually resolved.

The version is deliberately exact in all three configs. `npx -y @adrkit/mcp`
without a version resolves at launch, which would mean every agent session ran
against whatever was current that day, with no way to tell afterwards which code
produced a given answer — the same failure mode as pinning `@v0`.

### Three configs, one server

Three clients read three files in three schemas, so there is no single format to
collapse them into. The copies are a drift hazard, so drift is made a build
failure: `scripts/assert-mcp-config.mjs` asserts the invariants that determine
behavior (same package at the same exact version, same `docs/adr`, and — for the
two Copilot schemas — the same explicit four-tool allowlist), while tolerating
the differences the schemas require (`${workspaceFolder}` substitution in VS
Code; no `tools` key in the VS Code schema).

The tool allowlist enumerates the four tools rather than using `["*"]`. Copilot
invokes MCP tools autonomously **without asking for approval**, so the allowlist
is a real boundary, and enumerating it means an upstream release that adds a
fifth tool cannot silently widen what agents here can call — it becomes a failed
assertion and a deliberate re-verification.

### Making the server actually start in the agent environment

`@adrkit/mcp` declares `engines.node >= 22`, and npm treats `engines` as advisory
rather than fatal, so an older runtime would not necessarily fail loudly at
install time — it would fail later, or subtly. A server that fails to start also
fails *quietly* from the outside: an agent with no adrkit tools looks exactly
like an agent that chose not to use them.

[`.github/workflows/copilot-setup-steps.yml`](.github/workflows/copilot-setup-steps.yml)
addresses the two most likely causes. It pins Node 22, populates the npm cache
with the pinned version and its dependency closure so the launch resolves
locally rather than racing the network, and re-checks the same `sha512` so a
substituted artifact fails in setup — visibly, in the session log — rather than
silently becoming the code an agent runs.

The order of those steps is load-bearing, and getting it wrong is easy. An
earlier version verified a tarball fetched with `curl` and then ran `npm install
"@adrkit/mcp@0.7.0"` — which performs *its own* registry resolution, so the bytes
checked were never the bytes installed, and a re-point between the two commands
would have defeated the check while leaving it green. The step now runs `npm
pack` on the pinned spec, which emits exactly what npm resolves and serves,
hashes *that*, and installs the verified local file. Verified artifact and
installed artifact are now the same bytes.

**Even so, this is a precaution, not verified behavior.** This repository cannot
observe Copilot cloud agent's environment from outside, so nothing here is
evidence that an agent successfully starts the server; only that two known
failure modes have been addressed. Two limits are worth naming precisely:

- The integrity check covers what npm resolves **during this workflow run**. The
  `npx` in the MCP configuration performs its own resolution later, at agent
  launch, which this workflow does not gate. The binding provenance check —
  `sha512` plus the `src/` diff against the pinned commit — is
  `scripts/validate-mcp.sh`, and it runs in CI on every pull request.
- The workflow runs as an ordinary Actions workflow when it changes, which
  verifies the steps themselves succeed. It does not verify that Copilot ran
  them.

Because the pin now appears in that workflow as well as in
`scripts/validate-mcp.sh`, the drift check covers it: `SETUP-SPEC`,
`SETUP-SHA512`, `SETUP-NO-FLOAT`, and `SETUP-NO-STALE` assert the workflow
carries the same version and integrity, uses no non-exact spec, and mentions no
other version. The sweep looks for the version in *both* forms the file uses —
the npm spec and the packed tarball filename — because
the filename is `adrkit-mcp-0.7.0.tgz`, where the version is not adjacent to the
package spec. A single pattern anchored on the package name missed it, and a
negative test caught that the check was passing a case it claimed to catch;
`SETUP-SWEEP-NONVACUOUS` now additionally asserts both forms are present, so the
sweep cannot become vacuous if the file is restructured. Comments are stripped
before the sweep, because this file's own header explains the pin and therefore
contains it — without stripping, the real command could be changed to `@latest`
with every assertion still green.

### Running the MCP validation

```bash
./scripts/validate-mcp.sh
```

Requires Node ≥ 22 (`@adrkit/mcp`'s declared `engines` range; the script
re-checks it rather than trusting the workflow). Nothing is built from source:
the server under test is the published artifact, installed from the tarball whose
`sha512` was verified moments earlier and executed from that installation.

That last detail matters and was a correction. The harness originally launched a
second, independent `npx -y @adrkit/mcp@0.7.0` — which re-resolves by name and
could execute a cached or hoisted same-version copy that no version-string
assertion can distinguish from the verified one. It now runs the verified
install directly, so "the artifact validated" and "the artifact executed" are the
same bytes. Note this makes the harness's launch *not* byte-identical to the
configs': it invokes the installed binary rather than `npx`, and passes `--cwd`
where the two Copilot configs rely on the default. What is shared is the package,
the `--dir`, and the stdio transport.

The script cross-checks the adrkit pin against `scripts/validate-queue.sh`,
verifies the tarball integrity, proves the npm↔commit correspondence, installs
the verified tarball, runs the 28 configuration assertions, runs the 28 stdio
JSON-RPC assertions, and then re-hashes `docs/adr`. Observed against the current
pin — all 56 assertions pass:

| Assertion group | What is asserted |
|---|---|
| `MCP-1`–`MCP-2` | The server identifies as `@adrkit/mcp` and reports **0.7.0**. This is a consistency check, not provenance — provenance comes from having executed the sha512-verified install. |
| `MCP-3`–`MCP-5` | Exactly the four tools, every one annotated `readOnlyHint: true` and `openWorldHint: false`. These are *declarations*, not an enforced sandbox: they are what a client relies on when deciding to invoke autonomously, so a change to them is a change to that basis. Enforcement is not asserted here. |
| `MCP-6`–`MCP-9` | `src/payments/api/handler.ts` resolves to `governing: 0001, 0002`, `activeProposals: 0014`, `history: []` — the same status-aware buckets `adr check` and the CI Action produce for that path. |
| `MCP-10`–`MCP-12` | `corpusHealth` reports 15 records, 0 excluded, fingerprint `1664c5af…4bd936`. The fingerprint is asserted so an accidental corpus edit fails loudly here instead of silently shifting every expectation below it. |
| `MCP-13`–`MCP-16` | `search_decisions` finds the payments records; an ungoverned path (`README.md`) returns the `matches` branch with empty results rather than an error, so an agent can distinguish "nothing governs this" from "the lookup failed". |
| `MCP-17`–`MCP-21` | `list_superseded` returns `entries` (empty — this corpus declares no supersession, asserted rather than skipped); `get_decision` resolves `0001` as `accepted` and returns an explicit `not-found` for `9999` rather than a protocol error or a fabricated record. |
| `MCP-22`–`MCP-24` | Paths resolve by pattern without needing to exist. `src/payments/api/does-not-exist.ts` matches both `0001` (`src/payments/**`) and `0002` (`src/payments/api/**`), while `src/payments/does-not-exist.ts` matches only `0001` — which also pins nested-matcher discrimination. |
| `MCP-25`–`MCP-27` | Traversal (`../../../etc/passwd`), absolute (`/etc/passwd`), and Windows-separator paths are refused. |
| `MCP-28` | Nothing but well-formed JSON-RPC 2.0 frames appeared on stdout, which the server's contract reserves for the protocol. |

`MCP-25`–`MCP-27` assert the *kind* of rejection, not just its presence. Each is
refused with a schema message — `files must be repo-relative POSIX paths` — and
not `ENOENT` or `EACCES`. Combined with `MCP-22`, where a nonexistent path
resolves happily instead of erroring, this is consistent with the documented
behavior that path arguments are matched against patterns rather than opened.

**It is consistent with it, not proof of it.** Both observations are black-box
responses; neither inspects syscalls, and a server that opened its inputs and
then discarded the result would produce the same output. The stronger read-only
and never-opened evidence — import-graph inspection, `lsof` showing zero network
sockets — is from the original `896391cc` run and is
[recorded there with its own caveats](#full-cli--mcp-surface-dogfood-2026-07-25),
not re-established here.

Four corrections are worth recording, because each is the failure mode this
repository's evidence standard exists to catch — a check that would have been
recorded as evidence while testing nothing.

1. `MCP-25`–`MCP-27` were first written to expect a **JSON-RPC error**, and they
   failed. The server was right and the assertion was wrong: MCP reports tool
   input validation as an `isError: true` *result*, not a protocol error. Written
   to pass, they would have recorded "traversal is rejected" vacuously.
2. `MCP-24` initially asserted that *any* nonexistent path under `src/payments/`
   matched both `0001` and `0002`. It matches only `0001` — `0002`'s matcher is
   the narrower `src/payments/api/**`. A guess the corpus falsified.
3. The result reader originally fell back to the raw result when
   `structuredContent` was absent, and ignored `isError`. A tool that started
   returning errors, or stopped returning structured output, could have satisfied
   an `outcome` assertion by accident. Both are now hard failures. Likewise
   `summarize()` normalized a missing bucket to `[]`, which would have made every
   "this bucket is empty" assertion pass when the bucket was absent entirely.
4. `SETUP-NO-STALE` searched the raw workflow text, and that file's own header
   comment contains the pinned spec — so the real command could have been changed
   to `@latest` with every assertion still green. Comments are now stripped before
   the sweep, and `SETUP-NO-FLOAT` rejects any non-exact spec, including dist-tags
   and ranges that carry no version number for a semver sweep to compare.
5. `MCP-28` was evaluated while the server was still running, so anything emitted
   after the final response — or during shutdown, where stray output is most
   likely — arrived too late to be seen. The assertion now runs after the client
   closes. Closing also had to change: it ended stdin and sent `SIGTERM`
   immediately, which truncated the very output the assertion needed. Measured
   directly against a server that writes a non-JSON line on shutdown:

   ```console
   OLD (immediate kill) captured shutdown line: false
   NEW (graceful)      captured shutdown line: true
   ```

   A trailing fragment with no newline is now also counted as a violation rather
   than discarded with the buffer.

Each of these was found by deliberately breaking the thing the check claimed to
protect and confirming the check went red.

### What this does not establish

- It is **not** evidence that the cloud-agent setting on GitHub.com is correct,
  configured, or in agreement with the canonical file. That is unverifiable from
  here.
- It is **not** `specs/007-arb-queue` SC-004 / T048 evidence, for the same reason
  nothing else in this repository is — see
  [Status boundary](#-status-boundary--this-is-not-sc-004-evidence).
- It does **not** re-run the broader `896391cc` MCP sweep (22 calls, pagination
  cursors, `lsof` socket checks, import-graph inspection). Those remain
  point-in-time observations with the caveats recorded under
  [MCP re-coverage](#mcp-re-coverage-get_decision_context-only).
- The read-only check is narrower than "the server does not write". Hashing every
  file under `docs/adr` before and after establishes that the corpus **ended**
  byte-identical to how it started — it would not detect a write that was
  reverted, a temporary file created and removed, or a write anywhere outside
  `docs/adr`. It is a regression tripwire on the corpus, not a proof of
  read-only behavior.
- It does **not** content-pin the server's dependency closure. See the second
  scope caveat under
  [What is pinned](#what-is-pinned-and-why-npm-is-acceptable-here).
- It does **not** verify that agents actually *use* the server.
  [`.github/copilot-instructions.md`](.github/copilot-instructions.md) instructs
  them to, but instructions are not a mechanism, and no assertion here observes
  agent behavior.

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

### Live dispatch under the `c3dff3a7` pin

> **Superseded as the most recent dispatch.** `arb-queue.yml` has since been
> re-dispatched at the current `c5dc677f` pin — run
> [`31553913041`](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/31553913041),
> conclusion `success`, every self-verification assertion passing. See
> [Live evidence at this pin](#live-evidence-at-this-pin). This section is
> retained as the `c3dff3a7` record.

Dispatched against the repin branch `mbeacom-repin-queue-action-v0-4-0` at
commit `3bfe15a` — run
[`31288355812`](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/31288355812),
conclusion `success`, with the Action resolved at
`Download action repository 'mbeacom/adrkit@c3dff3a7a9c3df44233809423eb59a3505fcf6f5'`.

Every self-verification assertion passed, including exhaustive marker
discovery (`exactly one issue carries the managed-queue marker across
OPEN+CLOSED issues (found 1: 3)`), the marker's exact first-line position, the
`ADR ARB Queue` title, `open` state, an overview-table row for each of `0013`
/ `0014` / `0015` with its fixed tier label, `0015`'s `3/3` full quorum, the
absence of a `## Corpus Findings` section, and a `0 corpus finding(s)`
summary.

**This dispatch was not a no-op, and the reason is worth recording.** Under
the `bbe63e01` pin the equivalent dispatch was idempotent — issue `#3`'s body
hash and `updatedAt` were unchanged. Here the body moved from
`e82221fc2ad8946720d9897d687029320e7ba0b206c945094023f51ea3642d30` to
`28590cce9abbed8cafd320f264c5f6283757ffac8c28035d65a75caa77dd65ad`, and
`updatedAt` advanced to `2026-08-09T01:29:11Z`.

That is **not** attributable to the repin. This workflow always uses the
Action's default `--as-of` of *today*, and the previous render was made on
2026-07-25. In the intervening two weeks every item crossed its deadline, so
all three rows moved to `overdue` — `0013` in particular went `within-sla` →
`overdue` as its 2026-08-01 deadline passed. A body change was the correct
behavior; an unchanged body would have been the bug.

The idempotency claim was therefore tested separately, on its own terms, by
**re-dispatching the same workflow against the same branch on the same day** —
run [`31288387942`](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/31288387942),
conclusion `success`. After it, issue `#3`'s body SHA-256 was still
`28590cce…` and `updatedAt` was still `2026-08-09T01:29:11Z`: the Action
recognized the rendered report already matched and did not churn the issue.
That is the no-op, isolated from the date-driven change that preceded it.

Note the contrast with `scripts/validate-queue.sh`, which pins
`--as-of 2026-07-21` precisely so its output *is* stable across time. The two
are deliberately different: the script is a reproducible evidence artifact, the
workflow is a live operations queue that is supposed to track the calendar.

As with everything else in this repository, `verify-managed-queue-issue.sh`
is technical, owner-run evidence that the queue kernel/CLI/Action behave
correctly — it is not, and does not claim to be, `specs/007-arb-queue`
SC-004/T048 evidence. See the status boundary above.

## Spec Kit extension reference validation (`spec-kit-extension.yml`)

ADR-0014 **rung-2** evidence for `@adrkit/spec-kit`, the Spec Kit extension that
puts adrkit's governing decisions inside the spec-driven plan loop.

The upstream Spec Kit catalog entry has not landed yet, so the closest thing to
a consumer install is `specify extension add adrkit --from <URL>` against the
**release asset** — `adrkit.zip` from the `spec-kit-v0.1.2` GitHub release,
pinned by sha256. That asset, not a source checkout and not the npm tarball, is
the artifact under test: it is what the download path actually delivers, and its
contents differ from the npm tarball (the tarball ships `package.json`; the
asset does not — which is why the `PKG-*` absence assertions now assert about
what a consumer receives rather than about a build tree). The `adr` CLI it
shells out to is the **published** `@adrkit/cli`, pinned by version.

### Why a matrix

The extension's manifest declares `speckit_version: ">=0.13.0,<0.16.0"`. That
range is a claim, and a claim nobody re-checks is a claim that quietly stops
being true. The matrix runs the full assertion set against every version where
the published install path actually works (`0.14.4`, `0.15.1`), on every push
and weekly, so upstream drift turns this red here rather than in someone's
editor. `0.13.0` is excluded, for a measured reason — see below.

### What it asserts (49 assertions per version)

| Group | Proves |
|---|---|
| `PIN-*` | The release asset downloads from the pinned URL, and matches the pinned sha256 — both checked **before** anything is installed, so a 404, a network failure, or a digest mismatch fails closed with no side effect and still writes its evidence row. The installed manifest declares the pinned extension version, and the spec-kit and `adr` versions are exactly the pinned ones. Every later row is only as trustworthy as these. |
| `INS-*` | The extension installs, and all three commands render for the agent. |
| `HOOK-*` | The `after_plan` hook is registered, targets the read-only `check` command, and is `optional: true`. `HOOK-4` asserts **no** hook targets the writing `draft` command. |
| `PKG-*` | The consumer receives no test suite, tsconfig, package.json, or node_modules; the four scripts arrive (`PKG-p-*`) and arrive executable (`PKG-x-*`); the rendered command points at the installed script path. |
| `BEH-*` | Against this repository's real corpus: `context` names ADR `0001` for `src/payments/**` and the proposed ARB record `0015` for `src/orders/**`; `check` emits its marker and states when routing did not run. |
| `INV-*` | The path the rendered command names is executed **the way the agent is told to execute it** — directly, not through `sh`. See below for why this is a separate group. |
| `MUT-*` | `check` and `context` leave the consuming project byte-identical, and this repository unmodified. |
| `FC-*` | Four consumer-facing failure modes exit non-zero, name what is missing, and — for both `draft` paths — **write no record before failing**. |

`BEH-*` deliberately asserts specific record ids rather than counts. "0 decisions
govern this" and "I could not see the corpus" render as the same string, so a
count-based assertion would pass in exactly the case worth catching.

### The 0.13.0 exclusion, and why `INV-*` exists

Switching to the release asset surfaced a real upstream defect that the previous
`--dev` install could not see, because copying a directory preserves modes and
extracting a zip does not.

spec-kit 0.13.0 installs a zip via `zf.extractall()` and never restores Unix
modes, so a bundled `*.sh` lands non-executable (`-rw-r--r--`). 0.14.4 fixed it
by calling `ensure_executable_scripts` after extraction — its source comment
names exactly this failure.

The tempting conclusion is that the mode is cosmetic, because the command
frontmatter reads `scripts: sh: scripts/check.sh`. That conclusion is wrong, and
it is worth recording why, because this validation asserted it before checking
it. That `sh:` key selects the POSIX-shell **variant** of the script (as opposed
to `ps`); it is not an instruction to invoke through the `sh` binary. What the
agent actually receives is the body of the command, where `Run {SCRIPT}` renders
as a bare path:

```
2. Run `.specify/extensions/adrkit/scripts/check.sh` with those paths.
```

Followed literally on 0.13.0, that is:

```
/bin/bash: ./.specify/extensions/adrkit/scripts/check.sh: Permission denied
```

So on 0.13.0 the published install is broken for the instruction the agent is
given, and this repository no longer claims otherwise. The matrix covers
`0.14.4` and `0.15.1`; the manifest's `>=0.13.0` lower bound was verified under
`--dev`, where source modes carry, and does not hold for the published asset.
Narrowing that claim is upstream's call, not this repository's — recorded here,
not silently worked around.

`INV-*` is the assertion group that would have caught this. Every `BEH-*` runs
the scripts as `sh <path>`, which succeeds whether or not the file is
executable — a harness more forgiving than the contract it is checking. `INV-*`
runs the rendered path the way the rendered command says to run it, so an
install a consumer could not use now fails here.

### Status boundary

This is **rung-2 reference verification**: a maintainer-owned, isolated
repository, not an external adopter. It does not make the extension
`externally validated` (rung 3), and it does not make it `released`.

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

Because `c5dc677f` regenerated `packages/ci/dist/queue-action.js`, this
boundary was **re-probed directly against the new bundle** rather than carried
forward from the previous pin. The reason is stronger here than at the last
repin: across `bbe63e01` → `c3dff3a7` no Action source changed at all and the
bundle moved solely because bundled dependencies did, so the probe was guarding
against an invisible dependency-level change. Across `c3dff3a7` → `c5dc677f`
the Action source itself changed — `action.ts` now performs a marker pre-scan
inside `runAction`, and `index.ts` and `changed-files.ts` moved with it. None of
that is on the `queue` entrypoint's path (`queue-action-entrypoint.ts` is
unchanged, and the corpus-load `catch` still precedes `getOctokit`), but "the
entrypoint file is unchanged" is a claim about one file in a 1.7 MB bundle, so
it was checked by execution rather than accepted by reading.

Running the old and new committed bundles side by side against the real
checked-in fixture produces byte-identical output:

```console
$ env -i PATH="$PATH" HOME="$HOME" \
    INPUT_DIR="fixtures/fail-closed-invalid-corpus-dir" \
    GITHUB_REPOSITORY="mbeacom/adrkit-t018-dogfood" \
    GITHUB_API_URL="https://127.0.0.1:9" \
    GITHUB_TOKEN="bogus-token-not-a-real-credential" \
    INPUT_TOKEN="bogus-token-not-a-real-credential" \
    bun packages/ci/dist/queue-action.js; echo "EXIT CODE: $?"
::error::adrkit queue: could not load the ADR corpus at 'fixtures/fail-closed-invalid-corpus-dir': ENOTDIR: not a directory, scandir '<abs path>/fixtures/fail-closed-invalid-corpus-dir'
EXIT CODE: 1
```

Both bundles: exit `1`, identical stdout, and zero bytes on stderr. Re-run at
the `c3dff3a7` → `c5dc677f` repin with both bundles invoked from the same
working directory, their stdout was byte-identical (SHA-256
`1983356a…` at both). That digest is **path-dependent** — the absolute fixture
path appears inside the `ENOTDIR` message — so it is not comparable to the
`e99d2b83…` recorded for the earlier repin's probe, which ran from a different
directory. The claim it supports is equality between the two bundles at one
path, which is the claim being made.

Two details of that invocation are load-bearing:

- **`GITHUB_API_URL` points at a dead port** (`https://127.0.0.1:9`), and the
  token is deliberately bogus. Had the Action attempted *any* GitHub API call
  before failing, it would have surfaced as a connection or auth error instead
  of the corpus-load message. Getting the corpus-load message means execution
  never reached a network call — which is the actual claim being made.
- **`env -i`** clears the ambient environment, so no inherited `GITHUB_TOKEN`
  or proxy setting from the developer's shell could quietly make a real request
  succeed.

One correction to earlier write-ups of this probe: the `::error::` line is
written to **stdout**, not stderr. Both bundles produced zero bytes on stderr.
That does not affect the conclusion (the workflow asserts on step outcome and
issue mutation, not on stream) but the earlier description was inaccurate and
is fixed here rather than propagated.

The Action exits non-zero immediately (no network round trip's worth of
latency) with a message tied precisely to the corpus-load `catch` block,
confirming the failure occurs at that boundary and not, e.g., from an
auth/network error further down. That is an observation, not an inference from
an unchanged file.

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
   `mbeacom/adrkit/packages/ci/queue@e3155eaaf200c9ed7f3ea572d91f0bd4c11c35cc`
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

> **This table is evidence about the `c3dff3a7` pin, not the current one.** The
> repository now pins `e3155eaa` (adrkit `v0.7.0`). The workflow was last
> re-dispatched live at `c5dc677f` (adrkit `v0.6.0`) — run
> [`31553919618`](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/31553919618),
> conclusion `success`, with the same `outcome=failure`, empty `issue-number`,
> and byte-identical before/after snapshots (`7b725a02…`). See
> [Live evidence at this pin](#live-evidence-at-this-pin). **It has not been
> re-dispatched at `e3155eaa`**; the queue Action's `action.yml` is unchanged and
> `packages/core`'s queue logic moved only in JSDoc across that repin, so the
> `c5dc677f` result is carried forward rather than reproduced — see
> [What was not exercised at this pin](#what-was-not-exercised-at-this-pin-e3155eaa).
> The table below is retained as the `c3dff3a7` record.

| Field | Expected | Observed |
|-------|----------|----------|
| Pinned adrkit ref | `c3dff3a7a9c3df44233809423eb59a3505fcf6f5` | `c3dff3a7a9c3df44233809423eb59a3505fcf6f5` (confirmed via the run's own action-download log line: `Download action repository 'mbeacom/adrkit@c3dff3a7a9c3df44233809423eb59a3505fcf6f5'`) |
| Fixture | `fixtures/fail-closed-invalid-corpus-dir` (plain file, not a directory) | (unchanged) |
| `queue` step outcome | `failure` | `failure` |
| `queue` step `issue-number` output | (empty/unset) | (empty/unset) |
| Issue mutation | zero (before/after snapshot hashes equal) | zero — hashes equal, issue count unchanged at 1 |
| Workflow conclusion | `success` (workflow succeeds *because* the expected failure + zero-write proof both held) | `success` |

**Live run:** `31288359485` —
<https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/31288359485>
— dispatched against branch `mbeacom-repin-queue-action-v0-4-0` at commit
`3bfe15a` (the repin to `c3dff3a7`) — conclusion: `success`. The `queue`
step's own error output was:

```
##[error]adrkit queue: could not load the ADR corpus at 'fixtures/fail-closed-invalid-corpus-dir': ENOTDIR: not a directory, scandir '/home/runner/work/adrkit-t018-dogfood/adrkit-t018-dogfood/fixtures/fail-closed-invalid-corpus-dir'
```

Before/after snapshot SHA-256 (canonicalized):
`91fd7b28452f1502708ae3fde66e91bb7fc4028dcf32c6827e975b1bb9239004` for both
before and after (equal ⇒ zero mutation across `1` issue(s), the same `#3`
managed queue issue, `updatedAt` unchanged).

That digest differs from the `a6eef1ed…` recorded under the two previous pins,
and the difference is fully accounted for: the snapshot includes each issue's
`updatedAt` and `bodySha256`, and issue `#3` was legitimately re-rendered by
the `arb-queue.yml` dispatch minutes earlier (see
[Live dispatch under the `c3dff3a7` pin](#live-dispatch-under-the-c3dff3a7-pin)).
What the fail-closed proof asserts is that before and after are equal **to each
other within this run** — which they are. A digest that matched the old runs
would in fact have been the surprising result.

Note that this dispatch was made **against the pull request branch, before
merge**, using `gh workflow run --ref mbeacom-repin-queue-action-v0-4-0`. A
`workflow_dispatch` workflow must exist on the default branch to be
dispatchable at all — both of these do — but the run then executes the
workflow file *from the dispatched ref*, which is why it picked up the new pin
while `main` still carried `bbe63e01`. That is what made it possible to
produce live consumer-facing evidence for `c3dff3a7` as a precondition of the
repin rather than a follow-up to it.

**Previous dispatch under the `bbe63e01` pin (superseded, retained for
provenance):** run `30169579874` —
<https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/30169579874>
— branch `mbeacom-repin-adrkit-bbe63e01` at commit `8d43f4b` (PR
[#8](https://github.com/mbeacom/adrkit-t018-dogfood/pull/8)) — conclusion:
`success`, with the byte-identical error message and snapshot digest
`a6eef1ed…`.

**Dispatch under the `896391cc` pin (superseded, retained for
provenance):** run `30159430259` —
<https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/30159430259>
— branch `mbeacom-supreme-disco` (PR #7, the repin to `896391cc`) —
conclusion: `success`, with the byte-identical error message and the same
snapshot digest `a6eef1ed…`. The digest matching across those two pins was a
real continuity check, not a coincidence: it meant issue `#3`'s body,
`updatedAt`, state and title were untouched by both runs.

The error message is byte-identical to the one produced under all three
previous pins. Between `efef89b5` and `896391cc` that was a corollary of an
unchanged `packages/ci/`, so the fail-closed boundary was literally the same
compiled code. **That argument applies to neither of the last two pins** —
`bbe63e01` regenerated `dist/queue-action.js` from changed source,
`c3dff3a7` regenerated it again from changed *dependencies*, and `c5dc677f`
regenerated it once more from changed source — which is why the boundary was
re-probed against each new bundle directly rather than assumed. For `c3dff3a7`
that was done first locally and then live via run `31288359485` above; for
`c5dc677f` it was done locally and then live via run `31553919618`. The message
and exit code turned out to be identical every time, but that is a measured
result rather than an inference from an unchanged file.

**Earliest dispatch (superseded, retained for provenance):** run
`29920390292` —
<https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/29920390292>
— commit `2d7f6063b1d0d93f453138cf24a2bcd81aa287a6` (the `main` merge commit
for PR #6) — conclusion: `success`, using the oldest pin
`efef89b5d747ca175a1947f1ce2f4296dab54fa3`. Its before/after snapshot
SHA-256 was `9b15bda8a202ec4bb9539f920ceb47f96b2844a4b46232c2a3a4465e579802d9`
and its uploaded evidence artifact SHA-256 was
`15e3c042fbda394a579de560756d51ea1ca075031df5d1b458ffd2f8006cb966`.
Runner: `ubuntu-24.04` (image `20260714.240.1`, Actions runner `2.336.0`);
`GITHUB_TOKEN` permissions were exactly `contents: read`, `issues: write`,
`metadata: read` with secret source `Actions` (no PAT or
repository/organization secret involved). Action versions:
`actions/checkout@v4`, `actions/upload-artifact@v4`. Its snapshot digest
differs from the two later runs only because issue `#3`'s body (and therefore
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
| `adr --help` / `--version` | Added at `bbe63e01` (resolved defect 4). At that pin `adr --version` printed `0.2.0`; it printed `0.4.0` at `c3dff3a7` and prints `0.6.0` at the current `c5dc677f` pin. Recorded by `scripts/validate-queue.sh` on every run, without asserting the literal string. |
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

## Provenance note on the dispatch commits

The live dispatches recorded in this README were run twice, against two
different commits on branch `mbeacom-repin-queue-action-v0-4-0`, and both sets
are recorded rather than the inconvenient one being dropped.

The first set — `31288355812`, `31288359485` and `31288387942` — ran against
`3bfe15a96ecbc2015e6cd599910d4ee1f34cd3a5`. That commit carried a placeholder
message and was rewritten while finishing this README, so `3bfe15a` is no
longer an ancestor of the branch and those run ids point at a commit history no
longer contains.

Rather than leave the evidence attached to an unreachable commit, both
workflows were **re-dispatched from the final commit**
`ce63d8dd5c24f6ab2215ac44643f4af1fc7f356c`:

| Run | Workflow | Head | Conclusion | Resolved Action ref |
|-----|----------|------|------------|---------------------|
| [`31288615543`](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/31288615543) | `arb-queue.yml` | `ce63d8d` | `success` | `mbeacom/adrkit@c3dff3a7…` |
| [`31288621287`](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/31288621287) | `arb-queue-fail-closed.yml` | `ce63d8d` | `success` | `mbeacom/adrkit@c3dff3a7…` |

Both reproduced the earlier results exactly. The fail-closed run reported
before/after snapshot SHA-256
`91fd7b28452f1502708ae3fde66e91bb7fc4028dcf32c6827e975b1bb9239004` — equal, and
equal to the `3bfe15a` run — with `assert-no-issue-mutation OK: zero issue
mutations across 1 issue(s)`. The managed-issue run left issue `#3`'s body at
`28590cce9abbed8cafd320f264c5f6283757ffac8c28035d65a75caa77dd65ad` and its
`updatedAt` at `2026-08-09T01:29:11Z` — both unchanged by a run that executed at
`01:36`, which is the same-day idempotent no-op described above, now
independently reproduced at the final commit.

The rewrite touched `README.md` only —
`git diff 3bfe15a ce63d8d -- .github/workflows scripts/` is empty — so the two
sets of runs executed identical pins and identical assertions, which is
consistent with them producing identical evidence.

---

## Re-validation against `e3155eaa` (adrkit v0.7.0) (2026-08-12)

The repin from `c5dc677f` to `e3155eaa` is a single-release step, and unlike the
previous one it changes Action source in the surface this repository observes
most directly: how the governance Action identifies its own PR comment.

**Scope caveat, stated up front.** Everything recorded in this section was
observed **locally**, by running the four validation scripts against the new pin
on this branch. The two `workflow_dispatch` workflows (`arb-queue.yml`,
`arb-queue-fail-closed.yml`) and the live `adr.yml` comment behavior are **not**
re-run here and are therefore **not** claimed at this pin — see
[What was not exercised at this pin](#what-was-not-exercised-at-this-pin-e3155eaa)
below, which is the part of this section a reader should weigh most.

### What changed across `c5dc677f` → `e3155eaa`

53 files changed upstream. Of the publishable packages, the material change is
in the CI Action, from the GitHub API comparison (**inferred from the diff**, not
from reading the shipped bundle):

| File | Δ | What it is |
|------|---|------------|
| `packages/ci/src/github.ts` | +203 −36 | Comment identification rewritten (adrkit ADR-0026) |
| `packages/ci/src/index.ts` | +5 −9 | Stops inferring bot identity from token equality |
| `packages/ci/src/comment.ts` | +8 −0 | Requires the marker to lead the rendered body |
| `packages/ci/src/action.ts` | +1 −1 | Threads the logger into `upsertMarkedComment` |
| `packages/ci/dist/index.js` | +71 −24 | Rebundle of the above |
| `packages/mcp/src/server.ts` | +1 −1 | `SERVER_INFO.version` `0.6.0` → `0.7.0` |
| `packages/core/src/queue/types.ts` | +7 −0 | JSDoc only: `QueueReport.totalItems` now carries an external-consumer obligation |

The behavior adrkit ADR-0026 describes is that a token whose login is unknowable
— the default `GITHUB_TOKEN` is one — claims its prior comment by "author is a
bot" plus the marker leading the body, so a push to an open PR **updates** the
existing governing-decisions comment instead of adding a new one
([mbeacom/adrkit#107](https://github.com/mbeacom/adrkit/issues/107)). That
description is taken from the upstream record and the diff. **It was not
observed here** — see the scope note below.

**The MCP change is a version string and nothing else.** `packages/mcp/src` is a
one-line diff bumping `SERVER_INFO.version`; there is no behavioral change to
the four tools across this repin. That is a diff-level claim, and it is
corroborated by execution: `MCP-12` (corpus fingerprint) and the governance
resolution assertions `MCP-7`/`MCP-8` return the same values at `0.7.0` as they
did at `0.6.0`.

### What was re-run, and what it reported

All four validation scripts were run locally at the new pin. Every one passed:

| Script | Result at `e3155eaa` |
|--------|----------------------|
| `scripts/validate-queue.sh` | Pass. `adr --version` reports `0.7.0`; `adr lint` reports `checked 15 records, 0 errors, 0 warnings`; all three routing tiers and the `overdue`/`due`/`within-sla` triple reproduce at `--as-of 2026-07-21`. |
| `scripts/validate-mcp.sh` | Pass, 56 assertions. `sha512` matched, `src/` byte-identical to `packages/mcp/src` at the pin, 28 config assertions, 28 stdio JSON-RPC surface assertions, corpus unchanged after the run. |
| `scripts/validate-markers.sh` | Pass, 26 assertions across 8 fixtures. |
| `scripts/validate-badge-reports.sh` | Pass, 5 assertions (new in this change — see [Corpus badges](#corpus-badges)). |

The `QueueReport` reproduced with the same `corpusFingerprint`
(`1664c5af7cb42038eb6087ab980499339e28a9f1d1be7e5a9095ce52414bd936`) it had at
`c5dc677f`, which is the expected outcome given no corpus file changed.

### `corpusFingerprint` is cwd-dependent

Found while building the badge-report check, and worth recording because it
bears on how a consumer may use the field. `corpusFingerprint` is not a function
of corpus content alone: it changes with the **process working directory**, for
byte-identical files. Observed at this pin, same 15 records, same absolute
`--dir`, only `cd` varying:

```console
$ cd <repo root>   && adr queue --dir <root>/docs/adr --as-of 2026-07-21 --format json | jq -r .corpusFingerprint
1664c5af7cb42038eb6087ab980499339e28a9f1d1be7e5a9095ce52414bd936
$ cd <repo>/scripts && adr queue --dir <root>/docs/adr --as-of 2026-07-21 --format json | jq -r .corpusFingerprint
3e00b6543b6ebc55a085c7a5d3d1e15086358991030445752948af22437d2b79
$ cd /tmp          && adr queue --dir <root>/docs/adr --as-of 2026-07-21 --format json | jq -r .corpusFingerprint
66bf9f30c09e34d92da1f7a551f6ec954eb8f57e3bc1b7565dd48964e92415f8
```

The mechanism is visible in the same reports: `sourcePath` is resolved relative
to the process cwd rather than to `--dir`, so from `/tmp` the records are
reported at `../../Users/.../docs/adr/0014-….md`, and the fingerprint is
computed over those paths. A byte-identical corpus copied to a different
location fingerprints differently for the same reason.

This is **not** a regression at this pin — it was not compared against
`c5dc677f`, so it is stated as a property observed at `e3155eaa`, not as
something this repin introduced. It is recorded rather than worked around
because it limits what the field can be used for: it identifies *this corpus as
laid out here*, not the corpus content, so comparing fingerprints across two
checkouts at different paths, or across a CI job and a developer machine with
different working directories, can report a difference where none exists. This
repository's own `MCP-12` assertion compares fingerprints only within a single
run from a fixed cwd, so it is unaffected;
`scripts/validate-badge-reports.sh` `cd`s to the repository root before
regenerating for exactly this reason.

### What was *not* exercised at this pin (`e3155eaa`)

Stated plainly, because the headline upstream change is precisely the thing not
verified here:

- **The ADR-0026 comment-identity fix was not observed.** `.github/workflows/adr.yml`
  tracks `packages/ci@main` and is exercised only by a real pull request, so
  whether a second push now updates the existing comment rather than adding a new
  one is, in this document, a claim read off the upstream ADR and diff. The
  distinguishing observation requires two pushes to one open PR and an inspection
  of the resulting comment count; that has not been done at the time of writing.
- **Neither `workflow_dispatch` workflow was re-dispatched.** The managed queue
  issue (`arb-queue.yml`) and the fail-closed boundary
  (`arb-queue-fail-closed.yml`) carry the new pin in their `uses:` line, but the
  live evidence recorded elsewhere in this README was produced under
  `c5dc677f`. The queue Action's `action.yml` is unchanged across this repin and
  `packages/core`'s queue logic changed only in JSDoc, so carrying that evidence
  forward is *reasonable* — but it is carried forward, not reproduced.
- **No agent tool invocation was observed**, at this pin or any other. The MCP
  configuration remains prepared-and-validated only; see
  [What this does not establish](#what-this-does-not-establish).

---

## Corpus badges

The two badges at the top of this README are adrkit's own recipe
([ADR-0025](https://github.com/mbeacom/adrkit/blob/e3155eaaf200c9ed7f3ea572d91f0bd4c11c35cc/docs/adr/0025-ship-badges-as-recipes-over-existing-output.md),
shipped in `v0.7.0`, documented at [adrkit.dev/badges](https://adrkit.dev/badges/)).
adrkit ships no badge service and no `adr badge` command: each badge is
shields.io rendering one integer out of JSON the CLI already emits and the
adopter serves.

**They describe this repository's corpus, not adrkit's.** adrkit's own README
carries the same two badges pointed at `https://adrkit.dev/lint.json` and
`/queue.json`. Reusing those URLs here would have rendered adrkit's numbers on
this repository's front page — a claim about the wrong corpus, and the sort of
thing this repository is supposed to catch rather than commit. The badges here
read from files this repository publishes:

| Badge | Source | Field | Value at this pin |
|-------|--------|-------|-------------------|
| `ADRs` | [`.adrkit/lint.json`](.adrkit/lint.json) | `$.checked` | `15` |
| `ARB queue` | [`.adrkit/queue.json`](.adrkit/queue.json) | `$.totalItems` | `3` |

`$.checked` counts every record whatever its status — a superseded decision is
still a decision that was recorded. `$.totalItems` counts records whose status
is `proposed`, so it is queue **depth**, not deadline pressure.

### Why the reports are committed rather than regenerated by a bot

The published recipe adds a workflow holding `contents: write` that regenerates
both files and pushes them to the default branch whenever `docs/adr/**` changes.
This repository deliberately does not do that, and the reason is specific to
what this corpus is: `docs/adr/0001`–`0015` are frozen fixtures with
deterministic expectations asserted by `scripts/assert-queue-report.ts` against a
fixed `--as-of`. A report that needs regenerating here means someone changed the
corpus on purpose — which already obliges them to update those assertions in the
same change.

So the trade the upstream recipe makes is inverted. Automating the refresh would
add a token that can push to `main` in order to silently repair a state that
should stop the build. Committing the files and asserting they are current is
strictly stronger: `scripts/validate-badge-reports.sh` regenerates both at the
pinned commit and requires them to be byte-identical, so a stale badge source
**fails CI** instead of being quietly corrected after it has already rendered a
false number.

### One deliberate divergence from the published recipe

The recipe regenerates with `adr queue`'s default `--as-of`, which is today.
That would make the committed file differ from a regeneration every day and turn
the check into noise, so this repository pins the same fixed `--as-of
2026-07-21` that `scripts/validate-queue.sh` uses — cross-checked mechanically
between the two scripts, since a silent divergence would make the published
report disagree with this repository's own queue evidence.

That is sound **for the field the badge reads**, and this was verified rather
than assumed. Queue depth is selected by `status: proposed`, so it does not move
with the calendar:

```console
$ for d in 2026-01-01 2026-07-21 2027-12-31; do adr queue --dir docs/adr --as-of $d --format json \
    | jq -c '{totalItems, states: [.items[].slaState]}'; done
{"totalItems":3,"states":["within-sla","within-sla","within-sla"]}
{"totalItems":3,"states":["overdue","due","within-sla"]}
{"totalItems":3,"states":["overdue","overdue","overdue"]}
```

`totalItems` is `3` in all three; `slaState` moves in all three. The consequence
is stated rather than hidden: **the `slaState`, `deadlineDate`, and SLA fields
inside the committed `.adrkit/queue.json` are true as of `2026-07-21` and are not
a live view.** Nothing renders them — the badge dereferences `$.totalItems`
only — but anyone reading the file directly should read them as pinned evidence,
the same way the rest of this repository's queue evidence is pinned.

### What the check asserts, and that it can fail

`scripts/validate-badge-reports.sh` makes 5 assertions: both reports match a
regeneration at the pinned commit (`CURRENT-lint`, `CURRENT-queue`), both fields
the badge URLs dereference are integers (`BADGE-checked`, `BADGE-totalItems`),
and the published lint report carries no findings (`BADGE-clean`). The integer
checks exist because shields renders a missing key as `no result` and a
malformed one as its text, which reads to a visitor as a bug in the tooling
rather than as a broken file.

Every one of the five was **observed failing** before being credited as
coverage, by perturbing a throwaway copy — the same standard the marker
assertions are held to:

| Perturbation | Assertion(s) that failed |
|---|---|
| `.checked` bumped to `16` | `CURRENT-lint` |
| `.totalItems` set to `0` | `CURRENT-queue` |
| `.checked` set to the string `"15"` | `CURRENT-lint`, `BADGE-checked` |
| `.checked` set to `true` | `CURRENT-lint`, `BADGE-checked` |
| `lint.json` deleted | `CURRENT-lint`, `BADGE-checked`, `BADGE-clean` |
| `queue.json` truncated mid-document | `CURRENT-queue`, `BADGE-totalItems` |
| a finding injected into `lint.json` | `CURRENT-lint`, `BADGE-clean` |

The boolean case is why the type test is `type == "number"` rather than a
truthiness check, and the deleted-file case is why the readers are guarded: an
earlier revision aborted under `set -e` on the missing file and skipped the two
assertions after it, which would have reported fewer failures than were actually
present.

### What the badges disclose

A `dynamic/json` badge asks shields.io to fetch the URL, so every render sends
this repository's owner, name, and branch to a third party. The published
`.adrkit/queue.json` also carries each queued record's `routingTargets`
(`@mbeacom`, `@octocat`, `team:platform-eng`, `team:arb`). Those are already
public in this public repository's corpus and are fixture values, so the
disclosure is nil here — but it is the thing to check before copying this recipe
into a repository whose `deciders` are not public handles.

---

## Re-validation against `c5dc677f` (adrkit v0.6.0) (2026-08-11)

The repin from `c3dff3a7` to `c5dc677f` skips `v0.5.0` and lands directly on
`v0.6.0`, so this run had to account for two upstream releases at once. It was
gated on re-validating this repository against the new commit *before* changing
any pin. This section records what that run did and what it found.

**Scope caveat, stated up front.** Most of what follows was observed
**locally**: both pins built from source, their committed bundles executed, and
both validation scripts run end to end. The two `workflow_dispatch` workflows
(`arb-queue.yml`, `arb-queue-fail-closed.yml`) were then dispatched live against
the repin branch before the PR was merged, and the PR itself exercised the
`adr.yml` governance Action at `@main`. Those live results are recorded under
[Live evidence at this pin](#live-evidence-at-this-pin) below.

### Method

Both commits were fetched at their exact SHAs into separate temporary
directories, built with `bun install --frozen-lockfile && bun run build`, and
run side by side against this repository's real corpus. Unlike the `c3dff3a7`
re-validation — which drove the committed bundles because the Action *source*
was provably identical and only the bundle had moved — this range changes
source, so both the built CLI and the committed bundles were exercised.

1. Resolved `v0.6.0` through the GitHub API and dereferenced the annotated tag,
   rather than trusting the tag name (see
   [Pinned adrkit commit](#pinned-adrkit-commit)).
2. `diff -rq` across `packages/ci/src` at both pins, to establish exactly what
   moved, and SHA-256 of `packages/ci/queue/action.yml` at both.
3. Re-derived the recorded digests (QueueReport JSON, Markdown, corpus
   fingerprint, `lint`, `graph --format json`) at both pins.
4. Diffed `check --json` and `explain --json` at both pins against this
   repository's own governed file, `src/payments/api/handler.ts`.
5. Re-probed the fail-closed boundary against both committed bundles with an
   unreachable `GITHUB_API_URL` and a bogus token under `env -i`.
6. Re-ran the skipped-file falsification probe, to confirm
   `scripts/assert-queue-report.ts` still *fails* against a corpus it should
   reject rather than merely passing against this one.
7. Only then were the pins changed, and both `./scripts/validate-queue.sh` and
   `./scripts/validate-mcp.sh` re-run end-to-end at the new pin.

### Outputs are byte-identical across the pins

Re-derived at both pins against this repository's real 15-record corpus. The
digests match the values recorded elsewhere in this README, which is itself the
check — they were not copied forward:

| Artifact | `c3dff3a7` | `c5dc677f` |
|----------|------------|------------|
| QueueReport JSON (SHA-256) | `716e21b7…` | `716e21b7…` |
| Rendered Markdown (SHA-256) | `fbcd4d5f…` | `fbcd4d5f…` |
| Corpus fingerprint | `1664c5af…` | `1664c5af…` |
| `adr graph --format json` | identical | identical |
| `adr lint` | 15 records, 0 errors, 0 warnings | 15 records, 0 errors, 0 warnings |
| `adr --version` | `0.4.0` | `0.6.0` |
| `assert-queue-report.ts` | 13/13 pass | 13/13 pass |
| Fail-closed stdout | identical (`1983356a…`) | identical (`1983356a…`) |

The path-dependence caveat recorded for the previous re-validation applies
unchanged and was honored here: `716e21b7…` reproduces only when invoked with
the **relative** `--dir docs/adr` from the repository root, as
`scripts/validate-queue.sh` does.

### Two JSON surfaces widened, and one of them moved a key

This is the substantive finding of the repin, and the two widenings are not
equivalent in kind.

`adr check --json` gained a `markerScan` object. Observed by diffing the two
pins' output for `src/payments/api/handler.ts` — the only difference is an
addition:

```json
"markerScan": {
  "totalCandidates": 1,
  "limit": 3000,
  "counts": {
    "scanned": 1, "absent": 0, "unreadable": 0,
    "out-of-tree": 0, "truncated": 0, "skipped": 0
  },
  "absentPaths": [], "unreadablePaths": [],
  "outOfTreePaths": [], "truncatedPaths": [], "skippedPaths": []
}
```

`adr explain --json` gained `scannedBytes` and `fileBytes`, and **these were
inserted rather than appended** — they land between `windowBytes` and
`truncated`:

```json
"markers": {
  "state": "scanned",
  "windowBytes": 8192,
  "scannedBytes": 581,
  "fileBytes": 581,
  "truncated": false,
  "declared": []
}
```

adrkit's own changelog flags this positional insertion, and it is worth
restating as a consumer-facing distinction: a consumer reading fields by name is
unaffected, but one golden-diffing the `markers` block sees a positional change
rather than a clean append. Nothing in this repository golden-diffs `explain`,
so nothing here broke.

The new numbers were checked against an independent measurement rather than
taken at face value: `src/payments/api/handler.ts` is 581 bytes by `wc -c`, and
both `scannedBytes` and `fileBytes` report `581`. The file is well under the
8192-byte window, so `truncated: false` and the two values coincide — meaning
**this corpus does not exercise the interesting case** the field was added for.
The over-window case, where `fileBytes - scannedBytes` is a non-zero unscanned
remainder, is not measured anywhere in this repository, even though truncation
itself does occur on the Action path (see below).

`adr check`'s human output also gained one line:

```
marker scan: 1 scanned, 0 absent, 0 unreadable, 0 out-of-tree, 0 truncated, 0 skipped
```

### Live evidence at this pin

All seven workflows ran green on the repin PR
([#14](https://github.com/mbeacom/adrkit-t018-dogfood/pull/14), branch
`mbeacom-upgrade-adrkit-v0-6-0` at commit `7c9ad11`). The two
`workflow_dispatch` workflows were dispatched against the branch **before
merge**, as at the previous repin, so the live evidence is a precondition of the
repin rather than a follow-up to it.

| Run | Workflow | Trigger | Conclusion |
|---|---|---|---|
| [`31553913041`](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/31553913041) | `arb-queue.yml` | `workflow_dispatch` | `success` |
| [`31553919618`](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/31553919618) | `arb-queue-fail-closed.yml` | `workflow_dispatch` | `success` |
| [`31553878200`](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/31553878200) | `adr.yml` | `pull_request` | `success` |
| [`31553878197`](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/31553878197) | `queue-validation.yml` | `pull_request` | `success` |
| [`31553878172`](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/31553878172) | `mcp-validation.yml` | `pull_request` | `success` |
| [`31553878229`](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/31553878229) | `spec-kit-extension.yml` | `pull_request` | `success` |
| [`31553878201`](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/31553878201) | `copilot-setup-steps.yml` | `pull_request` | `success` |

The marker fixtures landed in a later commit on the same branch (`618237c`),
which added an eighth workflow and re-ran the rest. All green, and the two runs
that matter for the marker work are:

| Run | Workflow | Trigger | Conclusion |
|---|---|---|---|
| [`31555185437`](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/31555185437) | `marker-validation.yml` | `pull_request` | `success` — 26 assertions, then the self-test pass. That run predates the review fixes below, so its self-test covered 13 perturbations rather than the current 17. |
| [`31555185462`](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/31555185462) | `adr.yml` | `pull_request` | `success` — rendered the `declared by` edges quoted below |

Both dispatched runs resolved the Action at the new pin, confirmed by their own
download log line rather than by the workflow file:

```
Download action repository 'mbeacom/adrkit@c5dc677f55c492056184c01252d9f812919c80f9' (SHA:c5dc677f55c492056184c01252d9f812919c80f9)
```

**Managed issue.** Every self-verification assertion passed, including
exhaustive marker discovery (`exactly one issue carries the managed-queue marker
across OPEN+CLOSED issues (found 1: 3)`), the marker's exact first-line
position, the `ADR ARB Queue` title, `open` state, a row for each of `0013` /
`0014` / `0015` with its fixed tier label, `0015`'s `3/3` full quorum, and the
absence of a `## Corpus Findings` section. All three rows now render `overdue`,
which is correct and not a repin effect: this workflow uses the Action's default
`--as-of` of *today*, and every fixed deadline in the corpus is in the past.

**Fail-closed.** The Action failed at the corpus-load boundary with the same
`ENOTDIR` message observed locally, `outcome=failure`, an empty `issue-number`
output, and before/after issue snapshots byte-for-byte identical at
`7b725a02…` across `1` issue. That digest differs from the `91fd7b28…` recorded
at the previous pin for the expected reason — the snapshot includes each issue's
`updatedAt` and `bodySha256`, and issue `#3` was legitimately re-rendered by the
`arb-queue.yml` dispatch minutes earlier. What the proof asserts is that before
and after are equal **to each other within this run**, which they are.

**The governance Action scanned markers for the first time in this repository.**
`adr.yml` tracks `packages/ci@main`, so the PR picked up the v0.5.0/v0.6.0
marker scanning immediately, and logged:

```
adrkit: marker scan: 12 scanned, 0 absent, 0 unreadable, 0 out-of-tree, 3 truncated, 0 skipped.
```

This is the observation that corrected the coverage claim below: truncation
*is* reached here, on the Action path, even though the CLI path against the
governed file never truncates. The PR comment itself read `No governing
decisions for the changed files` — correct, since the repin PR touches no path
under `src/payments/**` — so no `declared by` edge was rendered and the marker
scan changed nothing about the outcome, which is exactly the "markers never
influence exit status" property v0.5.0 claims.

### Marker coverage was the gap this repin opened, and it is now closed

The list below is what this repository could *not* reach when the repin landed.
It is retained as the record of that gap; each item now names what closed it.

- ~~**No file in this repository declares an `@adr` marker.**~~ Two now do, and
  they were chosen to cover both edge directions rather than to demonstrate the
  syntax twice. `src/payments/api/handler.ts` declares `0014`, which already
  reaches it by pattern — the *merge* case, where one decision carries both
  `via path:` and `declared by`. `src/platform/ledger-client.ts` declares
  `0005, 0015`, neither of which names `src/platform/**` in `affects` — the
  *marker-only* case, where the decision comes back with an **empty
  `firedMatchers`** and a populated `declaredBy`. That empty matcher list is the
  observable difference between "a record reached this file" and "this file
  reached a record", and it is the thing a pattern cannot express without the
  orders records claiming a directory they do not own.
- ~~**No dangling marker.**~~ `fixtures/markers/unresolvable.ts` carries both
  unresolvable forms and pins their deliberately different severities:
  `@adr 9999` is `dangling-marker` at **`warn`**, and `@adr payments:0012` is
  `marker-unresolvable` at **`info`**. The second is the sharper case — `0012`
  *does* exist in this corpus, so a log-qualified ref must not quietly bind to
  the local record of the same id just because the number matches.
- ~~**No truncated scan** … the non-zero unscanned remainder is not measured.~~
  `fixtures/markers/over-window.ts` is 23,156 bytes with its marker in the
  header. Observed: `truncated: true`, `fileBytes: 23156`, and
  `scannedBytes: 8133` — **59 bytes short of the 8192 window**, which is the
  line-boundary cut the v0.6.0 fields were added to expose, and the number that
  `min(fileBytes, windowBytes)` would have gotten wrong. The header marker still
  resolves, so truncation does not lose a declaration that was inside the
  window. `fileBytes` is cross-checked against `wc -c` rather than trusted from
  the tool that reported it.
- **Still not exercised: the 3,000-file marker cap.** The largest scan observed
  scan observed here is **23** candidate files (workflow run
  [`31555185462`](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/31555185462)),
  against a cap of 3,000. Nothing in this repository approaches it, and
  `skippedPaths` has never been non-empty.
- **Still not exercised: `absent`, `unreadable`, and `out-of-tree` scan states.**
  All three are asserted to be zero (`SCAN-4`), which pins that they do not fire
  spuriously — but a passing zero is not coverage of the state itself.
- **Still not independently verified: the `localeCompare` → code-unit sort fix.**
  Byte-identical output was observed in a single locale, which is consistent
  with the fix but does not test it. adrkit additionally scopes the fix itself,
  leaving `packages/core/src/affects/**` on `localeCompare`.

#### What is asserted, and how it was proven

[`scripts/validate-markers.sh`](scripts/validate-markers.sh) captures
`adr explain --json` per fixture plus one batch `adr check --json`, and delegates
every correctness decision to
[`scripts/assert-markers.mjs`](scripts/assert-markers.mjs) — the same split as
`validate-queue.sh` / `assert-queue-report.ts`. **26 assertions**, run in CI on
pull requests, on `main`, weekly, and on demand.

| Group | What is pinned |
|---|---|
| `POS-1`–`POS-9` | The merge case; marker-only governance with an empty `firedMatchers`; a pattern-only control on the same file whose `declaredBy` key must be **absent**, asserted via `Object.hasOwn` rather than by counting (a count cannot tell a missing key from an empty array, which is the whole byte-compatibility claim); status bucketing surviving an inbound declaration; the comma list; and the four accepted introducers that must work (`//`, block-comment `*`, markdown `<!--`, MDX `{/*`). |
| `NEG-1`–`NEG-4` | The marker-looking lines that must **not** declare: trailing, inside a string literal, mid-prose, `@adrkit/core` (no separator), six fenced examples across backtick/tilde/longer-fence/info-string forms, and the five source-language introducers that are not markdown's. |
| `FIND-1`–`FIND-4` | Dangling at `warn`, foreign-log at `info`, both still present in `markers.declared` (scanned, but unbound), neither producing a governance edge, and `adr check` **reporting the dangling finding while still exiting `0` with `ok: true`** — markers never influence exit status. |
| `TRUNC-1`–`TRUNC-5` | `truncated`, `scannedBytes < fileBytes`, `scannedBytes < windowBytes`, `fileBytes` against `wc -c`, and the header declaration surviving truncation. |
| `SCAN-1`–`SCAN-4` | The batch `markerScan` the CI Action consumes: candidate count, truncated count, the named truncated path, and the four states that must stay zero. |

Two deliberate choices in how these are written:

- **Negative cases are stated as "the declared set is exactly X", never "Y is
  absent."** An absence assertion passes trivially the moment the scanner stops
  finding anything at all. `NEG-1` additionally pins the *introducer of the
  declaring line*, not just the ref, because every decoy in that fixture names
  `0001` too — a ref-only assertion would still pass if the trailing marker were
  the one that resolved.
- **`TRUNC-3` asserts an inequality, not the literal `8133`.** The exact extent
  depends on where the fixture's line breaks land, and pinning the literal would
  make an unrelated edit to the padding look like an adrkit regression.

**22 of the 26 assertions were observed failing; the other four are named, with
reasons.** The first draft of this section claimed "every assertion was observed
failing" while shipping only 13 perturbations — an overclaim of exactly the kind
this document is supposed to catch, and it was caught in review rather than by
the harness. The claim is now computed by the harness itself rather than written
by hand:

```
Marker self-test OK: 17 perturbations falsified 22 of 26 assertions.
not falsified by construction (see the PERTURBATIONS header): TRUNC-3, TRUNC-4, SCAN-1, SCAN-4
```

`./scripts/validate-markers.sh --self-test` perturbs one fixture at a time in a
throwaway copy and requires every assertion it names to fail — failing the run if
the suite still passes (the assertions are vacuous), if any named id is missing
from the failure list (a different assertion is doing the work), or if the
perturbation did not modify its target at all. Some rows name several ids
because the properties are genuinely coupled: shrinking the over-window fixture
necessarily moves the truncation flag, the byte comparison, and the batch
truncated count together, and inventing three contrived fixtures to separate
them would be theatre.

The four that are **not** falsified, and why — each established by attempting it,
not by assuming:

| Assertion | Why a fixture edit cannot violate it |
|---|---|
| `TRUNC-3` | `scannedBytes < windowBytes` survives every edit to this fixture: shrinking it leaves `scannedBytes` equal to the whole file, still under 8192. Falsifying it needs a file whose byte 8192 is *exactly* a line terminator — a different, byte-tuned fixture rather than an edit to this one. |
| `TRUNC-4` | `fileBytes` against `wc -c` is a cross-check between two observations of the same file; any edit moves both consistently. Violating it would require adrkit to misreport the size, which is the thing being checked. |
| `SCAN-1` | The candidate count is set by the fixture list in the script, not by fixture content. |
| `SCAN-4` | Asserting a set of zeros would need a file deleted or made unreadable, which is a different perturbation kind. Retained to catch spurious firing, not credited as proven. |

One attempt is recorded because it failed instructively. `FIND-4` was first
falsified by corrupting a record so `adr check` would exit non-zero — and it did
not: `check`'s exit status depends on error findings against **changed records**,
and the paths passed to it are source files, so a broken corpus left `check` at
exit 0 while `explain` exited 1. `FIND-4` was rewritten to assert the stronger
and falsifiable property that the dangling finding is *reported* and the run
still exits 0 with `ok: true` — because the bare "exit 0" form would have been
satisfied by a run in which the dangling marker was never detected at all, which
is the opposite of the claim.

The self-test earned its keep three times, and all three are recorded because
they are the argument for having it:

1. `NEG-1` was first written against a hardcoded **line number** (`43`). It
   failed immediately on the real fixture — the declaration is on line 39 — and
   was rewritten to assert the declaring line's *content*. A positional
   assertion would have been both brittle and silent about which line resolved.
2. The `NEG-1` perturbation itself initially did not modify its target file, so
   the assertion would have been credited without ever being exercised. The
   self-test's own guard (`perturbation did not modify <file>`) caught it. A
   self-test that cannot detect its own no-op is not a self-test.
3. `POS-3` claimed to pin that a pattern-only decision carries **no**
   `declaredBy` key, but the helper it used normalized a missing key and an
   empty array to the same `0`. It would have stayed green if the
   byte-compatible shape were widened to `declaredBy: []` — the exact regression
   it existed to catch. Now reported as the literal `absent` via `Object.hasOwn`.
   Caught in review, not by the harness.

**Scope limit worth stating plainly:** these assertions pin adrkit's behavior
as observed at `c5dc677f`. They are not a specification of what markers *should*
do, and a green run means "the pinned commit still behaves the way this
repository recorded", not "the marker rules are correct".

#### Live evidence: the `declared by` edge renders in the PR comment

The governance Action scanned `23 scanned, 0 absent, 0 unreadable, 0
out-of-tree, 6 truncated, 0 skipped` on the PR that added these fixtures, and
posted a comment containing every marker case at once — which is the first time
this repository has produced consumer-facing evidence of the marker feature
rather than CLI output:

```markdown
### Decisions governing this change

- **0001** — Govern the payments source boundary
  - via `path`: `src/payments/**`
  - declared by `fixtures/markers/not-a-marker.ts:39` (`@adr 0001`)
...
- **0005** — Govern the orders boundary
  - declared by `src/platform/ledger-client.ts:1` (`@adr 0005`)
- **0012** — Govern the platform boundary
  - via `path`: `src/platform/**`

#### Active proposals touching this change

These are not yet ratified and do not bind this change:
- **0014** — … _(proposed)_
  - via `path`: `src/payments/**`
  - declared by `src/payments/api/handler.ts:1` (`@adr 0014`)
- **0015** — … _(proposed)_
  - declared by `src/platform/ledger-client.ts:1` (`@adr 0015`)
```

All three shapes are visible in one render: `0001` and `0014` carry **both** a
pattern and a declaration, `0005` / `0015` carry a declaration **only**, and
`0012` carries a pattern only. `0014` and `0015` are declared inbound and still
sit under "not yet ratified and do not bind this change", which is the status
rule holding on the surface a reviewer actually reads.

#### A dangling marker is silent on that surface, by design

`fixtures/markers/unresolvable.ts` was in that same PR's changed-file set, and
its `@adr 9999` produced **no visible output in the comment at all** — no
warning, no note. That is deliberate upstream rather than a defect, and the
mechanism was read at the pinned commit rather than guessed:
`packages/ci/src/comment.ts` builds its findings list from

```ts
finding.field !== 'marker' && finding.path !== undefined && changed.has(finding.path)
```

so marker findings are excluded twice over — once explicitly by `field`, and
again by the restriction to changed **records**, which a source file is not.

Recorded because the consequence is worth knowing before adopting markers: a
mistyped or renamed reference degrades silently on the surface most reviewers
look at. It is not lost — `adr check` reports it in both human output and
`--json`, which is what `FIND-1` asserts against — but nothing surfaces it in
the pull request. Unlike most decisions in that file, the `field !== 'marker'`
exclusion carries no explanatory comment, so whether it is a considered
trade-off or belt-and-braces alongside the `changedRecords` filter is not
something this repository can tell from the outside.

**Raised upstream as [mbeacom/adrkit#126](https://github.com/mbeacom/adrkit/issues/126)**,
as a question about intent rather than a defect claim, with a minimal runnable
reproduction. It is deliberately filed separately from the existing
[#112](https://github.com/mbeacom/adrkit/issues/112) ("surface marker scan
health in the rendered PR comment"), because the two are different gaps and
#112's proposed fix would not cover this one: its trigger is
`counts.absent + counts.unreadable + counts['out-of-tree'] + counts.skipped > 0`,
and every one of those counters is `0` here. The scan was completely healthy —
it opened the file, read the marker, and parsed it as well-formed. #112 is
"could not look"; this is "looked, saw it, could not bind it".

### What this repository did *not* exercise when the repin landed

Retained as the record of the gap the repin opened, because the correction
history matters more than the tidy end state. Every marker item below was closed
in the same change by [Marker coverage](#marker-coverage-was-the-gap-this-repin-opened-and-it-is-now-closed);
the remaining gaps are named there rather than repeated here.

- ~~**No file in this repository declares an `@adr` marker.**~~ Closed: two now
  do, covering the merge case and marker-only governance.
- **Truncation was recorded backwards, and is corrected here rather than
  quietly fixed.** The original claim was a flat "no truncated scan", reasoning
  from `src/payments/api/handler.ts` — 581 bytes against an 8192-byte window, so
  `truncated` is always `false` on that CLI path. The governance Action then
  reported `12 scanned, 0 absent, 0 unreadable, 0 out-of-tree, 3 truncated, 0
  skipped` on the repin PR itself, because it scans *every changed file*, not
  only governed ones. The three are exactly the changed files over 8192 bytes:
  `README.md` (126,193), `scripts/assert-mcp-config.mjs` (11,997), and
  `scripts/validate-mcp.sh` (9,032). The claim was true of the CLI path and
  false as a statement about the repository. The narrower gap that survived
  that correction — that the *measured* remainder had still never been read,
  since the Action reports only a count — was then closed by
  `fixtures/markers/over-window.ts`, which observes `scannedBytes: 8133` against
  `fileBytes: 23156`.
- ~~**No dangling marker.**~~ Closed: `fixtures/markers/unresolvable.ts` pins
  both the `warn` dangling case and the `info` foreign-log case.
- **The 3,000-file marker cap is not approached** — still true; the largest
  scan observed here is 23 candidate files.
- **The `localeCompare` → code-unit sort fix is not independently verified
  here** — still true. Byte-identical `queue` output was observed in a single
  locale, which is consistent with the fix but does not test it; a cross-locale
  run would be required, and was not performed. adrkit additionally scopes the
  fix itself, leaving `packages/core/src/affects/**` on `localeCompare`.

These are gaps in this repository's coverage, not defects in adrkit.

### The fail-closed boundary was re-probed, not carried forward

`packages/ci/src/action.ts` changed in this range, so the argument that carried
the previous pin's fail-closed evidence forward does not apply unmodified. The
`queue` entrypoint (`queue-action-entrypoint.ts`) is unchanged and its
corpus-load `catch` still precedes `getOctokit`, but that was confirmed by
execution against both committed bundles rather than by reading one file in a
1.7 MB bundle. Both exit `1`, emit the same `ENOTDIR` `::error::` line on
stdout, write zero bytes to stderr, and produce no `issue-number` output. See
[Fail-closed evidence](#fail-closed-evidence-invalid-input-no-write).

### MCP re-validation at `@adrkit/mcp@0.6.0`

`./scripts/validate-mcp.sh` was re-run end-to-end after repinning: **all 56
assertions pass** (28 configuration, 28 stdio JSON-RPC). The two facts that
matter most were re-established rather than assumed:

- The published tarball's `sha512` matches the value now recorded in the script,
  verified independently against the registry before it was written down.
- The tarball's `src/` is byte-identical to `packages/mcp/src` at
  `c5dc677f55c492056184c01252d9f812919c80f9`, which is what licenses using npm
  for MCP at all.

`packages/mcp/src` changed across this range in exactly one respect — the
`SERVER_INFO` version constant `0.4.0` → `0.6.0`. **The four-tool surface did
not widen** (`MCP-3` still asserts exactly four tools), so the deliberately
enumerated tool allowlist in the checked-in configs did not need to change. The
corpus fingerprint assertion (`MCP-12`, `1664c5af…4bd936`) and the
governance-bucket assertions for `src/payments/api/handler.ts` reproduce
unchanged, and `docs/adr` was byte-identical before and after the run.

### No defects found — but two of this document's own claims were falsified

This run surfaced no adrkit defect. Everything predicted by the upstream
changelog was observed, including the positional-insertion caveat it flags. That
is a weaker result than the runs that found defects, and is stated as such
rather than presented as a stronger endorsement than it is — a clean run against
a corpus that only partly exercises the release's headline feature is a narrow
result.

The one thing this repin got wrong was in *this document*, not in adrkit. The
coverage section above originally asserted "no truncated scan", reasoning from
the 581-byte governed file that `adr check` and `adr explain` are pointed at.
That was written before the PR ran, and the governance Action then reported `3
truncated` out of 12 changed files — because it scans every changed file in a
pull request, not only governed ones. The claim was true of the CLI path and
false as a statement about the repository. It is corrected in place above rather
than quietly deleted, because "prefer falsification" is only meaningful if the
falsified version is still visible.

The second was inside the marker assertions added to close that gap. `NEG-1` was
first written against a hardcoded line number and failed on the real fixture;
then its self-test perturbation turned out not to modify its target file at all,
which would have credited the assertion without ever exercising it. Both were
caught mechanically rather than by review — the first by the assertion suite,
the second by the self-test's own no-op guard — and both are recorded under
[Marker coverage](#marker-coverage-was-the-gap-this-repin-opened-and-it-is-now-closed).

---

## Re-validation against `c3dff3a7` (adrkit v0.4.0) (2026-08-08)

The repin from `bbe63e01` to `c3dff3a7` was gated on re-validating this
repository against the new commit *before* changing any pin, and on live
consumer-facing dispatch evidence *before* opening the PR. This section records
what that run did and what it found, including the parts that diverged from
what was expected going in.

### Method

Both commits were fetched at their exact SHAs into separate temporary
directories and compared file-by-file; the **committed `dist/` bundles** were
then driven side by side rather than rebuilt, because the bundle is what a
consumer of the Action actually executes. This differs deliberately from the
`bbe63e01` re-validation, which built from source: the question here is not
"does the source behave the same" — the Action source is provably identical —
but "does the regenerated bundle behave the same". Sequence:

1. Resolved `v0.4.0` through the GitHub API and dereferenced it, rather than
   trusting the tag name (see [Pinned adrkit commit](#pinned-adrkit-commit)).
2. `diff -rq` across `packages/ci/` at both pins, to establish exactly what
   moved.
3. Re-probed the fail-closed boundary against both committed bundles with an
   unreachable `GITHUB_API_URL`, comparing outputs by SHA-256.
4. Re-derived the three recorded digests (QueueReport JSON, Markdown, corpus
   fingerprint) at both pins.
5. Only then were the pins changed, and `./scripts/validate-queue.sh` re-run
   end-to-end at the new pin.
6. Pushed and dispatched both workflows live against the branch.

### Outputs are byte-identical across the pins

Re-derived at both pins against this repository's real 15-record corpus, and
matching the values recorded elsewhere in this README:

| Artifact | `bbe63e01` | `c3dff3a7` |
|----------|------------|------------|
| QueueReport JSON (SHA-256) | `716e21b7…` | `716e21b7…` |
| Rendered Markdown (SHA-256) | `fbcd4d5f…` | `fbcd4d5f…` |
| Corpus fingerprint | `1664c5af…` | `1664c5af…` |
| Fail-closed stdout+stderr (SHA-256) | `e99d2b83…` | `e99d2b83…` |
| `adr lint` | 15 records, 0 errors, 0 warnings | 15 records, 0 errors, 0 warnings |
| `adr --version` | `0.2.0` | `0.4.0` |
| `assert-queue-report.ts` | 13/13 pass | 13/13 pass |

**A caveat that cost real time and is worth recording: these digests are
path-dependent.** `adr queue` embeds each record's `sourcePath` in the report,
so the digest depends on how `--dir` was spelled. Reproducing `716e21b7…`
requires invoking with the **relative** `--dir docs/adr` from the repository
root, exactly as `scripts/validate-queue.sh` does. An absolute `--dir` yields
`ff242b71…`, and running from a different checkout of the same corpus yields
`53b2d874…` — all three from byte-identical inputs. The first attempt at this
re-validation used an absolute path and produced an apparent mismatch that
looked like a regression and was not one. Any future digest comparison must
match the script's invocation form, and the mismatch is a property of the
invocation rather than of the corpus or the tool.

### The QueueReport contract widened (compatibly)

`specs/007-arb-queue/contracts/queue-report.md` changed between the two pins.
`CorpusFinding.severity` widened from the `"error"` literal to
`"error" | "warn"`, and `corpus.file-skipped` is now emitted at `warn` —
described upstream as a governance gap rather than a broken corpus, so it never
changes the exit code and never fails the Action.

This is a **backward-compatible widening**: `report.version` is still `"1"`,
every field that existed before still exists with the same meaning, and no
consumer that handled `"error"` can be broken by the addition. Verified at the
pinned commit rather than taken from the changelog —
`packages/core/src/queue/types.ts:51` now reads `severity: 'error' | 'warn';`,
and `packages/core/src/queue/findings.ts` registers the new code in a
`WARN_CORPUS_CODES` set.

It is called out here because `scripts/assert-queue-report.ts` asserts
`totalCorpusFindings === 0`, and that assertion is now load-bearing in a way it
was not before — a `warn`-severity finding can now occur, where previously it
could not. Empirically this corpus still produces **0** findings, so there is
no impact today. But the *reason* the assertion is safe changed, which is
exactly the kind of thing this repository records rather than glosses. The full
treatment, including a reproduction proving the assertion still fires for the
right reason, is under
[Two things this run found that are not fixed](#two-things-this-run-found-that-are-not-fixed).

### Three things diverged from what was expected

Recorded because a re-validation that only confirms its own premises has not
been performed.

1. **The bundle moved for a different reason than assumed.** The working
   hypothesis was that `packages/ci/dist/*` regenerated because bundled
   first-party dependencies (`packages/core` and friends) moved beneath it. The
   actual cause is visible in `packages/ci/package.json`: `@actions/core` went
   `^1.11.1` → `^3.0.1` and `@actions/github` went `^6.0.1` → `^9.1.1` — two
   major upgrades of the GitHub Actions toolkit itself. That is a materially
   different risk profile from a first-party refactor, and arguably a better
   reason to have re-probed the fail-closed boundary rather than inferred it.

2. **The fail-closed `::error::` line is on stdout, not stderr.** Both bundles
   write it to stdout; stderr is `0` bytes in both. This does not weaken the
   proof — the exit code is still `1`, the message is still byte-identical
   across pins, and no Octokit client is constructed — but the earlier
   description of it as a stderr message was wrong, and a proof whose stated
   mechanics are wrong is not a proof.

3. **The managed-issue dispatch was *not* a no-op on first run.** See
   [Live dispatch under the `c3dff3a7` pin](#live-dispatch-under-the-c3dff3a7-pin)
   for the full account: the body legitimately changed because
   `arb-queue.yml` renders with *today's* date and two weeks of calendar drift
   had accumulated since the previous render. Idempotency is real but had to be
   demonstrated by a separate same-day re-dispatch rather than claimed from the
   first run.

### What this does not establish

The same boundaries as every prior section here. This is a consumer-side
integration record, not upstream test coverage, and not SC-004/T048 evidence —
see [Status boundary](#-status-boundary--this-is-not-sc-004-evidence). A newer
pin does not make it more external. In particular, the claim "the Action source
did not change" is a statement about `packages/ci/src/` and
`packages/ci/queue/action.yml` only; the bundle that actually runs *did*
change, which is why it was re-probed rather than assumed.

---

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

At the current `c5dc677f` pin the MCP position is different and better: the
56-assertion `scripts/validate-mcp.sh` harness now drives the published server
on every pull request, so `get_decision_context`, `search_decisions`,
`get_decision`, `list_superseded`, the read-only annotations, and the
path-rejection checks are all re-exercised continuously. What remains **not**
re-verified from the original `896391cc` sweep is the local-only boundary
evidence gathered by external observation — `lsof` showing zero network
sockets, and corpus mtimes — which that harness does not reproduce. It does
re-hash `docs/adr` before and after each run, so mutation is covered; network
isolation is not.

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

   **Status:** fixed in [mbeacom/adrkit#52](https://github.com/mbeacom/adrkit/pull/52)
   (open at the time of writing, not yet merged and **not** part of the
   `bbe63e01` pin). Verified from the outside against that branch at
   `ffdde26`: `* Deciders: @mbeacom, @octocat` now round-trips to
   `["@mbeacom", "@octocat"]` with no finding.

   One residual distinction was found while checking it and
   [reported on the PR](https://github.com/mbeacom/adrkit/pull/52#issuecomment-5080016338):
   entries that were real but not identity-formatted were dropped, leaving the
   record indistinguishable from one whose source declared no deciders at all.
   **Fixed in `ffdde26` on the same branch, and re-verified here.** A new
   `import-deciders-unmapped` warning names the dropped values, so the four
   source states are now distinguishable:

   | Source `* Deciders:` | Imported | Findings |
   |---|---|---|
   | `Jane Smith, Bob Jones` | `[]` | `warn import-deciders-unmapped` naming both, **plus** `info import-incomplete` |
   | `[list everyone involved in the decision]` | `[]` | `warn import-deciders-unmapped` naming the placeholder, **plus** `info import-incomplete` |
   | *(no `* Deciders:` line)* | `[]` | `info import-incomplete` only |
   | `@mbeacom, Jane Smith` | `["@mbeacom"]` | `warn import-deciders-unmapped` naming `Jane Smith` only; no `import-incomplete` |
   | `@mbeacom, team:platform-eng` | both | none |

   The first three rows all previously collapsed into the third's output. Each
   was re-run against `ffdde26`; the placeholder row is included because it
   was part of the originally reported problem, so leaving its resolution
   unrecorded would have made this account incomplete. Pairing the two
   findings is right rather than redundant: the record really does have no
   deciders, so the backfill advice still applies, *and* the source named
   values worth fixing. A frontmatter `deciders:` list still wins over the
   bullet, and when it does the bullet is ignored wholesale including its
   warning — verified: frontmatter `["@octocat"]` against a bullet reading
   `Jane Smith` imports `["@octocat"]` silently. That is a deliberate
   precedence choice, not a suppressed signal: the field was satisfied, so
   nothing was lost.
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

   **Status:** fixed in [mbeacom/adrkit#52](https://github.com/mbeacom/adrkit/pull/52)
   (open at the time of writing, not yet merged and **not** part of the
   `bbe63e01` pin). Re-verified from the outside against that branch at
   `ffdde26` using the original reproduction — the same undiscoverable
   `proposed` `arb`-tier record now yields:

   ```console
   $ adr queue --dir docs/adr --as-of 2026-07-21 --format json
   totalItems = 0, totalCorpusFindings = 1
   corpusFindings = [{ "sourcePath": "docs/adr/migrate-the-ledger.md",
                       "code": "corpus.file-skipped", "severity": "warn", … }]
   ```

   and the Markdown rendering now reports `1 corpus finding(s)` with a
   `## Corpus Findings` table, where it previously reported
   `0 corpus finding(s)` and `*No proposed records found.*` — the false
   all-clear is gone.

   **Forward dependency for the next repin.** Fixing
   [#51](https://github.com/mbeacom/adrkit/issues/51) changes what the managed
   queue issue renders for a corpus with skipped files, and this repository
   asserts on that. Two things here are coupled to the current behavior:
   `scripts/assert-managed-issue-body.sh` (lines 134–138) asserts the
   **absence** of a `## Corpus Findings` section and that the summary reports
   `0 corpus finding(s)`, and `scripts/assert-queue-report.ts` (lines 76–77)
   asserts `totalCorpusFindings === 0` with an empty `corpusFindings` array.
   Those assertions hold today and would continue to hold for *this* corpus,
   which has no skipped files — but they are written as blanket invariants,
   not scoped to "no skipped files", so they encode an assumption the fix
   invalidates for consumers generally.

   **This is no longer a forward dependency — the fix landed at the
   `c3dff3a7` pin and remains in the current one.**
   [mbeacom/adrkit#52](https://github.com/mbeacom/adrkit/pull/52)
   is included in `c3dff3a7` (adrkit `v0.4.0`) and in `c5dc677f` (adrkit
   `v0.6.0`). What was predicted above is now observed. Read directly at the pinned commit,
   `packages/core/src/queue/types.ts:51` now reads
   `severity: 'error' | 'warn';` (it read `severity: 'error';` at `bbe63e01`),
   and `packages/core/src/queue/findings.ts` registers `corpus.file-skipped` in
   a `WARN_CORPUS_CODES` set.

   **The prediction held against this repository's real corpus.**
   `totalCorpusFindings` is still `0`, `scripts/assert-queue-report.ts` passes
   **unmodified** (all 13 assertions), and the QueueReport is byte-identical to
   the `bbe63e01` output at SHA-256 `716e21b7…`. The repin did not break CI —
   the widening is a correctness-of-intent change, not a repair.

   **The assertions were still deliberately not tightened here, and the reason
   changed.** Previously the narrow and blanket forms were the *same*
   assertion, because a `warn`-severity corpus finding could not occur at the
   pinned commit. That is no longer true: at `c3dff3a7` one can occur, so
   `totalCorpusFindings === 0` is now load-bearing in a genuinely new way. It
   still holds for this corpus — empirically `0` findings, re-confirmed at
   `c5dc677f` — but it holds for a different reason than before, and that
   distinction is exactly the kind of thing this repository records rather than
   glosses.

   The trade-off the README previously flagged is why it stays blanket for now:
   the current form fails **loudly** on any unexpected finding, whereas a
   filtered form (`corpusFindings.filter(f => f.severity === 'error')`) fails
   **quietly** if the field is ever renamed or restructured — an empty filter
   result is indistinguishable from a clean corpus. Against a corpus that is
   supposed to have zero findings of *any* severity, the loud form is strictly
   more informative.

   **The verification step the previous version of this section demanded was
   performed rather than deferred.** It asked whoever moved the pin to confirm
   the assertions actually *fire* against a corpus with a skipped file, not
   merely that they still pass against this one. Built at `c3dff3a7`, and
   re-run unchanged at `c5dc677f` with the same result: a single
   `proposed` `arb`-tier record under a filename that does not match
   `<id>-<slug>.md`, in a throwaway `/tmp` corpus, yields

   ```json
   {
     "totalItems": 0,
     "totalCorpusFindings": 1,
     "corpusFindings": [
       {
         "sourcePath": "skiptest/adr/no-id-slug-name.md",
         "code": "corpus.file-skipped",
         "severity": "warn",
         "message": "Markdown file in the corpus directory is not a discoverable ADR record and was skipped; rename it to <id>-<slug>.md (four or more leading digits) for it to be linted and enforced"
       }
     ]
   }
   ```

   with `adr queue` still exiting `0` (the `warn` severity does not change the
   exit code, as designed), the Markdown rendering reporting
   `1 corpus finding(s)` with a `## Corpus Findings` section, and
   `scripts/assert-queue-report.ts` **failing loudly** against it:

   ```
   FAIL: zero corpus findings (got 1)
   FAIL: corpusFindings array is empty
   Queue validation FAILED: 9 assertion(s) did not hold.
   ```

   So the blanket assertions are confirmed to reject a skipped-file corpus for
   the right reason, not merely to pass against a clean one. Re-run at the
   `c5dc677f` pin, the finding is reproduced identically — same `code`,
   `severity: "warn"`, and message text, `adr queue` still exiting `0` — and
   `scripts/assert-queue-report.ts` still fails loudly with the same 9
   assertions. The `/tmp` corpus was discarded; `docs/adr/**` was never touched.

   To be unambiguous about where that instruction comes from: it is a
   convention adopted **in this repository**, arrived at while re-validating
   `bbe63e01`. It is **not** an adrkit rule. A record has since been drafted
   upstream — adrkit ADR-0016, "Require every check to be observed failing
   before it counts as coverage", proposed in
   [mbeacom/adrkit#54](https://github.com/mbeacom/adrkit/pull/54) — but it is
   an **unratified draft** and binds nothing: verified on that branch as
   `status: draft`, `deciders: []`, `provenance.authoredBy: agent-drafted`,
   with the PR open and unmerged, and its own first action item being "ratify
   or reject". Cite it as "proposed in mbeacom/adrkit#54, unratified draft" if
   you cite it at all; "adrkit requires this" will not be true unless and
   until that record is `accepted` and merged. If that happens, replace this
   paragraph with the record id.

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
real third-party MADR corpus. adrkit's own test suite was not run. As with
everything else in this repository, none of this is
`specs/007-arb-queue` SC-004 / T048 evidence: see the status boundary at the
top of this document. Re-validating a fix does not make this repository
independent of the maintainer who wrote it.
