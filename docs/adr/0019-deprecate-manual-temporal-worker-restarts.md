---
schemaVersion: 0.1.0
id: "0019"
title: Deprecate manual temporal worker restarts
status: deprecated
date: 2025-12-01
deciders: ["@mbeacom"]
tags: [dogfood, temporal, as-of]
scope: component
reversibility: two-way-door
blastRadius: component
affects:
  - type: path
    pattern: "src/temporal/legacy/**"
---

# Deprecate manual temporal worker restarts

Fixture for ADR-0039 rung-2 evidence. `status: deprecated` records no
`supersededBy` — the schema forbids it outside `status: superseded` — so this
record has no close date anywhere in its frontmatter. `adr explain --as-of`
must report it as `undetermined` with a `temporal-window-undetermined` finding
for any date on or after `2025-12-01`, never as `governing` and never as
`history`.
