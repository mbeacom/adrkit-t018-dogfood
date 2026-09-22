---
schemaVersion: 0.1.0
id: "0016"
title: Adopt connection pooling for temporal workers
status: superseded
date: 2025-11-01
supersededBy: "0017"
deciders: ["@mbeacom"]
tags: [dogfood, temporal, as-of]
scope: component
reversibility: two-way-door
blastRadius: component
affects:
  - type: path
    pattern: "src/temporal/pool/**"
---

# Adopt connection pooling for temporal workers

Fixture for [ADR-0039](https://github.com/mbeacom/adrkit/blob/main/docs/adr/0039-derive-a-valid-time-window-from-date-and-supersession-and-resolve-a-git-ref-at-th.md)
rung-2 evidence (ADR-0039 action item 5). Superseded by `0017`; the pair opens
this record's valid-time window on `2025-11-01` and closes it on `2017`'s own
`date`, `2026-02-01`.
