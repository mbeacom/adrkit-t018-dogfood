#!/usr/bin/env node
/**
 * Pure, network-free assertions over captured `adr explain --json` /
 * `adr check --json` output for this repository's inbound `@adr` marker
 * fixtures.
 *
 * Split from scripts/validate-markers.sh for the same reason
 * scripts/assert-queue-report.ts is split from validate-queue.sh: the half that
 * decides whether the behavior is correct should not also be the half that
 * builds a toolchain and shells out. Everything here is a comparison over JSON
 * that was already captured; it performs no I/O beyond reading those captures.
 *
 * Usage: assert-markers.mjs <captureDir>
 *
 * `captureDir` holds one `<slug>.json` per fixture (the `explain --json`
 * document), plus `check-exit.txt` and `check.json` for the batch surface.
 *
 * Exit codes: 0 = every assertion held; 1 = at least one did not.
 */

import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const [, , captureDir] = process.argv;
if (!captureDir) {
  console.error('usage: assert-markers.mjs <captureDir>');
  process.exit(2);
}

const checks = [];

function assert(id, description, expected, observed) {
  const ok = JSON.stringify(expected) === JSON.stringify(observed);
  checks.push({ id, description, ok, expected, observed });
}

function load(slug) {
  return JSON.parse(readFileSync(join(captureDir, `${slug}.json`), 'utf8'));
}

/** Every ref the scanner accepted as a declaration in this file, in scan order. */
function declaredRefs(doc) {
  return (doc.markers?.declared ?? []).map((entry) => entry.ref);
}

/** The 1-based lines the scanner accepted declarations on. */
function declaredLines(doc) {
  return (doc.markers?.declared ?? []).map((entry) => entry.line);
}

/**
 * The text of each line the scanner accepted a declaration on.
 *
 * Content rather than line number, deliberately. A positional assertion breaks
 * on any unrelated edit above the marker and, worse, says nothing about *which*
 * of several marker-looking lines resolved — which is exactly the property the
 * negative fixtures exist to pin.
 */
function declaredLineText(slug, doc) {
  const lines = readFileSync(join(captureDir, `${slug}.source`), 'utf8').split(/\r\n|[\r\n]/);
  return declaredLines(doc).map((line) => (lines[line - 1] ?? '').trim());
}

/** One decision from the union bucket, reduced to what these assertions care about. */
function decision(doc, recordId) {
  const found = (doc.governedBy ?? []).find((entry) => entry.recordId === recordId);
  if (!found) return undefined;
  return {
    bucket: found.bucket,
    status: found.status,
    firedMatcherCount: (found.firedMatchers ?? []).length,
    declaredByCount: (found.declaredBy ?? []).length,
  };
}

function findingRules(doc) {
  return (doc.findings ?? []).map((finding) => `${finding.rule}:${finding.severity}`).sort();
}

// ---------------------------------------------------------------------------
// POS — markers that must resolve, and the two edge directions composing.
// ---------------------------------------------------------------------------

const handler = load('handler');

// The merge case. `0014` reaches this path by pattern AND is declared by the
// file, so it must carry both. If `declaredBy` ever replaced `firedMatchers`
// rather than joining it, this is what would catch it.
assert('POS-1', 'handler.ts: 0014 carries BOTH a fired matcher and a declaration', {
  bucket: 'activeProposals',
  status: 'proposed',
  firedMatcherCount: 1,
  declaredByCount: 1,
}, decision(handler, '0014'));

const ledger = load('ledger-client');

// Marker-only governance: no `affects` pattern in this corpus names
// `src/platform/**` from an orders record, so an empty `firedMatchers` with a
// non-empty `declaredBy` is the observable signature of "the file reached the
// record" rather than the reverse.
assert('POS-2', 'ledger-client.ts: 0005 governs by declaration alone (no fired matcher)', {
  bucket: 'governing',
  status: 'accepted',
  firedMatcherCount: 0,
  declaredByCount: 1,
}, decision(ledger, '0005'));

