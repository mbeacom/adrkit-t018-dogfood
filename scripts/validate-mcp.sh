#!/usr/bin/env bash
# Validates the adrkit MCP server configured for this repository.
#
# This repository configures an adrkit MCP server for GitHub Copilot cloud agent,
# Copilot code review, Copilot CLI, and VS Code, so agents working here can ask
# the corpus what governs a file instead of guessing. That configuration is only
# worth something if the server it names is pinned, unmodified, and returns the
# answers CI will actually enforce. This script asserts all three.
#
# Like scripts/validate-queue.sh, this is owner-run technical validation, not
# specs/007-arb-queue SC-004 / T048 evidence. See README.md ("Status boundary").
#
# What it does:
#   1. Checks the Node toolchain against @adrkit/mcp's declared engines range.
#   2. Downloads the exact pinned npm tarball and verifies its sha512 integrity
#      against the value recorded here, so the pin is immutable in the same sense
#      the Action SHA and the release-asset sha256 are.
#   3. Verifies the published tarball against the adrkit commit this repository
#      pins, by diffing the src/ tree the package ships against the same tree at
#      that commit. This is what licenses using npm for MCP at all: without it,
#      "the MCP server matches our pinned Action" would be an assumption.
#   4. Asserts the three checked-in client configurations agree with each other
#      and with the pin.
#   5. Drives the server over stdio JSON-RPC against this repository's real
#      corpus and asserts the four-tool surface, the read-only annotations, the
#      governance resolution for a governed path, and input rejection.
#   6. Asserts the run mutated nothing -- the server claims to be read-only, so
#      that claim is checked rather than trusted.
#
# Nothing here writes to the corpus and nothing is committed.
set -euo pipefail

# Pin: the exact published @adrkit/mcp version agents in this repository run. It
# is duplicated in .github/copilot-mcp-config.json, .copilot/mcp-config.json, and
# .vscode/mcp.json; step 4 fails the build if any of them drift from it.
#
# Do NOT change this to a dist-tag or a semver range. `npx -y @adrkit/mcp`
# without a version resolves at launch, which would mean every agent session in
# this repository ran against whatever was current that day, with no way to tell
# afterwards which code produced a given answer.
ADRKIT_MCP_VERSION="0.13.0"

# The npm registry's own integrity for that exact tarball. This is the npm
# analogue of ADRKIT_EXT_SHA256 in .github/workflows/spec-kit-extension.yml: a
# version number alone is a name, and names can in principle be re-pointed, so
# what is verified is the content.
ADRKIT_MCP_SHA512="sha512-aL2X38xNmriULdAlf11lMakb6FKYNsQOdzDPQwPO+6W1JO1KXgBxfVtpmEuHpZqMp9dJQH1qsi0ebd05CtlFhQ=="

# The adrkit commit this repository pins everywhere else -- the commit behind the
# v0.13.0 release tag. Kept in sync with scripts/validate-queue.sh; step 3 is what
# proves the npm package above and this commit are the same code.
ADRKIT_REF="3e40675ed6f513d9712b1dccaa68034d649d1eb9"
ADRKIT_REPO="${ADRKIT_REPO:-https://github.com/mbeacom/adrkit.git}"

# From @adrkit/mcp's package.json "engines".
MIN_NODE_MAJOR=22

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_SPEC="@adrkit/mcp@${ADRKIT_MCP_VERSION}"

WORKDIR="$(mktemp -d)"
cleanup() { rm -rf "${WORKDIR}"; }
trap cleanup EXIT

echo "==> Checking Node toolchain"
if ! command -v node >/dev/null 2>&1; then
  echo "error: node is not installed; @adrkit/mcp requires Node >= ${MIN_NODE_MAJOR}" >&2
  exit 1
fi
NODE_VERSION="$(node --version)"
NODE_MAJOR="${NODE_VERSION#v}"
NODE_MAJOR="${NODE_MAJOR%%.*}"
if (( NODE_MAJOR < MIN_NODE_MAJOR )); then
  echo "error: Node ${NODE_VERSION} is below @adrkit/mcp's engines range (>= ${MIN_NODE_MAJOR})" >&2
  exit 1
fi
echo "node ${NODE_VERSION} (>= ${MIN_NODE_MAJOR})"

echo ""
echo "==> Verifying the pinned npm tarball integrity"
TARBALL="${WORKDIR}/adrkit-mcp.tgz"
TARBALL_URL="https://registry.npmjs.org/@adrkit/mcp/-/mcp-${ADRKIT_MCP_VERSION}.tgz"
curl -fsSL -o "${TARBALL}" "${TARBALL_URL}"
OBSERVED_SHA512="sha512-$(openssl dgst -sha512 -binary "${TARBALL}" | openssl base64 -A)"
if [[ "${OBSERVED_SHA512}" != "${ADRKIT_MCP_SHA512}" ]]; then
  echo "error: integrity mismatch for ${PACKAGE_SPEC}" >&2
  echo "  expected: ${ADRKIT_MCP_SHA512}" >&2
  echo "  observed: ${OBSERVED_SHA512}" >&2
  echo "The pinned tarball is not the tarball this repository verified." >&2
  exit 1
fi
echo "integrity ok: ${PACKAGE_SPEC}"
echo "  ${OBSERVED_SHA512}"

