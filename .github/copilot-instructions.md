# Copilot instructions — adrkit-t018-dogfood

This repository is a dogfood repository for [adrkit](https://adrkit.dev). Its
decision corpus in `docs/adr/` is not documentation *about* the code — it is a
governance corpus that CI enforces, and it is the subject under test.

## Query the adrkit MCP server before proposing architecture changes

An adrkit MCP server is configured for this repository (`.github/copilot-mcp-config.json`
for Copilot cloud agent and code review, `.vscode/mcp.json` for VS Code,
`.copilot/mcp-config.json` for Copilot CLI). It exposes four read-only tools over
the corpus in `docs/adr/`. **Use them. Do not infer this repository's decisions by
grepping `docs/adr/` when the MCP server can answer authoritatively** — the server
resolves record status, `affects` matchers, and supersession the same way `adr
check` and the CI Action do, so its answer is the one CI will act on.

Concretely:

- **Before editing any file under `src/`** — call `get_decision_context` with the
  repo-relative paths you intend to change. `src/payments/**` is governed. Treat
  `governing` records as binding constraints on the change, and read
  `activeProposals` as decisions currently in ARB review that your change may
  conflict with or depend on.
- **Before proposing a new approach** — call `search_decisions` first. The corpus
  deliberately includes superseded and rejected records; re-proposing a path this
  repository already ruled out is the specific failure mode adrkit exists to
  prevent.
- **Before citing a decision** — call `get_decision` and quote the real record.
  Do not paraphrase a decision from its filename or from this file.
- **Before assuming a record is current** — call `list_superseded`. Supersession is
  reported one hop deep and is not transitively expanded; follow the chain yourself
  with further `get_decision` calls if it matters.

If a tool returns `not-found`, `ambiguous-local-id`, or a non-empty `findings`
page, report that outcome rather than working around it. A corpus that does not
resolve is a finding about adrkit or about this corpus, and this repository exists
to surface exactly those.

## Report MCP defects rather than routing around them

This repository's purpose is to find adrkit defects from the outside. If the MCP
server misbehaves — a wrong governance bucket, a crash, a schema violation, a tool
that contradicts `adr check` — that is a **result**, not an obstacle. Say so
explicitly in your response, with the exact tool call and the observed output, so
it can be filed upstream. Silently falling back to reading Markdown files hides the
defect and defeats the point of the repository.

## Evidence discipline

The README of this repository is an evidence document. It is written to a strict
standard, and contributions to it are held to the same one:

- **Never claim a behavior you did not observe.** Distinguish what was run and
  observed from what was inferred from a diff. Where something was inferred, say
  that it was inferred.
- **State scope caveats.** If only part of a surface was re-verified at the current
  pin, say which part, and do not let a broader earlier claim be read as current.
- **Prefer falsification.** Treat "this should still work" as a hypothesis to test,
  not an assumption to record.

## Pin discipline

Every adrkit reference in this repository is pinned to an immutable identity: an
exact 40-character commit SHA for Actions and clones, an exact version plus a
verified `sha512` integrity for npm packages, and a `sha256` for downloaded release
assets. adrkit publishes a moving `v0` tag; it is useful for *discovering* the
current SHA and must never be used *as* a pin. Do not replace any pin with a branch
name, a tag, `@latest`, or a semver range. Bumping a pin is a re-verification, not
a chore: re-run the affected validation script and record what changed.

The MCP version pinned in the three config files must stay in agreement with the
adrkit commit pinned in `scripts/validate-queue.sh`. `scripts/validate-mcp.sh`
enforces both that agreement and the npm-to-commit correspondence, and it runs in
CI.

## Do not mutate the governed corpus casually

`docs/adr/0001`–`0015` are fixtures with deterministic expected behavior asserted
by `scripts/assert-queue-report.ts` against a fixed `--as-of` date. Editing a
record, or adding a new one, changes CI expectations. If a task genuinely calls for
corpus changes, update the assertions in the same change and explain the new
expected values. For exploratory adrkit runs, build a synthetic corpus in a
temporary directory instead — that is how the existing dogfood runs were done.
