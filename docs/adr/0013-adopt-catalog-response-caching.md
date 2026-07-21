---
schemaVersion: 0.1.0
id: "0013"
title: Adopt in-memory response caching for the catalog service
status: proposed
date: 2026-07-18
deciders: ["@mbeacom"]
tags: [dogfood, arb-queue]
scope: component
reversibility: two-way-door
blastRadius: component
affects:
  - type: path
    pattern: "src/catalog/**"
review:
  tier: auto
  tierReason: "Two-way-door change with component-level blast radius; qualifies for the expedited auto-approve routing lane."
  queuedAt: "2026-07-18T00:00:00Z"
  slaDays: 14
  quorum: 1
---

# Adopt in-memory response caching for the catalog service

Add a short-lived in-memory cache in front of catalog read endpoints to reduce
duplicate lookups under load. The cache is easily reverted (two-way-door) and
scoped to a single component, so it is routed through the `auto` tier of the
Phase 6 ARB operations queue for expedited, human-accepted rollout rather than
full asynchronous or ARB review.
