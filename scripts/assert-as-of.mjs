#!/usr/bin/env node
/**
 * Pure, network-free assertions over captured `adr explain --json` output for
 * this repository's `--as-of` fixtures (ADR-0039 rung-2 evidence, ADR-0039
 * action item 5).
 *
 * Split from scripts/validate-as-of.sh for the same reason
 * scripts/assert-markers.mjs is split from validate-markers.sh: the half that
 * decides whether the behavior is correct should not also be the half that
 * builds a toolchain and shells out. Everything here is a comparison over JSON
 * and text that was already captured; it performs no I/O beyond reading those
 * captures.
 *
 * Usage: assert-as-of.mjs <captureDir>
 *
 * `captureDir` holds one `<slug>.json` per `adr explain --json` capture, plus
 * `<slug>.exit` and `<slug>.stdout`/`<slug>.stderr` for the fail-closed and
 * git-ref captures. See validate-as-of.sh for the exact slugs produced.
 *
 * Exit codes: 0 = every assertion held; 1 = at least one did not.
 */

import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';

const [, , captureDir] = process.argv;
if (!captureDir) {
  console.error('usage: assert-as-of.mjs <captureDir>');
  process.exit(2);
}

const checks = [];

function assert(id, description, expected, observed) {
  const ok = JSON.stringify(expected) === JSON.stringify(observed);
  checks.push({ id, description, ok, expected, observed });
}

function assertTrue(id, description, ok, detail) {
  checks.push({ id, description, ok, expected: true, observed: detail ?? ok });
}

function loadJson(slug) {
  return JSON.parse(readFileSync(join(captureDir, `${slug}.json`), 'utf8'));
}

function loadText(slug, ext) {
  const path = join(captureDir, `${slug}.${ext}`);
  return existsSync(path) ? readFileSync(path, 'utf8') : '';
}

/** One decision from an as-of bucket, reduced to what these assertions care about. */
function decisionsOf(doc, bucket) {
  return (doc.asOf?.[bucket] ?? []).map((d) => d.recordId).sort();
}

function findingRules(doc) {
  return (doc.findings ?? []).map((f) => `${f.rule}:${f.severity}`).sort();
}

function decisionById(doc, bucket, recordId) {
  return (doc.asOf?.[bucket] ?? []).find((d) => d.recordId === recordId);
}

/** The union `governedBy` entry, present-tense, for cross-checking `bucket` vs `standing`. */
function governedById(doc, recordId) {
  return (doc.governedBy ?? []).find((d) => d.recordId === recordId);
}

// ---------------------------------------------------------------------------
// Scenario 1 — A -> B pair (0016 superseded-by 0017), half-open boundary.
// Fixture: docs/adr/0016 opens 2025-11-01, closes 2026-02-01 (0017's date).
// ---------------------------------------------------------------------------
{
  const before = loadJson('pool-before-open');
  assert('BOUND-1', '0016 is notYetRecorded the day before its own date (2025-10-31)',
    'notYetRecorded', decisionById(before, 'notYetRecorded', '0016')?.standing);
  assertTrue('BOUND-1b', '0016 appears in no other as-of bucket on 2025-10-31',
    decisionsOf(before, 'governing').length === 0 && decisionsOf(before, 'history').length === 0);

  const onOpen = loadJson('pool-on-open');
  assert('BOUND-2', '0016 is governing on its own opening date (2025-11-01), boundary inclusive',
    'governing', decisionById(onOpen, 'governing', '0016')?.standing);

  const lastDay = loadJson('pool-last-day-of-window');
  assert('BOUND-3', '0016 is still governing the day before handover (2026-01-31)',
    'governing', decisionById(lastDay, 'governing', '0016')?.standing);

  const handover = loadJson('pool-handover-day');
  assert('BOUND-4', '0016 is history on the handover day (2026-02-01) — the half-open close',
    'history', decisionById(handover, 'history', '0016')?.standing);
  assert('BOUND-5', '0017 is governing on the handover day (2026-02-01) — the successor owns the day',
    'governing', decisionById(handover, 'governing', '0017')?.standing);
  assertTrue('BOUND-6', 'exactly one of 0016/0017 is governing on the handover day',
    decisionsOf(handover, 'governing').filter((id) => id === '0016' || id === '0017').length === 1);
}

// ---------------------------------------------------------------------------
// Scenario 2 — A -> B -> C chain (0016 -> 0017 -> 0018): immediate, not
// terminal, successor. As-of a date inside 0018's tenure, 0016's window must
// still be closed by 0017 (its immediate successor), not by 0018.
// ---------------------------------------------------------------------------
{
  const inChain = loadJson('pool-during-terminal-tenure');
  const d0016 = decisionById(inChain, 'history', '0016');
  assert('CHAIN-1', '0016 window is closed by its immediate successor 0017, not the terminal 0018',
    '0017', d0016?.window?.closedBy);
  assert('CHAIN-2', '0016 standing is history (not governing) once 0017 opened, deep into 0018\'s tenure',
    'history', d0016?.standing);
  assert('CHAIN-3', '0017 (the middle link) is itself history once 0018 opened',
    'history', decisionById(inChain, 'history', '0017')?.standing);
  assert('CHAIN-4', '0018 (the terminal record) is governing',
    'governing', decisionById(inChain, 'governing', '0018')?.standing);
  assertTrue('CHAIN-5', 'exactly one record along the 0016/0017/0018 chain is governing',
    decisionsOf(inChain, 'governing').filter((id) => ['0016', '0017', '0018'].includes(id)).length === 1);
}

