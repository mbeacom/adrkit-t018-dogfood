// @adr 9999
// @adr payments:0012
//
// Fixture for the two markers that resolve to nothing, and the deliberately
// different severities adrkit gives them.
//
// `@adr 9999` is DANGLING: the ref is well-formed but this corpus has no record
// `9999`. adrkit reports `dangling-marker` at `warn`, not `error`, and the
// reasoning is worth preserving because it is easy to get backwards. A dangling
// `relatesTo` inside a record is an `error` — the corpus owns its own references
// and a broken one means the record is wrong. A marker lives in a file the
// corpus does not own and cannot be required to be complete for, so an
// unresolvable one is a claim that could not be honored, reported without
// failing the run.
//
// `@adr payments:0012` is LOG-QUALIFIED: it names a decision log called
// `payments`, and this corpus is not that log. adrkit reports
// `marker-unresolvable` at `info` — inert here, not broken. `0012` does exist in
// this corpus, which is the point: the qualified ref must NOT quietly resolve
// against the local record of the same id just because the number matches.
//
// Neither finding may affect exit status. `adr check` still exits 0, and the
// governing-decisions Action fails only on `error` findings attached to changed
// ADR records, which these are not.
//
// Expected: zero declarations, one `dangling-marker` (warn), one
// `marker-unresolvable` (info). Asserted as `FIND-1` through `FIND-4`.

export const unresolved = true;
