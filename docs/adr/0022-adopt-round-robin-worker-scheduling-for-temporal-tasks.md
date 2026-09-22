---
schemaVersion: 0.1.0
id: "0022"
title: Adopt round-robin worker scheduling for temporal tasks
status: accepted
date: 2026-03-01
deciders: ["@mbeacom"]
tags: [dogfood, temporal, as-of]
scope: component
reversibility: two-way-door
blastRadius: component
affects:
  - type: path
    pattern: "src/temporal/inverted/**"
---

# Adopt round-robin worker scheduling for temporal tasks

Fixture for ADR-0039 rung-2 evidence. Dated `2026-03-01`, one month before
`0021` — the record it is named as the successor of. Currently the accepted,
governing decision for `src/temporal/inverted/**`.
