---
schemaVersion: 0.1.0
id: "0015"
title: Migrate the order settlement ledger to an append-only event store
status: proposed
date: 2026-07-10
deciders: ["@mbeacom", "@octocat", "team:arb"]
tags: [dogfood, arb-queue]
scope: org
reversibility: one-way-door
blastRadius: org
affects:
  - type: path
    pattern: "src/orders/**"
review:
  tier: arb
  tierReason: "One-way-door migration with org-wide blast radius; requires full ARB human review and quorum before it may proceed."
  queuedAt: "2026-07-10T00:00:00Z"
  slaDays: 11
  quorum: 3
  approvals: ["@mbeacom", "@octocat"]
---

# Migrate the order settlement ledger to an append-only event store

Replace the mutable order settlement ledger table with an append-only event
store to preserve a full audit trail and simplify downstream reconciliation.
The migration is irreversible once historical writes are backfilled
(one-way-door) and affects every consumer of order settlement data
(org-wide blast radius), so it is routed through the `arb` tier for full ARB
human review rather than the `auto` or `async` lanes.

This record was queued on `2026-07-10` with an 11-day SLA, placing its
computed deadline on `2026-07-21` — the fixed `--as-of` date used for the
dogfood queue evidence in this repository, so the record is deterministically
`due` on that run. Two of the three-decider quorum have approved; ARB review
is still pending the third decision.
