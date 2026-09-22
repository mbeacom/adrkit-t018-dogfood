// @adr 0016
//
// Fixture for ADR-0039 rung-2 evidence (adrkit-t018-dogfood). This marker
// names 0016, which is superseded today, so present-tense `adr explain` and
// `adr check` must report `stale-marker`. Under `--as-of` for any date inside
// 0016's valid-time window (2025-11-01 through 2026-01-31, inclusive), the
// same marker must be reported as accurate for that date and the
// `stale-marker` finding must be suppressed. Outside that window it must
// remain stale, including under `--as-of`.
export function acquireWorkerConnection(): void {
  // Intentionally empty: this file exists to be scanned, not executed.
}
