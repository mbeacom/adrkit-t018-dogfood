#!/usr/bin/env node
// Asserts that the three checked-in MCP configurations agree with each other and
// with the pin this repository claims to be running.
//
// Three copies of a configuration is three chances to drift. The copies exist
// because three different clients read three different files in three different
// schemas -- there is no shared format to collapse them into -- so the drift is
// made a build failure instead of a hazard.
//
// The files are NOT compared literally: VS Code substitutes ${workspaceFolder}
// and so carries a --cwd that the other two deliberately omit, and only the
// Copilot schemas have a `tools` allowlist. What is asserted is the set of
// invariants that actually determine behavior:
//
//   1. Every config launches the same npm package at the same exact version.
//   2. That version equals the pin passed in by scripts/validate-mcp.sh.
//   3. Nobody has quietly introduced @latest or a semver range.
//   4. Every config points at docs/adr.
//   5. Both Copilot schemas allowlist exactly the four read-only tools -- not
//      ["*"], which would let a future upstream tool through unreviewed.
//   6. .github/workflows/copilot-setup-steps.yml, which preinstalls and
//      integrity-checks the same package, carries the same version and the same
//      sha512 -- so the environment prepared for an agent cannot drift from the
//      server the configs point at.
//
// Usage: assert-mcp-config.mjs <repoRoot> <expectedVersion> <expectedSha512>

import { readFileSync } from 'node:fs';
import { join } from 'node:path';

const [, , repoRoot, expectedVersion, expectedSha512] = process.argv;

if (!repoRoot || !expectedVersion || !expectedSha512) {
  console.error(
    'usage: assert-mcp-config.mjs <repoRoot> <expectedVersion> <expectedSha512>',
  );
  process.exit(2);
}

const EXPECTED_SPEC = `@adrkit/mcp@${expectedVersion}`;
const EXPECTED_DIR = 'docs/adr';
const EXPECTED_TOOLS = [
  'get_decision',
  'get_decision_context',
  'list_superseded',
  'search_decisions',
];

const failures = [];
const checks = [];

function assert(id, description, expected, actual) {
  const e = JSON.stringify(expected);
  const a = JSON.stringify(actual);
  const ok = e === a;
  checks.push({ id, description, ok, expected: e, actual: a });
  if (!ok) failures.push({ id, description, expected: e, actual: a });
}

// The `$comment` key in .github/copilot-mcp-config.json is documentation for the
// human pasting it into repository settings, not part of the MCP schema. It is
// stripped here so this script validates the payload that actually gets pasted.
function loadConfig(relPath) {
  const abs = join(repoRoot, relPath);
  let raw;
  try {
    raw = readFileSync(abs, 'utf8');
  } catch (error) {
    console.error(`error: cannot read ${relPath}: ${error.message}`);
    process.exit(1);
  }
  try {
    return JSON.parse(raw);
  } catch (error) {
    console.error(`error: ${relPath} is not valid JSON: ${error.message}`);
    process.exit(1);
  }
}

// Locates the pinned package spec inside an args array, so the assertion does not
// depend on argument order.
function specFrom(args) {
  return args.find((a) => typeof a === 'string' && a.startsWith('@adrkit/mcp'));
}

function dirFrom(args) {
  const i = args.indexOf('--dir');
  return i >= 0 ? args[i + 1] : undefined;
}

// Each client has its own schema, so the expected `type` and argument array
// differ. They are asserted exactly rather than loosely: a config that merely
// *contains* the right package can still fail to launch, or launch against the
// wrong root, which CI would otherwise call green.
const targets = [
  {
    id: 'CLOUD',
    path: '.github/copilot-mcp-config.json',
    key: 'mcpServers',
    expectsTools: true,
    // Cloud agent runs the server from the repository checkout, so --cwd is
    // omitted deliberately and the server's default (process.cwd()) applies.
    expectedType: 'local',
    expectedArgs: ['-y', EXPECTED_SPEC, '--dir', EXPECTED_DIR],
  },
  {
    id: 'CLI',
    path: '.copilot/mcp-config.json',
    key: 'mcpServers',
    expectsTools: true,
    expectedType: 'local',
    expectedArgs: ['-y', EXPECTED_SPEC, '--dir', EXPECTED_DIR],
  },
  {
    id: 'VSCODE',
    path: '.vscode/mcp.json',
    key: 'servers',
    expectsTools: false,
    // VS Code launches from an arbitrary working directory, so --cwd with the
    // ${workspaceFolder} substitution is required here, not optional.
    expectedType: 'stdio',
    expectedArgs: [
      '-y',
      EXPECTED_SPEC,
      '--cwd',
      '${workspaceFolder}',
      '--dir',
      EXPECTED_DIR,
    ],
  },
];

