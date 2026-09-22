---
schemaVersion: 0.1.0
id: "0017"
title: Adopt a managed connection-pool service for temporal workers
status: superseded
date: 2026-02-01
supersededBy: "0018"
deciders: ["@mbeacom"]
tags: [dogfood, temporal, as-of]
scope: component
reversibility: two-way-door
blastRadius: component
affects:
  - type: path
    pattern: "src/temporal/pool/**"
---

# Adopt a managed connection-pool service for temporal workers

Fixture for ADR-0039 rung-2 evidence. Supersedes `0016` (opens this record's
window and closes `0016`'s) and is itself superseded by `0018`. Exercises the
**immediate, not terminal**, successor rule: a query for `0016` as-of a date in
`0018`'s tenure must report `0016`'s window as closed by `0017`, not by `0018`.
