#!/usr/bin/env bash
# Reference validation for the adrkit Spec Kit extension (ADR-0014 rung 2).
#
# Downloads the extension's published release asset, verifies it against a
# pinned sha256 before it is allowed to touch anything, installs it into a real
# Spec Kit project at a pinned upstream version, then asserts its behavior
# against this repository's real ADR corpus.
#
# Self-verifying: every expectation below is asserted mechanically and this
# script exits non-zero the moment observed diverges from expected. It never
# asks a human to read a log and decide.
#
# Fail-closed: the FC-* assertions prove the consumer-facing failure modes exit
# non-zero, name the missing dependency, and — critically — produce no side
# effect before failing.
set -euo pipefail

SPECIFY_VERSION="${SPECIFY_VERSION:?SPECIFY_VERSION is required}"
ADRKIT_CLI_VERSION="${ADRKIT_CLI_VERSION:?ADRKIT_CLI_VERSION is required}"
ADRKIT_EXT_TAG="${ADRKIT_EXT_TAG:?ADRKIT_EXT_TAG (extension release tag) is required}"
ADRKIT_EXT_VERSION="${ADRKIT_EXT_VERSION:?ADRKIT_EXT_VERSION (version the artifact must declare) is required}"
ADRKIT_EXT_URL="${ADRKIT_EXT_URL:?ADRKIT_EXT_URL (release asset URL) is required}"
ADRKIT_EXT_SHA256="${ADRKIT_EXT_SHA256:?ADRKIT_EXT_SHA256 (pinned asset digest) is required}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
PROJECT="$WORK/project"
VENV="$WORK/venv"
SANDBOX_BIN="$WORK/sandbox-bin"

FAILURES=0
declare -a ROWS=()

record() { # id | expectation | expected | observed | outcome
	ROWS+=("$1|$2|$3|$4|$5")
}

assert_eq() { # id, expectation, expected, observed
	local id="$1" what="$2" expected="$3" observed="$4"
	if [ "$expected" = "$observed" ]; then
		record "$id" "$what" "$expected" "$observed" "PASS"
		printf '  ✓ %-6s %s\n' "$id" "$what"
	else
		record "$id" "$what" "$expected" "$observed" "FAIL"
		printf '  ✗ %-6s %s\n      expected: %s\n      observed: %s\n' "$id" "$what" "$expected" "$observed"
		FAILURES=$((FAILURES + 1))
	fi
}

assert_contains() { # id, expectation, needle, haystack
	local id="$1" what="$2" needle="$3" haystack="$4"
	if printf '%s' "$haystack" | grep -qF -- "$needle"; then
		assert_eq "$id" "$what" "contains: $needle" "contains: $needle"
	else
		assert_eq "$id" "$what" "contains: $needle" "ABSENT (got: $(printf '%s' "$haystack" | head -c 160))"
	fi
}

emit_evidence() {
	{
		echo "# Expected vs observed — spec-kit ${SPECIFY_VERSION}, adrkit extension ${ADRKIT_EXT_TAG} (sha256 ${ADRKIT_EXT_SHA256})"
		echo
		echo "| id | expectation | expected | observed | outcome |"
		echo "|---|---|---|---|---|"
		for row in "${ROWS[@]}"; do
			IFS='|' read -r id what expected observed outcome <<<"$row"
			echo "| \`$id\` | $what | \`$expected\` | \`$observed\` | **$outcome** |"
		done
	} >"${EVIDENCE_OUT:-$WORK/evidence.md}"
}

ASSET="$WORK/adrkit.zip"

# --------------------------------------------------------------------------
# Pinned inputs, verified rather than assumed.
#
# PIN-1 is the load-bearing one and it runs first: the artifact is only allowed
# to reach `specify extension add` after its digest matches the pin. A mismatch
# aborts here, before any install side effect.
#
# The download is routed through an assertion rather than left to `set -e`. A
# 404 or a network failure is a real result about the pinned artifact, and it
# should be recorded as a FAIL row in the evidence table like everything else —
# not vanish into a bare non-zero exit with no evidence written.
# --------------------------------------------------------------------------
echo "== pinned inputs =="
curl -fsSL --retry 3 -o "$ASSET" "$ADRKIT_EXT_URL" && CURL_RC=0 || CURL_RC=$?
assert_eq "PIN-0" "release asset downloads from the pinned URL" "0" "$CURL_RC"