// The control for POS-2: a pattern-only decision on the same file must come
// back with no `declaredBy` key at all, which is what keeps `check --json`
// byte-identical for consumers written before markers existed.
assert('POS-3', 'ledger-client.ts: 0012 reaches the file by pattern only', {
  bucket: 'governing',
  status: 'accepted',
  firedMatcherCount: 1,
  declaredByCount: 0,
}, decision(ledger, '0012'));

// Status bucketing is not bypassed by declaring a record inbound. This is the
// property most worth pinning: a marker is a claim about relevance, not a grant
// of authority, so a `proposed` record stays non-binding however it was reached.
assert('POS-4', 'ledger-client.ts: declared-but-proposed 0015 stays a non-binding proposal', {
  bucket: 'activeProposals',
  status: 'proposed',
  firedMatcherCount: 0,
  declaredByCount: 1,
}, decision(ledger, '0015'));

// A comma continues the list; a bare space would have ended it.
assert('POS-5', 'ledger-client.ts: the comma list declares exactly two records', ['0005', '0015'], declaredRefs(ledger));

const notAMarker = load('not-a-marker');

// The block-comment `*` continuation is an accepted introducer, so this is a
// positive case deliberately living in the negative-fixture file. It is the
// boundary between the two rules: without it, a future tightening of the
// negative cases could kill block-comment declarations and still look clean.
assert('POS-6', 'not-a-marker.ts: the block-comment continuation DOES declare 0001', ['0001'], declaredRefs(notAMarker));

const fenced = load('fenced-examples');
assert('POS-7', 'fenced-examples.ts: the single unfenced marker declares 0002', ['0002'], declaredRefs(fenced));

const markdown = load('markdown-introducers');
assert('POS-8', 'markdown-introducers.md: the HTML comment declares 0003', ['0003'], declaredRefs(markdown));

const mdx = load('mdx-introducer');
assert('POS-9', 'mdx-introducer.mdx: the JSX expression comment declares 0004', ['0004'], declaredRefs(mdx));

// ---------------------------------------------------------------------------
// NEG — marker-looking lines that must NOT declare.
//
// These are stated as "the declared set is exactly X" rather than "Y is absent".
// An absence assertion passes trivially when the scanner stops finding anything
// at all; an exact-set assertion fails in both directions.
// ---------------------------------------------------------------------------

// not-a-marker.ts contains five marker-looking lines and exactly one real
// declaration. Pinning the declaring line's introducer, not just the ref, is
// what makes this non-vacuous: every decoy names 0001 too, so a ref-only
// assertion would still pass if the trailing marker were the one that resolved.
// `* ` is the block-comment continuation; `return 'trailing'; //` would be the
// trailing case, and neither the string literal nor the prose leads with `@adr`.
assert(
  'NEG-1',
  'not-a-marker.ts: only the block comment declares (trailing/string/prose/scope do not)',
  ['* @adr 0001'],
  declaredLineText('not-a-marker', notAMarker).map((text) => text.slice(0, '* @adr 0001'.length)),
);

// Six fenced markers across backtick, tilde, longer-fence and info-string
// forms, none of which may declare.
assert('NEG-2', 'fenced-examples.ts: no fenced marker declares', false, declaredRefs(fenced).some((ref) => ref !== '0002'));

// Markdown gets `<!--` and `{/*` only. `#`, `*`, `--`, `%` and `;` are all
// comments in some source language and none of them is one here.
assert('NEG-3', 'markdown-introducers.md: source-language introducers do not declare in markdown', ['0003'], declaredRefs(markdown));

// `.mdx` uses markdown's introducer set too, so the heading must stay inert.
assert('NEG-4', 'mdx-introducer.mdx: a heading does not declare in MDX', false, declaredRefs(mdx).includes('0001'));

// ---------------------------------------------------------------------------
// FIND — markers that resolve to nothing, and their deliberately split severity.
// ---------------------------------------------------------------------------

const unresolvable = load('unresolvable');

assert('FIND-1', 'unresolvable.ts: a dangling ref warns and a foreign log is info', ['dangling-marker:warn', 'marker-unresolvable:info'], findingRules(unresolvable));