for (const target of targets) {
  const config = loadConfig(target.path);
  const servers = config[target.key];

  if (!servers || typeof servers !== 'object') {
    failures.push({
      id: `${target.id}-SHAPE`,
      description: `${target.path} has a "${target.key}" object`,
      expected: 'object',
      actual: typeof servers,
    });
    continue;
  }

  // A second server would be launched by agents in this repository without ever
  // appearing in this script's other assertions, so the server set is pinned too.
  assert(
    `${target.id}-SERVERS`,
    `${target.path} declares exactly the adrkit server`,
    ['adrkit'],
    Object.keys(servers).sort(),
  );

  // A null or non-object entry passes a keys-only check while being unusable, so
  // the shape is asserted before anything is read out of it.
  const server = servers.adrkit;
  if (!server || typeof server !== 'object' || Array.isArray(server)) {
    failures.push({
      id: `${target.id}-SERVER-SHAPE`,
      description: `${target.path} defines the adrkit server as an object`,
      expected: '"object"',
      actual: JSON.stringify(server === null ? 'null' : typeof server),
    });
    continue;
  }

  const args = Array.isArray(server.args) ? server.args : [];

  assert(`${target.id}-COMMAND`, `${target.path} launches npx`, 'npx', server.command);
  assert(
    `${target.id}-TYPE`,
    `${target.path} declares type ${target.expectedType}`,
    target.expectedType,
    server.type,
  );
  // Asserted as a whole array, so an extra, missing, or reordered argument is a
  // failure. The individual SPEC/DIR checks below stay because they produce a
  // far more legible message for the mistake that actually happens at a repin.
  assert(
    `${target.id}-ARGS`,
    `${target.path} passes the exact expected arguments`,
    target.expectedArgs,
    args,
  );
  assert(
    `${target.id}-SPEC`,
    `${target.path} pins ${EXPECTED_SPEC}`,
    EXPECTED_SPEC,
    specFrom(args),
  );
  assert(
    `${target.id}-DIR`,
    `${target.path} points at ${EXPECTED_DIR}`,
    EXPECTED_DIR,
    dirFrom(args),
  );

  // `npx -y @adrkit/mcp` without a version resolves to whatever is current at
  // launch, which would make every agent run unreproducible. Caught explicitly
  // rather than relying on the SPEC assertion, so the failure message names the
  // actual mistake.
  const floating = args.filter(
    (a) =>
      typeof a === 'string' &&
      a.startsWith('@adrkit/mcp') &&
      a !== EXPECTED_SPEC,
  );
  assert(
    `${target.id}-NO-FLOAT`,
    `${target.path} carries no floating @adrkit/mcp spec`,
    [],
    floating,
  );

  if (target.expectsTools) {
    assert(
      `${target.id}-TOOLS`,
      `${target.path} allowlists exactly the four read-only tools`,
      EXPECTED_TOOLS,
      Array.isArray(server.tools) ? [...server.tools].sort() : server.tools,
    );
  }
}

// The Copilot setup-steps workflow preinstalls and integrity-checks the same
// package before an agent starts. It is a separate file in a separate format, so
// its pinned literals are checked as text.
//
// Comments are stripped first, and that is not cosmetic. This file's own header
// comment explains the pin and therefore *contains* the pinned spec, so a naive
// substring search over the raw text is satisfiable by documentation alone: the
// real command could be changed to `@latest` and every assertion would still
// pass. Only executable content is searched.
const SETUP_STEPS_PATH = '.github/workflows/copilot-setup-steps.yml';
const setupStepsAbs = join(repoRoot, SETUP_STEPS_PATH);
let setupSteps;
try {
  setupSteps = readFileSync(setupStepsAbs, 'utf8');
} catch (error) {
  failures.push({
    id: 'SETUP-READ',
    description: `${SETUP_STEPS_PATH} is readable`,
    expected: 'readable',
    actual: error.message,
  });
}

