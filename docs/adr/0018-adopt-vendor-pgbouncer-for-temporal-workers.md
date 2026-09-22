---
schemaVersion: 0.1.0
id: "0018"
title: Adopt vendored PgBouncer for temporal workers
status: accepted
date: 2026-05-01
deciders: ["@mbeacom"]
tags: [dogfood, temporal, as-of]
scope: component
reversibility: two-way-door
blastRadius: component
affects:
  - type: path
    pattern: "src/temporal/pool/**"
---

# Adopt vendored PgBouncer for temporal workers

Fixture for ADR-0039 rung-2 evidence. Terminal record of the `0016` → `0017` →
`0018` chain; the currently accepted, governing decision for
`src/temporal/pool/**`.