if [ "$CURL_RC" -ne 0 ]; then
	OBSERVED_SHA="UNAVAILABLE (download failed, curl exit $CURL_RC)"
else
	OBSERVED_SHA="$(sha256sum "$ASSET" | cut -d' ' -f1)"
fi
assert_eq "PIN-1" "release asset matches the pinned sha256 (checked before install)" \
	"$ADRKIT_EXT_SHA256" "$OBSERVED_SHA"
if [ "$ADRKIT_EXT_SHA256" != "$OBSERVED_SHA" ]; then
	emit_evidence
	echo "REFERENCE VALIDATION FAILED: pinned artifact unusable; refusing to install" >&2
	exit 1
fi

python3 -m venv "$VENV" >/dev/null
"$VENV/bin/pip" install --quiet "specify-cli @ git+https://github.com/github/spec-kit@v${SPECIFY_VERSION}"
SPECIFY="$VENV/bin/specify"
assert_eq "PIN-2" "specify CLI is the pinned version" "specify $SPECIFY_VERSION" "$("$SPECIFY" --version 2>&1 | head -1 | tr -d '\r')"

npm install --silent --prefix "$WORK/npm" "@adrkit/cli@${ADRKIT_CLI_VERSION}" >/dev/null 2>&1
export PATH="$WORK/npm/node_modules/.bin:$PATH"
assert_eq "PIN-3" "adr CLI is the pinned published version" "$ADRKIT_CLI_VERSION" "$(adr --version 2>&1 | tr -d '\r')"

# --------------------------------------------------------------------------
# Install into a real Spec Kit project.
# --------------------------------------------------------------------------
echo "== install =="
mkdir -p "$PROJECT"
git -C "$PROJECT" init -q .
(cd "$PROJECT" && "$SPECIFY" init --here --integration copilot --script sh --force --ignore-agent-tools >/dev/null 2>&1)
assert_eq "INS-1" "Spec Kit project initialized" "true" "$([ -d "$PROJECT/.specify" ] && echo true || echo false)"

# Install from the release asset over HTTPS — the path a real consumer takes
# while the upstream catalog entry is pending. `--from` is default-deny: it
# prints an untrusted-source panel and calls typer.confirm(default=False), so
# with no TTY the install aborts unless stdin supplies the answer.
ADD_OUT="$(cd "$PROJECT" && printf 'y\n' | "$SPECIFY" extension add adrkit --from "$ADRKIT_EXT_URL" 2>&1)" || true
assert_contains "INS-2" "extension installs cleanly from the release asset" "Extension installed successfully" "$ADD_OUT"

INSTALLED="$PROJECT/.specify/extensions/adrkit"
assert_contains "PIN-4" "installed manifest declares the pinned extension version" \
	"version: \"$ADRKIT_EXT_VERSION\"" "$(cat "$INSTALLED/extension.yml")"
for cmd in context check draft; do
	assert_eq "INS-3.$cmd" "command speckit.adrkit.$cmd rendered for the agent" "true" \
		"$([ -f "$PROJECT/.github/agents/speckit.adrkit.$cmd.agent.md" ] && echo true || echo false)"
done

# --------------------------------------------------------------------------
# Hook contract. The hook is the only surface that fires without being typed,
# so its two invariants are asserted directly against the registry upstream
# actually consults.
# --------------------------------------------------------------------------
echo "== hook contract =="
REGISTRY="$PROJECT/.specify/extensions.yml"
assert_contains "HOOK-1" "hook registered on after_plan" "after_plan" "$(cat "$REGISTRY")"
assert_contains "HOOK-2" "hook targets the read-only check command" "command: speckit.adrkit.check" "$(cat "$REGISTRY")"
assert_contains "HOOK-3" "hook is optional, never automatic" "optional: true" "$(cat "$REGISTRY")"
assert_eq "HOOK-4" "no hook targets the writing draft command" "0" \
	"$(grep -c 'command: speckit.adrkit.draft' "$REGISTRY" || true)"

