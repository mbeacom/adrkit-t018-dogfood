---
schemaVersion: 0.1.0
id: "0020"
title: Reject a single global temporal worker pool
status: rejected
date: 2025-12-15
deciders: ["@mbeacom"]
tags: [dogfood, temporal, as-of]
scope: component
reversibility: two-way-door
blastRadius: component
affects:
  - type: path
    pattern: "src/temporal/legacy/**"
---

# Reject a single global temporal worker pool

Fixture for ADR-0039 rung-2 evidence. A `rejected` record was never in force at
any time, so `adr explain --as-of` must report it as `history` for every date
on or after `2025-12-15`, never as `governing` and never as `undetermined`.
