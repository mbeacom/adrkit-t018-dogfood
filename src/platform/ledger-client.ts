// @adr 0005, 0015
//
// Marker-only governance, which is the case this repository could not reach
// before markers existed.
//
// By pattern this file is a platform file: `0012` (`affects: src/platform/**`)
// is the only decision whose matcher fires on it. But it is a client of the
// order settlement ledger, so the decisions that actually constrain it are the
// orders ones — `0005` (accepted) and `0015` (proposed) — and neither of those
// records lists `src/platform/**` under `affects`. A pattern cannot express
// that without the orders records claiming a directory they do not own.
//
// The marker is the other direction: the file declares itself. `0005` is
// therefore reported with `declared by` and an EMPTY `firedMatchers`, which is
// the observable difference between "a record reached this file" and "this file
// reached a record".
//
// Two further properties are deliberate here rather than incidental:
//
//   * The comma list declares two records from one token. A bare space would
//     have ended the list instead, so `@adr 0005, 0015` is two declarations
//     while `@adr 0005 0015` would be one.
//   * `0015` is `proposed`, and it stays in the ACTIVE PROPOSALS bucket rather
//     than becoming binding. Status bucketing is not bypassed by declaring a
//     record inbound, which is the property most worth pinning: a marker is a
//     claim about relevance, not a grant of authority.
//
// Asserted by scripts/validate-markers.sh (`POS-2` through `POS-5`).

export interface LedgerEntry {
  id: string;
  amountMinorUnits: number;
}

export function appendEntry(entry: LedgerEntry): LedgerEntry {
  return entry;
}
