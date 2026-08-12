// @adr 0014
//
// The marker above is the inbound half of this repository's marker coverage: a
// file declaring the decision it lives under, rather than a record declaring the
// files it affects. `0014` already reaches this path by pattern
// (`affects: src/payments/**`), so this is deliberately the *merge* case — the
// decision is reported with both `via path:` and `declared by`, which is the
// only way to see that the two edge directions compose rather than shadow each
// other. See scripts/validate-markers.sh (assertion `POS-1`).
//
// Touched deliberately by the repin to adrkit bbe63e01 (PR #8) so that this
// governed path appears in that PR's changed-file set and the `adr.yml`
// governance Action posts a real, status-bucketed comment as live evidence.
// This is a no-op comment on purpose: this file is Phase 3 T018 evidence, and
// the point is to trigger the workflow, not to change the governed subject
// matter. See README.md ("Live governance comment (status-aware)").
export function handlePayment(): string {
  return 'created';
}

export function refundPayment(): string {
  return 'refunded';
}
