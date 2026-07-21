---
schemaVersion: 0.1.0
id: "0014"
title: Introduce asynchronous cache invalidation for payments settlement events
status: proposed
date: 2026-05-15
deciders: ["@mbeacom", "team:platform-eng"]
tags: [dogfood, arb-queue]
scope: domain
reversibility: two-way-door
blastRadius: cross-team
reviewBy: 2026-06-01
affects:
  - type: path
    pattern: "src/payments/**"
review:
  tier: async
  tierReason: "Two-way-door change with cross-team blast radius; requires asynchronous human review before merge."
  queuedAt: "2026-05-15T00:00:00Z"
  slaDays: 17
  quorum: 2
  approvals: ["@mbeacom"]
  objections:
    - by: "@octocat"
      summary: "Cache invalidation lag could cause stale settlement totals during the migration window."
      resolved: false
---

# Introduce asynchronous cache invalidation for payments settlement events

Publish a settlement-events topic that downstream services subscribe to for
cache invalidation, replacing the current polling-based refresh. The change
crosses team boundaries (payments and platform), so it is routed through the
`async` tier for asynchronous human review rather than the `auto` fast path.

The explicit `reviewBy: 2026-06-01` deadline has elapsed relative to the
current ARB queue run, so this record is deterministically `overdue` for the
dogfood queue evidence captured in this repository — one of one approval
against a quorum of two, with one unresolved objection outstanding.