// Strips whole-line and trailing `#` comments. Quote-aware so a `#` inside a
// quoted value (a URL fragment, for example) is not mistaken for a comment.
function stripYamlComments(text) {
  return text
    .split('\n')
    .map((line) => {
      let quote = null;
      for (let i = 0; i < line.length; i += 1) {
        const ch = line[i];
        if (quote) {
          if (ch === quote && line[i - 1] !== '\\') quote = null;
        } else if (ch === '"' || ch === "'") {
          quote = ch;
        } else if (ch === '#' && (i === 0 || /\s/.test(line[i - 1]))) {
          return line.slice(0, i);
        }
      }
      return line;
    })
    .join('\n');
}

if (setupSteps !== undefined) {
  const active = stripYamlComments(setupSteps);

  assert(
    'SETUP-SPEC',
    `${SETUP_STEPS_PATH} preinstalls ${EXPECTED_SPEC} in executable content`,
    true,
    active.includes(EXPECTED_SPEC),
  );

  assert(
    'SETUP-SHA512',
    `${SETUP_STEPS_PATH} carries the pinned sha512 in executable content`,
    true,
    active.includes(expectedSha512),
  );

  // Any @adrkit/mcp spec that is not the exact pinned one -- including dist-tags
  // like @latest and ranges like ^0.6.0, which a semver-only sweep would miss
  // entirely because they contain no version number to compare.
  const badSpecs = [
    ...new Set(
      [...active.matchAll(/@adrkit\/mcp@([^\s"')\]]+)/g)]
        .map((m) => `@adrkit/mcp@${m[1]}`)
        .filter((spec) => spec !== EXPECTED_SPEC),
    ),
  ].sort();
  assert(
    'SETUP-NO-FLOAT',
    `${SETUP_STEPS_PATH} carries no non-exact @adrkit/mcp spec`,
    [],
    badSpecs,
  );

  // Catches the repin mistake of updating one literal and not the other. Two
  // forms carry a version here and both must be swept: the npm spec, and the
  // packed tarball filename `adrkit-mcp-<version>.tgz` -- the version there is
  // not adjacent to the package spec, so a single pattern anchored on it misses
  // that occurrence.
  const mentioned = [
    ...new Set([
      ...[...active.matchAll(/@adrkit\/mcp@(\d+\.\d+\.\d+)/g)].map((m) => m[1]),
      ...[...active.matchAll(/\bmcp-(\d+\.\d+\.\d+)\.tgz\b/g)].map((m) => m[1]),
    ]),
  ].sort();
  assert(
    'SETUP-NO-STALE',
    `${SETUP_STEPS_PATH} mentions only version ${expectedVersion}`,
    [expectedVersion],
    mentioned,
  );

  // A version present in neither form would make SETUP-NO-STALE vacuous -- an
  // empty set trivially contains no stale version -- so both forms are required
  // to be present in executable content.
  assert(
    'SETUP-SWEEP-NONVACUOUS',
    `${SETUP_STEPS_PATH} contains both a pinned spec and a pinned tarball filename`,
    { spec: true, tarball: true },
    {
      spec: /@adrkit\/mcp@\d+\.\d+\.\d+/.test(active),
      tarball: /\bmcp-\d+\.\d+\.\d+\.tgz\b/.test(active),
    },
  );
}

for (const check of checks) {
  console.log(`${check.ok ? 'ok  ' : 'FAIL'} ${check.id}  ${check.description}`);
}

if (failures.length > 0) {
  console.error('');
  console.error(`MCP configuration drift: ${failures.length} assertion(s) failed.`);
  for (const failure of failures) {
    console.error(`  ${failure.id}: ${failure.description}`);
    console.error(`    expected: ${failure.expected}`);
    console.error(`    actual:   ${failure.actual}`);
  }
  console.error('');
  console.error(
    'The three MCP configs and the pin in scripts/validate-mcp.sh must agree.',
  );
  process.exit(1);
}

console.log('');
console.log(
  `MCP configuration agreement: ${checks.length} assertions passed (${EXPECTED_SPEC}).`,
);
