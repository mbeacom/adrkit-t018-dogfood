#!/usr/bin/env bun
/**
 * Asserts that a QueueReport v1 JSON document (see
 * https://github.com/mbeacom/adrkit/blob/c5dc677f55c492056184c01252d9f812919c80f9/specs/007-arb-queue/contracts/queue-report.md)
 * produced by `adr queue --format json` matches the deterministic dogfood
 * expectations for this repository's docs/adr corpus:
 *
 *   - report.version === "1"
 *   - zero corpus findings (schema-valid corpus)
 *   - at least 3 proposed items
 *   - all three routing tiers (auto, async, arb) are represented
 *   - at least one item is "overdue" and at least one item is "due"
 *   - at least one item carries both approvals and objections
 *   - every item has at least one routing target (decider)
 *
 * Usage: bun scripts/assert-queue-report.ts <report.json> [expectedAsOf]
 */

import { readFileSync } from "node:fs";

interface QueueItem {
  tier: "auto" | "async" | "arb" | null;
  slaState: string;
  approvalCount: number;
  unresolvedObjectionCount: number;
  resolvedObjectionCount: number;
  routingTargets: string[];
}

interface QueueReport {
  version: string;
  asOf: string;
  totalItems: number;
  totalCorpusFindings: number;
  items: QueueItem[];
  corpusFindings: unknown[];
}

const [, , reportPath, expectedAsOf] = process.argv;

if (!reportPath) {
  console.error("Usage: assert-queue-report.ts <report.json> [expectedAsOf]");
  process.exit(2);
}

let report: QueueReport;
try {
  report = JSON.parse(readFileSync(reportPath, "utf8"));
} catch (error) {
  console.error(`FAIL: could not read or parse "${reportPath}" as JSON: ${(error as Error).message}`);
  process.exit(1);
}

if (report === null || typeof report !== "object") {
  console.error(`FAIL: parsed report is not an object (got ${JSON.stringify(report)})`);
  process.exit(1);
}

let failures = 0;

function assert(condition: unknown, message: string): void {
  if (!condition) {
    console.error(`FAIL: ${message}`);
    failures += 1;
  } else {
    console.log(`ok:   ${message}`);
  }
}

assert(report.version === "1", `QueueReport.version is "1" (got ${JSON.stringify(report.version)})`);

if (expectedAsOf) {
  assert(report.asOf === expectedAsOf, `QueueReport.asOf is "${expectedAsOf}" (got "${report.asOf}")`);
}

assert(report.totalCorpusFindings === 0, `zero corpus findings (got ${report.totalCorpusFindings})`);
assert(Array.isArray(report.corpusFindings) && report.corpusFindings.length === 0, "corpusFindings array is empty");
assert(report.totalItems >= 3, `at least 3 proposed items in the queue (got ${report.totalItems})`);

const items = Array.isArray(report.items) ? report.items : [];
assert(
  Array.isArray(report.items) && report.items.length === report.totalItems,
  `report.items is an array whose length matches totalItems (got ${items.length} items, totalItems ${report.totalItems})`,
);

const tiersPresent = new Set(items.map((item) => item.tier));

for (const tier of ["auto", "async", "arb"] as const) {
  assert(tiersPresent.has(tier), `at least one proposed item is routed to the "${tier}" tier`);
}

assert(items.some((item) => item.slaState === "overdue"), 'at least one item has slaState "overdue"');
assert(items.some((item) => item.slaState === "due"), 'at least one item has slaState "due"');

assert(
  items.some(
    (item) => item.approvalCount > 0 && (item.unresolvedObjectionCount > 0 || item.resolvedObjectionCount > 0),
  ),
  "at least one item carries both approvals and objections",
);

assert(
  items.every((item) => Array.isArray(item.routingTargets) && item.routingTargets.length > 0),
  "every queue item has at least one routing target (decider)",
);

console.log("");
if (failures > 0) {
  console.error(`Queue validation FAILED: ${failures} assertion(s) did not hold.`);
  process.exit(1);
}

console.log(`Queue validation OK: ${items.length} proposed item(s), 0 corpus findings, all tiers represented.`);