// ---------------------------------------------------------------------------
// Scenario 3 — deprecated (0019): undetermined, never governing, never history.
// ---------------------------------------------------------------------------
{
  const doc = loadJson('legacy-after-deprecation');
  assert('DEP-1', '0019 (deprecated, no successor derivable) is undetermined',
    'undetermined', decisionById(doc, 'undetermined', '0019')?.standing);
  assertTrue('DEP-2', '0019 never appears in governing or history',
    !decisionsOf(doc, 'governing').includes('0019') && !decisionsOf(doc, 'history').includes('0019'));
  assertTrue('DEP-3', 'a temporal-window-undetermined warning fires for 0019',
    findingRules(doc).includes('temporal-window-undetermined:warn'));
}

// ---------------------------------------------------------------------------
// Scenario 4 — rejected (0020): history on every date it could be asked about,
// never governing, never undetermined.
// ---------------------------------------------------------------------------
{
  const doc = loadJson('legacy-after-deprecation'); // same path/date probes both 0019 and 0020
  assert('REJ-1', '0020 (rejected) is history, not governing and not undetermined',
    'history', decisionById(doc, 'history', '0020')?.standing);
  assertTrue('REJ-2', '0020 never appears in governing or undetermined',
    !decisionsOf(doc, 'governing').includes('0020') && !decisionsOf(doc, 'undetermined').includes('0020'));

  const early = loadJson('legacy-on-rejection-date');
  assert('REJ-3', '0020 is history even exactly on its own recorded date (never in force at all)',
    'history', decisionById(early, 'history', '0020')?.standing);
}

// ---------------------------------------------------------------------------
// Scenario 5 — inverted pair (0021 superseded-by 0022, but 0022 dated
// BEFORE 0021). 0021 must never be governing on any date, must render no
// in-force interval, and must carry a temporal-window-inverted finding.
// ---------------------------------------------------------------------------
{
  const doc = loadJson('inverted-after-both-dates');
  assert('INV-1', '0021 (inverted window) is history, never governing, on a date after both records\' dates',
    'history', decisionById(doc, 'history', '0021')?.standing);
  assertTrue('INV-2', '0021 never appears in the governing bucket',
    !decisionsOf(doc, 'governing').includes('0021'));
  assertTrue('INV-3', 'a temporal-window-inverted warning fires for 0021',
    findingRules(doc).includes('temporal-window-inverted:warn'));
  assert('INV-4', '0022 (the accepted, earlier-dated record) is governing',
    'governing', decisionById(doc, 'governing', '0022')?.standing);

  const humanRendering = loadText('inverted-after-both-dates', 'stdout');
  assertTrue('INV-5', 'the human view renders "no in-force interval" for 0021, never "in force <opens> -> <closes>"',
    /no in-force interval/.test(humanRendering) && !/0021[\s\S]{0,200}in force\s+2026-04-01/i.test(humanRendering));
}

// ---------------------------------------------------------------------------
// Scenario 6 — marker suppression. src/temporal/pool/worker-pool.ts declares
// "@adr 0016". Present-tense: stale (0016 is superseded today). As-of inside
// 0016's window: accurate, suppressed. As-of outside it: stale again.
// ---------------------------------------------------------------------------
{
  const presentTense = loadJson('marker-present-tense');
  assertTrue('MARK-1', 'present-tense: stale-marker fires for the @adr 0016 declaration',
    findingRules(presentTense).includes('stale-marker:warn'));

  const inWindow = loadJson('marker-as-of-in-window');
  assertTrue('MARK-2', 'as-of inside 0016\'s window: stale-marker is suppressed',
    !findingRules(inWindow).includes('stale-marker:warn'));
  assert('MARK-3', 'as-of inside 0016\'s window: 0016 itself is reported governing',
    'governing', decisionById(inWindow, 'governing', '0016')?.standing);

  const outsideWindow = loadJson('marker-as-of-outside-window');
  assertTrue('MARK-4', 'as-of outside 0016\'s window (after handover): stale-marker fires again',
    findingRules(outsideWindow).includes('stale-marker:warn'));
}

// ---------------------------------------------------------------------------
// Scenario 7 — bucket vs standing legitimately disagree.
// 0016 is bucket:"history" (present tense, it is superseded) and can be
// standing:"governing" (as-of, inside its own window) at once.
// ---------------------------------------------------------------------------
{
  const onOpen = loadJson('pool-on-open');
  const present = governedById(onOpen, '0016');
  const asOf = decisionById(onOpen, 'governing', '0016');
  assert('DISAGREE-1', '0016 present-tense bucket is "history" (it is superseded today)',
    'history', present?.bucket);
  assert('DISAGREE-2', '0016 as-of standing is "governing" on the same response, same date',
    'governing', asOf?.standing);
}