# --------------------------------------------------------------------------
# Packaging: what a consumer actually receives.
# --------------------------------------------------------------------------
echo "== packaging =="
for unwanted in test tsconfig.json package.json node_modules; do
	assert_eq "PKG-$unwanted" "development-only '$unwanted' not shipped to the consumer" "absent" \
		"$([ -e "$INSTALLED/$unwanted" ] && echo present || echo absent)"
done
# Exec bits are a spec-kit version boundary, not an extension property. The zip
# install path in 0.13.0 calls `zf.extractall()` and never restores Unix modes,
# so a bundled *.sh lands non-executable; 0.14.4 fixed it by calling
# `ensure_executable_scripts` after extraction, with a comment naming exactly
# this defect. So the expectation is asserted in both directions rather than
# skipped on 0.13.0 — if upstream ever backports the fix, or regresses it after
# 0.14.4, this goes red either way.
case "$SPECIFY_VERSION" in
0.13.0) EXPECT_EXEC="false" ;;
*) EXPECT_EXEC="true" ;;
esac
for script in adrkit-lib.sh context.sh check.sh draft.sh; do
	assert_eq "PKG-x-$script" "$script installed; executable iff spec-kit restores zip modes (>=0.14.4)" "$EXPECT_EXEC" \
		"$([ -x "$INSTALLED/scripts/$script" ] && echo true || echo false)"
	assert_eq "PKG-p-$script" "$script present regardless of mode" "true" \
		"$([ -f "$INSTALLED/scripts/$script" ] && echo true || echo false)"
done
assert_contains "PKG-ref" "rendered command points at the installed script path" \
	".specify/extensions/adrkit/scripts/check.sh" "$(cat "$PROJECT/.github/agents/speckit.adrkit.check.agent.md")"

# --------------------------------------------------------------------------
# Behavior against this repository's real ADR corpus.
# --------------------------------------------------------------------------
echo "== behavior against the real corpus =="
cp -R "$REPO_ROOT/docs" "$PROJECT/docs"
mkdir -p "$PROJECT/specs/001-reference"
printf '# Plan\n\nTouches src/orders and src/payments.\n' >"$PROJECT/specs/001-reference/plan.md"

run_in_project() { (cd "$PROJECT" && ADRKIT_FEATURE_DIR="$PROJECT/specs/001-reference" "$@"); }

CTX_OUT="$(run_in_project sh "$INSTALLED/scripts/context.sh" src/payments/api.ts 2>&1)" && CTX_RC=0 || CTX_RC=$?
assert_eq "BEH-1" "context exits 0 on a governed path" "0" "$CTX_RC"
# Positive assertion about a specific observed record, not a count: ADR 0001
# governs src/payments/** in this corpus. "0 decisions" and "I could not see the
# corpus" render identically, so a count would prove nothing.
assert_contains "BEH-2" "context names the decision governing src/payments" '"recordId": "0001"' "$CTX_OUT"

CTX2_OUT="$(run_in_project sh "$INSTALLED/scripts/context.sh" src/orders/ledger.ts 2>&1)" || true
assert_contains "BEH-3" "context surfaces the proposed ARB decision on src/orders" '"recordId": "0015"' "$CTX2_OUT"

QUEUE_OUT="$(run_in_project sh "$INSTALLED/scripts/context.sh" 2>&1)" || true
assert_contains "BEH-4" "context with no paths reports the open decision queue" '"asOf"' "$QUEUE_OUT"

CHK_OUT="$(run_in_project sh "$INSTALLED/scripts/check.sh" src/payments/api.ts 2>&1)" && CHK_RC=0 || CHK_RC=$?
assert_eq "BEH-5" "check exits 0 against a clean corpus" "0" "$CHK_RC"
assert_contains "BEH-6" "check emits its section marker" "==> adrkit:check" "$CHK_OUT"
assert_contains "BEH-7" "check announces that routing did not run without a snapshot" "no ADRKIT_SNAPSHOT configured" "$CHK_OUT"

