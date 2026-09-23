# `adr explain --as-of` — rung-2 reference-verification evidence index

**Purpose**: The tracked, sanitized evidence index for
[ADR-0039](./adr/0039-derive-a-valid-time-window-from-date-and-supersession-and-resolve-a-git-ref-at-th.md)
("Derive a valid-time window from date and supersession, and resolve a git ref
at the CLI boundary"), closing that record's action item 5. It records what
was actually run against `adr explain --as-of <date|ref>`, what those runs
produced, and — as plainly as possible — what they do **not** establish.

This is [ADR-0014](./adr/0014-stage-phase-landing-evidence-across-a-three-rung-validation-ladder.md)
**rung 2 — maintainer-owned isolated reference-repository validation**. It is
**not** rung-3 external validation, and this evidence must not be described
as "externally validated", "production-ready", or "real user" anywhere it is
cited. This repository (`mbeacom/adrkit-t018-dogfood`) is maintainer-owned and
isolated, not an external team or third party.

**Created**: 2026-09-22
**Decision**: [ADR-0039](./adr/0039-derive-a-valid-time-window-from-date-and-supersession-and-resolve-a-git-ref-at-th.md)
(action item 5)
**PR (this repository)**: [mbeacom/adrkit-t018-dogfood#24](https://github.com/mbeacom/adrkit-t018-dogfood/pull/24)

## Immutable references

| What | Value |
|---|---|
| adrkit commit pinned by this validation | `4886dd6bb127d6aca57804a71d1c4b8548424d3b` |
| adrkit release tag at that commit | `v0.14.0`, verified by dereferencing the annotated tag: `gh api repos/mbeacom/adrkit/git/ref/tags/v0.14.0` → tag object `a281dcb453ba95d1065dc0a7e7cc281357493aa8` → `gh api .../git/tags/a281dcb4...` → commit `4886dd6bb127d6aca57804a71d1c4b8548424d3b` |
| This repository's commit under evidence | `6587559edf93eb9bd3d1eedb461f7662575aba52` |
| CI run — `adrkit as-of validation` (self-verifying, green) | [runs/35727968513](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/35727968513) |
| CI run — `ADR governance` (`adr.yml`, now pinned to the same commit) | [runs/35727968312](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/35727968312) |
| CI run — full check suite at this commit | [`gh pr checks 24`](https://github.com/mbeacom/adrkit-t018-dogfood/pull/24/checks): 7 passed, 0 failed |
| Deliberately-broken run — `as-of-validation.yml` itself | [runs/35728825424](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/35728825424), dispatched on a throwaway branch (`tmp/break-as-of-ci`, deleted after capture, never merged) with `0017`'s `date` shifted from `2026-02-01` to `2026-01-01`. Failed exactly as required: `BOUND-3` ("0016 is still governing the day before handover") failed, `assert-as-of.mjs` exited 1, and the job failed — proving the workflow's exit-code wiring, not just the assertions in isolation. |
| Deliberately-broken run — a different job, same PR | [runs/35727726598](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/35727726598) (an earlier commit on this same PR, `f1e29796fa177ff5f222539ab3d7cd220664b319`) — `adrkit MCP validation` failed because the extended corpus changed values three hardcoded assertions had not been updated for; fixed in the next commit and shown green above. A second, independent instance of "observed failing," not a substitute for the row above. |

## Tool versions / environment

| Component | Version |
|---|---|
| `adr` (pinned build) | `0.14.0` |
| git | `2.50.1` (Apple Git-155) |
| Bun (build/runtime) | `1.3.14` (CI, pinned via `oven-sh/setup-bun@v2`); `1.4.2` (local development machine) |
| Node.js | `22` (CI, via `actions/setup-node@v4`); `v22.22.2` (local development machine) |
| OS / arch (local) | macOS 26.6.2 (build 25G83), Darwin arm64 |
| OS (CI) | `ubuntu-latest` (GitHub-hosted runner) |
| CI runner | GitHub Actions, `.github/workflows/as-of-validation.yml` |

## Content hashes (fixtures and validation scripts, at commit `6587559`)

| File | SHA-256 |
|---|---|
| `docs/adr/0016-adopt-connection-pooling-for-temporal-workers.md` | `8da678946b5e367d75a354f64f0f9bce80971fb462c2f32be17ef073226c112d` |
| `docs/adr/0017-adopt-managed-connection-pool-service-for-temporal-workers.md` | `c6ce400ca7d95c3759fe3c1a6d4305df20316852295af73107f19ceead86b248` |
| `docs/adr/0018-adopt-vendor-pgbouncer-for-temporal-workers.md` | `b17b4c6755c06461cc22f575f578bfd87f61942f167a4fa49e336531213fb330` |
| `docs/adr/0019-deprecate-manual-temporal-worker-restarts.md` | `233fa593d90da7e1150be91da52735c89606d97c3b4d01362a011f50b7e26b13` |
| `docs/adr/0020-reject-single-global-temporal-worker-pool.md` | `8b574abe0e4daba64f8099a52ade1ef91442dd2a97ff944601a6bd89c8a56fd6` |
| `docs/adr/0021-adopt-sticky-worker-affinity-for-temporal-tasks.md` | `b921492090633ba7e3701a356ff02df0deb42839b5e95449415df0cb7998b874` |
| `docs/adr/0022-adopt-round-robin-worker-scheduling-for-temporal-tasks.md` | `9e60f3b17193ac58bfb835d01abb472262ac5ce3346e1b869b79ba4ed23a3e99` |
| `src/temporal/pool/worker-pool.ts` | `54d77aac6096ef1bce4343dbdc1c4b21931b5ab377716f6d41194494bcd48eaf` |
| `src/temporal/legacy/restart.ts` | `a0fcb76be530e047cce9bec2aee0463d653bf7291ac279d120770ac8973a56ca` |
| `src/temporal/inverted/scheduler.ts` | `6ea64e31e20d82518e3b9e49294f2e0a0f75237a92999e2c4beef5be7715020d` |
| `scripts/validate-as-of.sh` | `312f2afda67b32b768cf3d7dc3c4c5faa6039f44309e27e0a517e30b7ba3835c` |
| `scripts/assert-as-of.mjs` | `d3eceaa77bd83d6fed9466f908c38a46dc46fc696b719d80a74d76a4a33ae233` |

## Why the T018 corpus alone could not produce this evidence

As of `2026-08-30`, `docs/adr/0001`–`0015` were entirely `accepted` or
`proposed` — no record carried `supersededBy`, and most shared one `date`
(`2026-07-19`). An `--as-of` run against that corpus exercises only two of
`standingAsOf`'s five branches ("accepted record governs" and "record did not
exist yet"); it never exercises the window *closing* along an
`accepted → superseded` lineage, which is the feature ADR-0039 adds. Reporting
a green run against that corpus as rung-2 evidence would have been evidence of
nothing. `docs/adr/0016`–`0022` (added by this PR) exist specifically to make
the remaining branches observable.

## Fixture corpus

| Fixture | Shape | Makes observable |
|---|---|---|
| `0016` → `0017` | Supersession pair, `2025-11-01` → `2026-02-01`, both `affects: src/temporal/pool/**` | Window open/close, half-open boundary |
| `0017` → `0018` | `0017` also superseded, by `0018` (`2026-05-01`) | Close at the **immediate** successor, not the terminal one |
| `0019` | `deprecated`, no successor (the schema forbids one outside `status: superseded`) | `undetermined` standing + `temporal-window-undetermined` finding |
| `0020` | `rejected` | `history` on every date it could be asked about |
| `0021` → `0022` (inverted) | `0021` superseded by `0022`, but `0022` dated **before** `0021` | `temporal-window-inverted`; renders as "no in-force interval" |
| `src/temporal/pool/worker-pool.ts` | Source file declaring `@adr 0016` | Stale-marker suppression inside `0016`'s window; stale again outside it |

All dates are far from "today" (`2026-09-22`) and from each other, so window
boundaries are unambiguous. `adr lint --dir docs/adr` passes this extended
corpus with **0 errors, 0 warnings** (22 records total) — the inverted-date
pair is not a schema violation, because a cross-record date-ordering
constraint is not expressible on one record's frontmatter; catching it is
exactly ADR-0039's kernel's job, not the schema's.

## Scenario matrix — expected vs. observed

All scenarios below were captured against the pinned `4886dd6` build and
asserted by `scripts/assert-as-of.mjs` (51 assertions total). Full detail —
every assertion id, its description, and its pass/fail status — is in the
[`adrkit as-of validation`](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/35727968513)
CI run log; the table below is a representative summary, not the complete
list.

### Half-open window boundary (`0016` → `0017`, opens `2025-11-01`, closes `2026-02-01`)

| `--as-of` | Expected standing (`0016`) | Observed | Assertion id |
|---|---|---|---|
| `2025-10-31` | `notYetRecorded` | `notYetRecorded` | BOUND-1 |
| `2025-11-01` | `governing` (boundary inclusive) | `governing` | BOUND-2 |
| `2026-01-31` | `governing` | `governing` | BOUND-3 |
| `2026-02-01` | `history` (handover day belongs to `0017` alone) | `history` | BOUND-4 |

`0017` is `governing` on `2026-02-01` (BOUND-5) and exactly one of `0016`/`0017`
is `governing` on that day (BOUND-6) — both observed as expected.

### Immediate, not terminal, successor (`0016` → `0017` → `0018` chain)

| Probe | Expected | Observed | Assertion id |
|---|---|---|---|
| `0016`'s window, as-of `2026-06-01` (deep in `0018`'s tenure) | `window.closedBy === "0017"`, not `"0018"` | `closedBy: "0017"` | CHAIN-1 |
| `0016` standing at that date | `history` | `history` | CHAIN-2 |
| `0017` standing at that date | `history` (the middle link, also closed) | `history` | CHAIN-3 |
| `0018` standing at that date | `governing` | `governing` | CHAIN-4 |
| Records `governing` along the chain | exactly one | one (`0018`) | CHAIN-5 |

### `deprecated` (`0019`) and `rejected` (`0020`)

| Record | `--as-of` | Expected | Observed | Assertion id |
|---|---|---|---|---|
| `0019` (deprecated, `2025-12-01`) | `2026-01-01` | `undetermined` + `temporal-window-undetermined` finding | `undetermined`, finding present | DEP-1, DEP-3 |
| `0019` | `2026-01-01` | never `governing`/`history` | absent from both | DEP-2 |
| `0020` (rejected, `2025-12-15`) | `2026-01-01` | `history`, never `governing`/`undetermined` | `history` only | REJ-1, REJ-2 |
| `0020` | exactly `2025-12-15` (its own date) | `history` (never in force at all) | `history` | REJ-3 |

### Inverted pair (`0021` superseded by `0022`, but `0022` dated before `0021`)

| Probe | Expected | Observed | Assertion id |
|---|---|---|---|
| `0021` standing, as-of `2026-05-01` | `history`, never `governing` on any date | `history`; absent from `governing` | INV-1, INV-2 |
| Finding | `temporal-window-inverted` warn | present | INV-3 |
| `0022` standing | `governing` | `governing` | INV-4 |
| Human rendering for `0021` | "no in-force interval", never `in force <opens> → <closes>` | `no in-force interval: recorded 2026-04-01, but its successor 0022 is dated 2026-03-01` | INV-5 |

### Marker suppression (`src/temporal/pool/worker-pool.ts` declares `@adr 0016`)

| `--as-of` | Expected `stale-marker` | Observed | Assertion id |
|---|---|---|---|
| (absent — present tense) | fires (`0016` is superseded today) | fires | MARK-1 |
| `2025-12-01` (inside `0016`'s window) | suppressed | absent | MARK-2 |
| `2025-12-01` | `0016` reported `governing` | `governing` | MARK-3 |
| `2026-03-01` (outside `0016`'s window, after handover) | fires again | fires | MARK-4 |

### `bucket` (present) vs. `standing` (as-of) legitimately disagree

| Field | As-of `2025-11-01` | Assertion id |
|---|---|---|
| `0016`'s present-tense `bucket` (union `governedBy` entry) | `"history"` (it is superseded today) | DISAGREE-1 |
| `0016`'s as-of `standing`, same response | `"governing"` (inside its own window) | DISAGREE-2 |

Both observed exactly as expected — one decision, two temporal vocabularies,
both true at once, matching ADR-0039's Trade-offs.

### JSON shape and additive-only guarantee

| Property | Expected | Observed | Assertion id |
|---|---|---|---|
| `asOf` block fields | `requested`, `date`, `resolvedFrom`, plus the 5 standing arrays | present | SHAPE-1, SHAPE-2 |
| Each as-of decision | carries `window` and `standing` | present | SHAPE-3 |
| Ref-resolved `asOf` | carries `commit`, `committedAt` | present | SHAPE-4, SHAPE-5 |
| Without `--as-of` | `asOf` key absent entirely | absent | SHAPE-6 |
| Top-level `governing`/`activeProposals`/`history` | unchanged by the flag | identical with and without `--as-of` | SHAPE-7, SHAPE-8 |

### Git-ref resolution (isolated throwaway repository, pinned committer date)

| Probe | Expected | Observed | Assertion id |
|---|---|---|---|
| `--as-of HEAD`, committer date pinned to `2025-11-01T12:00:00Z` | `asOf.committedAt === "2025-11-01T12:00:00Z"`, `resolvedFrom: "ref"` | matched exactly (also asserted directly in `validate-as-of.sh`, independent of `assert-as-of.mjs`) | SHAPE-4/5, script-level sanity check |
| A tag literally named `2026-03-01` (date-shaped), passed as `--as-of 2026-03-01` | resolves via the **date grammar first**, `resolvedFrom: "date"`, never touches the tag | `resolvedFrom: "date"`, no `commit`/`committedAt` fields | REF-1, REF-2 |

The throwaway repository is built fresh per run under `mktemp -d`, seeded with
`GIT_CONFIG_GLOBAL=/dev/null` and `GIT_CONFIG_SYSTEM=/dev/null` (ADR-0039's
Consequences record that inherited git config — `tag.gpgSign`,
`log.showSignature` — corrupts this exact code path), so the committer date
is fully controlled and the run is reproducible.

### Fail-closed (required by rung 2)

All four scenarios were run directly against this repository (not the
throwaway one, except where a git repository is required to test its
absence). `git status --porcelain` was captured immediately before the first
and immediately after the last scenario and asserted identical; stdout was
captured per-scenario and asserted empty.

| Scenario | Expected | Observed | Assertion id |
|---|---|---|---|
| `--as-of 2026-02-30` (invalid calendar date) | exit `2`, message names the date grammar, stdout empty | exit `2`, `"Expected YYYY-MM-DD, ..."`, stdout empty | FAIL-fail-invalid-date-* |
| `--as-of 2026-03-01T00:00:00` (no timezone) | exit `2`, refuses rather than guesses, stdout empty | exit `2`, `"Timezone-less datetimes are ambiguous..."`, stdout empty | FAIL-fail-tzless-* |
| `--as-of no-such-ref` | exit `2`, names git, stdout empty | exit `2`, `"...git could not resolve it to a commit..."`, stdout empty | FAIL-fail-no-such-ref-* |
| Outside a git repository, `--as-of deadbeef` | exit `2`, says "not a git repository", stdout empty | exit `2`, `"...is not a git repository."`, stdout empty | FAIL-fail-outside-git-repo-* |
| `git status --porcelain`, before vs. after all four | identical | identical (asserted by the script; a mismatch fails the run before assertions even execute) | script-level gate |

## Self-verification (ADR-0016: a check never observed failing is not coverage)

`scripts/validate-as-of.sh --self-test` perturbs six independent properties
of the committed fixtures in a throwaway copy of the corpus and requires the
dependent assertions to fail:

| Perturbation | Target | Assertions required to fail | Result |
|---|---|---|---|
| Shift `0016`'s own `date` past `0017`'s | `docs/adr/0016...md` | BOUND-2, BOUND-3, BOUND-4, DISAGREE-2 | observed failing |
| Repoint `0016`'s `supersededBy` at the chain terminal (`0018`) directly | `docs/adr/0016...md` | CHAIN-1 | observed failing |
| Change `0019`'s `status` from `deprecated` to `accepted` | `docs/adr/0019...md` | DEP-1, DEP-2, DEP-3 | observed failing |
| Change `0020`'s `status` from `rejected` to `accepted` | `docs/adr/0020...md` | REJ-1, REJ-2, REJ-3 | observed failing |
| Fix the inversion (`0022`'s `date` moved after `0021`'s) | `docs/adr/0022...md` | INV-3, INV-5 | observed failing |
| Remove the `@adr 0016` marker | `src/temporal/pool/worker-pool.ts` | MARK-1, MARK-4 | observed failing |

Result: **6 perturbations falsified 15 of 51 assertions**, all exactly
matching the claimed ids (no under- or over-claiming — verified by iterating
on this exact mismatch twice during authoring, see Limitations). The
remaining 36 assertions (JSON shape, git-ref resolution, the fail-closed
scenarios, and a handful of corpus invariants — `BOUND-1`/`1b`/`5`/`6`,
`DISAGREE-1`, `INV-1`/`2`, `MARK-2` — that hold true under every perturbation
attempted against them) are not claimed as self-test-falsified. That is
stated plainly in the script's own output and is not hidden.

The self-test above proves the *assertions* fail under perturbation, run
locally and in the same CI job that also asserts them — which leaves the
workflow's own exit-code wiring (assertion failure → job failure → PR check
red) unproven by that alone. A dedicated deliberately-broken run closes that
gap directly: `as-of-validation.yml` was dispatched
([runs/35728825424](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/35728825424))
against a throwaway branch with `0017`'s `date` shifted by one month. `BOUND-3`
failed, `assert-as-of.mjs` exited 1, and the job failed — end to end, not just
in isolation. The branch was deleted after capturing the run and was never
merged.

A second, independent instance of "observed failing" — in a different job,
caught incidentally rather than deliberately induced — is the earlier commit
on this PR cited above ([runs/35727726598](https://github.com/mbeacom/adrkit-t018-dogfood/actions/runs/35727726598)):
`assert-mcp-surface.mjs` hardcoded a record count, a corpus fingerprint, and
"no superseded records" against the prior 15-record corpus. Adding the
ADR-0039 fixtures broke all three, CI caught it before merge, and the fix
(updating the hardcoded expectations to match the real, extended corpus — not
loosening the assertions) is the next commit on the same PR, shown green
above.

## Reproducibility

- adrkit pinned at the immutable commit `4886dd6bb127d6aca57804a71d1c4b8548424d3b`
  (`v0.14.0`), verified by dereferencing the annotated release tag rather than
  trusting the GitHub release page (see "Immutable references").
- Every fixture is committed, not generated at run time. `scripts/validate-as-of.sh`
  reads `docs/adr/0016`–`0022` and `src/temporal/**` directly from this
  repository's working tree.
- The one exception — the isolated throwaway git repository for `--as-of <ref>`
  resolution — is itself built deterministically inside the script from those
  same committed fixtures, with an explicitly pinned `GIT_COMMITTER_DATE`
  (`2025-11-01T12:00:00Z`), so its result is reproducible even though the
  repository itself is not committed.
- `.github/workflows/adr.yml`'s previous unpinned `mbeacom/adrkit/packages/ci@main`
  reference is fixed to the same `4886dd6` commit as part of this PR.

## Limitations (honest scope of this evidence)

- **This is rung 2, not rung 3.** No external party ran this. `mbeacom/adrkit-t018-dogfood`
  is maintainer-owned and isolated per ADR-0014's own definition, not an
  external team or third-party adopter.
- **The fixture corpus's status mix is chosen to exercise the rules, not
  sampled from a real project.** Of the seven new records, 1 is `deprecated`
  (`0019`), 3 are `superseded` (`0016`, `0017`, `0021` — one of the three
  deliberately inverted), 1 is `rejected` (`0020`), and 2 are `accepted`
  (`0018`, `0022`). That is a 1-in-7 (≈14%) `deprecated` share by
  construction — deliberately built to guarantee at least one `undetermined`
  fixture exists, not sampled from real usage. It says **nothing** about how
  often real corpora deprecate versus supersede and must not be read as
  evidence toward or against ADR-0039's own "how we would know this was
  wrong" item 2 (the ~quarter `undetermined`-share threshold across a real
  corpus), which this fixture corpus was not built to test and is too small
  (7 records) to say anything statistically meaningful about regardless.
- **`temporal-window-open` (a `superseded` record whose successor the corpus
  lacks) was not exercised as a committed fixture.** ADR-0039 itself states
  this finding is reachable only through `resolveDecisionsAsOf` as a library
  call, gated out of the CLI path by the `dangling-supersededBy` **error**
  that `adr explain` refuses to run past. Committing such a fixture to this
  corpus would make `adr explain` unusable for every other scenario in it
  (the corpus-error gate returns exit `1` for any path, not just the
  affected one). Not exercised here; ADR-0039's own claim about this is
  accepted on the strength of its stated reasoning (the schema-level gate is
  directly visible in `packages/core/src/validate/corpus-invariants.ts`) but
  was not independently re-verified against a throwaway corpus by this
  evidence. This is a real gap, not a rounding error, and is named as such.
- **One host, one OS family for the local development steps.** Manual
  verification during authoring ran on macOS (arm64); the asserted, graded
  evidence above is from `ubuntu-latest` GitHub Actions runners (CI), which
  is what the run links point to.
- **Single-run CI observations, like the rest of this repository's evidence.**
  Each CI run is one execution of a deterministic script against a fixed
  corpus and pinned dates — determinism is the point, not a claim about
  behavior across many independent runs of a non-deterministic process.
- **The self-test's "not falsified by construction" list is not a weakness
  being hidden — it is stated in three places** (the script's own trailing
  output, this document, and the README's "As-of validation" section) so a
  reader does not have to infer it from what is absent.
- **No adversarial or fuzz testing.** Nothing probed malformed dates beyond
  the four fail-closed cases named in ADR-0039's own review, a corpus with
  thousands of records, or concurrent `--as-of` invocations.

## Verdict

`adr explain --as-of <date|ref>` behaves as ADR-0039 specifies against a
corpus fixture set purpose-built to exercise every branch of its temporal
kernel: the half-open window boundary, the immediate-vs-terminal successor
rule, `deprecated`'s honest `undetermined` gap, `rejected`'s permanent
`history` standing, the inverted-window guard (kernel and renderer agreeing),
marker suppression judged against the asked-for date, the `bucket`/`standing`
dual vocabulary, JSON shape and additive-only guarantees, git-ref resolution
via the committer date with the date-grammar-first precedence, and all four
named fail-closed failure modes. 51 assertions passed; 15 of them were
independently observed failing under a targeted perturbation before being
counted as coverage (ADR-0016), and a genuine CI failure (three stale
hardcoded values in an unrelated MCP surface test) was caught and fixed in
the same PR rather than worked around.

This is **rung 2 (reference-verified)** per ADR-0014. It is **not** rung 3
and must not be described as externally validated, production-ready, or
validated by a real user. ADR-0039 action item 5 is closed by this evidence;
action items 6 and 7 (whether `adr check`/the Action should accept `--as-of`,
and `%cI` vs. `%aI`) remain open and are unaffected by this work.

**Reviewer verdict**: Accepted as ADR-0014 rung-2 evidence for ADR-0039
action item 5. [mbeacom/adrkit-t018-dogfood#24](https://github.com/mbeacom/adrkit-t018-dogfood/pull/24)
merged at `e9a2bf5226f540f7ea905ce18e06a813c2f4a27b` with all 7 CI checks
green, including a dedicated deliberately-broken dispatch of
`as-of-validation.yml` proving the workflow's own exit-code wiring. The
scenario matrix, self-test falsification accounting, and limitations above
were reviewed against that merged state. — `@mbeacom`, 2026-09-22.