echo ""
echo "==> Verifying the published package against pinned adrkit ${ADRKIT_REF:0:8}"
# The package ships its own src/ (package.json "files"), which makes this a
# byte-level check rather than a version-string comparison. Only the pinned
# commit is fetched, blobless and shallow, so this stays cheap enough to run on
# every pull request.
mkdir -p "${WORKDIR}/pkg" "${WORKDIR}/adrkit" "${WORKDIR}/fromgit"
tar xzf "${TARBALL}" -C "${WORKDIR}/pkg"

git -C "${WORKDIR}/adrkit" init -q .
git -C "${WORKDIR}/adrkit" remote add origin "${ADRKIT_REPO}"
git -C "${WORKDIR}/adrkit" fetch -q --depth 1 --filter=blob:none origin "${ADRKIT_REF}"
git -C "${WORKDIR}/adrkit" archive FETCH_HEAD packages/mcp/src \
  | tar x -C "${WORKDIR}/fromgit"

if ! diff -r "${WORKDIR}/pkg/package/src" "${WORKDIR}/fromgit/packages/mcp/src"; then
  echo "error: ${PACKAGE_SPEC} src/ differs from adrkit ${ADRKIT_REF} packages/mcp/src" >&2
  echo "The npm channel and the pinned commit are not the same code. Do not" >&2
  echo "assume the MCP server matches the Action this repository pins." >&2
  exit 1
fi

PACKED_VERSION="$(node -e 'process.stdout.write(require(process.argv[1]).version)' \
  "${WORKDIR}/pkg/package/package.json")"
if [[ "${PACKED_VERSION}" != "${ADRKIT_MCP_VERSION}" ]]; then
  echo "error: tarball declares version ${PACKED_VERSION}, expected ${ADRKIT_MCP_VERSION}" >&2
  exit 1
fi
echo "src/ is byte-identical to adrkit ${ADRKIT_REF} packages/mcp/src (version ${PACKED_VERSION})"

echo ""
echo "==> Cross-checking the adrkit pin against scripts/validate-queue.sh"
# The commit SHA is duplicated across validation scripts. Repinning one and
# forgetting the other would leave both workflows green while they validated
# different code, which is exactly the failure the pin discipline exists to
# prevent. Extracted mechanically rather than compared by eye.
QUEUE_REF="$(sed -n 's/^ADRKIT_REF="\([0-9a-f]\{40\}\)"$/\1/p' \
  "${REPO_ROOT}/scripts/validate-queue.sh" | head -n 1)"
if [[ -z "${QUEUE_REF}" ]]; then
  echo "error: could not extract ADRKIT_REF from scripts/validate-queue.sh" >&2
  echo "The cross-check cannot be silently skipped; fix the extraction." >&2
  exit 1
fi
if [[ "${QUEUE_REF}" != "${ADRKIT_REF}" ]]; then
  echo "error: adrkit pin disagreement between validation scripts" >&2
  echo "  validate-mcp.sh:   ${ADRKIT_REF}" >&2
  echo "  validate-queue.sh: ${QUEUE_REF}" >&2
  exit 1
fi
echo "both validation scripts pin ${ADRKIT_REF}"

echo ""
echo "==> Installing the verified tarball (with its dependency closure)"
# Installed from the local, integrity-verified file rather than by name, so the
# package that runs is provably the tarball checked above. `npx -y
# @adrkit/mcp@0.13.0` would re-resolve by name and could execute a cached or
# hoisted same-version copy, which a version string cannot distinguish.
#
# Scope: this pins @adrkit/mcp itself. Its dependencies (@adrkit/core,
# @modelcontextprotocol/server, zod) are resolved by npm at install time and are
# NOT content-pinned here -- see README.md, "What is pinned, and why npm is
# acceptable here", which states that limitation rather than implying otherwise.
npm install --silent --no-audit --no-fund \
  --prefix "${WORKDIR}/install" "${TARBALL}" >/dev/null 2>&1

MCP_BIN="${WORKDIR}/install/node_modules/.bin/adrkit-mcp"
if [[ ! -x "${MCP_BIN}" ]]; then
  echo "error: expected the adrkit-mcp binary at ${MCP_BIN}" >&2
  exit 1
fi
echo "installed: ${MCP_BIN}"

echo ""
echo "==> Asserting the checked-in MCP configurations agree"
node "${REPO_ROOT}/scripts/assert-mcp-config.mjs" \
  "${REPO_ROOT}" "${ADRKIT_MCP_VERSION}" "${ADRKIT_MCP_SHA512}"

# Recorded before the server runs so the read-only claim can be checked after.
CORPUS_BEFORE="$(cd "${REPO_ROOT}" && find docs/adr -type f -exec shasum -a 256 {} \; | LC_ALL=C sort)"

echo ""
echo "==> Driving the MCP server over stdio JSON-RPC"
node "${REPO_ROOT}/scripts/assert-mcp-surface.mjs" \
  "${REPO_ROOT}" "${MCP_BIN}" "${ADRKIT_MCP_VERSION}"

echo ""
echo "==> Asserting the run mutated nothing"
CORPUS_AFTER="$(cd "${REPO_ROOT}" && find docs/adr -type f -exec shasum -a 256 {} \; | LC_ALL=C sort)"
if [[ "${CORPUS_BEFORE}" != "${CORPUS_AFTER}" ]]; then
  echo "error: docs/adr changed while the MCP server ran; it is not read-only" >&2
  diff <(echo "${CORPUS_BEFORE}") <(echo "${CORPUS_AFTER}") >&2 || true
  exit 1
fi
echo "docs/adr is byte-identical before and after the run"

echo ""
echo "MCP validation complete: ${PACKAGE_SPEC} == adrkit@${ADRKIT_REF}."