# --------------------------------------------------------------------------
# Mutation. The hook can fire check unattended, so it must touch nothing.
# --------------------------------------------------------------------------
echo "== mutation =="
BEFORE="$(cd "$PROJECT" && find . -path ./.git -prune -o -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum)"
run_in_project sh "$INSTALLED/scripts/check.sh" src/payments/api.ts >/dev/null 2>&1 || true
run_in_project sh "$INSTALLED/scripts/context.sh" src/payments/api.ts >/dev/null 2>&1 || true
AFTER="$(cd "$PROJECT" && find . -path ./.git -prune -o -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum)"
assert_eq "MUT-1" "check and context mutate nothing in the consuming project" "$BEFORE" "$AFTER"
assert_eq "MUT-2" "the reference repository checkout is unmodified" "" "$(git -C "$REPO_ROOT" status --porcelain)"

# --------------------------------------------------------------------------
# Fail-closed. Each proves a non-zero exit, a message naming the missing
# dependency, and no side effect produced before failing.
# --------------------------------------------------------------------------
echo "== fail-closed =="
mkdir -p "$SANDBOX_BIN"
for util in sh dirname sed head date; do ln -sf "$(command -v "$util")" "$SANDBOX_BIN/$util"; done
if [ -e "$SANDBOX_BIN/adr" ]; then echo "sandbox is contaminated with an adr binary" >&2; exit 1; fi

FC1="$(cd "$PROJECT" && env -i PATH="$SANDBOX_BIN" ADRKIT_FEATURE_DIR="$PROJECT/specs/001-reference" \
	sh "$INSTALLED/scripts/context.sh" src/payments/api.ts 2>&1)" && FC1_RC=0 || FC1_RC=$?
assert_eq "FC-1a" "absent CLI exits non-zero" "nonzero" "$([ "$FC1_RC" -ne 0 ] && echo nonzero || echo zero)"
assert_contains "FC-1b" "absent CLI names the missing dependency" "adrkit's CLI is not installed" "$FC1"

FC2="$(cd "$WORK" && env -i PATH="$SANDBOX_BIN" sh "$INSTALLED/scripts/context.sh" 2>&1)" && FC2_RC=0 || FC2_RC=$?
assert_eq "FC-2a" "absent corpus exits non-zero" "nonzero" "$([ "$FC2_RC" -ne 0 ] && echo nonzero || echo zero)"
assert_contains "FC-2b" "absent corpus names the directory it looked in" "no ADR corpus at 'docs/adr'" "$FC2"

# The load-bearing one: the only writing command must fail *before* writing.
CORPUS_BEFORE="$(find "$PROJECT/docs/adr" -type f | sort | sha256sum)"
FC3="$(run_in_project sh "$INSTALLED/scripts/draft.sh" 2>&1)" && FC3_RC=0 || FC3_RC=$?
CORPUS_AFTER="$(find "$PROJECT/docs/adr" -type f | sort | sha256sum)"
assert_eq "FC-3a" "draft without a title is a usage error (exit 2)" "2" "$FC3_RC"
assert_contains "FC-3b" "draft without a title says what is missing" "draft needs a title" "$FC3"
assert_eq "FC-3c" "draft wrote no record before failing" "$CORPUS_BEFORE" "$CORPUS_AFTER"

FC4="$(cd "$PROJECT" && ADRKIT_FEATURE_DIR="$WORK" sh "$INSTALLED/scripts/draft.sh" Some Title 2>&1)" && FC4_RC=0 || FC4_RC=$?
CORPUS_AFTER2="$(find "$PROJECT/docs/adr" -type f | sort | sha256sum)"
assert_eq "FC-4a" "draft without a plan exits non-zero" "nonzero" "$([ "$FC4_RC" -ne 0 ] && echo nonzero || echo zero)"
assert_contains "FC-4b" "draft without a plan names the missing plan" "no plan at" "$FC4"
assert_eq "FC-4c" "draft wrote no record when the plan was missing" "$CORPUS_BEFORE" "$CORPUS_AFTER2"

# --------------------------------------------------------------------------
# Machine-readable evidence for the tracked index.
# --------------------------------------------------------------------------
emit_evidence

echo
echo "assertions: ${#ROWS[@]}, failures: $FAILURES"
if [ "$FAILURES" -ne 0 ]; then
	echo "REFERENCE VALIDATION FAILED" >&2
	exit 1
fi
echo "REFERENCE VALIDATION PASSED (spec-kit $SPECIFY_VERSION)"