// ---------------------------------------------------------------------------
// Scenario 8 — JSON shape and additive-only guarantee.
// ---------------------------------------------------------------------------
{
  const withFlag = loadJson('pool-on-open');
  assertTrue('SHAPE-1', 'asOf block carries requested/date/resolvedFrom',
    typeof withFlag.asOf?.requested === 'string' &&
      typeof withFlag.asOf?.date === 'string' &&
      typeof withFlag.asOf?.resolvedFrom === 'string');
  assertTrue('SHAPE-2', 'asOf block carries all five standing keys',
    ['governing', 'activeProposals', 'history', 'notYetRecorded', 'undetermined']
      .every((k) => Array.isArray(withFlag.asOf?.[k])));
  assertTrue('SHAPE-3', 'each as-of decision carries a window and a standing',
    (withFlag.asOf.governing).every((d) => d.window && typeof d.standing === 'string'));

  const withRef = loadJson('ref-committer-date');
  assertTrue('SHAPE-4', 'a ref-resolved asOf carries commit and committedAt',
    typeof withRef.asOf?.commit === 'string' && typeof withRef.asOf?.committedAt === 'string');
  assert('SHAPE-5', 'a ref-resolved asOf reports resolvedFrom: "ref"', 'ref', withRef.asOf?.resolvedFrom);

  const withoutFlag = loadJson('pool-no-flag');
  assertTrue('SHAPE-6', 'without --as-of, the asOf key is entirely absent',
    !Object.hasOwn(withoutFlag, 'asOf'));
  assert('SHAPE-7', 'without --as-of, top-level governing is present-tense (0018 only, chain terminal)',
    ['0018'], (withoutFlag.governing ?? []).map((d) => d.recordId).sort());
  assert('SHAPE-8', 'with --as-of, the SAME present-tense top-level governing key is unchanged',
    ['0018'], (withFlag.governing ?? []).map((d) => d.recordId).sort());
}

// ---------------------------------------------------------------------------
// Scenario 9 — date-shaped tag resolves as a date, never as a ref.
// ---------------------------------------------------------------------------
{
  const dateShapedTag = loadJson('date-shaped-tag-resolves-as-date');
  assert('REF-1', 'a value that is both a valid date and an existing tag name resolves via the date grammar',
    'date', dateShapedTag.asOf?.resolvedFrom);
  assertTrue('REF-2', 'resolving as a date means no commit/committedAt fields are present',
    !Object.hasOwn(dateShapedTag.asOf, 'commit') && !Object.hasOwn(dateShapedTag.asOf, 'committedAt'));
}

// ---------------------------------------------------------------------------
// Scenario 10 — fail-closed. Each of the four scenarios must exit 2, print
// nothing to stdout, and leave the corpus/working tree untouched (asserted by
// validate-as-of.sh via git status --porcelain around the whole run).
// ---------------------------------------------------------------------------
{
  const cases = [
    { slug: 'fail-invalid-date', mustContain: 'YYYY-MM-DD' },
    { slug: 'fail-tzless', mustContain: 'Timezone-less' },
    { slug: 'fail-no-such-ref', mustContain: 'git' },
    { slug: 'fail-outside-git-repo', mustContain: 'not a git repository' },
  ];
  for (const { slug, mustContain } of cases) {
    const exitCode = loadText(slug, 'exit').trim();
    const stdout = loadText(slug, 'stdout');
    const stderr = loadText(slug, 'stderr');
    assert(`FAIL-${slug}-exit`, `${slug}: exits 2`, '2', exitCode);
    assertTrue(`FAIL-${slug}-stdout`, `${slug}: stdout is empty`, stdout.length === 0, stdout);
    assertTrue(`FAIL-${slug}-message`, `${slug}: stderr names "${mustContain}"`, stderr.includes(mustContain), stderr);
  }
}

// ---------------------------------------------------------------------------
// Report
// ---------------------------------------------------------------------------
let failures = 0;
for (const check of checks) {
  if (check.ok) {
    console.log(`ok   ${check.id}  ${check.description}`);
  } else {
    failures += 1;
    console.log(`FAIL ${check.id}  ${check.description}`);
    console.log(`     expected: ${JSON.stringify(check.expected)}`);
    console.log(`     observed: ${JSON.stringify(check.observed)}`);
  }
}
// Machine-readable failure list, consumed by validate-as-of.sh's self-test.
for (const check of checks) {
  if (!check.ok) console.log(`failing: ${check.id}`);
}

console.log('');
if (failures > 0) {
  console.log(`As-of assertions FAILED: ${failures} of ${checks.length} failed.`);
  process.exit(1);
}
console.log(`As-of assertions OK: ${checks.length} checks passed.`);
