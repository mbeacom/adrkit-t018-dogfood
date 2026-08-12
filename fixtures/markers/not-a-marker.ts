// Negative fixture: marker-looking lines that must NOT declare a decision.
//
// Every line below resembles a marker and none of them is one. adrkit requires
// `@adr` to be the first content of a dedicated comment line, and each case here
// violates that in a different way. If any of them starts declaring, the
// dedicated-line rule has regressed and `NEG-1` in scripts/validate-markers.sh
// fails.
//
// This is a MIXED boundary fixture, not a purely negative one. It contains four
// marker-looking lines that must not declare AND one block-comment continuation
// that must — see the bottom of the file. Its expected declaration set is
// therefore exactly `0001`, declared once, from the block comment alone
// (`POS-6` and `NEG-1`). Every decoy names `0001` too, which is what makes the
// pairing meaningful: the assertion pins WHICH line declared, not just that
// something did.

// The reference is real (0001 is an accepted record in this corpus), so if any
// of these resolved, the failure would be visible rather than silently inert.

export function trailing(): string {
  // A trailing marker is not a file-level declaration: `@adr` is not the
  // comment's first content, it follows code on the same physical line.
  return 'trailing'; // @adr 0001
}

export function stringLiteral(): string {
  // The marker text inside a string literal is data, not a comment. adrkit does
  // not parse the language, so this is held by the line-lead rule alone.
  return '// @adr 0001';
}

export function prose(): string {
  // Discussing @adr 0001 in the middle of a sentence must not declare it —
  // otherwise every comment that mentions a decision would silently bind the
  // file to it.
  return 'prose';
}

// @adrkit/core is the npm scope, not the marker token. A separator is required
// after `@adr`, so this line must not declare a record either.
export const scope = '@adrkit/core';

/*
 * @adr 0001 inside a block comment IS a dedicated line by adrkit's rules — the
 * `*` continuation is an accepted introducer. This one is therefore a POSITIVE
 * case living in a negative-fixture file, and it is here on purpose: it is the
 * boundary between the two rules, and pinning it stops a future "tighten the
 * negative cases" change from over-correcting and killing block-comment
 * declarations. Asserted separately as `POS-6`.
 */
export const blockComment = true;