// Both markers were scanned and accepted as well-formed. This separates "the
// scanner did not see them" from "the scanner saw them and could not bind
// them", which is the distinction the finding severities exist to express.
assert('FIND-2', 'unresolvable.ts: both refs were scanned before failing to resolve', ['9999', 'payments:0012'], declaredRefs(unresolvable));

// A log-qualified ref must not silently bind to the local record of the same
// id. `0012` exists in this corpus, so this is the case where a sloppy
// implementation would resolve and be wrong.
assert('FIND-3', 'unresolvable.ts: neither marker produces a governance edge', [], unresolvable.governedBy ?? []);

// Markers never influence exit status.
assert('FIND-4', 'adr check exits 0 despite a dangling marker', '0', readFileSync(join(captureDir, 'check-exit.txt'), 'utf8').trim());

// ---------------------------------------------------------------------------
// TRUNC — the measured scan extent, which is what v0.6.0 added.
// ---------------------------------------------------------------------------

const overWindow = load('over-window');
const markers = overWindow.markers ?? {};
const realSize = Number(readFileSync(join(captureDir, 'over-window-size.txt'), 'utf8').trim());

assert('TRUNC-1', 'over-window.ts: the scan is reported as truncated', true, markers.truncated);

assert('TRUNC-2', 'over-window.ts: scannedBytes is strictly less than fileBytes', true, markers.scannedBytes < markers.fileBytes);

// The window constant is NOT the extent: the scan stops at the last complete
// line inside the bound. Asserted as an inequality rather than a literal so an
// unrelated edit to the fixture's padding cannot masquerade as a regression.
assert('TRUNC-3', 'over-window.ts: scannedBytes falls short of the window constant (line-boundary cut)', true, markers.scannedBytes < markers.windowBytes);

// fileBytes is cross-checked against the real on-disk size rather than trusted
// from the tool that reported it.
assert('TRUNC-4', 'over-window.ts: fileBytes equals the on-disk size', realSize, markers.fileBytes);

// Truncation must not lose a declaration that was inside the window.
assert('TRUNC-5', 'over-window.ts: the header marker still resolves despite truncation', {
  bucket: 'governing',
  status: 'accepted',
  firedMatcherCount: 0,
  declaredByCount: 1,
}, decision(overWindow, '0011'));

// ---------------------------------------------------------------------------
// SCAN — the batch surface the CI Action consumes.
// ---------------------------------------------------------------------------

const check = JSON.parse(readFileSync(join(captureDir, 'check.json'), 'utf8'));
const scan = check.markerScan ?? {};

assert('SCAN-1', 'check --json reports a marker scan over every fixture passed', 7, scan.totalCandidates);

assert('SCAN-2', 'check --json counts exactly one truncated file', 1, scan.counts?.truncated);

assert('SCAN-3', 'check --json names the truncated file', ['fixtures/markers/over-window.ts'], scan.truncatedPaths);

assert('SCAN-4', 'check --json reports nothing absent, unreadable, out-of-tree, or skipped', {
  absent: 0,
  unreadable: 0,
  'out-of-tree': 0,
  skipped: 0,
}, {
  absent: scan.counts?.absent,
  unreadable: scan.counts?.unreadable,
  'out-of-tree': scan.counts?.['out-of-tree'],
  skipped: scan.counts?.skipped,
});

// ---------------------------------------------------------------------------

for (const check of checks) {
  console.log(`${check.ok ? 'ok  ' : 'FAIL'} ${check.id}  ${check.description}`);
  if (!check.ok) {
    console.log(`       expected: ${JSON.stringify(check.expected)}`);
    console.log(`       observed: ${JSON.stringify(check.observed)}`);
  }
}

const failed = checks.filter((check) => !check.ok);
console.log('');
if (failed.length > 0) {
  console.log(`Marker validation FAILED: ${failed.length} of ${checks.length} assertion(s) did not hold.`);
  console.log(`failing: ${failed.map((check) => check.id).join(', ')}`);
  process.exit(1);
}
console.log(`Marker validation OK: ${checks.length} assertions passed.`);
