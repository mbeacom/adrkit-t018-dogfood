---
schemaVersion: 0.1.0
id: "0021"
title: Adopt sticky worker affinity for temporal tasks
status: superseded
date: 2026-04-01
supersededBy: "0022"
deciders: ["@mbeacom"]
tags: [dogfood, temporal, as-of]
scope: component
reversibility: two-way-door
blastRadius: component
affects:
  - type: path
    pattern: "src/temporal/inverted/**"
---

# Adopt sticky worker affinity for temporal tasks

Fixture for ADR-0039 rung-2 evidence. Deliberately inverted: its successor,
`0022`, is dated `2026-03-01` — **before** this record's own `2026-04-01` — so
the corpus disagrees with itself about which decision came first. The schema
does not and cannot forbid this (a `date` ordering constraint across two
records is not expressible on one record's frontmatter), so `adr lint` passes
this pair with zero findings; ADR-0039's kernel is the layer that must catch
it. `adr explain --as-of` must never report `0021` as `governing` on any date,
must emit a `temporal-window-inverted` warning, and must render no in-force
interval for it.
